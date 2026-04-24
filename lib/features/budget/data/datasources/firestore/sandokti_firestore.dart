import 'package:cloud_firestore/cloud_firestore.dart';

class SandoktiFirestore {
  SandoktiFirestore._();

  static final SandoktiFirestore instance = SandoktiFirestore._();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get categories =>
      firestore.collection('categories');

  DocumentReference<Map<String, dynamic>> userDoc(String uid) {
    return firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> userCollection(
    String uid,
    String name,
  ) {
    return userDoc(uid).collection(name);
  }

  Future<void> ensureInitialized() async {
    await _seedCategories();
  }

  Future<void> _seedCategories() async {
    final snapshot = await categories.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final items = <Map<String, dynamic>>[
      {
        'id': 'cat_food',
        'name': 'Nourriture',
        'iconKey': 'basket',
        'colorHex': '0xFFD4AF37',
      },
      {
        'id': 'cat_rent',
        'name': 'Loyer',
        'iconKey': 'home',
        'colorHex': '0xFF0B1F3A',
      },
      {
        'id': 'cat_transport',
        'name': 'Transport',
        'iconKey': 'car',
        'colorHex': '0xFF1E3A8A',
      },
      {
        'id': 'cat_school',
        'name': 'École / Études',
        'iconKey': 'school',
        'colorHex': '0xFF1E3A8A',
      },
      {
        'id': 'cat_health',
        'name': 'Santé',
        'iconKey': 'health',
        'colorHex': '0xFF94A3B8',
      },
      {
        'id': 'cat_bills',
        'name': 'Factures',
        'iconKey': 'bolt',
        'colorHex': '0xFF1E3A8A',
      },
      {
        'id': 'cat_eid',
        'name': 'Aïd / Mouton',
        'iconKey': 'gift',
        'colorHex': '0xFFD4AF37',
      },
      {
        'id': 'cat_ramadan',
        'name': 'Ramadan',
        'iconKey': 'ramadan',
        'colorHex': '0xFF0B1F3A',
      },
      {
        'id': 'cat_travel',
        'name': 'Vacances / Voyages',
        'iconKey': 'plane',
        'colorHex': '0xFFD4AF37',
      },
      {
        'id': 'cat_unexpected',
        'name': 'Imprévus',
        'iconKey': 'warning',
        'colorHex': '0xFF94A3B8',
      },
      {
        'id': 'cat_saving',
        'name': 'Épargne',
        'iconKey': 'safe',
        'colorHex': '0xFF1E3A8A',
      },
      // ── Alimentation complémentaires ──────────────────
      {
        'id': 'cat_market',
        'name': 'Marché / Épicerie',
        'iconKey': 'market',
        'colorHex': '0xFFD97706',
      },
      {
        'id': 'cat_restaurant',
        'name': 'Restaurant / Café',
        'iconKey': 'restaurant',
        'colorHex': '0xFFEA580C',
      },
      // ── Transport complémentaires ─────────────────────
      {
        'id': 'cat_bus',
        'name': 'Bus / Tram',
        'iconKey': 'bus',
        'colorHex': '0xFF2563EB',
      },
      {
        'id': 'cat_fuel',
        'name': 'Essence / Carburant',
        'iconKey': 'fuel',
        'colorHex': '0xFF7C3AED',
      },
      {
        'id': 'cat_auto_maintenance',
        'name': 'Entretien voiture',
        'iconKey': 'wrench',
        'colorHex': '0xFF6B7280',
      },
      {
        'id': 'cat_auto_insurance',
        'name': 'Assurance voiture',
        'iconKey': 'insurance',
        'colorHex': '0xFF0B1F3A',
      },
      // ── Factures complémentaires ──────────────────────
      {
        'id': 'cat_internet',
        'name': 'Internet / WiFi',
        'iconKey': 'wifi',
        'colorHex': '0xFF0284C7',
      },
      {
        'id': 'cat_phone',
        'name': 'Téléphone / Mobile',
        'iconKey': 'phone',
        'colorHex': '0xFF0369A1',
      },
      // ── Sport & Beauté ────────────────────────────────
      {
        'id': 'cat_sport',
        'name': 'Sport / Gym',
        'iconKey': 'sport',
        'colorHex': '0xFF059669',
      },
      {
        'id': 'cat_beauty',
        'name': 'Beauté / Hammam',
        'iconKey': 'beauty',
        'colorHex': '0xFFDB2777',
      },
      // ── Loisirs ───────────────────────────────────────
      {
        'id': 'cat_fun',
        'name': 'Loisirs / Sorties',
        'iconKey': 'fun',
        'colorHex': '0xFFF59E0B',
      },
      // ── Famille ───────────────────────────────────────
      {
        'id': 'cat_children',
        'name': 'Enfants',
        'iconKey': 'children',
        'colorHex': '0xFF06B6D4',
      },
      {
        'id': 'cat_family',
        'name': 'Famille',
        'iconKey': 'family',
        'colorHex': '0xFF8B5CF6',
      },
    ];

    final batch = firestore.batch();

    for (final item in items) {
      final id = item['id'] as String;
      batch.set(categories.doc(id), item);
    }

    await batch.commit();
  }
}