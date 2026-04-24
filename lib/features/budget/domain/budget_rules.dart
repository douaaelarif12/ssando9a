class BudgetRecommendation {
  final String id;
  final String label;
  final int percent;
  final int amountCents;

  const BudgetRecommendation({
    required this.id,
    required this.label,
    required this.percent,
    required this.amountCents,
  });
}

class BudgetAlert {
  final String id;
  final String label;
  final int recommendedCents;
  final int spentCents;
  final double ratio;
  final String severity; // warning | danger

  const BudgetAlert({
    required this.id,
    required this.label,
    required this.recommendedCents,
    required this.spentCents,
    required this.ratio,
    required this.severity,
  });
}

class BudgetRules {
  static List<BudgetRecommendation> buildRecommendations({
    required int incomeCents,
    required String householdType,
    required int childrenCount,
  }) {
    final rules = _resolveRules(
      householdType: householdType,
      childrenCount: childrenCount,
    );

    return rules.entries.map((entry) {
      final percent = entry.value.$1;
      final label = entry.value.$2;

      return BudgetRecommendation(
        id: entry.key,
        label: label,
        percent: percent,
        amountCents: ((incomeCents * percent) / 100).round(),
      );
    }).toList();
  }

  static List<BudgetAlert> buildAlerts({
    required List<BudgetRecommendation> recommendations,
    required List<Map<String, Object?>> byCategory,
  }) {
    final spentByRule = <String, int>{};

    for (final row in byCategory) {
      final categoryId = row['categoryId'] as String?;
      final total = (row['totalCents'] as int?) ?? 0;
      final ruleId = mapCategoryToRule(categoryId);

      if (ruleId == null) continue;
      spentByRule[ruleId] = (spentByRule[ruleId] ?? 0) + total;
    }

    final alerts = <BudgetAlert>[];

    for (final rec in recommendations) {
      final spent = spentByRule[rec.id] ?? 0;
      if (rec.amountCents <= 0 || spent <= 0) continue;

      final ratio = spent / rec.amountCents;

      if (ratio >= 1.0) {
        alerts.add(
          BudgetAlert(
            id: rec.id,
            label: rec.label,
            recommendedCents: rec.amountCents,
            spentCents: spent,
            ratio: ratio,
            severity: 'danger',
          ),
        );
      } else if (ratio >= 0.8) {
        alerts.add(
          BudgetAlert(
            id: rec.id,
            label: rec.label,
            recommendedCents: rec.amountCents,
            spentCents: spent,
            ratio: ratio,
            severity: 'warning',
          ),
        );
      }
    }

    alerts.sort((a, b) => b.ratio.compareTo(a.ratio));
    return alerts;
  }

  static String? mapCategoryToRule(String? categoryId) {
    switch (categoryId) {
      case 'cat_rent':
        return null;

      case 'cat_bills':
      case 'cat_phone':
      case 'cat_internet':
        return 'bills';

      case 'cat_food':
      case 'cat_market':
      case 'cat_restaurant':
        return 'food';

      case 'cat_transport':
      case 'cat_fuel':
      case 'cat_bus':
      case 'cat_auto_maintenance':
      case 'cat_auto_insurance':
        return 'transport';

      case 'cat_fun':
      case 'cat_beauty':
        return 'coffee';

      case 'cat_sport':
        return 'sport';

      case 'cat_health':
        return 'health';

      case 'cat_school':
      case 'cat_family':
      case 'cat_children':
        return 'children';

      case 'cat_unexpected':
        return 'unexpected';

      case 'cat_saving':
        return 'saving';

      default:
        return null;
    }
  }

  static Map<String, (int, String)> _resolveRules({
    required String householdType,
    required int childrenCount,
  }) {
    if (householdType == 'couple' && childrenCount > 0) {
      return {
        'bills': (20, 'Electricité / Eau / Gaz'),
        'food': (28, 'Nourriture'),
        'transport': (16, 'Transport / Voiture'),
        'children': (16, 'Enfants'),
        'health': (20, 'Santé'),
        'unexpected': (15, 'Imprévus'),
        'saving': (20, 'Epargne obligatoire'),
      };
    }

    if (householdType == 'couple') {
      return {
        'bills': (12, 'Electricité / Eau / Gaz'),
        'food': (15, 'Nourriture'),
        'transport': (10, 'Transport / Voiture'),
        'coffee': (9, 'Café / Sorties'),
        'unexpected': (10, 'Imprévus'),
        'saving': (15, 'Epargne obligatoire'),
      };
    }

    return {
      'bills': (6, 'Electricité / Eau / Gaz'),
      'food': (10, 'Nourriture'),
      'transport': (8, 'Transport / Voiture'),
      'coffee': (4, 'Café / Sorties'),
      'sport': (8, 'Sport / Bien-être'),
      'unexpected': (10, 'Imprévus'),
      'saving': (20, 'Epargne obligatoire'),
    };
  }
}