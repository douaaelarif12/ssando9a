import 'dart:async' show unawaited;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/navigation/auth_gate.dart';
import 'app/theme/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'features/budget/data/datasources/firestore/sandokti_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Init notifications en arrière-plan (n'attend pas)
  unawaited(NotificationService.instance.initialize());

  // Init Firestore en arrière-plan — l'UI s'affiche immédiatement
  unawaited(SandoktiFirestore.instance.ensureInitialized());

  runApp(const ProviderScope(child: SandoktiApp()));
}

class SandoktiApp extends ConsumerWidget {
  const SandoktiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sandokti',
      themeMode: themeMode,

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFF7FC),
        cardColor: Colors.white,
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        useMaterial3: true,
      ),

      home: const AuthGate(),
    );
  }
}