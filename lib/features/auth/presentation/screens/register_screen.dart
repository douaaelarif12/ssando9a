import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';
import 'onboarding_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _salary = TextEditingController();
  final TextEditingController _childrenCount =
  TextEditingController(text: '0');

  String _householdType = 'single';

  Future<void> _submit() async {
    final salary = int.tryParse(_salary.text.trim()) ?? 0;
    final children = int.tryParse(_childrenCount.text.trim()) ?? 0;

    if (_fullName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom complet est obligatoire')),
      );
      return;
    }

    if (_email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'email est obligatoire")),
      );
      return;
    }

    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le mot de passe doit contenir au moins 6 caractères',
          ),
        ),
      );
      return;
    }

    if (salary <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le salaire mensuel est invalide')),
      );
      return;
    }

    if (_householdType == 'couple' && children < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le nombre d'enfants est invalide")),
      );
      return;
    }

    final String? error = await ref.read(authProvider.notifier).register(
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      monthlySalaryDh: salary,
      householdType: _householdType,
      childrenCount: _householdType == 'couple' ? children : 0,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final bool isLoading = auth.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 24),
          const Text(
            'Créer un compte',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Entre tes informations',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _fullName,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nom complet',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            obscureText: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _salary,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Salaire mensuel total (DH)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _householdType,
            decoration: const InputDecoration(
              labelText: 'Situation familiale',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'single',
                child: Text('Célibataire'),
              ),
              DropdownMenuItem(
                value: 'couple',
                child: Text('Couple'),
              ),
            ],
            onChanged: isLoading
                ? null
                : (value) {
              setState(() {
                _householdType = value ?? 'single';
                if (_householdType == 'single') {
                  _childrenCount.text = '0';
                }
              });
            },
          ),
          if (_householdType == 'couple') ...[
            const SizedBox(height: 14),
            TextField(
              controller: _childrenCount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Nombre d'enfants",
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: Text(isLoading ? 'Chargement...' : "S'inscrire"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _salary.dispose();
    _childrenCount.dispose();
    super.dispose();
  }
}