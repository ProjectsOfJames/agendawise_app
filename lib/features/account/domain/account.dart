/// The signed-in online account, combined with on-device extras.
class Account {
  const Account({
    required this.uid,
    required this.displayName,
    required this.email,
    this.imagePath,
  });

  final String uid;
  final String displayName;
  final String email;

  /// Profile picture kept on this device only.
  final String? imagePath;
}

/// Thrown by account operations with a message that can be shown as is.
class AccountException implements Exception {
  const AccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What the user agreed to when creating an account.
class SignUpRequest {
  const SignUpRequest({
    required this.displayName,
    required this.email,
    required this.password,
    required this.ageConfirmed,
    required this.consentAccepted,
    required this.usageOptIn,
  });

  final String displayName;
  final String email;
  final String password;
  final bool ageConfirmed;
  final bool consentAccepted;

  /// Optional sharing of anonymous usage events; off unless chosen.
  final bool usageOptIn;
}
