import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sandokti/app/theme/sandokti_colors.dart';
import 'package:sandokti/core/utils/currency.dart';
import 'package:sandokti/features/budget/presentation/dashboard_controller.dart';
import 'package:sandokti/features/budget/presentation/providers/budget_providers.dart';

class FixedExpensesScreen extends ConsumerStatefulWidget {
  const FixedExpensesScreen({super.key});

  @override
  ConsumerState<FixedExpensesScreen> createState() =>
      _FixedExpensesScreenState();
}

class _FixedExpensesScreenState extends ConsumerState<FixedExpensesScreen> {
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadFixedExpenses();
  }

  Future<List<Map<String, Object?>>> _loadFixedExpenses() {
    final ds = ref.read(budgetDsProvider);
    return ds.getFixedExpenses();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadFixedExpenses();
    });
  }

  String _monthLabel(int month) {
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
    return labels[month];
  }

  List<int> _parseMonths(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList()
      ..sort();
  }

  Future<void> _showExpenseForm({Map<String, Object?>? existing}) async {
    final isEdit = existing != null;

    final titleController = TextEditingController(
      text: existing?['title'] as String? ?? '',
    );

    final amountController = TextEditingController(
      text: existing == null
          ? ''
          : (((existing['amountCents'] as int?) ?? 0) ~/ 100).toString(),
    );

    String chargeType = (existing?['chargeType'] as String?) ?? 'monthly';
    final selectedMonths =
    Set<int>.from(_parseMonths(existing?['activeMonths'] as String?));

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEdit
                          ? 'Modifier une charge fixe'
                          : 'Ajouter une charge fixe',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre',
                        hintText: 'Ex: Loyer, Internet, Crédit...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant (DH)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: chargeType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text('Tous les mois'),
                        ),
                        DropdownMenuItem(
                          value: 'seasonal',
                          child: Text('Certains mois seulement'),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          chargeType = value ?? 'monthly';
                        });
                      },
                    ),
                    if (chargeType == 'seasonal') ...[
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mois actifs',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(12, (i) {
                          final month = i + 1;
                          return FilterChip(
                            label: Text(_monthLabel(month)),
                            selected: selectedMonths.contains(month),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedMonths.add(month);
                                } else {
                                  selectedMonths.remove(month);
                                }
                              });
                            },
                          );
                        }),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final amount =
                              int.tryParse(amountController.text.trim()) ?? 0;

                          if (title.isEmpty || amount <= 0) {
                            return;
                          }

                          if (chargeType == 'seasonal' &&
                              selectedMonths.isEmpty) {
                            return;
                          }

                          final ds = ref.read(budgetDsProvider);

                          if (isEdit) {
                            await ds.updateFixedExpense(
                              id: existing['id'] as String,
                              title: title,
                              amountDh: amount,
                              chargeType: chargeType,
                              activeMonths: chargeType == 'monthly'
                                  ? []
                                  : selectedMonths.toList()..sort(),
                            );
                          } else {
                            await ds.insertFixedExpense(
                              title: title,
                              amountDh: amount,
                              chargeType: chargeType,
                              activeMonths: chargeType == 'monthly'
                                  ? []
                                  : selectedMonths.toList()..sort(),
                            );
                          }

                          ref.invalidate(dashboardProvider);

                          if (context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                        child: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      await _refresh();
    }
  }

  Future<void> _deleteExpense(String id) async {
    final ds = ref.read(budgetDsProvider);
    await ds.deleteFixedExpense(id);
    ref.invalidate(dashboardProvider);
    await _refresh();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Charge fixe supprimée')),
      );
    }
  }

  String _buildSubtitle(Map<String, Object?> item) {
    final chargeType = (item['chargeType'] as String?) ?? 'monthly';

    if (chargeType == 'monthly') {
      return 'Tous les mois';
    }

    final months = _parseMonths(item['activeMonths'] as String?);
    if (months.isEmpty) {
      return 'Certains mois';
    }

    return months.map(_monthLabel).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charges fixes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: SandoktiColors.emerald,
        foregroundColor: Colors.white,
        onPressed: () => _showExpenseForm(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.receipt_long_outlined, size: 56),
                    SizedBox(height: 12),
                    Text(
                      'Aucune charge fixe pour le moment',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final totalCents = items.fold<int>(
            0,
                (sum, item) => sum + ((item['amountCents'] as int?) ?? 0),
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SandoktiColors.emerald.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total des charges fixes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatMAD(totalCents),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...items.map((item) {
                  final id = item['id'] as String? ?? '';
                  final title = item['title'] as String? ?? '';
                  final amountCents = (item['amountCents'] as int?) ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        SandoktiColors.emerald.withOpacity(0.12),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: SandoktiColors.emerald,
                        ),
                      ),
                      title: Text(title),
                      subtitle: Text(_buildSubtitle(item)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatMAD(amountCents),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () => _showExpenseForm(existing: item),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => _deleteExpense(id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
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
}