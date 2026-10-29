const minPasswordLength = 8;
const maxDisplayNameLength = 60;

/// Version of the privacy notice the user accepts at sign-up. Raise it when
/// the notice changes so the accepted version can be told apart.
const privacyNoticeVersion = '2026-10-29';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? validateDisplayName(String value) {
  final name = value.trim();
  if (name.isEmpty) return 'Enter your name';
  if (name.length > maxDisplayNameLength) {
    return 'Use at most $maxDisplayNameLength characters';
  }
  return null;
}

String? validateEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return 'Enter your email address';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
  return null;
}

String? validateNewPassword(String password, String confirmation) {
  if (password.length < minPasswordLength) {
    return 'Use at least $minPasswordLength characters';
  }
  if (password != confirmation) return 'The passwords do not match';
  return null;
}

/// Turns Firebase Authentication error codes into plain messages.
String messageForAuthCode(String code) => switch (code) {
      'invalid-email' => 'That email address is not valid.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' =>
        'The email or password is incorrect.',
      'email-already-in-use' => 'An account with this email already exists.',
      'weak-password' =>
        'Choose a stronger password of at least $minPasswordLength characters.',
      'requires-recent-login' => 'Please enter your password again.',
      'too-many-requests' =>
        'Too many attempts. Wait a few minutes and try again.',
      'network-request-failed' =>
        'No internet connection. Connect and try again.',
      'operation-not-allowed' =>
        'Email sign-in is not switched on for this app.',
      _ => 'Something went wrong ($code). Please try again.',
    };

/// Today's date as yyyy-mm-dd, used for the once-a-day activity stamp.
String dayStamp(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-'
    '${now.month.toString().padLeft(2, '0')}-'
    '${now.day.toString().padLeft(2, '0')}';

/// Month key for anonymous statistics, e.g. "2026-10".
String monthStamp(DateTime at) =>
    '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}';
