import 'dart:math';

import '../entities/habit_insight.dart';
import '../entities/spending_habit_analysis.dart';

class SpendingHabitAnalyzer {
  static const int smallExpenseThresholdCents = 5000; // 50 DH

  SpendingHabitAnalysis analyze({
    required List<dynamic> currentMonthTransactions,
    required List<dynamic> previousMonthTransactions,
  }) {
    final currentExpenses = _extractExpenses(currentMonthTransactions);
    final previousExpenses = _extractExpenses(previousMonthTransactions);

    if (currentExpenses.isEmpty) {
      return SpendingHabitAnalysis.empty();
    }

    final totalExpensesCents = currentExpenses.fold<int>(
      0,
      (sum, tx) => sum + _amountOf(tx),
    );

    final expenseCount = currentExpenses.length;
    final averageExpenseCents =
        expenseCount == 0 ? 0 : (totalExpensesCents / expenseCount).round();

    final topCategoryData = _findTopCategory(currentExpenses);
    final topCategory = topCategoryData.$1;
    final topCategoryAmountCents = topCategoryData.$2;

    final topDayData = _findMostExpensiveDay(currentExpenses);
    final mostExpensiveDayName = topDayData.$1;
    final mostExpensiveDayAmountCents = topDayData.$2;

    final smallExpenses = currentExpenses
        .where((tx) => _amountOf(tx) <= smallExpenseThresholdCents)
        .toList();

    final smallExpensesCount = smallExpenses.length;
    final smallExpensesTotalCents = smallExpenses.fold<int>(
      0,
      (sum, tx) => sum + _amountOf(tx),
    );

    final smallExpensesShare = totalExpensesCents == 0
        ? 0.0
        : smallExpensesTotalCents / totalExpensesCents;

    final risingCategoryData = _findRisingCategory(
      currentExpenses: currentExpenses,
      previousExpenses: previousExpenses,
    );
    final risingCategory = risingCategoryData.$1;
    final risingCategoryPercent = risingCategoryData.$2;

    final spendingRegularityScore = _calculateRegularityScore(currentExpenses);

    final insights = _buildInsights(
      totalExpensesCents: totalExpensesCents,
      topCategory: topCategory,
      topCategoryAmountCents: topCategoryAmountCents,
      mostExpensiveDayName: mostExpensiveDayName,
      mostExpensiveDayAmountCents: mostExpensiveDayAmountCents,
      smallExpensesCount: smallExpensesCount,
      smallExpensesShare: smallExpensesShare,
      risingCategory: risingCategory,
      risingCategoryPercent: risingCategoryPercent,
      spendingRegularityScore: spendingRegularityScore,
    );

    return SpendingHabitAnalysis(
      totalExpensesCents: totalExpensesCents,
      expenseCount: expenseCount,
      averageExpenseCents: averageExpenseCents,
      topCategory: topCategory,
      topCategoryAmountCents: topCategoryAmountCents,
      mostExpensiveDayName: mostExpensiveDayName,
      mostExpensiveDayAmountCents: mostExpensiveDayAmountCents,
      smallExpensesCount: smallExpensesCount,
      smallExpensesTotalCents: smallExpensesTotalCents,
      smallExpensesShare: smallExpensesShare,
      risingCategory: risingCategory,
      risingCategoryPercent: risingCategoryPercent,
      spendingRegularityScore: spendingRegularityScore,
      insights: insights,
    );
  }

  List<dynamic> _extractExpenses(List<dynamic> transactions) {
    return transactions.where((tx) => _typeOf(tx) == 'expense').toList();
  }

  (String?, int) _findTopCategory(List<dynamic> expenses) {
    if (expenses.isEmpty) return (null, 0);

    final byCategory = <String, int>{};

    for (final tx in expenses) {
      final category = _categoryOf(tx).trim().isEmpty
          ? 'Autres'
          : _categoryOf(tx).trim();

      byCategory[category] = (byCategory[category] ?? 0) + _amountOf(tx);
    }

    String? bestCategory;
    int bestAmount = 0;

    for (final entry in byCategory.entries) {
      if (entry.value > bestAmount) {
        bestCategory = entry.key;
        bestAmount = entry.value;
      }
    }

    return (bestCategory, bestAmount);
  }

  (String?, int) _findMostExpensiveDay(List<dynamic> expenses) {
    if (expenses.isEmpty) return (null, 0);

    final byWeekday = <int, int>{};

    for (final tx in expenses) {
      final weekday = _dateOf(tx).weekday;
      byWeekday[weekday] = (byWeekday[weekday] ?? 0) + _amountOf(tx);
    }

    int? bestWeekday;
    int bestAmount = 0;

    for (final entry in byWeekday.entries) {
      if (entry.value > bestAmount) {
        bestWeekday = entry.key;
        bestAmount = entry.value;
      }
    }

    return (_weekdayLabel(bestWeekday), bestAmount);
  }

  (String?, double) _findRisingCategory({
    required List<dynamic> currentExpenses,
    required List<dynamic> previousExpenses,
  }) {
    if (currentExpenses.isEmpty) return (null, 0);

    final currentMap = _sumByCategory(currentExpenses);
    final previousMap = _sumByCategory(previousExpenses);

    String? bestCategory;
    double bestPercent = 0;

    for (final entry in currentMap.entries) {
      final category = entry.key;
      final currentAmount = entry.value;
      final previousAmount = previousMap[category] ?? 0;

      // On ignore si le mois précédent était trop faible (< 50 DH)
      // pour éviter des % absurdes genre +6900%
      if (previousAmount < 5000) continue;

      final percent = ((currentAmount - previousAmount) / previousAmount) * 100;

      // On plafonne à 500% pour éviter des chiffres choquants non utiles
      final double capped = percent.clamp(0.0, 500.0);

      if (capped > bestPercent) {
        bestPercent = capped;
        bestCategory = category;
      }
    }

    return (bestCategory, bestPercent);
  }

