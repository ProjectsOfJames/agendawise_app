import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cloud/activity_actions.dart';
import '../../../core/cloud/activity_logger.dart';
import '../../../core/cloud/firebase_setup.dart';
import '../../../core/utils/clock.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/account.dart';
import '../domain/account_rules.dart';
import 'user_repository.dart';

const _lastActiveKey = 'account_last_active_date';

/// Online account operations.
abstract interface class AccountService {
  /// The signed-in account, or null; emits on every change.
  Stream<Account?> watch();

  Future<void> signUp(SignUpRequest request);

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  Future<void> updateDisplayName(String name);

  /// Sends a confirmation link to [newEmail]; the address changes once the
  /// link is opened.
  Future<void> requestEmailChange({
    required String newEmail,
    required String password,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Deletes the account and its online records. Raw activity entries are
  /// first reduced to anonymous monthly totals.
  Future<void> deleteAccount({required String password});

  Future<bool> usageOptIn();

  Future<void> setUsageOptIn(bool value);

  Future<void> setProfilePicture(String? path);

  /// Stamps the account's last active day, at most once a day.
  Future<void> recordActive();
}

/// Used when Firebase is not available (tests, setup not finished).
class UnavailableAccountService implements AccountService {
  const UnavailableAccountService();

  static const _error = AccountException(
    'Online accounts are not available on this device right now.',
  );

  @override
  Stream<Account?> watch() => Stream.value(null);

  @override
  Future<void> signUp(SignUpRequest request) async => throw _error;

  @override
  Future<void> signIn({required String email, required String password}) async =>
      throw _error;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordReset(String email) async => throw _error;

  @override
  Future<void> updateDisplayName(String name) async => throw _error;

  @override
  Future<void> requestEmailChange({
    required String newEmail,
    required String password,
  }) async =>
      throw _error;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async =>
      throw _error;

  @override
  Future<void> deleteAccount({required String password}) async => throw _error;

  @override
  Future<bool> usageOptIn() async => false;

  @override
  Future<void> setUsageOptIn(bool value) async => throw _error;

  @override
  Future<void> setProfilePicture(String? path) async => throw _error;

  @override
  Future<void> recordActive() async {}
}

/// Firebase Authentication for sign-in and Firestore `users/{uid}` for the
/// profile. Only the fields in the privacy notice are stored online.
class FirebaseAccountService implements AccountService {
  FirebaseAccountService({
    required UserRepository cache,
    required SettingsRepository settings,
    required Clock clock,
    ActivityLogger activity = const NoopActivityLogger(),
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _cache = cache,
        _settings = settings,
        _clock = clock,
        _activity = activity,
        _auth = auth ?? fb.FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final UserRepository _cache;
  final SettingsRepository _settings;
  final Clock _clock;
  final ActivityLogger _activity;
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  @override
  Stream<Account?> watch() {
    late StreamController<Account?> controller;
    StreamSubscription<fb.User?>? authSub;
    StreamSubscription<Object?>? cacheSub;

    void listenTo(fb.User? user) {
      cacheSub?.cancel();
      if (user == null) {
        controller.add(null);
        return;
      }
      final email = user.email ?? '';
      final name = user.displayName ?? '';
      unawaited(_cache.cacheProfile(uid: user.uid, fullName: name, email: email));
      cacheSub = _cache.watchCached().listen((cached) {
        controller.add(Account(
          uid: user.uid,
          displayName:
              name.isNotEmpty ? name : (cached?.fullName ?? email),
          email: email,
          imagePath: cached?.id == user.uid ? cached?.imagePath : null,
        ));
      });
    }

    controller = StreamController<Account?>(
      onListen: () => authSub = _auth.userChanges().listen(listenTo),
      onCancel: () async {
        await authSub?.cancel();
        await cacheSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> signUp(SignUpRequest request) async {
    if (!request.ageConfirmed) {
      throw const AccountException('Accounts are for people aged 18 or older.');
    }
    if (!request.consentAccepted) {
      throw const AccountException('Please accept the privacy notice.');
    }
    final name = request.displayName.trim();
    final email = request.email.trim();
    final credential = await _guard(() => _auth.createUserWithEmailAndPassword(
          email: email,
          password: request.password,
        ));
    final user = credential.user!;
    try {
      await user.updateDisplayName(name);
      await _userDoc(user.uid).set({
        'displayName': name,
        'emailLower': email.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
        'consentVersion': privacyNoticeVersion,
        'consentAt': FieldValue.serverTimestamp(),
        'analyticsOptIn': request.usageOptIn,
        'ageConfirmed': true,
        'lastActiveDate': dayStamp(_clock()),
      });
    } on Object {
      // Without the profile record the account is unusable; remove it so
      // the same email can be used again.
      await user.delete().catchError((Object _) {});
      throw const AccountException(
        'The account could not be set up. Check your connection and try again.',
      );
    }
    await _cache.cacheProfile(uid: user.uid, fullName: name, email: email);
    await _settings.setString(_lastActiveKey, dayStamp(_clock()));
    await user.reload();
    await _activity.refreshOptIn();
    _activity.log(ActivityAction.accountCreated);
    _activity.log(
      ActivityAction.consentAccepted,
      meta: {'version': privacyNoticeVersion, 'usageOptIn': request.usageOptIn},
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _guard(() => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ));
    await _settings.remove(_lastActiveKey);
    await _activity.refreshOptIn();
    _activity.log(ActivityAction.signIn);
    unawaited(recordActive());
  }

  @override
  Future<void> signOut() async {
    await _activity.logAndWait(ActivityAction.signOut);
    await _auth.signOut();
    await _activity.refreshOptIn();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
    // Only recorded when requested while signed in.
    _activity.log(ActivityAction.passwordResetRequested);
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final user = _requireUser();
    final clean = name.trim();
    await _guard(() => user.updateDisplayName(clean));
    await _guard(() => _userDoc(user.uid).update({
          'displayName': clean,
          'emailLower': ?user.email?.toLowerCase(),
        }));
    await _cache.cacheProfile(
        uid: user.uid, fullName: clean, email: user.email ?? '');
    await user.reload();
  }

  @override
  Future<void> requestEmailChange({
    required String newEmail,
    required String password,
  }) async {
    final user = await _reauthenticate(password);
    await _guard(() => user.verifyBeforeUpdateEmail(newEmail.trim()));
    _activity.log(ActivityAction.emailChanged, meta: {'stage': 'requested'});
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = await _reauthenticate(currentPassword);
    await _guard(() => user.updatePassword(newPassword));
    _activity.log(ActivityAction.passwordChanged);
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    final user = await _reauthenticate(password);
    final uid = user.uid;
    try {
      await _anonymiseActivity(uid);
      await _userDoc(uid).delete();
    } on FirebaseException catch (error) {
      debugPrint('Account deletion stopped: $error');
      throw const AccountException(
        'Your account could not be deleted right now. Nothing was lost; '
        'please try again later.',
      );
    }
    await _guard(user.delete);

    final cached = await _cache.getCached();
    final picture = cached?.imagePath;
    if (picture != null) {
      final file = File(picture);
      if (await file.exists()) await file.delete();
    }
    await _cache.clear();
    await _settings.remove(_lastActiveKey);
  }

  /// Replaces the user's raw activity entries by anonymous monthly counts,
  /// then counts the deletion itself. Reads come from the server so this
  /// fails cleanly when offline instead of working from a stale cache.
  Future<void> _anonymiseActivity(String uid) async {
    final logs = await _db
        .collection('activity_logs')
        .where('uid', isEqualTo: uid)
        .get(const GetOptions(source: Source.server));

    final totals = <String, Map<String, int>>{};
    for (final doc in logs.docs) {
      final data = doc.data();
      final action = data['action'];
      final createdAt = data['createdAt'];
      if (action is! String || createdAt is! Timestamp) continue;
      final month = monthStamp(createdAt.toDate());
      final counts = totals.putIfAbsent(month, () => {});
      counts[action] = (counts[action] ?? 0) + 1;
    }

    for (final entry in totals.entries) {
      await _db.collection('anon_stats').doc(entry.key).set({
        'counts': {
          for (final count in entry.value.entries)
            count.key: FieldValue.increment(count.value),
        },
      }, SetOptions(merge: true));
    }

    // Firestore batches hold at most 500 writes.
    for (var i = 0; i < logs.docs.length; i += 400) {
      final batch = _db.batch();
      for (final doc in logs.docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await _db.collection('anon_stats').doc(monthStamp(_clock())).set({
      'accountsDeleted': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  @override
  Future<bool> usageOptIn() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final snapshot = await _userDoc(user.uid).get();
      return snapshot.data()?['analyticsOptIn'] == true;
    } on FirebaseException {
      return false;
    }
  }

  @override
  Future<void> setUsageOptIn(bool value) async {
    final user = _requireUser();
    await _guard(() => _userDoc(user.uid).update({
          'analyticsOptIn': value,
          'emailLower': ?user.email?.toLowerCase(),
        }));
    await _activity.refreshOptIn();
  }

  @override
  Future<void> setProfilePicture(String? path) async {
    final user = _requireUser();
    await _cache.updateImagePath(user.uid, path);
  }

  @override
  Future<void> recordActive() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final today = dayStamp(_clock());
    if (await _settings.getString(_lastActiveKey) == today) return;
    try {
      final email = user.email;
      await _userDoc(user.uid).update({
        'lastActiveDate': today,
        // Keeps the admin lookup field in step after a confirmed email change.
        'emailLower': ?email?.toLowerCase(),
      });
      await _settings.setString(_lastActiveKey, today);
    } on Object catch (error) {
      debugPrint('Could not record activity: $error');
      return;
    }
    await _touchSuperadmin(user.uid);
  }

  /// Keeps the superadmin's last active time fresh, which decides when
  /// another admin may claim the role. Other users cannot read the record,
  /// so the denied read is expected and ignored.
  Future<void> _touchSuperadmin(String uid) async {
    try {
      final config = _db.collection('config').doc('superadmin');
      final snapshot = await config.get();
      if (snapshot.data()?['uid'] != uid) return;
      await config.update({'lastActiveAt': FieldValue.serverTimestamp()});
    } on FirebaseException {
      // Not an admin.
    }
  }

  fb.User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AccountException('Please sign in again.');
    }
    return user;
  }

  Future<fb.User> _reauthenticate(String password) async {
    final user = _requireUser();
    final email = user.email;
    if (email == null) throw const AccountException('Please sign in again.');
    final credential =
        fb.EmailAuthProvider.credential(email: email, password: password);
    await _guard(() => user.reauthenticateWithCredential(credential));
    return user;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on fb.FirebaseAuthException catch (error) {
      throw AccountException(messageForAuthCode(error.code));
    } on FirebaseException catch (error) {
      if (error.code == 'unavailable') {
        throw const AccountException(
            'No internet connection. Connect and try again.');
      }
      throw AccountException('Something went wrong (${error.code}).');
    }
  }
}

final accountServiceProvider = Provider<AccountService>((ref) {
  if (!ref.watch(cloudAvailableProvider)) return const UnavailableAccountService();
  return FirebaseAccountService(
    cache: ref.watch(userRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
    activity: ref.watch(activityLoggerProvider),
  );
});
