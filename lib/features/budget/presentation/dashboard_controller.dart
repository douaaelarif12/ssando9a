import '../domain/entities/spending_habit_analysis.dart';
import '../domain/services/spending_habit_analyzer.dart';
import '../domain/ai/budget_advice_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/firestore/budget_firestore_datasource.dart';
import '../data/models/transaction_model.dart';
import '../domain/ai/anomaly_detector.dart';
import '../domain/ai/spending_forecast.dart';
import '../domain/budget_rules.dart';
import 'providers/budget_providers.dart';

class DashboardState {
  final String userName;
  final int incomeCents;
  final int expenseCents;
  final int previousExpenseCents;
  final int fixedExpensesCents;
  final int actualSavingCents;
  final List<TransactionModel> recent;
  final List<Map<String, Object?>> byCategory;
  final List<BudgetRecommendation> recommendations;
  final List<BudgetAlert> alerts;
  final int plannedMonthlySavingCents;
  final String smartAdvice;
  final SpendingHabitAnalysis spendingHabitAnalysis;

  final int forecastExpenseCents;
  final bool forecastWillOverrun;

  int get reservedSavingCents => plannedMonthlySavingCents;

  int get realAvailableBudgetCents =>
      incomeCents - plannedMonthlySavingCents - actualSavingCents - fixedExpensesCents;

  int get availableBudgetCents => realAvailableBudgetCents;

  int get realBalanceCents => realAvailableBudgetCents - expenseCents;

  int get balanceCents => incomeCents - expenseCents;

  bool get isOverBudget => realBalanceCents < 0;

  double get savingRate {
    if (incomeCents == 0) return 0;
    return (actualSavingCents / incomeCents) * 100;
  }

  double get expenseVariationPercent {
    if (previousExpenseCents == 0) return 0;
    return ((expenseCents - previousExpenseCents) / previousExpenseCents) * 100;
  }

  const DashboardState({
    required this.userName,
    required this.incomeCents,
    required this.expenseCents,
    required this.previousExpenseCents,
    required this.fixedExpensesCents,
    required this.actualSavingCents,
    required this.recent,
    required this.byCategory,
    required this.recommendations,
    required this.alerts,
    required this.plannedMonthlySavingCents,
    required this.forecastExpenseCents,
    required this.forecastWillOverrun,
    required this.smartAdvice,
    required this.spendingHabitAnalysis,
  });
}

final dashboardProvider =
AsyncNotifierProvider<DashboardController, DashboardState>(
  DashboardController.new,
);

class DashboardController extends AsyncNotifier<DashboardState> {
  BudgetFirestoreDatasource get ds => ref.read(budgetDsProvider);