  Map<String, int> _sumByCategory(List<dynamic> expenses) {
    final map = <String, int>{};

    for (final tx in expenses) {
      final category = _categoryOf(tx).trim().isEmpty
          ? 'Autres'
          : _categoryOf(tx).trim();

      map[category] = (map[category] ?? 0) + _amountOf(tx);
    }

    return map;
  }

  double _calculateRegularityScore(List<dynamic> expenses) {
    if (expenses.isEmpty) return 0;

    final byDay = <DateTime, int>{};

    for (final tx in expenses) {
      final date = _dateOf(tx);
      final key = DateTime(date.year, date.month, date.day);

      byDay[key] = (byDay[key] ?? 0) + _amountOf(tx);
    }

    final values = byDay.values.map((e) => e.toDouble()).toList();

    if (values.length <= 1) return 100;

    final mean = values.reduce((a, b) => a + b) / values.length;

    if (mean == 0) return 100;

    double varianceSum = 0;
    for (final value in values) {
      varianceSum += pow(value - mean, 2).toDouble();
    }

    final variance = varianceSum / values.length;
    final stdDev = sqrt(variance);

    final coefficientOfVariation = stdDev / mean;

    final rawScore = 100 - (coefficientOfVariation * 100);
    return rawScore.clamp(0, 100).toDouble();
  }

  List<HabitInsight> _buildInsights({
    required int totalExpensesCents,
    required String? topCategory,
    required int topCategoryAmountCents,
    required String? mostExpensiveDayName,
    required int mostExpensiveDayAmountCents,
    required int smallExpensesCount,
    required double smallExpensesShare,
    required String? risingCategory,
    required double risingCategoryPercent,
    required double spendingRegularityScore,
  }) {
    final insights = <HabitInsight>[];

    if (topCategory != null && totalExpensesCents > 0) {
      final share = topCategoryAmountCents / totalExpensesCents;

      if (share >= 0.35) {
        insights.add(
          HabitInsight(
            id: 'top_category_dominant',
            title: 'Catégorie dominante',
            message:
                'La catégorie $topCategory représente une part importante de tes dépenses ce mois-ci.',
            type: HabitInsightType.spendingPattern,
            severity: HabitInsightSeverity.info,
          ),
        );
      }
    }

    if (mostExpensiveDayName != null && mostExpensiveDayAmountCents > 0) {
      insights.add(
        HabitInsight(
          id: 'most_expensive_day',
          title: 'Jour le plus coûteux',
          message: 'Tu as le plus dépensé le $mostExpensiveDayName ce mois-ci.',
          type: HabitInsightType.monthlyTrend,
          severity: HabitInsightSeverity.info,
        ),
      );
    }

    if (smallExpensesCount >= 5 && smallExpensesShare >= 0.20) {
      insights.add(
        HabitInsight(
          id: 'small_expenses_alert',
          title: 'Petites dépenses fréquentes',
          message:
              'Tes petites dépenses sont nombreuses et pèsent sur ton budget global.',
          type: HabitInsightType.smallExpenses,
          severity: HabitInsightSeverity.warning,
        ),
      );
    }

    if (risingCategory != null && risingCategoryPercent >= 15) {
      insights.add(
        HabitInsight(
          id: 'rising_category',
          title: 'Catégorie en hausse',
          message:
              'Tes dépenses de $risingCategory ont augmenté de ${risingCategoryPercent.toStringAsFixed(0)} % par rapport au mois précédent.',
          type: HabitInsightType.categoryTrend,
          severity: HabitInsightSeverity.warning,
        ),
      );
    }

    if (spendingRegularityScore >= 75) {
      insights.add(
        HabitInsight(
          id: 'regularity_good',
          title: 'Bonne régularité',
          message: 'Tes dépenses sont relativement régulières sur le mois.',
          type: HabitInsightType.budgetDiscipline,
          severity: HabitInsightSeverity.positive,
        ),
      );
    } else if (spendingRegularityScore <= 40) {
      insights.add(
        HabitInsight(
          id: 'regularity_low',
          title: 'Dépenses irrégulières',
          message:
              'Tes dépenses sont assez irrégulières, avec des pics marqués sur certains jours.',
          type: HabitInsightType.budgetDiscipline,
          severity: HabitInsightSeverity.warning,
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        const HabitInsight(
          id: 'default_info',
          title: 'Habitudes analysées',
          message:
              "Ton comportement financier est en cours d'analyse. Continue à enregistrer tes dépenses pour obtenir des insights plus précis.",
          type: HabitInsightType.recommendation,
          severity: HabitInsightSeverity.info,
        ),
      );
    }

    return insights;
  }

  int _amountOf(dynamic tx) => tx.amountCents as int;

  String _typeOf(dynamic tx) => (tx.type as String).toLowerCase();

  String _categoryOf(dynamic tx) =>
      (tx.categoryName as String?)?.trim().isNotEmpty == true
          ? tx.categoryName as String
          : 'Autres';

  DateTime _dateOf(dynamic tx) =>
      DateTime.fromMillisecondsSinceEpoch(tx.occurredAt as int);

  String? _weekdayLabel(int? weekday) {
    switch (weekday) {
      case 1:
        return 'Lundi';
      case 2:
        return 'Mardi';
      case 3:
        return 'Mercredi';
      case 4:
        return 'Jeudi';
      case 5:
        return 'Vendredi';
      case 6:
        return 'Samedi';
      case 7:
        return 'Dimanche';
      default:
        return null;
    }
  }
}