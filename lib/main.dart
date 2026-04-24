import 'dart:async' show unawaited;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/navigation/auth_gate.dart';
import 'features/budget/data/datasources/firestore/sandokti_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Init Firestore en arrière-plan — l'UI s'affiche immédiatement
  unawaited(SandoktiFirestore.instance.ensureInitialized());

  runApp(const ProviderScope(child: SandoktiApp()));
}

class SandoktiApp extends StatelessWidget {
  const SandoktiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sandokti',
      home: const AuthGate(),
    );
  }
}