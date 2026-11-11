class AdminUserMetrics {
  const AdminUserMetrics({
    required this.totalAccounts,
    required this.recentSignups,
    required this.activeAccounts,
    this.suspendedAccounts = 0,
    this.openSupportRequests = 0,
  });

  final int totalAccounts;
  final int recentSignups;
  final int activeAccounts;
  final int suspendedAccounts;
  final int openSupportRequests;

  factory AdminUserMetrics.fromMap(Map<String, dynamic> map) {
    int readCount(String key) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return AdminUserMetrics(
      totalAccounts: readCount('total_accounts'),
      recentSignups: readCount('signups_last_30_days'),
      activeAccounts: readCount('active_last_30_days'),
      suspendedAccounts: readCount('suspended_accounts'),
      openSupportRequests: readCount('open_support_requests'),
    );
  }
}
