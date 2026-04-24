import 'package:flutter/material.dart';
import 'package:sandokti/app/theme/sandokti_colors.dart';

/// Helpers UI pour rendre les catégories "à la marocaine"
class CategoryUI {
  /// Retourne l'icône correspondant à un categoryId (cat_*) ou à un iconKey legacy.
  static IconData iconForCategory(String? categoryId) {
    switch (categoryId) {
      // ── Alimentation ────────────────────────────────
      case 'cat_food':
        return Icons.shopping_basket_rounded;
      case 'cat_market':
        return Icons.storefront_rounded;
      case 'cat_restaurant':
        return Icons.restaurant_rounded;

      // ── Logement ────────────────────────────────────
      case 'cat_rent':
        return Icons.home_rounded;

      // ── Transport ───────────────────────────────────
      case 'cat_transport':
        return Icons.directions_bus_rounded;
      case 'cat_bus':
        return Icons.directions_bus_filled_rounded;
      case 'cat_fuel':
        return Icons.local_gas_station_rounded;
      case 'cat_auto_maintenance':
        return Icons.build_circle_rounded;
      case 'cat_auto_insurance':
        return Icons.car_crash_rounded;

      // ── Factures & Services ─────────────────────────
      case 'cat_bills':
        return Icons.bolt_rounded;
      case 'cat_internet':
        return Icons.wifi_rounded;
      case 'cat_phone':
        return Icons.smartphone_rounded;

      // ── Santé ────────────────────────────────────────
      case 'cat_health':
        return Icons.local_hospital_rounded;

      // ── Sport & Bien-être ────────────────────────────
      case 'cat_sport':
        return Icons.fitness_center_rounded;
      case 'cat_beauty':
        return Icons.face_retouching_natural_rounded;

      // ── Loisirs & Sorties ────────────────────────────
      case 'cat_fun':
        return Icons.local_activity_rounded;

      // ── Éducation ────────────────────────────────────
      case 'cat_school':
        return Icons.school_rounded;

      // ── Famille & Enfants ────────────────────────────
      case 'cat_children':
        return Icons.child_care_rounded;
      case 'cat_family':
        return Icons.family_restroom_rounded;

      // ── Occasions marocaines ─────────────────────────
      case 'cat_eid':
        return Icons.celebration_rounded;
      case 'cat_ramadan':
        return Icons.nightlight_round;

      // ── Voyages ──────────────────────────────────────
      case 'cat_travel':
        return Icons.flight_takeoff_rounded;

      // ── Imprévus ─────────────────────────────────────
      case 'cat_unexpected':
        return Icons.warning_amber_rounded;

      // ── Épargne ──────────────────────────────────────
      case 'cat_saving':
        return Icons.savings_rounded;

      // ── Legacy icon keys (compatibilité ascendante) ──
      default:
        return _iconForKey(categoryId);
    }
  }

  /// @deprecated — utiliser iconForCategory(categoryId) à la place.
  static IconData iconForKey(String? key) => _iconForKey(key);

  static IconData _iconForKey(String? key) {
    switch (key) {
      case 'basket':
        return Icons.shopping_basket_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'car':
        return Icons.local_taxi_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'tshirt':
        return Icons.checkroom_rounded;
      case 'spa':
        return Icons.spa_rounded;
      case 'user':
        return Icons.person_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'box':
        return Icons.inventory_2_rounded;
      case 'plane':
        return Icons.flight_takeoff_rounded;
      case 'wrench':
        return Icons.build_rounded;
      case 'health':
        return Icons.local_hospital_rounded;
      case 'safe':
        return Icons.savings_rounded;
      case 'ramadan':
        return Icons.nightlight_round;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  /// hex attendu: '0xFFD4AF37'
  static Color colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return SandoktiColors.emerald;
    try {
      final value = int.parse(hex);
      return Color(value);
    } catch (_) {
      return SandoktiColors.emerald;
    }
  }

  static Color bg(Color c) => c.withOpacity(0.14);
}