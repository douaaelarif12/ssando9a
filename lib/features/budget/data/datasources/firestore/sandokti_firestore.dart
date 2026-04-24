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
    ];

    final batch = firestore.batch();

    for (final item in items) {
      final id = item['id'] as String;
      batch.set(categories.doc(id), item);
    }

    await batch.commit();
  }
}