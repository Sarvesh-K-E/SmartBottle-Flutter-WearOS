class DailyIntake {
  DailyIntake({
    required this.date,
    required this.drankLiters,
    required this.used,
    required this.goalAchieved,
  });

  final DateTime date;
  final double drankLiters;
  final bool used;
  final bool goalAchieved;

  factory DailyIntake.fromMap(Map<String, Object?> map) {
    return DailyIntake(
      date: DateTime.parse(map['date']! as String),
      drankLiters: (map['drank_liters'] as num?)?.toDouble() ?? 0,
      used: ((map['used'] as num?)?.toInt() ?? 0) == 1,
      goalAchieved: ((map['goal_achieved'] as num?)?.toInt() ?? 0) == 1,
    );
  }
}

class ReportSummary {
  const ReportSummary({
    required this.averagePerUsedDay,
    required this.goalAchievedDays,
    required this.usedDays,
    required this.totalDrank,
  });

  final double averagePerUsedDay;
  final int goalAchievedDays;
  final int usedDays;
  final double totalDrank;
}
