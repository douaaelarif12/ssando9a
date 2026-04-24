import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/sandokti_colors.dart';
import '../../../../core/utils/currency.dart';
import '../dashboard_controller.dart';
import '../providers/budget_providers.dart';

final savingOverviewProvider = FutureProvider<SavingOverview>((ref) async {
  final ds = ref.read(budgetDsProvider);
  final dashboard = await ref.read(dashboardProvider.future);

  final now = DateTime.now();
  final currentMonthSaved = await ds.getMonthlySavingsCents(now.year, now.month);

  final previous = now.month == 1
      ? DateTime(now.year - 1, 12, 1)
      : DateTime(now.year, now.month - 1, 1);

  final previousMonthSaved = await ds.getMonthlySavingsCents(
    previous.year,
    previous.month,
  );

  final cumulativeSaved = await ds.getCumulativeSavingsCents();
  final rawHistory = await ds.getMonthlySavingsHistory();

  final history = rawHistory.map((row) {
    return MonthlySavedItem(
      year: int.tryParse('${row['year']}') ?? now.year,
      month: int.tryParse('${row['month']}') ?? now.month,
      amountCents: (row['totalCents'] as int?) ?? 0,
    );
  }).toList()
    ..sort((a, b) {
      final ax = a.year * 100 + a.month;
      final bx = b.year * 100 + b.month;
      return ax.compareTo(bx);
    });

  final average = history.isEmpty
      ? 0
      : history.fold<int>(0, (sum, e) => sum + e.amountCents) ~/ history.length;

  int best = 0;
  if (history.isNotEmpty) {
    best = history
        .map((e) => e.amountCents)
        .reduce((a, b) => a > b ? a : b);
  }

  final suggested = dashboard.recommendations
      .where((e) => e.id == 'saving')
      .fold<int>(0, (sum, e) => sum + e.amountCents);

  return SavingOverview(
    cumulativeSavedCents: cumulativeSaved,
    currentMonthSavedCents: currentMonthSaved,
    previousMonthSavedCents: previousMonthSaved,
    suggestedThisMonthCents: suggested,
    averageSavedCents: average,
    bestMonthSavedCents: best,
    history: history,
  );
});

class SavingOverview {
  final int cumulativeSavedCents;
  final int currentMonthSavedCents;
  final int previousMonthSavedCents;
  final int suggestedThisMonthCents;
  final int averageSavedCents;
  final int bestMonthSavedCents;
  final List<MonthlySavedItem> history;

  const SavingOverview({
    required this.cumulativeSavedCents,
    required this.currentMonthSavedCents,
    required this.previousMonthSavedCents,
    required this.suggestedThisMonthCents,
    required this.averageSavedCents,
    required this.bestMonthSavedCents,
    required this.history,
  });

  double get variationPercent {
    if (previousMonthSavedCents == 0) return 0;
    return ((currentMonthSavedCents - previousMonthSavedCents) /
        previousMonthSavedCents) *
        100;
  }

  int get gapThisMonthCents => currentMonthSavedCents - suggestedThisMonthCents;

  double get progressToSuggested {
    if (suggestedThisMonthCents <= 0) {
      return currentMonthSavedCents > 0 ? 1 : 0;
    }
    final value = currentMonthSavedCents / suggestedThisMonthCents;
    return value.clamp(0, 1).toDouble();
  }

  int get progressPercent => (progressToSuggested * 100).round();

  bool get reachedSuggestedGoal =>
      suggestedThisMonthCents > 0 &&
          currentMonthSavedCents >= suggestedThisMonthCents;

