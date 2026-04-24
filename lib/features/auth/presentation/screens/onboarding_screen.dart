import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/navigation/app_shell.dart';
import '../../../budget/presentation/dashboard_controller.dart';
import '../../../budget/presentation/providers/budget_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final List<Map<String, dynamic>> _charges = [];

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

  Future<void> _openChargeForm({int? index}) async {
    final isEdit = index != null;
    final current = isEdit ? _charges[index] : null;

    final titleController = TextEditingController(
      text: current?['title'] as String? ?? '',
    );
    final amountController = TextEditingController(
      text: current == null ? '' : '${current['amountDh']}',
    );

    String chargeType = current?['chargeType'] as String? ?? 'monthly';

    final selectedMonths = current == null
        ? <int>{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
        : Set<int>.from(current['activeMonths'] as List<int>);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
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
                      isEdit ? 'Modifier charge' : 'Ajouter charge',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la charge',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                      child: ElevatedButton(
                        onPressed: () {
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

                          Navigator.pop(context, {
                            'title': title,
                            'amountDh': amount,
                            'chargeType': chargeType,
                            'activeMonths': chargeType == 'monthly'
                                ? <int>[]
                                : selectedMonths.toList()..sort(),
                          });
                        },
                        child: const Text('Valider'),
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

    if (result == null) return;

    setState(() {
      if (isEdit) {
        _charges[index] = result;
      } else {
        _charges.add(result);
      }
    });
  }

  void _deleteCharge(int index) {
    setState(() {
      _charges.removeAt(index);
    });
  }

  Future<void> _save() async {
    final ds = ref.read(budgetDsProvider);

    for (final item in _charges) {
      await ds.insertFixedExpense(
        title: item['title'] as String,
        amountDh: item['amountDh'] as int,
        chargeType: item['chargeType'] as String,
        activeMonths: (item['activeMonths'] as List<int>),
      );
    }

    ref.invalidate(dashboardProvider);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AppShell(),
      ),
          (route) => false,
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 40),
          SizedBox(height: 10),
          Text(
            'Aucune charge fixe ajoutée',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Ajoute seulement les obligations réelles : loyer, crédit, internet, école...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildChargeCard(Map<String, dynamic> item, int index) {
    final chargeType = item['chargeType'] as String? ?? 'monthly';
    final months = (item['activeMonths'] as List<int>? ?? []);
    final monthsText = chargeType == 'monthly'
        ? 'Tous les mois'
        : months.map(_monthLabel).join(', ');

    return Card(
      child: ListTile(
        title: Text(
          item['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${item['amountDh']} DH\n$monthsText',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openChargeForm(index: index),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteCharge(index),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charges fixes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Ajoute tes charges fixes. Elles seront retirées du budget avant les dépenses normales.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (_charges.isEmpty) _buildEmpty(),
          if (_charges.isNotEmpty)
            ...List.generate(
              _charges.length,
                  (index) => _buildChargeCard(_charges[index], index),
            ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _openChargeForm(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une charge fixe'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }
}