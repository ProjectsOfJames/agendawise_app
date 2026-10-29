import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/cloud/activity_actions.dart';
import '../../../core/cloud/activity_logger.dart';
import '../../../core/cloud/firebase_setup.dart';
import '../../../core/utils/clock.dart';
import '../../account/domain/account_rules.dart';
import '../domain/admin_models.dart';
import '../domain/log_export.dart';

class AdminException implements Exception {
  const AdminException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One page of log entries. [cursor] is passed back to load the next page.
class LogPage {
  const LogPage({
    required this.entries,
    required this.cursor,
    required this.hasMore,
  });

  final List<LogEntry> entries;
  final Object? cursor;
  final bool hasMore;
}

enum ExportFormat { csv, json }

/// Admin tools and the user's own activity history, backed by Firestore.
/// Access is enforced by the security rules; the checks here only produce
/// clearer messages.
class AdminRepository {
  AdminRepository({
    required ActivityLogger activity,
    required Clock clock,
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _activity = activity,
        _clock = clock,
        _auth = auth ?? fb.FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final ActivityLogger _activity;
  final Clock _clock;
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _logs =>
      _db.collection('activity_logs');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _admins =>
      _db.collection('admins');
  DocumentReference<Map<String, dynamic>> get _superadmin =>
      _db.collection('config').doc('superadmin');

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const AdminException('Please sign in again.');
    return uid;
  }

  // ---------------------------------------------------------------- role

  Future<AdminStatus> status() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return AdminStatus.none;

    var listedAsAdmin = false;
    try {
      listedAsAdmin = (await _admins.doc(uid).get()).exists;
    } on FirebaseException {
      return AdminStatus.none;
    }

    // A superadmin may have no admins entry, so the config record is read
    // either way. Ordinary users are refused, which means "not an admin".
    try {
      final config = await _superadmin.get();
      final data = config.data();
      final superUid = data?['uid'] as String?;
      final lastActive = (data?['lastActiveAt'] as Timestamp?)?.toDate();
      if (superUid == uid) {
        return AdminStatus(
          role: AdminRole.superadmin,
          superadminUid: superUid,
          superadminLastActive: lastActive,
        );
      }
      if (listedAsAdmin) {
        return AdminStatus(
          role: AdminRole.admin,
          superadminUid: superUid,
          superadminLastActive: lastActive,
        );
      }
    } on FirebaseException {
      // Not readable: not an admin.
    }
    return AdminStatus.none;
  }

  // ------------------------------------------------------------- summary

  Future<AdminSummary> summary() async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = DatePreset.last7Days.start(now)!;

    Future<int> count(Query<Map<String, dynamic>> query) async =>
        (await query.count().get()).count ?? 0;

