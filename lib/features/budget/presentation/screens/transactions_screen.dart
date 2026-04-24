import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sandokti/app/theme/sandokti_colors.dart';
import 'package:sandokti/core/utils/category_ui.dart';
import 'package:sandokti/core/utils/currency.dart';
import '../providers/budget_providers.dart';

final selectedMonthProvider = StateProvider.autoDispose<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final transactionsFilterProvider =
StateProvider.autoDispose<String>((ref) => 'all');

final transactionsMonthOverviewProvider =
FutureProvider.autoDispose<_TransactionsMonthOverview>((ref) async {
  final ds = ref.read(budgetDsProvider);
  final month = ref.watch(selectedMonthProvider);

  final items = await ds.getTransactionsForMonth(month.year, month.month);

  final salaryCents = await ds.getMonthlyIncomeFixedCents();
  final fixedExpensesCents =
  await ds.getTotalFixedExpensesCentsForMonth(month.year, month.month);
  final expenseCents = await ds.getMonthlyExpenseCents(month.year, month.month);
  final savingsCents = await ds.getMonthlySavingsCents(month.year, month.month);

  int primesCents = 0;
  for (final item in items) {
    if (item.type == 'income') {
      primesCents += item.amountCents;
    }
  }

  final remainingBudgetCents = salaryCents +
      primesCents -
      fixedExpensesCents -
      expenseCents -
      savingsCents;

  return _TransactionsMonthOverview(
    items: items,
    expenseCents: expenseCents,
    remainingBudgetCents: remainingBudgetCents,
    primesCents: primesCents,
    savingsCents: savingsCents,
  );
});

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final filter = ref.watch(transactionsFilterProvider);
    final async = ref.watch(transactionsMonthOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Choisir un mois',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: month,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2100, 12, 31),
                helpText: 'Choisir une date (on prendra le mois)',
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context)
                          .colorScheme
                          .copyWith(primary: SandoktiColors.emerald),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                ref.read(selectedMonthProvider.notifier).state =
                    DateTime(picked.year, picked.month, 1);
              }
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (overview) {
          final filteredItems = _applyFilter(overview.items, filter);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(transactionsMonthOverviewProvider);
              await ref.read(transactionsMonthOverviewProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _AnimatedEntrance(
                  delayMs: 0,
                  child: _MonthHeroHeader(
                    month: month,
                    count: filteredItems.length,
                    onPrev: () => _shiftMonth(ref, -1),
                    onNext: () => _shiftMonth(ref, 1),
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedEntrance(
                  delayMs: 60,
                  child: _FilterBar(
                    selected: filter,
                    onChanged: (value) {
                      ref.read(transactionsFilterProvider.notifier).state =
                          value;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedEntrance(
                  delayMs: 120,
                  child: _SummaryCard(
                    expenseCents: overview.expenseCents,
                    remainingBudgetCents: overview.remainingBudgetCents,
                    primesCents: overview.primesCents,
                    savingsCents: overview.savingsCents,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(animation);

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: filteredItems.isEmpty
                      ? const Padding(
                    key: ValueKey('empty-state'),
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'Aucune opération pour ce filtre ce mois-ci.',
                      ),
                    ),
                  )
                      : Column(
                    key: ValueKey(
                      'list-${month.year}-${month.month}-$filter-${filteredItems.length}',
                    ),
                    children: _buildList(filteredItems),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _shiftMonth(WidgetRef ref, int delta) {
    final current = ref.read(selectedMonthProvider);
    final shifted = DateTime(current.year, current.month + delta, 1);
    ref.read(selectedMonthProvider.notifier).state = shifted;
  }

  List _applyFilter(List items, String filter) {
    if (filter == 'expense') {
      return items.where((t) => t.type == 'expense').toList();
    }

    if (filter == 'prime') {
      return items.where((t) => t.type == 'income').toList();
    }

    if (filter == 'saving') {
      return items.where((t) => t.type == 'saving').toList();
    }

    return items;
  }

  List<Widget> _buildList(List items) {
    return List.generate(items.length, (i) {
      final t = items[i];

      final isExpense = t.type == 'expense';
      final isSaving = t.type == 'saving' || t.categoryId == 'cat_saving';
      final isPrime = t.type == 'income';

      Color accent;
      IconData icon;
      String label;

      if (isSaving) {
        accent = const Color(0xFF3B82F6);
        icon = Icons.savings_rounded;
        label = 'Épargne';
      } else if (isPrime) {
        accent = SandoktiColors.gold;
        icon = Icons.star_rounded;
        label = 'Prime';
      } else {
        accent = SandoktiColors.emerald;
        icon = CategoryUI.iconForCategory(t.categoryId);
        label = t.categoryName ?? 'Dépense';
      }

      final amountText = (isExpense ? '-' : '+') + formatMAD(t.amountCents);

      final amountColor = isExpense
          ? const Color(0xFFEF4444)
          : (isSaving ? const Color(0xFF3B82F6) : SandoktiColors.gold);

      return _AnimatedEntrance(
        delayMs: 180 + (i * 45),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.black.withOpacity(0.04),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(t.occurredAt),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.black.withOpacity(0.48),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.96, end: 1),
                  duration: Duration(
                    milliseconds: 260 + math.min(i * 30, 180),
                  ),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Text(
                    amountText,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                      color: amountColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _MonthHeroHeader extends StatelessWidget {
  const _MonthHeroHeader({
    required this.month,
    required this.count,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final int count;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = _monthLabel(month);

    return Container(
      padding: const EdgeInsets.all(16),
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
        boxShadow: [
          BoxShadow(
            color: SandoktiColors.emerald.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _MonthArrowButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPrev,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Mois sélectionné',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count opération${count > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _MonthArrowButton(
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _MonthArrowButton extends StatelessWidget {
  const _MonthArrowButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _filterChip(label: 'Toutes', value: 'all')),
        const SizedBox(width: 8),
        Expanded(child: _filterChip(label: 'Dépenses', value: 'expense')),
        const SizedBox(width: 8),
        Expanded(child: _filterChip(label: 'Primes', value: 'prime')),
        const SizedBox(width: 8),
        Expanded(child: _filterChip(label: 'Épargne', value: 'saving')),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required String value,
  }) {
    final isSelected = selected == value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? SandoktiColors.emerald.withOpacity(0.14)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? SandoktiColors.emerald.withOpacity(0.40)
                  : Colors.black.withOpacity(0.08),
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: SandoktiColors.emerald.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color:
                isSelected ? SandoktiColors.emerald : SandoktiColors.ink,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.expenseCents,
    required this.remainingBudgetCents,
    required this.primesCents,
    required this.savingsCents,
  });

  final int expenseCents;
  final int remainingBudgetCents;
  final int primesCents;
  final int savingsCents;

  @override
  Widget build(BuildContext context) {
    final remainingNegative = remainingBudgetCents < 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.98, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    label: 'Dépenses',
                    value: formatMAD(expenseCents),
                    accent: const Color(0xFFEF4444),
                    chip: const Color(0xFFFFE4E6),
                    prefix: '-',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniStat(
                    label: 'Budget restant',
                    value: formatMAD(remainingBudgetCents.abs()),
                    accent: remainingNegative
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFF22C55E),
                    chip: remainingNegative
                        ? const Color(0xFFFF6B6B).withOpacity(0.12)
                        : const Color(0xFF22C55E).withOpacity(0.12),
                    prefix: remainingNegative ? '-' : '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    label: 'Primes',
                    value: formatMAD(primesCents),
                    accent: SandoktiColors.gold,
                    chip: SandoktiColors.gold.withOpacity(0.16),
                    prefix: '+',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniStat(
                    label: 'Épargne',
                    value: formatMAD(savingsCents),
                    accent: const Color(0xFF3B82F6),
                    chip: const Color(0xFFDBEAFE),
                    prefix: '+',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required Color accent,
    required Color chip,
    String prefix = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: chip,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            prefix.isEmpty ? value : '$prefix$value',
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

class _AnimatedEntrance extends StatefulWidget {
  const _AnimatedEntrance({
    required this.child,
    this.delayMs = 0,
  });

  final Widget child;
  final int delayMs;

  @override
  State<_AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<_AnimatedEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (!mounted) return;
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _AnimatedEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child.key != widget.child.key) {
      _visible = false;
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (!mounted) return;
        setState(() {
          _visible = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        child: widget.child,
      ),
    );
  }
}

class _TransactionsMonthOverview {
  final List items;
  final int expenseCents;
  final int remainingBudgetCents;
  final int primesCents;
  final int savingsCents;

  const _TransactionsMonthOverview({
    required this.items,
    required this.expenseCents,
    required this.remainingBudgetCents,
    required this.primesCents,
    required this.savingsCents,
  });
}

String _formatDate(int millis) {
  final d = DateTime.fromMillisecondsSinceEpoch(millis);
  return "${d.day.toString().padLeft(2, '0')}/"
      "${d.month.toString().padLeft(2, '0')}/"
      "${d.year} • "
      "${d.hour.toString().padLeft(2, '0')}:"
      "${d.minute.toString().padLeft(2, '0')}";
}

String _monthLabel(DateTime d) {
  const months = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];
  return "${months[d.month - 1]} ${d.year}";
}