  @override
  Future<DashboardState> build() async {
    final now = DateTime.now();
    final currentUser = await ds.getCurrentUser();

    if (currentUser == null) {
      return DashboardState(
        userName: 'Salam',
        incomeCents: 0,
        expenseCents: 0,
        previousExpenseCents: 0,
        fixedExpensesCents: 0,
        actualSavingCents: 0,
        recent: [],
        byCategory: [],
        recommendations: [],
        alerts: [],
        plannedMonthlySavingCents: 0,
        forecastExpenseCents: 0,
        forecastWillOverrun: false,
        smartAdvice: 'Aucun conseil disponible pour le moment.',
        spendingHabitAnalysis: SpendingHabitAnalysis.empty(),
      );
    }

    final income = await ds.getMonthlyIncomeTotalCents(now.year, now.month);
    final expense = await ds.getMonthlyExpenseCents(now.year, now.month);
    final actualSaving = await ds.getMonthlySavingsCents(now.year, now.month);

    final fixedExpenses = await ds.getTotalFixedExpensesCentsForMonth(
      now.year,
      now.month,
    );

    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;

    final previousExpense = await ds.getMonthlyExpenseCents(
      prevYear,
      prevMonth,
    );

    final recent = await ds.getRecentTransactions();

    final currentMonthTransactions =
    await ds.getTransactionsForMonth(now.year, now.month);

    final previousMonthTransactions =
    await ds.getTransactionsForMonth(prevYear, prevMonth);

    final byCategory = await ds.getMonthlyExpenseByCategoryRaw(
      now.year,
      now.month,
    );

    final planned = await ds.getPlannedExpenses();

    int monthlySavingTotal = 0;
    for (final p in planned) {
      monthlySavingTotal += ds.calculateMonthlySaving(
        totalCents: p['totalAmountCents'] as int,
        targetDateMillis: p['targetDate'] as int,
      );
    }

    int variableBudgetBase =
        income - monthlySavingTotal - actualSaving - fixedExpenses;

    if (variableBudgetBase < 0) {
      variableBudgetBase = 0;
    }

    final recommendations = BudgetRules.buildRecommendations(
      incomeCents: variableBudgetBase,
      householdType: currentUser.householdType,
      childrenCount: currentUser.childrenCount,
    );

    final alerts = BudgetRules.buildAlerts(
      recommendations: recommendations,
      byCategory: byCategory,
    );

    final globalAnomaly = AnomalyDetector.isAnomalous(
      currentCents: expense,
      averageCents: previousExpense,
    );

    if (globalAnomaly) {
      alerts.add(
        BudgetAlert(
          id: 'global_anomaly',
          label: 'Dépenses globales',
          recommendedCents: previousExpense,
          spentCents: expense,
          ratio: previousExpense == 0 ? 0 : expense / previousExpense,
          severity: 'danger',
        ),
      );
    }

    final currentDay = now.day;
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final availableBudgetForForecast =
        income - fixedExpenses - monthlySavingTotal - actualSaving;

    final forecast = SpendingForecastEngine.forecast(
      currentExpenseCents: expense,
      availableBudgetCents: availableBudgetForForecast,
      currentDay: currentDay,
      totalDaysInMonth: totalDaysInMonth,
    );

    if (forecast.willOverrun) {
      alerts.add(
        BudgetAlert(
          id: 'forecast_overrun',
          label: 'Prévision fin de mois',
          recommendedCents: availableBudgetForForecast,
          spentCents: forecast.predictedExpenseCents,
          ratio: availableBudgetForForecast == 0
              ? 0
              : forecast.predictedExpenseCents / availableBudgetForForecast,
          severity: 'danger',
        ),
      );
    }

    final warningCategories = alerts
        .where((a) => a.id != 'forecast_overrun' && a.id != 'global_anomaly')
        .map((a) => a.label)
        .toList();

    final hasDangerAlert = alerts.any((a) => a.severity == 'danger');

    final smartAdvice = BudgetAdviceEngine.buildAdvice(
      warningCategories: warningCategories,
      forecastWillOverrun: forecast.willOverrun,
      hasDangerAlert: hasDangerAlert,
    );

    final spendingHabitAnalysis = SpendingHabitAnalyzer().analyze(
      currentMonthTransactions: currentMonthTransactions,
      previousMonthTransactions: previousMonthTransactions,
    );

    return DashboardState(
      userName: currentUser.fullName,
      incomeCents: income,
      expenseCents: expense,
      previousExpenseCents: previousExpense,
      fixedExpensesCents: fixedExpenses,
      actualSavingCents: actualSaving,
      recent: recent,
      byCategory: byCategory,
      recommendations: recommendations,
      alerts: alerts,
      plannedMonthlySavingCents: monthlySavingTotal,
      forecastExpenseCents: forecast.predictedExpenseCents,
      forecastWillOverrun: forecast.willOverrun,
      smartAdvice: smartAdvice,
      spendingHabitAnalysis: spendingHabitAnalysis,
    );
  }

  Future<void> addExpense({
    required String title,
    required int dh,
    required String categoryId,
  }) async {
    final now = DateTime.now();
    final userId = await ds.getCurrentUserId();

    if (userId == null || userId.isEmpty) return;

    final tx = TransactionModel(
      id: 'tx_${now.microsecondsSinceEpoch}',
      type: 'expense',
      title: title,
      amountCents: dh * 100,
      categoryId: categoryId,
      occurredAt: now.millisecondsSinceEpoch,
      userId: userId,
    );

    await ds.insertTransaction(tx);
    ref.invalidateSelf();
  }

  Future<void> addIncome({
    required String title,
    required int dh,
    String type = 'prime',
  }) async {
    if (dh <= 0) return;

    await ds.insertIncome(
      title: title,
      amountDh: dh,
      type: type,
    );

    ref.invalidateSelf();
  }
}