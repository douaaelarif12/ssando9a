import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';

class SalarySetupScreen extends ConsumerStatefulWidget {
  const SalarySetupScreen({super.key});

  @override
  ConsumerState<SalarySetupScreen> createState() => _SalarySetupScreenState();
}

class _SalarySetupScreenState extends ConsumerState<SalarySetupScreen> {
  final _salary = TextEditingController();
  bool _loading = false;

  Future<void> _save() async {
    final dh = int.tryParse(_salary.text.trim()) ?? 0;

    if (dh <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Salaire invalide")),
      );
      return;
    }

    setState(() => _loading = true);

    final error = await ref.read(authProvider.notifier).updateMonthlySalary(
      monthlySalaryDh: dh,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Salaire mensuel")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Définis ton salaire mensuel fixe",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _salary,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Salaire (DH)",
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: const Text("Enregistrer"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _salary.dispose();
    super.dispose();
  }
}