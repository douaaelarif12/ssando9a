import 'package:flutter/material.dart';
import 'package:sandokti/app/theme/sandokti_colors.dart';

/// Helpers UI pour rendre les catégories "à la marocaine"
class CategoryUI {
  static IconData iconForKey(String? key) {
    switch (key) {
      case 'basket': // Nourriture (BIM/Carrefour)
        return Icons.shopping_basket_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'bolt': // Lydec/Amendis
        return Icons.bolt_rounded;
      case 'car': // Diesel/Taxi
        return Icons.local_taxi_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'tshirt':
        return Icons.checkroom_rounded;
      case 'spa': // Hammam / Sadaqa
        return Icons.spa_rounded;
      case 'user':
        return Icons.person_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'box': // Provisions (huile/miel)
        return Icons.inventory_2_rounded;
      case 'plane':
        return Icons.flight_takeoff_rounded;
      case 'wrench':
        return Icons.build_rounded;
      case 'health':
        return Icons.health_and_safety_rounded;
      case 'safe': // épargne
        return Icons.savings_rounded;
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