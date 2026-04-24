import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/spending_habit_analysis.dart';
import '../../domain/services/spending_habit_analyzer.dart';
import 'budget_providers.dart';

final habitAnalysisProvider = FutureProvider<SpendingHabitAnalysis>((ref) async {
  final datasource = ref.watch(budgetDsProvider);

  final now = DateTime.now();

  // 📅 Mois actuel
  final currentTransactions = await datasource.getTransactionsForMonth(
    now.year,
    now.month,
  );

  // 📅 Mois précédent
  final previousDate = DateTime(now.year, now.month - 1);

  final previousTransactions = await datasource.getTransactionsForMonth(
    previousDate.year,
    previousDate.month,
  );

  final analyzer = SpendingHabitAnalyzer();

  return analyzer.analyze(
    currentMonthTransactions: currentTransactions,
    previousMonthTransactions: previousTransactions,
  );
});