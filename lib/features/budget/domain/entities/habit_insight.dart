class HabitInsight {
  final String id;
  final String title;
  final String message;
  final HabitInsightType type;
  final HabitInsightSeverity severity;

  const HabitInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
  });
}

enum HabitInsightType {
  spendingPattern,
  categoryTrend,
  smallExpenses,
  budgetDiscipline,
  monthlyTrend,
  recommendation,
}

enum HabitInsightSeverity {
  info,
  warning,
  positive,
}