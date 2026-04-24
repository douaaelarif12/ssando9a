import '../entities/spending_habit_analysis.dart';
import '../../presentation/dashboard_controller.dart';

class BudgetAssistantService {
  const BudgetAssistantService();

  String reply({
    required String userMessage,
    required DashboardState dashboard,
    required SpendingHabitAnalysis habits,
  }) {
    final message = userMessage.trim().toLowerCase();

    if (message.isEmpty) {
      return _emptyReply();
    }

    // 1) Salutations simples (FR + AR + Darija)
    if (_containsAny(message, [
      'bonjour', 'bonsoir', 'salut', 'salam', 'slm',
      'hello', 'hey', 'coucou',
      'marhba', 'marhaba', 'labas', 'la bas', 'lbas',
    ]) || _containsAnyAr(userMessage, [
      'مرحبا', 'أهلا', 'اهلا', 'صباح الخير', 'مساء الخير',
      'لاباس', 'سلام',
    ])) {
      return _greetingReply();
    }

    // 2) Remerciements (FR + AR + Darija)
    if (_containsAny(message, [
      'merci', 'merci beaucoup', 'thanks', 'thank you',
      'choukran', 'chokran', 'shukran',
    ]) || _containsAnyAr(userMessage, [
      'شكرا', 'شكراً', 'بارك الله فيك', 'مشكور',
    ])) {
      return "Avec plaisir 👌 Pose-moi une autre question sur ton budget, ton épargne ou tes dépenses.";
    }

    // 3) Réponses vagues
    if (_containsAny(message, [
      'oui', 'ok', 'okay', 'dac', 'daccord', 'non', 'hmm',
    ])) {
      return "Je peux t'aider sur ton budget. Demande-moi par exemple : "
          '"Combien il me reste ?", "Quelle est ma catégorie dominante ?" ou "Donne-moi un conseil".';
    }

    // 4) Budget restant
    if (_containsAny(message, [
      'solde', 'reste', 'budget restant', 'combien il me reste',
      'combien me reste', 'reste actuel', 'kdam bqa', 'chhal bqa',
    ])) {
      return _budgetReply(dashboard);
    }

    // 5) Épargne
    if (_containsAny(message, [
      'épargne', 'epargne', 'economiser', 'économiser',
      'mettre de côté', 'mettre de cote', 'sauver', 'twfir',
    ])) {
      return _savingReply(dashboard);
    }

    // 6) Catégorie dominante / habitudes
    if (_containsAny(message, [
      'catégorie', 'categorie', 'je dépense le plus', 'depense le plus',
      'plus grosse dépense', 'habitudes', 'categorie dominante',
      'catégorie dominante', 'point faible',
    ])) {
      return _topCategoryReply(habits);
    }

    // 7) Jour le plus coûteux
    if (_containsAny(message, [
      'jour', 'quel jour', 'jour le plus coûteux',
      'jour le plus couteux', 'jour le plus cher',
    ])) {
      return _dayReply(habits);
    }

    // 8) Alertes / risques
    if (_containsAny(message, [
      'alerte', 'alertes', 'danger', 'risque',
      'dépassement', 'depassement',
    ])) {
      return _alertsReply(dashboard);
    }

    // 9) Analyse globale
    if (_containsAny(message, [
      'analyse', 'analyse mon budget', 'analyse ce mois',
      'résume', 'resume', 'bilan', 'budget de ce mois', 'hlal',
    ])) {
      return _analysisReply(dashboard, habits);
    }

    // 10) Conseil
    if (_containsAny(message, [
      'conseil', 'recommande', 'recommandation', 'que faire',
      'aide-moi', 'aide moi', 'quoi faire', 'nsawbak', 'chi conseil',
    ])) {
      return _adviceReply(dashboard, habits);
    }

    return _fallbackReply(habits);
  }

  String _greetingReply() {
    return "Salam 👋 Je suis là pour t'aider. "
        'Tu peux me demander par exemple : "Combien il me reste ?", '
        '"Quelle est ma catégorie dominante ?" ou "Donne-moi un conseil".';
  }

  String _emptyReply() {
    return "Écris-moi une vraie question sur ton budget, ton épargne ou tes dépenses.";
  }

  String _budgetReply(DashboardState dashboard) {
    return 'Ton reste réel actuel est de ${_mad(dashboard.realBalanceCents)}. '
        "Tu as dépensé ${_mad(dashboard.expenseCents)} ce mois pour un revenu total de ${_mad(dashboard.incomeCents)}.";
  }

