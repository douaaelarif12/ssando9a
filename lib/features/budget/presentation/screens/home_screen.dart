import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sandokti/app/theme/sandokti_colors.dart';
import 'package:sandokti/core/utils/currency.dart';
import 'package:sandokti/features/budget/domain/ai/expense_categorizer.dart';
import 'package:sandokti/features/budget/presentation/dashboard_controller.dart';
import 'habits_analysis_screen.dart';
import '../providers/budget_providers.dart';
import 'assistant_screen.dart';
import '../providers/habit_analysis_provider.dart';
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showRecommendedBudget = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('sandokti'),
        actions: [
  IconButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AssistantScreen(),
        ),
      );
    },
    icon: const Icon(Icons.smart_toy_outlined),
    tooltip: 'Assistant',
  ),
  Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: SandoktiColors.emerald.withOpacity(0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: SandoktiColors.emerald.withOpacity(0.14),
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 18,
        color: SandoktiColors.emerald,
      ),
    ),
  ),
],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (s) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            await ref.read(dashboardProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              _header(context, s),
              const SizedBox(height: 16),
              _quickActions(context, s),
              const SizedBox(height: 16),
              _smartInsightBanner(context, s),
              const SizedBox(height: 16),
              _recommendedBudget(context, s),
              const SizedBox(height: 16),
              _budgetAlerts(context, s),
              const SizedBox(height: 16),
              _categoryChart(context, s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, DashboardState s) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/patterns/zellige.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      SandoktiColors.ink.withOpacity(0.92),
                      SandoktiColors.emerald.withOpacity(0.86),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salam, ${s.userName}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Reste réel',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Text(
                      formatMAD(s.realBalanceCents),
                      key: ValueKey(s.realBalanceCents),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _metricChip(
                        label: 'Revenu',
                        value: formatMAD(s.incomeCents),
                        bg: SandoktiColors.gold.withOpacity(0.22),
                        fg: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      _metricChip(
                        label: 'Dépenses',
                        value: formatMAD(s.expenseCents),
                        bg: Colors.white.withOpacity(0.14),
                        fg: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        s.expenseVariationPercent >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: s.expenseVariationPercent >= 0
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFF22C55E),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${s.expenseVariationPercent.toStringAsFixed(1)}% vs mois précédent',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Taux d'épargne réel : ${s.savingRate.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: s.savingRate > 30
                          ? const Color(0xFF22C55E)
                          : s.savingRate > 10
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w900,
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

  Widget _metricChip({
    required String label,
    required String value,
    required Color bg,
    required Color fg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: fg.withOpacity(0.75),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context, DashboardState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.remove_circle_outline,
                label: 'Dépense',
                subtitle: 'Ajouter',
                accent: const Color(0xFFFF6B6B),
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _QuickAddExpenseSheet(ref: ref),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_circle_outline,
                label: 'Prime',
                subtitle: 'Ajouter',
                accent: SandoktiColors.gold,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _QuickAddIncomeSheet(ref: ref),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.savings_outlined,
                label: 'Épargne',
                subtitle: 'Ajouter',
                accent: SandoktiColors.emerald,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _QuickAddSavingSheet(ref: ref),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

 Widget _smartInsightBanner(BuildContext context, DashboardState s) {
  final message = s.smartAdvice;
  final tone = _homeCoachTone(s);

  return InkWell(
    borderRadius: BorderRadius.circular(22),
    onTap: () {
      ref.invalidate(habitAnalysisProvider);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const HabitsAnalysisScreen(),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withOpacity(0.14),
            tone.withOpacity(0.06),
          ],
        ),
        border: Border.all(color: tone.withOpacity(0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tone.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _homeCoachIcon(s),
              color: tone,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conseil intelligent',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Appuie pour voir l'analyse détaillée",
                  style: TextStyle(
                    color: tone,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: tone,
          ),
        ],
      ),
    ),
  );
}

  Color _homeCoachTone(DashboardState s) {
    if (s.realBalanceCents < 0) return const Color(0xFFFF6B6B);
    if (s.alerts.isNotEmpty) return const Color(0xFFF59E0B);
    if (s.savingRate >= 20) return SandoktiColors.emerald;
    return SandoktiColors.ink;
  }

  IconData _homeCoachIcon(DashboardState s) {
    if (s.realBalanceCents < 0) return Icons.warning_amber_rounded;
    if (s.alerts.isNotEmpty) return Icons.insights_rounded;
    if (s.savingRate >= 20) return Icons.workspace_premium_rounded;
    return Icons.auto_awesome_rounded;
  }

  Widget _recommendedBudget(BuildContext context, DashboardState s) {
    if (s.recommendations.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _showRecommendedBudget = !_showRecommendedBudget;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Budget conseillé ce mois-ci',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _showRecommendedBudget ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Répartition automatique selon ton profil',
              style: TextStyle(color: Colors.black54),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: s.recommendations.map((r) {
                    final isSaving = r.id == 'saving';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSaving
                            ? SandoktiColors.gold.withOpacity(0.10)
                            : SandoktiColors.emerald.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSaving
                              ? SandoktiColors.gold.withOpacity(0.35)
                              : SandoktiColors.emerald.withOpacity(0.20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.label,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            '${r.percent}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatMAD(r.amountCents),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              crossFadeState: _showRecommendedBudget
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetAlerts(BuildContext context, DashboardState s) {
    if (s.alerts.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alertes budget',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...s.alerts.map((a) {
              final isDanger = a.severity == 'danger';
              final bg = isDanger
                  ? const Color(0xFFFFE4E6)
                  : const Color(0xFFFFF7ED);
              final border = isDanger
                  ? const Color(0xFFFB7185)
                  : const Color(0xFFF59E0B);

              final remaining = a.recommendedCents > a.spentCents
                  ? a.recommendedCents - a.spentCents
                  : 0;

              final multiple = a.recommendedCents > 0
                  ? a.spentCents / a.recommendedCents
                  : 0.0;

              final multipleText =
                  multiple.toStringAsFixed(multiple % 1 == 0 ? 0 : 1);

              final title = a.id == 'forecast_overrun'
                  ? 'Risque de dépassement en fin de mois'
                  : isDanger
                      ? '${a.label} a dépassé le budget conseillé'
                      : '${a.label} approche du budget conseillé';

              final footerText = a.id == 'forecast_overrun'
                  ? '$multipleText× le budget conseillé'
                  : isDanger
                      ? '$multipleText× le budget conseillé'
                      : 'Il te reste ${formatMAD(remaining)} avant la limite';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isDanger
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                      color: border,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dépensé : ${formatMAD(a.spentCents)} • Conseillé : ${formatMAD(a.recommendedCents)}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            footerText,
                            style: TextStyle(
                              color: border,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _categoryChart(BuildContext context, DashboardState s) {
    final rows = s.byCategory;
    final filtered =
        rows.where((r) => (r['totalCents'] as int? ?? 0) > 0).toList();

    if (filtered.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text('Aucune dépense ce mois-ci.'),
        ),
      );
    }

    final total = filtered.fold<int>(
      0,
      (sum, r) => sum + ((r['totalCents'] as int?) ?? 0),
    );

    final palette = [
      SandoktiColors.emerald,
      SandoktiColors.gold,
      SandoktiColors.ink,
      SandoktiColors.emerald.withOpacity(0.55),
      SandoktiColors.gold.withOpacity(0.65),
      SandoktiColors.slate.withOpacity(0.70),
    ];

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < filtered.length; i++) {
      final v = (filtered[i]['totalCents'] as int?) ?? 0;
      final pct = (v / total) * 100.0;

      sections.add(
        PieChartSectionData(
          value: v.toDouble(),
          title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
          radius: 54,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
          color: palette[i % palette.length],
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
              'Dépenses par catégorie',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Visualise les postes qui consomment le plus ton budget.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 54,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...filtered.take(4).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              final name = r['name'] as String? ?? 'Catégorie';
              final v = (r['totalCents'] as int?) ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: palette[i % palette.length],
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formatMAD(v),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withOpacity(0.14)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddExpenseSheet extends StatefulWidget {
  const _QuickAddExpenseSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_QuickAddExpenseSheet> createState() => _QuickAddExpenseSheetState();
}

class _QuickAddExpenseSheetState extends State<_QuickAddExpenseSheet> {
  final _title = TextEditingController(text: 'BIM');
  final _amount = TextEditingController(text: '45');
  String _categoryId = 'cat_food';

  void _autoDetectCategory(String value) {
    final detected = ExpenseCategorizer.detectCategoryId(value);

    if (detected != null && detected != _categoryId) {
      setState(() {
        _categoryId = detected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nouvelle dépense',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              onChanged: _autoDetectCategory,
              decoration: const InputDecoration(labelText: 'Libellé'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant (DH)'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _categoryId,
              items: const [
                DropdownMenuItem(value: 'cat_food', child: Text('Nourriture')),
                DropdownMenuItem(
                  value: 'cat_transport',
                  child: Text('Transport'),
                ),
                DropdownMenuItem(value: 'cat_bills', child: Text('Factures')),
                DropdownMenuItem(value: 'cat_health', child: Text('Santé')),
                DropdownMenuItem(value: 'cat_sport', child: Text('Sport')),
                DropdownMenuItem(value: 'cat_fun', child: Text('Sorties')),
                DropdownMenuItem(value: 'cat_children', child: Text('Enfants')),
                DropdownMenuItem(
                  value: 'cat_unexpected',
                  child: Text('Imprévus'),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  _categoryId = v ?? 'cat_food';
                });
              },
              decoration: const InputDecoration(labelText: 'Catégorie'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SandoktiColors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final dh = int.tryParse(_amount.text.trim()) ?? 0;
                  final title =
                      _title.text.trim().isEmpty ? 'Dépense' : _title.text.trim();

                  await widget.ref.read(dashboardProvider.notifier).addExpense(
                        title: title,
                        dh: dh,
                        categoryId: _categoryId,
                      );

                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }
}

class _QuickAddIncomeSheet extends StatefulWidget {
  const _QuickAddIncomeSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_QuickAddIncomeSheet> createState() => _QuickAddIncomeSheetState();
}

class _QuickAddIncomeSheetState extends State<_QuickAddIncomeSheet> {
  final _title = TextEditingController(text: 'Prime');
  final _amount = TextEditingController(text: '500');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nouvelle prime',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Libellé (ex: Prime de rendement)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant (DH)'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SandoktiColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final dh = int.tryParse(_amount.text.trim()) ?? 0;
                  final title =
                      _title.text.trim().isEmpty ? 'Prime' : _title.text.trim();

                  await widget.ref.read(dashboardProvider.notifier).addIncome(
                        title: title,
                        dh: dh,
                      );

                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }
}

class _QuickAddSavingSheet extends ConsumerStatefulWidget {
  const _QuickAddSavingSheet({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_QuickAddSavingSheet> createState() =>
      _QuickAddSavingSheetState();
}

class _QuickAddSavingSheetState extends ConsumerState<_QuickAddSavingSheet> {
  final _title = TextEditingController(text: 'Épargne');
  final _amount = TextEditingController(text: '500');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nouvelle épargne',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Libellé'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant (DH)'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SandoktiColors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () async {
                  final dh = int.tryParse(_amount.text.trim()) ?? 0;
                  final title =
                      _title.text.trim().isEmpty ? 'Épargne' : _title.text.trim();

                  if (dh <= 0) return;

                  final ds = ref.read(budgetDsProvider);
                  await ds.addSaving(title: title, amountDh: dh);

                  ref.invalidate(dashboardProvider);

                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }
}