  int get streakMonths {
    if (history.isEmpty) return 0;

    int streak = 0;
    for (int i = history.length - 1; i >= 0; i--) {
      if (history[i].amountCents > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  SavingLevel get level {
    final amount = currentMonthSavedCents;
    if (amount >= 1000 * 100) return SavingLevel.master;
    if (amount >= 500 * 100) return SavingLevel.serious;
    if (amount >= 200 * 100) return SavingLevel.disciplined;
    return SavingLevel.beginner;
  }

  String get badgeTitle {
    if (reachedSuggestedGoal && gapThisMonthCents >= 200 * 100) {
      return 'Champion du mois';
    }
    if (reachedSuggestedGoal) {
      return 'Objectif validé';
    }
    if (streakMonths >= 3) {
      return 'Régulier';
    }
    if (currentMonthSavedCents > 0) {
      return 'Premier pas';
    }
    return 'Prêt à commencer';
  }

  String get motivationalMessage {
    if (currentMonthSavedCents == 0) {
      return "Commence aujourd'hui, même avec un petit montant. Chaque dirham épargné compte.";
    }

    if (reachedSuggestedGoal && gapThisMonthCents >= 200 * 100) {
      return "Excellent travail. Tu dépasses largement l\u2019épargne suggérée par l\u2019application ce mois.";
    }

    if (reachedSuggestedGoal) {
      return "Bravo, tu as atteint le montant d\u2019épargne conseillé par l\u2019application ce mois.";
    }

    if (progressPercent >= 75) {
      return 'Tu es très proche de ton objectif suggéré. Encore un petit effort.';
    }

    if (progressPercent >= 40) {
      return 'Tu avances bien. Garde ce rythme pour atteindre ton objectif du mois.';
    }

    return "Ton objectif est encore accessible. Essaie d'ajouter une petite somme cette semaine.";
  }

  String get comparisonHint {
    if (reachedSuggestedGoal) {
      return 'Tu es au-dessus du niveau recommandé par Sandokti.';
    }
    if (currentMonthSavedCents >= averageSavedCents &&
        currentMonthSavedCents > 0) {
      return 'Tu fais mieux que ta moyenne habituelle.';
    }
    return "Essaie d'atteindre au moins le niveau recommandé par Sandokti ce mois.";
  }
}

enum SavingLevel {
  beginner,
  disciplined,
  serious,
  master,
}

class MonthlySavedItem {
  final int year;
  final int month;
  final int amountCents;

  const MonthlySavedItem({
    required this.year,
    required this.month,
    required this.amountCents,
  });

  String get label {
    const labels = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return '${labels[month]} $year';
  }
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savingOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Épargne'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (data) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(savingOverviewProvider);
              await ref.read(savingOverviewProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                _HeroCard(data: data),
                const SizedBox(height: 14),
                _GoalProgressCard(data: data),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MiniCard(
                        label: 'Ajouté ce mois',
                        value: formatMAD(data.currentMonthSavedCents),
                        accent: SandoktiColors.emerald,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniCard(
                        label: 'Souhaité par app',
                        value: formatMAD(data.suggestedThisMonthCents),
                        accent: SandoktiColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MiniCard(
                        label: 'Écart',
                        value: formatMAD(data.gapThisMonthCents),
                        accent: data.gapThisMonthCents >= 0
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFFF6B6B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniCard(
                        label: 'Moyenne',
                        value: formatMAD(data.averageSavedCents),
                        accent: SandoktiColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _MiniCard(
                  label: 'Meilleur mois',
                  value: formatMAD(data.bestMonthSavedCents),
                  accent: const Color(0xFF22C55E),
                ),
                const SizedBox(height: 14),
                _MotivationCard(data: data),
                const SizedBox(height: 14),
                _RewardCard(data: data),
                const SizedBox(height: 14),
                _InsightCard(data: data),
                const SizedBox(height: 14),
                _ChartCard(data: data),
                const SizedBox(height: 14),
                _HistoryCard(data: data),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data});

  final SavingOverview data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF083B33),
            Color(0xFF0B7A43),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: const DecorationImage(
          image: AssetImage('assets/patterns/zellige.png'),
          fit: BoxFit.cover,
          opacity: 0.12,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: Colors.black.withOpacity(0.10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solde épargne cumulée',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatMAD(data.cumulativeSavedCents),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Argent réellement mis de côté par toi',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _HeroPill(
                    title: 'Ce mois',
                    value: formatMAD(data.currentMonthSavedCents),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroPill(
                    title: 'Tendance',
                    value:
                    '${data.variationPercent >= 0 ? '+' : ''}${data.variationPercent.toStringAsFixed(1)}% vs mois dernier',
                    icon: Icons.trending_up_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.title,
    required this.value,
    this.icon,
  });

  final String title;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  const _GoalProgressCard({required this.data});

  final SavingOverview data;

  @override
  Widget build(BuildContext context) {
    final remaining = math.max(
      data.suggestedThisMonthCents - data.currentMonthSavedCents,
      0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Objectif suggéré par l'application",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Calculé à partir du budget mensuel, des primes et des charges fixes.',
              style: TextStyle(
                color: Colors.black.withOpacity(0.55),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatMAD(data.currentMonthSavedCents),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: SandoktiColors.emerald.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${data.progressPercent}%',
                    style: TextStyle(
                      color: SandoktiColors.emerald,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: data.progressToSuggested,
                minHeight: 12,
                backgroundColor: Colors.grey.withOpacity(0.14),
                valueColor: AlwaysStoppedAnimation<Color>(
                  data.reachedSuggestedGoal
                      ? SandoktiColors.gold
                      : SandoktiColors.emerald,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              data.reachedSuggestedGoal
                  ? "Bravo, tu as atteint le montant d'épargne recommandé ce mois."
                  : 'Il te reste ${formatMAD(remaining)} pour atteindre le montant suggéré.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({required this.data});

  final SavingOverview data;

  Color _levelColor(SavingLevel level) {
    switch (level) {
      case SavingLevel.beginner:
        return const Color(0xFF64748B);
      case SavingLevel.disciplined:
        return const Color(0xFF2563EB);
      case SavingLevel.serious:
        return SandoktiColors.emerald;
      case SavingLevel.master:
        return SandoktiColors.gold;
    }
  }

  String _levelLabel(SavingLevel level) {
    switch (level) {
      case SavingLevel.beginner:
        return 'Débutant';
      case SavingLevel.disciplined:
        return 'Discipliné';
      case SavingLevel.serious:
        return 'Épargnant sérieux';
      case SavingLevel.master:
        return "Maître de l'épargne";
    }
  }

  IconData _levelIcon(SavingLevel level) {
    switch (level) {
      case SavingLevel.beginner:
        return Icons.eco_outlined;
      case SavingLevel.disciplined:
        return Icons.bolt_rounded;
      case SavingLevel.serious:
        return Icons.workspace_premium_outlined;
      case SavingLevel.master:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(data.level);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Motivation',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniCard(
                    label: 'Niveau',
                    value: _levelLabel(data.level),
                    accent: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniCard(
                    label: 'Badge',
                    value: data.badgeTitle,
                    accent: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniCard(
                    label: 'Streak',
                    value: '${data.streakMonths} mois',
                    accent: const Color(0xFFEA580C),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniCard(
                    label: 'Repère Sandokti',
                    value: data.reachedSuggestedGoal ? 'Au-dessus' : 'À suivre',
                    accent: data.reachedSuggestedGoal
                        ? SandoktiColors.gold
                        : SandoktiColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.16)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_levelIcon(data.level), color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.motivationalMessage,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.comparisonHint,
              style: TextStyle(
                color: Colors.black.withOpacity(0.60),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.data});

  final SavingOverview data;

  @override
  Widget build(BuildContext context) {
    final unlocked = data.reachedSuggestedGoal;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: unlocked
              ? [
            const Color(0xFF3B2A00),
            const Color(0xFF8A6A12),
          ]
              : [
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: unlocked
              ? SandoktiColors.gold.withOpacity(0.35)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked
                    ? Colors.white.withOpacity(0.16)
                    : SandoktiColors.emerald.withOpacity(0.10),
              ),
              child: Icon(
                unlocked ? Icons.emoji_events_rounded : Icons.card_giftcard,
                color: unlocked ? Colors.white : SandoktiColors.emerald,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unlocked ? 'Récompense débloquée' : 'Récompense du mois',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: unlocked ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unlocked
                        ? "Tu as validé ton objectif d'épargne suggéré. Badge \"${data.badgeTitle}\" débloqué."
                        : "Atteins le montant suggéré par l'application pour débloquer ton badge du mois.",
                    style: TextStyle(
                      color: unlocked ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.data});

  final SavingOverview data;

  @override
  Widget build(BuildContext context) {
    final good = data.gapThisMonthCents >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analyse du mois',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                good ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: good
                      ? const Color(0xFF22C55E).withOpacity(0.25)
                      : const Color(0xFFF59E0B).withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    good ? Icons.savings_outlined : Icons.info_outline,
                    color: good
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      good
                          ? "Tu as ajouté plus d\u2019épargne que le montant souhaité par l\u2019application ce mois."
                          : "Tu as ajouté moins d\u2019épargne que le montant souhaité par l\u2019application ce mois.",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.data});

  final SavingOverview data;

  @override
  Widget build(BuildContext context) {
    final months = data.history.length > 6
        ? data.history.sublist(data.history.length - 6)
        : data.history;

    if (months.isEmpty) return const SizedBox.shrink();

    final maxValue = months
        .map((e) => e.amountCents)
        .fold<int>(0, (a, b) => a > b ? a : b);

    final topY = maxValue == 0 ? 1000.0 : (maxValue * 1.2).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Évolution de l'épargne ajoutée",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Les 6 derniers mois',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: topY,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: topY / 4,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= months.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              months[index].label.split(' ').first,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(months.length, (index) {
                    final m = months[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: m.amountCents.toDouble(),
                          width: 20,
                          borderRadius: BorderRadius.circular(6),
                          color: SandoktiColors.emerald,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.data});

  final SavingOverview data;

  @override
  Widget build(BuildContext context) {
    final items = data.history.reversed.toList();

    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text('Aucune épargne ajoutée pour le moment.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique mensuel',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...items.take(6).map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      formatMAD(item.amountCents),
                      style: TextStyle(
                        color: SandoktiColors.emerald,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}