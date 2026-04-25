/// Détecteur d'anomalies budgétaires — messages adaptés au contexte marocain.
class AnomalyDetector {
  /// Seuil minimum : ignorer si dépenses actuelles < 500 DH
  static const int _minAbsoluteThresholdCents = 50000;

  /// Multiplicateur : anomalie si current > average × 1.8
  static const double _multiplier = 1.8;

  /// Noms affichables des catégories en français/darija
  static const Map<String, String> _categoryLabels = {
    'cat_food':             'les courses',
    'cat_market':           'le marché',
    'cat_restaurant':       'les restaurants et cafés',
    'cat_rent':             'le loyer',
    'cat_bills':            'les factures (eau/électricité)',
    'cat_internet':         'internet',
    'cat_phone':            'le téléphone',
    'cat_transport':        'le transport (taxi/tram)',
    'cat_bus':              'le bus/train',
    'cat_fuel':             'l\'essence',
    'cat_auto_maintenance': 'l\'entretien de voiture',
    'cat_auto_insurance':   'l\'assurance voiture',
    'cat_health':           'la santé',
    'cat_school':           'la scolarité',
    'cat_sport':            'le sport',
    'cat_beauty':           'le hammam et la beauté',
    'cat_fun':              'les loisirs',
    'cat_children':         'les dépenses enfants',
    'cat_family':           'la famille et invités',
    'cat_ramadan':          'Ramadan',
    'cat_eid':              'l\'Aïd',
    'cat_travel':           'les voyages',
    'cat_unexpected':       'les imprévus',
    'cat_saving':           'l\'épargne (daret)',
  };

  static bool isAnomalous({
    required int currentCents,
    required int averageCents,
  }) {
    if (averageCents <= 0) return false;
    if (currentCents < _minAbsoluteThresholdCents) return false;
    return currentCents > (averageCents * _multiplier);
  }

  static String buildMessage({
    required String categoryId,
    required int currentCents,
    required int averageCents,
  }) {
    final label = _categoryLabels[categoryId] ?? 'cette catégorie';
    final current = (currentCents / 100).toStringAsFixed(0);
    final avg = (averageCents / 100).toStringAsFixed(0);
    return 'Tes dépenses pour $label ont augmenté ($current DH ce mois vs $avg DH le mois dernier). Pense à vérifier.';
  }

  /// Retourne le label lisible d'une catégorie
  static String labelFor(String categoryId) {
    return _categoryLabels[categoryId] ?? categoryId;
  }
}
