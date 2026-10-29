import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_actions.dart';
import 'firebase_setup.dart';

/// Writes entries to the cloud activity log.
abstract interface class ActivityLogger {
  /// Records [action] for the signed-in user. Does nothing when signed out,
  /// or for usage actions when the user has not opted in. Never throws and
  /// never waits for the network: Firestore keeps unsent entries and
  /// delivers them once the device is online.
  void log(
    ActivityAction action, {
    bool success = true,
    Map<String, Object?> meta = const {},
  });

  /// Like [log], but waits (briefly) until the entry reaches the server.
  /// Used just before signing out, after which it could not be sent.
  Future<void> logAndWait(
    ActivityAction action, {
    Duration timeout = const Duration(seconds: 4),
  });

  /// Re-reads the user's usage choice after it changes or on sign-in.
  Future<void> refreshOptIn();
}

class NoopActivityLogger implements ActivityLogger {
  const NoopActivityLogger();

  @override
  void log(
    ActivityAction action, {
    bool success = true,
    Map<String, Object?> meta = const {},
  }) {}

  @override
  Future<void> logAndWait(
    ActivityAction action, {
    Duration timeout = const Duration(seconds: 4),
  }) async {}

  @override
  Future<void> refreshOptIn() async {}
}

class FirestoreActivityLogger implements ActivityLogger {
  FirestoreActivityLogger({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String? _optInFor;
  bool _optIn = false;

  @override
  void log(
    ActivityAction action, {
    bool success = true,
    Map<String, Object?> meta = const {},
  }) {
    final user = _auth.currentUser;
    if (user == null) return;
    unawaited(_write(user.uid, action, success, meta));
  }

  @override
  Future<void> logAndWait(
    ActivityAction action, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _write(user.uid, action, true, const {}).timeout(timeout);
    } on TimeoutException {
      // Left queued; it is sent if the same user signs in again.
    }
  }

  Future<void> _write(
    String uid,
    ActivityAction action,
    bool success,
    Map<String, Object?> meta,
  ) async {
    try {
      if (action.needsOptIn) {
        if (_optInFor != uid) await refreshOptIn();
        if (!_optIn) return;
      }
      await _db.collection('activity_logs').add({
        'uid': uid,
        'action': action.wire,
        'outcome': success ? 'success' : 'failure',
        'createdAt': FieldValue.serverTimestamp(),
        'appVersion': appVersion,
        'platform': defaultTargetPlatform.name,
        'meta': meta,
      });
    } on Object catch (error) {
      debugPrint('Activity entry not written: $error');
    }
  }

  @override
  Future<void> refreshOptIn() async {
    final user = _auth.currentUser;
    if (user == null) {
      _optInFor = null;
      _optIn = false;
      return;
    }
    try {
      final snapshot = await _db.collection('users').doc(user.uid).get();
      _optIn = snapshot.data()?['analyticsOptIn'] == true;
      _optInFor = user.uid;
    } on Object {
      _optIn = false;
    }
  }
}

final activityLoggerProvider = Provider<ActivityLogger>(
  (ref) => ref.watch(cloudAvailableProvider)
      ? FirestoreActivityLogger()
      : const NoopActivityLogger(),
);
