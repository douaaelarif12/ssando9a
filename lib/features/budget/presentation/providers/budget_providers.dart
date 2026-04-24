import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firestore/budget_firestore_datasource.dart';
import '../../data/services/gemini_service.dart';

final budgetDsProvider = Provider<BudgetFirestoreDatasource>((ref) {
  return BudgetFirestoreDatasource();
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