    final results = await Future.wait([
      count(_users.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))),
      count(_users.where('lastActiveDate', isEqualTo: dayStamp(now))),
      count(_logs.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(today))),
      _db
          .collection('anon_stats')
          .doc(monthStamp(now))
          .get()
          .then((s) => (s.data()?['accountsDeleted'] as num?)?.toInt() ?? 0),
    ]);
    return AdminSummary(
      signUpsLast7Days: results[0],
      activeToday: results[1],
      entriesToday: results[2],
      accountsDeletedThisMonth: results[3],
    );
  }

  Future<List<LogEntry>> latest({int limit = 5}) async {
    final snapshot =
        await _logs.orderBy('createdAt', descending: true).limit(limit).get();
    return snapshot.docs.map(_entryFrom).toList();
  }

  // ---------------------------------------------------------------- logs

  /// Finds users by exact email (case-insensitive) or exact display name.
  /// At most [maxUserMatches] are returned so the query stays within
  /// Firestore's limits when combined with an action filter.
  Future<Set<String>> findUsers(String text) async {
    final query = text.trim();
    if (query.isEmpty) return const {};
    final snapshot = query.contains('@')
        ? await _users
            .where('emailLower', isEqualTo: query.toLowerCase())
            .limit(maxUserMatches)
            .get()
        : await _users
            .where('displayName', isEqualTo: query)
            .limit(maxUserMatches)
            .get();
    return snapshot.docs.map((d) => d.id).toSet();
  }

  Query<Map<String, dynamic>> _filtered(LogFilter filter) {
    Query<Map<String, dynamic>> query = _logs;
    final uids = filter.uids.toList();
    if (uids.length == 1) {
      query = query.where('uid', isEqualTo: uids.single);
    } else if (uids.isNotEmpty) {
      query = query.where('uid', whereIn: uids);
    }
    final actions = filter.actions.map((a) => a.wire).toList();
    if (actions.length == 1) {
      query = query.where('action', isEqualTo: actions.single);
    } else if (actions.isNotEmpty) {
      query = query.where('action', whereIn: actions);
    }
    switch (filter.outcome) {
      case OutcomeFilter.any:
        break;
      case OutcomeFilter.success:
        query = query.where('outcome', isEqualTo: 'success');
      case OutcomeFilter.failure:
        query = query.where('outcome', isEqualTo: 'failure');
    }
    final start = filter.datePreset.start(_clock());
    if (start != null) {
      query = query.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }
    return query.orderBy('createdAt', descending: true);
  }

  Future<LogPage> page(LogFilter filter, {Object? after}) async {
    var query = _filtered(filter).limit(logPageSize);
    if (after is DocumentSnapshot) query = query.startAfterDocument(after);
    final snapshot = await _guard(query.get);
    final docs = snapshot.docs;
    return LogPage(
      entries: docs.map(_entryFrom).toList(),
      cursor: docs.isEmpty ? after : docs.last,
      hasMore: docs.length == logPageSize,
    );
  }

  // -------------------------------------------------------------- export

  /// Writes the filtered entries (at most [exportRowCap]) to a file and
  /// opens the share sheet. Returns the number of rows written.
  Future<int> export(
    LogFilter filter, {
    required ExportFormat format,
    required bool includeEmails,
  }) async {
    final me = _requireUid();
    final entries = <LogEntry>[];
    DocumentSnapshot? cursor;
    var truncated = false;
    while (true) {
      var query = _filtered(filter).limit(500);
      if (cursor != null) query = query.startAfterDocument(cursor);
      final snapshot = await _guard(query.get);
      entries.addAll(snapshot.docs.map(_entryFrom));
      if (entries.length >= exportRowCap) {
        truncated = entries.length > exportRowCap || snapshot.docs.length == 500;
        entries.removeRange(exportRowCap, entries.length);
        break;
      }
      if (snapshot.docs.length < 500) break;
      cursor = snapshot.docs.last;
    }

    final emails = includeEmails
        ? await _emailsFor(entries.map((e) => e.uid).toSet())
        : null;
    final now = _clock();
    final header = exportHeader(
      exportedBy: _auth.currentUser?.email ?? me,
      exportedAt: now,
      filter: filter,
      rows: entries.length,
      truncated: truncated,
    );
    final content = switch (format) {
      ExportFormat.csv =>
        logsToCsv(entries: entries, header: header, emails: emails),
      ExportFormat.json =>
        logsToJson(entries: entries, header: header, emails: emails),
    };

    final stamp = '${dayStamp(now)}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/agendawise-logs-$stamp.${format.name}');
    await file.writeAsString(content);

    _activity.log(ActivityAction.adminLogsExported, meta: {
      'rows': entries.length,
      'format': format.name,
      'includeEmails': includeEmails,
    });

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      subject: 'AgendaWise activity log',
    ));
    return entries.length;
  }

  Future<Map<String, String>> _emailsFor(Set<String> uids) async {
    final result = <String, String>{};
    final list = uids.toList();
    for (var i = 0; i < list.length; i += 30) {
      final chunk = list.sublist(i, (i + 30).clamp(0, list.length));
      final snapshot =
          await _users.where(FieldPath.documentId, whereIn: chunk).get();
      for (final doc in snapshot.docs) {
        final email = doc.data()['emailLower'];
        if (email is String) result[doc.id] = email;
      }
    }
    return result;
  }

  // ----------------------------------------------------------- retention

  /// Deletes entries older than [logRetention]. Returns how many went.
  Future<int> purgeOld() async {
    final cutoff = Timestamp.fromDate(_clock().subtract(logRetention));
    var deleted = 0;
    while (true) {
      final snapshot = await _guard(() => _logs
          .where('createdAt', isLessThan: cutoff)
          .orderBy('createdAt')
          .limit(400)
          .get());
      if (snapshot.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await _guard(batch.commit);
      deleted += snapshot.docs.length;
      if (snapshot.docs.length < 400) break;
    }
    _activity.log(ActivityAction.adminLogsPurged, meta: {'count': deleted});
    return deleted;
  }

  // -------------------------------------------------------------- admins

  Future<List<AdminInfo>> admins() async {
    final snapshot = await _guard(_admins.get);
    final profiles = await _profilesFor(snapshot.docs.map((d) => d.id).toSet());
    final list = [
      for (final doc in snapshot.docs)
        AdminInfo(
          uid: doc.id,
          displayName: profiles[doc.id]?.$1 ?? 'Unknown user',
          email: profiles[doc.id]?.$2 ?? '',
          addedAt: (doc.data()['addedAt'] as Timestamp?)?.toDate(),
        ),
    ];
    list.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return list;
  }

  Future<Map<String, (String, String)>> _profilesFor(Set<String> uids) async {
    final result = <String, (String, String)>{};
    final list = uids.toList();
    for (var i = 0; i < list.length; i += 30) {
      final chunk = list.sublist(i, (i + 30).clamp(0, list.length));
      final snapshot =
          await _users.where(FieldPath.documentId, whereIn: chunk).get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        result[doc.id] = (
          data['displayName'] as String? ?? '',
          data['emailLower'] as String? ?? '',
        );
      }
    }
    return result;
  }

  Future<void> addAdmin(String email) async {
    final me = _requireUid();
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) throw const AdminException('Enter an email address.');
    final match = await _guard(
        () => _users.where('emailLower', isEqualTo: clean).limit(1).get());
    if (match.docs.isEmpty) {
      throw const AdminException('No account uses that email address.');
    }
    final uid = match.docs.single.id;
    if (uid == me) {
      throw const AdminException('You are already the superadmin.');
    }
    final existing = await _guard(() => _admins.doc(uid).get());
    if (existing.exists) {
      throw const AdminException('That account is already an admin.');
    }
    await _guard(() => _admins.doc(uid).set({
          'role': 'admin',
          'addedBy': me,
          'addedAt': FieldValue.serverTimestamp(),
        }));
    _activity.log(ActivityAction.adminAdded, meta: {'targetUid': uid});
  }

  Future<void> removeAdmin(String uid) async {
    await _guard(() => _admins.doc(uid).delete());
    _activity.log(ActivityAction.adminRemoved, meta: {'targetUid': uid});
  }

  /// Hands the superadmin role to an existing admin after confirming the
  /// current password. The new superadmin's admins entry is removed in the
  /// same write; the previous superadmin becomes an ordinary user.
  Future<void> transferSuperadmin({
    required String targetUid,
    required String password,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AdminException('Please sign in again.');
    }
    try {
      await user.reauthenticateWithCredential(
        fb.EmailAuthProvider.credential(email: email, password: password),
      );
    } on fb.FirebaseAuthException catch (error) {
      throw AdminException(messageForAuthCode(error.code));
    }
    final batch = _db.batch()
      ..update(_superadmin, {
        'uid': targetUid,
        'lastActiveAt': FieldValue.serverTimestamp(),
      })
      ..delete(_admins.doc(targetUid));
    await _guard(batch.commit);
    _activity.log(ActivityAction.superadminTransferred,
        meta: {'targetUid': targetUid});
  }

  /// Takes over the role from a superadmin inactive for longer than
  /// [superadminInactivityLimit]. The rules check the time on the server.
  Future<void> claimSuperadmin() async {
    final me = _requireUid();
    final batch = _db.batch()
      ..update(_superadmin, {
        'uid': me,
        'lastActiveAt': FieldValue.serverTimestamp(),
      })
      ..delete(_admins.doc(me));
    await _guard(batch.commit);
    _activity.log(ActivityAction.superadminClaimed);
  }

  // ------------------------------------------------------------- helpers

  LogEntry _entryFrom(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final meta = data['meta'];
    return LogEntry(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      action: data['action'] as String? ?? '',
      success: data['outcome'] != 'failure',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      appVersion: data['appVersion'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      meta: meta is Map ? Map<String, Object?>.from(meta) : const {},
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (error) {
      debugPrint('Admin request failed: $error');
      throw AdminException(switch (error.code) {
        'permission-denied' => 'You do not have permission to do that.',
        'unavailable' => 'No internet connection. Connect and try again.',
        'failed-precondition' =>
          'The database is still preparing for this filter. Try again in a few minutes.',
        _ => 'Something went wrong (${error.code}).',
      });
    }
  }
}

/// Null when Firebase is not available.
final adminRepositoryProvider = Provider<AdminRepository?>((ref) {
  if (!ref.watch(cloudAvailableProvider)) return null;
  return AdminRepository(
    activity: ref.watch(activityLoggerProvider),
    clock: ref.watch(clockProvider),
  );
});