  String _savingReply(DashboardState dashboard) {
    final savingRec = dashboard.recommendations.where((e) => e.id == 'saving');
    final suggested = savingRec.isEmpty
        ? 0
        : savingRec.fold<int>(0, (sum, item) => sum + item.amountCents);

    if (suggested <= 0) {
      return "Je n'ai pas encore assez d'informations pour calculer une épargne conseillée fiable.";
    }

    return "Ce mois-ci, je te conseille d'épargner environ ${_mad(suggested)}. "
        "Ton taux d'épargne réel actuel est de ${dashboard.savingRate.toStringAsFixed(1)}%.";
  }

  String _topCategoryReply(SpendingHabitAnalysis habits) {
    if (!habits.hasData || habits.topCategory == null) {
      return "Je n'ai pas encore assez de données pour identifier ta catégorie dominante.";
    }

    return "Ta catégorie dominante ce mois-ci est ${habits.topCategory} "
        "avec ${_mad(habits.topCategoryAmountCents)} dépensés. "
        "C'est probablement ton point faible principal ce mois-ci.";
  }

  String _dayReply(SpendingHabitAnalysis habits) {
    if (!habits.hasData || habits.mostExpensiveDayName == null) {
      return "Je n'ai pas encore assez de données pour trouver ton jour le plus coûteux.";
    }

    return 'Le jour où tu dépenses le plus est ${habits.mostExpensiveDayName}.';
  }

  String _alertsReply(DashboardState dashboard) {
    if (dashboard.alerts.isEmpty) {
      return "Bonne nouvelle : je ne détecte aucune alerte budgétaire majeure pour le moment.";
    }

    final first = dashboard.alerts.first;
    return 'Attention : ${first.label} dépasse ou approche le budget conseillé. '
        'Montant conseillé : ${_mad(first.recommendedCents)}, '
        'montant dépensé : ${_mad(first.spentCents)}.';
  }

  String _analysisReply(DashboardState dashboard, SpendingHabitAnalysis habits) {
    if (!habits.hasData) {
      return "Je n'ai pas encore assez de données pour faire une vraie analyse. "
          'Ajoute encore quelques dépenses ce mois-ci.';
    }

    return 'Voici ton résumé du mois : reste réel ${_mad(dashboard.realBalanceCents)}, '
        'catégorie dominante ${habits.topCategory ?? "non disponible"}, '
        'moyenne par dépense ${_mad(habits.averageExpenseCents)}.';
  }

  String _adviceReply(DashboardState dashboard, SpendingHabitAnalysis habits) {
    if (dashboard.realBalanceCents < 0) {
      return "Ton reste réel est négatif. Réduis immédiatement les dépenses non essentielles ce mois-ci.";
    }

    if (dashboard.alerts.isNotEmpty) {
      final first = dashboard.alerts.first;
      return 'Je te conseille de surveiller en priorité la catégorie ${first.label}, '
          'car elle met ton budget sous pression.';
    }

    if (habits.smallExpensesCount >= 5 && habits.smallExpensesShare >= 0.20) {
      return "Tes petites dépenses fréquentes pèsent sur ton budget. Essaie de leur fixer une limite hebdomadaire.";
    }

    return dashboard.smartAdvice;
  }

  String _fallbackReply(SpendingHabitAnalysis habits) {
    if (!habits.hasData) {
      return "Je peux t'aider sur ton budget, ton épargne et tes dépenses. "
          'Demande-moi par exemple : "Combien il me reste ?"';
    }

    return "Je n'ai pas bien compris ta question. "
        'Tu peux me demander par exemple : '
        '"Combien il me reste ?", "Analyse mon budget" ou "Donne-moi un conseil".';
  }

  /// Recherche dans le message Latin (toLowerCase déjà appliqué)
  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  /// Recherche dans le message original (pour l'arabe, case insensitive sans perte)
  bool _containsAnyAr(String original, List<String> keywords) {
    for (final keyword in keywords) {
      if (original.contains(keyword)) return true;
    }
    return false;
  }

  String _mad(int cents) {
    final dh = cents / 100;
    if (dh % 1 == 0) return '${dh.toStringAsFixed(0)} DH';
    return '${dh.toStringAsFixed(2)} DH';
  }
}
