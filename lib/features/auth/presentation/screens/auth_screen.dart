import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _registerSalary = TextEditingController();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  final _registerName = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();

  String _selectedProfileType = 'single';
  final _childrenCount = TextEditingController(text: '0');

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _doLogin() async {
    setState(() => _busy = true);

    final error = await ref.read(authProvider.notifier).login(
      email: _loginEmail.text.trim(),
      password: _loginPassword.text,
    );

    setState(() => _busy = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _doRegister() async {
    final salary = int.tryParse(_registerSalary.text.trim()) ?? 0;

    final householdType =
        _selectedProfileType == 'single' ? 'single' : 'couple';

    int childrenCount = 0;
    if (_selectedProfileType == 'couple_with_children') {
      childrenCount = int.tryParse(_childrenCount.text.trim()) ?? 0;
    }

    if (_registerName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom complet est obligatoire')),
      );
      return;
    }

    if (_registerEmail.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'email est obligatoire")),
      );
      return;
    }

    if (_registerPassword.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe doit contenir au moins 6 caractères'),
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

    if (_selectedProfileType == 'couple_with_children' && childrenCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le nombre d'enfants est invalide")),
      );
      return;
    }

    setState(() => _busy = true);

    final error = await ref.read(authProvider.notifier).register(
      fullName: _registerName.text.trim(),
      email: _registerEmail.text.trim(),
      password: _registerPassword.text,
      monthlySalaryDh: salary,
      householdType: householdType,
      childrenCount: childrenCount,
    );

    setState(() => _busy = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            const Text(
              "sandokti",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Gestion de budget premium pour le Maroc",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Connexion"),
                Tab(text: "Créer un compte"),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLogin(),
                  _buildRegister(),
                ],
              ),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      children: [
        TextField(
          controller: _loginEmail,
          decoration: const InputDecoration(labelText: "Email"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPassword,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Mot de passe"),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _busy ? null : _doLogin,
            child: const Text("Se connecter"),
          ),
        ),
      ],
    );
  }

  Widget _buildRegister() {
    return Column(
      children: [
        TextField(
          controller: _registerName,
          decoration: const InputDecoration(labelText: "Nom complet"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: "Email"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerPassword,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Mot de passe"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerSalary,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Salaire mensuel (DH)"),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedProfileType,
          decoration: const InputDecoration(labelText: 'Situation familiale'),
          items: const [
            DropdownMenuItem(
              value: 'single',
              child: Text('Single'),
            ),
            DropdownMenuItem(
              value: 'couple_no_children',
              child: Text('Couple sans enfants'),
            ),
            DropdownMenuItem(
              value: 'couple_with_children',
              child: Text('Couple avec enfants'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedProfileType = value ?? 'single';
              if (_selectedProfileType != 'couple_with_children') {
                _childrenCount.text = '0';
              }
            });
          },
        ),
        if (_selectedProfileType == 'couple_with_children') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _childrenCount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Nombre d'enfants"),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _busy ? null : _doRegister,
            child: const Text("Créer mon compte"),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _registerName.dispose();
    _registerEmail.dispose();
    _registerPassword.dispose();
    _registerSalary.dispose();
    _childrenCount.dispose();
    super.dispose();
  }
}