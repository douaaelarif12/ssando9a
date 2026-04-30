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
  bool _obscurePassword = true;

  Future<void> _submit() async {
    final salary = int.tryParse(_salary.text.trim()) ?? 0;
    final children = int.tryParse(_childrenCount.text.trim()) ?? 0;

    if (_fullName.text.trim().isEmpty) {
      _show("Le nom complet est obligatoire");
      return;
    }
    if (_email.text.trim().isEmpty) {
      _show("L'email est obligatoire");
      return;
    }
    if (_password.text.length < 6) {
      _show('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }
    if (salary <= 0) {
      _show('Le salaire mensuel est invalide');
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
      _show(error);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final bool isLoading = auth.isLoading;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🔹 Background zellige
          Image.asset(
            'assets/patterns/zellige.png',
            fit: BoxFit.cover,
          ),

          // 🔹 Overlay
          Container(
            color: Colors.black.withOpacity(0.30),
          ),

          SafeArea(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                const SizedBox(height: 24),

                // 🔙 Header
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Text(
                      'Inscription',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // 🔥 CARD
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3A3A).withOpacity(0.70),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Crée ton compte',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      _buildInput(_fullName, 'Nom complet',
                          icon: Icons.person_outline),

                      _buildInput(_email, 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress),

                      // Mot de passe avec œil
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: TextField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            labelStyle:
                                const TextStyle(color: Colors.white70),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Color(0xFFD4AF37)),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ),

                      _buildInput(_salary, 'Salaire mensuel (DH)',
                          icon: Icons.account_balance_wallet_outlined,
                          keyboardType: TextInputType.number),

                      // Dropdown situation familiale
                      DropdownButtonFormField<String>(
                        value: _householdType,
                        dropdownColor: const Color(0xFF0B3A3A),
                        style: const TextStyle(color: Colors.white),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white54),
                        decoration: const InputDecoration(
                          labelText: 'Situation familiale',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFFD4AF37)),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'single',
                              child: Text('Célibataire')),
                          DropdownMenuItem(
                              value: 'couple', child: Text('Couple')),
                        ],
                        onChanged: (value) => setState(
                            () => _householdType = value ?? 'single'),
                      ),

                      if (_householdType == 'couple') ...[
                        const SizedBox(height: 4),
                        _buildInput(_childrenCount, "Nombre d'enfants",
                            icon: Icons.child_care_outlined,
                            keyboardType: TextInputType.number),
                      ],

                      const SizedBox(height: 30),

                      // Bouton S'inscrire
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: isLoading ? null : _submit,
                          child: Text(
                            isLoading ? 'Chargement...' : "S'inscrire",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Center(
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text(
                            'Déjà un compte ? Se connecter',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.white54, size: 20)
              : null,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFD4AF37)),
          ),
        ),
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