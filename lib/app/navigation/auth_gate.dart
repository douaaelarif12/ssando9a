import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import 'app_shell.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return auth.when(
      // Splash pendant la vérification de session Firebase
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      // Erreur inattendue → login
      error: (_, __) => const LoginScreen(),
      // Résultat : user connecté → AppShell, sinon → LoginScreen
      data: (user) => user != null ? const AppShell() : const LoginScreen(),
    );
  }
}