import 'habit_insight.dart';

class SpendingHabitAnalysis {
  final int totalExpensesCents;
  final int expenseCount;
  final int averageExpenseCents;

  final String? topCategory;
  final int topCategoryAmountCents;

  final String? mostExpensiveDayName;
  final int mostExpensiveDayAmountCents;

  final int smallExpensesCount;
  final int smallExpensesTotalCents;
  final double smallExpensesShare;

  final String? risingCategory;
  final double risingCategoryPercent;

  final double spendingRegularityScore;
  final List<HabitInsight> insights;

  const SpendingHabitAnalysis({
    required this.totalExpensesCents,
    required this.expenseCount,
    required this.averageExpenseCents,
    required this.topCategory,
    required this.topCategoryAmountCents,
    required this.mostExpensiveDayName,
    required this.mostExpensiveDayAmountCents,
    required this.smallExpensesCount,
    required this.smallExpensesTotalCents,
    required this.smallExpensesShare,
    required this.risingCategory,
    required this.risingCategoryPercent,
    required this.spendingRegularityScore,
    required this.insights,
  });

  factory SpendingHabitAnalysis.empty() {
    return const SpendingHabitAnalysis(
      totalExpensesCents: 0,
      expenseCount: 0,
      averageExpenseCents: 0,
      topCategory: null,
      topCategoryAmountCents: 0,
      mostExpensiveDayName: null,
      mostExpensiveDayAmountCents: 0,
      smallExpensesCount: 0,
      smallExpensesTotalCents: 0,
      smallExpensesShare: 0,
      risingCategory: null,
      risingCategoryPercent: 0,
      spendingRegularityScore: 0,
      insights: [],
    );
  }

  bool get hasData => expenseCount > 0;
}