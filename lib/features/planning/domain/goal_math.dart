class GoalSnapshot {
  const GoalSnapshot({
    required this.target,
    required this.saved,
    required this.now,
    this.targetDate,
  });

  final num target;
  final num saved;
  final DateTime now;
  final DateTime? targetDate;

  double get progress {
    if (target <= 0) return 0;
    final ratio = saved / target;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio.toDouble();
  }

  int get percent => (progress * 100).round();

  num get gap => target - saved < 0 ? 0 : target - saved;
}

int monthsRemaining(DateTime now, DateTime target) {
  var months = (target.year - now.year) * 12 + target.month - now.month;
  if (target.day > now.day) {
    // The target day is still ahead inside that month.
  } else if (target.day < now.day) {
    months -= 1;
  }
  if (months < 1) return 1;
  return months;
}

num? requiredMonthly(GoalSnapshot goal) {
  final date = goal.targetDate;
  if (date == null) return null;
  if (!date.isAfter(DateTime(goal.now.year, goal.now.month, goal.now.day))) {
    return goal.gap;
  }
  return goal.gap / monthsRemaining(goal.now, date);
}

class PaceEstimate {
  const PaceEstimate({
    required this.sufficient,
    this.monthlyPace,
    this.estimatedCompletion,
  });

  final bool sufficient;
  final num? monthlyPace;
  final DateTime? estimatedCompletion;
}

PaceEstimate paceFromContributions({
  required num gap,
  required List<DateTime> contributionDates,
  required List<num> amounts,
  required DateTime now,
}) {
  if (contributionDates.length < 2 || contributionDates.length != amounts.length) {
    return const PaceEstimate(sufficient: false);
  }
  final first = contributionDates.reduce((a, b) => a.isBefore(b) ? a : b);
  final months = monthsRemaining(first, now);
  num total = 0;
  for (final amount in amounts) {
    total += amount;
  }
  final pace = total / months;
  if (pace <= 0) return const PaceEstimate(sufficient: false);
  final extraMonths = (gap / pace).ceil();
  return PaceEstimate(
    sufficient: true,
    monthlyPace: pace,
    estimatedCompletion: DateTime(now.year, now.month + extraMonths, now.day),
  );
}

enum GoalFeasibility { ahead, onTrack, behind, unknown }

GoalFeasibility feasibility({
  required num? requiredPerMonth,
  required num? currentPace,
}) {
  if (requiredPerMonth == null || currentPace == null) return GoalFeasibility.unknown;
  if (requiredPerMonth <= 0) return GoalFeasibility.ahead;
  if (currentPace + 0.001 >= requiredPerMonth) return GoalFeasibility.onTrack;
  return GoalFeasibility.behind;
}
