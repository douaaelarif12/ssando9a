import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/sandokti_colors.dart';
import '../../../../core/utils/currency.dart';
import '../providers/habit_analysis_provider.dart';

class HabitsAnalysisScreen extends ConsumerWidget {
  const HabitsAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(habitAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyse des habitudes'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (analysis) {
          if (!analysis.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Pas assez de données pour analyser tes habitudes.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(habitAnalysisProvider);
              await ref.read(habitAnalysisProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                _SummaryCard(analysis: analysis),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MiniCard(
                        label: 'Catégorie dominante',
                        value: analysis.topCategory ?? '—',
                        accent: SandoktiColors.emerald,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniCard(
                        label: 'Moyenne / dépense',
                        value: formatMAD(analysis.averageExpenseCents),
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
                        label: 'Jour le plus coûteux',
                        value: analysis.mostExpensiveDayName ?? '—',
                        accent: SandoktiColors.ink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniCard(
                        label: 'Régularité',
                        value:
                            '${analysis.spendingRegularityScore.toStringAsFixed(0)}%',
                        accent: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _DetailCard(
                  title: 'Petites dépenses fréquentes',
                  value:
                      '${analysis.smallExpensesCount} opérations • ${formatMAD(analysis.smallExpensesTotalCents)}',
                ),
                const SizedBox(height: 10),
                _DetailCard(
                  title: 'Catégorie en hausse',
                  value: analysis.risingCategory == null
                      ? 'Aucune hausse marquante'
                      : '${analysis.risingCategory} • +${analysis.risingCategoryPercent.toStringAsFixed(0)}%',
                ),
                const SizedBox(height: 14),
                const Text(
                  'Insights intelligents',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                ...analysis.insights.map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InsightTile(
                      title: insight.title,
                      message: insight.message,
                      severity: insight.severity.name,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.analysis});

  final dynamic analysis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF083B33),
            Color(0xFF0B7A43),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analyse de tes habitudes',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatMAD(analysis.totalExpensesCents),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${analysis.expenseCount} dépenses analysées ce mois',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
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
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.title,
    required this.message,
    required this.severity,
  });

  final String title;
  final String message;
  final String severity;

  @override
  Widget build(BuildContext context) {
    final Color accent = severity == 'warning'
        ? const Color(0xFFF59E0B)
        : severity == 'positive'
            ? const Color(0xFF22C55E)
            : SandoktiColors.emerald;

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
            title,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}