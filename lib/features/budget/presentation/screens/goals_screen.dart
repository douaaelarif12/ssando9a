import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sandokti/app/theme/sandokti_colors.dart';
import 'package:sandokti/core/utils/currency.dart';
import '../dashboard_controller.dart';
import '../providers/budget_providers.dart';

final plannedExpensesProvider = FutureProvider.autoDispose((ref) async {
  final ds = ref.read(budgetDsProvider);
  return ds.getPlannedExpenses();
});

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(plannedExpensesProvider);
    final ds = ref.read(budgetDsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objectifs'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: FloatingActionButton.extended(
          backgroundColor: SandoktiColors.emerald,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter'),
          onPressed: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _AddGoalSheet(),
            );

            ref.invalidate(plannedExpensesProvider);
            ref.invalidate(dashboardProvider);
          },
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (items) {
          int totalMonthlySaving = 0;

          for (final item in items) {
            totalMonthlySaving += ds.calculateMonthlySaving(
              totalCents: item['totalAmountCents'] as int,
              targetDateMillis: item['targetDate'] as int,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(plannedExpensesProvider);
              ref.invalidate(dashboardProvider);
              await ref.read(plannedExpensesProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              children: [
                _GoalsSummaryCard(monthlySavingCents: totalMonthlySaving),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 42,
                          color: SandoktiColors.emerald,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Aucun objectif pour le moment',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Ajoute un objectif comme Aïd, vacances ou assurance voiture.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                else
                  ...items.map((item) {
                    final id = item['id'] as String;
                    final totalCents = item['totalAmountCents'] as int;
                    final targetDateMillis = item['targetDate'] as int;
                    final targetDate =
                        DateTime.fromMillisecondsSinceEpoch(targetDateMillis);

                    final monthlySavingCents = ds.calculateMonthlySaving(
                      totalCents: totalCents,
                      targetDateMillis: targetDateMillis,
                    );

                    final progress = _timeProgress(targetDate);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GoalCard(
                        id: id,
                        title: (item['title'] as String?) ?? 'Objectif',
                        totalCents: totalCents,
                        monthlySavingCents: monthlySavingCents,
                        targetDate: targetDate,
                        progress: progress,
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Supprimer cet objectif ?'),
                              content: const Text(
                                'Cette action supprimera définitivement cet objectif.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed != true) return;

                          await ds.deletePlannedExpense(id);

                          ref.invalidate(plannedExpensesProvider);
                          ref.invalidate(dashboardProvider);

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Objectif supprimé'),
                            ),
                          );
                        },
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  double _timeProgress(DateTime targetDate) {
    final now = DateTime.now();
    final totalMonths =
        (targetDate.year - now.year) * 12 + (targetDate.month - now.month);

    if (totalMonths <= 1) return 1.0;

    final estimatedWindow = totalMonths.clamp(1, 12);
    final elapsedRatio = 1 / estimatedWindow;

    return elapsedRatio.clamp(0.08, 1.0);
  }
}

class _GoalsSummaryCard extends StatelessWidget {
  const _GoalsSummaryCard({
    required this.monthlySavingCents,
  });

  final int monthlySavingCents;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SandoktiColors.ink.withOpacity(0.96),
            SandoktiColors.emerald.withOpacity(0.88),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Épargne planifiée',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatMAD(monthlySavingCents),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'à mettre de côté chaque mois pour atteindre tes objectifs',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.id,
    required this.title,
    required this.totalCents,
    required this.monthlySavingCents,
    required this.targetDate,
    required this.progress,
    required this.onDelete,
  });

  final String id;
  final String title;
  final int totalCents;
  final int monthlySavingCents;
  final DateTime targetDate;
  final double progress;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final urgent = _monthsLeft(targetDate) <= 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: urgent
                    ? const Color(0xFFFFF7ED)
                    : SandoktiColors.emerald.withOpacity(0.12),
                child: Icon(
                  urgent ? Icons.warning_amber_rounded : Icons.flag_rounded,
                  color: urgent
                      ? const Color(0xFFF59E0B)
                      : SandoktiColors.emerald,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Supprimer',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: SandoktiColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_monthsLeft(targetDate)} mois',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: SandoktiColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  label: 'Montant total',
                  value: formatMAD(totalCents),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfo(
                  label: 'Par mois',
                  value: formatMAD(monthlySavingCents),
                  accent: SandoktiColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Date cible : ${_formatDate(targetDate)}',
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.black.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                urgent ? const Color(0xFFF59E0B) : SandoktiColors.emerald,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            urgent
                ? 'Objectif proche : essaie de mettre de côté rapidement.'
                : 'Préparation mensuelle recommandée.',
            style: TextStyle(
              color: urgent ? const Color(0xFFF59E0B) : Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  int _monthsLeft(DateTime target) {
    final now = DateTime.now();
    int months = (target.year - now.year) * 12 + (target.month - now.month);
    if (months <= 0) months = 1;
    return months;
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.label,
    required this.value,
    this.accent = SandoktiColors.emerald,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGoalSheet extends ConsumerStatefulWidget {
  const _AddGoalSheet();

  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final _title = TextEditingController(text: 'Aïd');
  final _amount = TextEditingController(text: '4000');

  DateTime _targetDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 4,
    1,
  );

  bool _saving = false;

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
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
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
              'Nouvel objectif',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Titre (ex: Aïd, Vacances)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant total (DH)',
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _saving
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _targetDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100, 12, 31),
                        helpText: 'Choisir la date cible',
                      );

                      if (picked != null) {
                        setState(() {
                          _targetDate = picked;
                        });
                      }
                    },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.12)),
                ),
                child: Text(
                  'Date cible : ${_targetDate.day.toString().padLeft(2, '0')}/'
                  '${_targetDate.month.toString().padLeft(2, '0')}/'
                  '${_targetDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
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
                onPressed: _saving
                    ? null
                    : () async {
                        final title = _title.text.trim();
                        final totalDh = int.tryParse(_amount.text.trim()) ?? 0;

                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Le titre est obligatoire'),
                            ),
                          );
                          return;
                        }

                        if (totalDh <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Le montant est invalide'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _saving = true;
                        });

                        try {
                          final ds = ref.read(budgetDsProvider);
                          await ds.addPlannedExpense(
                            title: title,
                            totalDh: totalDh,
                            targetDate: _targetDate,
                          );

                          ref.invalidate(dashboardProvider);
                          ref.invalidate(plannedExpensesProvider);

                          if (!mounted) return;
                          Navigator.pop(context);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _saving = false;
                            });
                          }
                        }
                      },
                icon: const Icon(Icons.check),
                label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
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