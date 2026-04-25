import 'anomaly_detector.dart';

/// Moteur de conseils budgétaires — adapté aux habitudes marocaines.
class BudgetAdviceEngine {
  /// Conseils selon les postes dépassés et la situation du mois.
  static String buildAdvice({
    required List<String> warningCategories,
    required bool forecastWillOverrun,
    required bool hasDangerAlert,
  }) {
    if (forecastWillOverrun) {
      return _overrunAdvice(warningCategories);
    }

    if (hasDangerAlert && warningCategories.isNotEmpty) {
      return _dangerAdvice(warningCategories.first);
    }

    if (warningCategories.isNotEmpty) {
      return _warningAdvice(warningCategories.first);
    }

    return _positiveAdvice();
  }

  static String _overrunAdvice(List<String> categories) {
    if (categories.isEmpty) {
      return "Au rythme actuel, ton budget risque d'être dépassé avant la fin du mois. Essaie de limiter les dépenses non essentielles.";
    }
    final label = AnomalyDetector.labelFor(categories.first);
    return "Au rythme actuel, ton budget sera dépassé. Le poste '$label' pèse lourd ce mois — quelques ajustements suffiront.";
  }

  static String _dangerAdvice(String categoryId) {
    final label = AnomalyDetector.labelFor(categoryId);
    return switch (categoryId) {
      'cat_restaurant' =>
        "Manger dehors souvent revient cher. Cuisiner à la maison quelques fois par semaine peut faire une vraie différence sur ton budget.",
      'cat_fun' =>
        "Les sorties s'accumulent ce mois. Choisis les moments qui comptent vraiment et garde le reste pour le mois prochain.",
      'cat_transport' =>
        "Tes frais de taxi sont élevés. Le tram ou le bus peut être une bonne alternative pour les trajets courts.",
      'cat_fuel' =>
        "Tes dépenses en essence dépassent la normale. Si possible, regroupe tes trajets pour réduire la consommation.",
      'cat_beauty' =>
        "Le budget hammam et beauté est élevé ce mois. Espacer quelques soins peut aider à l'équilibrer.",
      'cat_food' =>
        "Les courses semblent plus chères ce mois. Profite des promos BIM et Marjane, et préfère le souk pour les légumes.",
      'cat_family' =>
        "Les dépenses famille et invités sont importantes. C'est normal dans notre culture, mais pense à prévoir une enveloppe mensuelle dédiée.",
      _ =>
        "Le poste '$label' dépasse nettement le niveau conseillé. Une petite réduction sur ce poste améliorera ton équilibre ce mois.",
    };
  }

  static String _warningAdvice(String categoryId) {
    final label = AnomalyDetector.labelFor(categoryId);
    return switch (categoryId) {
      'cat_food' =>
        "Les courses alimentaires prennent une part notable du budget. Pense à faire une liste avant d'aller au souk ou au supermarché.",
      'cat_restaurant' =>
        "Les cafés et restaurants s'accumulent. Un café moins le week-end peut libérer quelques dirhams pour l'épargne.",
      'cat_transport' =>
        "Les frais de transport augmentent. Pense à l'abonnement mensuel tram ou bus si tu fais des trajets réguliers.",
      'cat_phone' =>
        "Les recharges téléphone sont fréquentes. Un forfait mensuel fixe serait peut-être plus économique.",
      'cat_bills' =>
        "Les factures (eau/électricité) sont en hausse. Pense à éteindre les appareils en veille et à surveiller ta consommation d'eau.",
      'cat_children' =>
        "Les dépenses enfants sont importantes ce mois. Pense à anticiper les fournitures scolaires à l'avance pour mieux répartir le budget.",
      _ =>
        "Le poste '$label' prend une place importante ce mois. Garde un œil dessus pour maintenir ton équilibre budgétaire.",
    };
  }

  static String _positiveAdvice() {
    final tips = [
      "Ton budget est bien maîtrisé ce mois. C'est le bon moment pour alimenter ton épargne ou ta daret.",
      "Bonne gestion ce mois ! Si tu n'as pas encore d'épargne d'urgence, commence avec 200 DH de côté chaque mois.",
      "Tout est équilibré. Pense à prévoir les dépenses de Ramadan ou de l'Aïd si elles approchent.",
      "Bravo, ton budget est sain ce mois. Continue sur ce rythme et envisage un objectif épargne pour la prochaine saison.",
    ];
    // index basé sur le jour du mois pour varier les messages
    final day = DateTime.now().day;
    return tips[day % tips.length];
  }
}
