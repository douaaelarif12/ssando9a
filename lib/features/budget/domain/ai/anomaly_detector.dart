class AnomalyDetector {
  /// Seuil minimum absolu : ignorer si les dépenses actuelles < 500 DH
  /// (évite les faux positifs quand les deux mois sont très faibles)
  static const int _minAbsoluteThresholdCents = 50000; // 500 DH

  /// Multiplicateur : anomalie si current > average * 1.8 (au lieu de * 2)
  static const double _multiplier = 1.8;

  /// Détecte si les dépenses du mois sont anormalement élevées
  static bool isAnomalous({
    required int currentCents,
    required int averageCents,
  }) {
    if (averageCents <= 0) return false;
    if (currentCents < _minAbsoluteThresholdCents) return false;

    return currentCents > (averageCents * _multiplier);
  }

  /// Génère un message lisible
  static String buildMessage({
    required String category,
    required int currentCents,
    required int averageCents,
  }) {
    final current = (currentCents / 100).toStringAsFixed(0);
    final avg = (averageCents / 100).toStringAsFixed(0);

    return 'Tes dépenses $category sont élevées ($current DH vs $avg DH le mois dernier)';
  }
}
