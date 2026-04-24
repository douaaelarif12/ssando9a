import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

// Le provider est déclaré dans budget_providers.dart — pas ici
class GeminiService {
  Future<String> ask({
    required String userMessage,
    required String appContext,
  }) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash-lite',
      );

      final prompt =
          'Tu es Sandokti, assistant financier personnel pour le Maroc. '
          'Reponds en francais, de facon claire et concise (3 a 6 lignes max). '
          'Utilise les chiffres en dirhams (DH).\n\n'
          '$appContext\n\n'
          'Question : $userMessage';

      final response = await model.generateContent([
        Content.text(prompt),
      ]).timeout(const Duration(seconds: 25));

      final text = response.text;
      if (text != null && text.isNotEmpty) {
        return text.trim();
      }

      return "Je n'ai pas pu generer une reponse. Reessaie.";
    } on FirebaseException catch (e) {
      debugPrint('FirebaseException AI: ${e.code} - ${e.message}');
      if (e.code.contains('resource-exhausted') ||
          e.message?.contains('429') == true ||
          e.message?.toLowerCase().contains('quota') == true) {
        throw Exception('quota_cooldown');
      }
      if (e.code.contains('permission-denied') ||
          e.code.contains('unauthenticated')) {
        throw Exception('gemini_bad_key');
      }
      return 'Desole, le service IA est indisponible. (${e.code})';
    } on TimeoutException catch (_) {
      throw Exception('gemini_timeout');
    } catch (e) {
      debugPrint('Erreur inattendue AI: $e');
      return "Desole, l'IA rencontre un probleme technique. Reessaie.";
    }
  }
}
