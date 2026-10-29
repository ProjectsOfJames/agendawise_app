import '../../../core/cloud/activity_actions.dart';

/// Days without activity after which an admin may claim the superadmin role.
const superadminInactivityLimit = Duration(days: 180);

/// Raw log entries older than this are removed by the retention purge.
const logRetention = Duration(days: 365);

const logPageSize = 50;
const exportRowCap = 5000;

/// Firestore allows at most 30 combinations of "in" values in one query;
/// 3 users x 10 actions stays within that.
const maxUserMatches = 3;
const maxActionFilters = 10;

enum AdminRole { none, admin, superadmin }

class AdminStatus {
  const AdminStatus({
    required this.role,
    this.superadminUid,
    this.superadminLastActive,
  });

  static const none = AdminStatus(role: AdminRole.none);

  final AdminRole role;
  final String? superadminUid;
  final DateTime? superadminLastActive;

  bool get isAdmin => role != AdminRole.none;
  bool get isSuperadmin => role == AdminRole.superadmin;

  /// True when this admin may take over an inactive superadmin's role.
  bool canClaim(DateTime now) {
    if (role != AdminRole.admin) return false;
    final last = superadminLastActive;
    return last != null && now.difference(last) > superadminInactivityLimit;
  }
}

class AdminSummary {
  const AdminSummary({
    required this.signUpsLast7Days,
    required this.activeToday,
    required this.entriesToday,
    required this.accountsDeletedThisMonth,
  });

  final int signUpsLast7Days;
  final int activeToday;
  final int entriesToday;
  final int accountsDeletedThisMonth;
}

class LogEntry {
  const LogEntry({
    required this.id,
    required this.uid,
    required this.action,
    required this.success,
    required this.createdAt,
    required this.appVersion,
    required this.platform,
    required this.meta,
  });

  final String id;
  final String uid;

  /// Stored action name; unknown names are kept as they are.
  final String action;
  final bool success;
  final DateTime? createdAt;
  final String appVersion;
  final String platform;
  final Map<String, Object?> meta;

  String get actionLabel => ActivityAction.fromWire(action)?.label ?? action;
}

enum DatePreset {
  today('Today'),
  last7Days('Last 7 days'),
  last30Days('Last 30 days'),
  last12Months('Last 12 months'),
  all('All time');

  const DatePreset(this.label);

  final String label;

  /// Start of the range, or null for no lower bound.
  DateTime? start(DateTime now) {
    // Calendar arithmetic keeps midnight correct across daylight saving.
    DateTime daysBack(int days) => DateTime(now.year, now.month, now.day - days);
    return switch (this) {
      DatePreset.today => daysBack(0),
      DatePreset.last7Days => daysBack(6),
      DatePreset.last30Days => daysBack(29),
      DatePreset.last12Months => DateTime(now.year - 1, now.month, now.day),
      DatePreset.all => null,
    };
  }
}

enum OutcomeFilter {
  any('Any outcome'),
  success('Success'),
  failure('Failure');

  const OutcomeFilter(this.label);

  final String label;
}

/// Filters for the log viewer and export. [uids] restricts entries to those
/// users; [userQuery] is the text that produced them, kept for headers.
class LogFilter {
  const LogFilter({
    this.uids = const {},
    this.userQuery,
    this.actions = const {},
    this.datePreset = DatePreset.last7Days,
    this.outcome = OutcomeFilter.any,
  });

  final Set<String> uids;
  final String? userQuery;
  final Set<ActivityAction> actions;
  final DatePreset datePreset;
  final OutcomeFilter outcome;

  LogFilter copyWith({
    Set<String>? uids,
    String? userQuery,
    bool clearUser = false,
    Set<ActivityAction>? actions,
    DatePreset? datePreset,
    OutcomeFilter? outcome,
  }) =>
      LogFilter(
        uids: clearUser ? const {} : (uids ?? this.uids),
        userQuery: clearUser ? null : (userQuery ?? this.userQuery),
        actions: actions ?? this.actions,
        datePreset: datePreset ?? this.datePreset,
        outcome: outcome ?? this.outcome,
      );

  /// One line per active filter, for export headers.
  List<String> describe() => [
        'Date range: ${datePreset.label}',
        if (userQuery != null) 'User: $userQuery',
        'Actions: ${actions.isEmpty ? 'All' : actions.map((a) => a.wire).join(', ')}',
        'Outcome: ${outcome.label}',
      ];
}

class AdminInfo {
  const AdminInfo({
    required this.uid,
    required this.displayName,
    required this.email,
    this.addedAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final DateTime? addedAt;
}
