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
    // merge:true → mise à jour automatique si catégorie déjà existante
    final items = <Map<String, dynamic>>[
      // ── 🛒 Alimentation ─────────────────────────────────
      {
        'id': 'cat_food',
        'name': 'Courses / Épicerie',
        'iconKey': 'basket',
        'colorHex': '0xFFD97706',
        'description': 'BIM, Marjane, Carrefour, épicier du quartier',
      },
      {
        'id': 'cat_market',
        'name': 'Marché (souk)',
        'iconKey': 'market',
        'colorHex': '0xFFEA580C',
        'description': 'Légumes, fruits, viande au souk',
      },
      {
        'id': 'cat_restaurant',
        'name': 'Restaurant / Café',
        'iconKey': 'restaurant',
        'colorHex': '0xFFB45309',
        'description': 'Cafés, fast-food, restaurants, snacks',
      },
      // ── 🏠 Logement ──────────────────────────────────────
      {
        'id': 'cat_rent',
        'name': 'Loyer',
        'iconKey': 'home',
        'colorHex': '0xFF0B1F3A',
        'description': 'Loyer mensuel ou mensualité crédit immobilier',
      },
      // ── ⚡ Factures & Services ────────────────────────────
      {
        'id': 'cat_bills',
        'name': 'Eau & Électricité',
        'iconKey': 'bolt',
        'colorHex': '0xFF1D4ED8',
        'description': 'Lydec, Amendis, RADEEF, ONEE',
      },
      {
        'id': 'cat_internet',
        'name': 'Internet / WiFi',
        'iconKey': 'wifi',
        'colorHex': '0xFF0284C7',
        'description': 'Maroc Telecom, Inwi, Orange box',
      },
      {
        'id': 'cat_phone',
        'name': 'Téléphone / Recharge',
        'iconKey': 'phone',
        'colorHex': '0xFF0369A1',
        'description': 'Forfait ou recharge IAM, Inwi, Orange',
      },
      // ── 🚗 Transport ─────────────────────────────────────
      {
        'id': 'cat_transport',
        'name': 'Taxi / Transport urbain',
        'iconKey': 'car',
        'colorHex': '0xFF7C3AED',
        'description': 'Petit taxi, grand taxi, InDrive, Careem, tram',
      },
      {
        'id': 'cat_bus',
        'name': 'Bus / CTM',
        'iconKey': 'bus',
        'colorHex': '0xFF2563EB',
        'description': 'CTM, bus urbain, tramway, ONCF',
      },
      {
        'id': 'cat_fuel',
        'name': 'Essence / Carburant',
        'iconKey': 'fuel',
        'colorHex': '0xFF6D28D9',
        'description': 'Station essence, diesel, gasoil',
      },
      {
        'id': 'cat_auto_maintenance',
        'name': 'Entretien véhicule',
        'iconKey': 'wrench',
        'colorHex': '0xFF374151',
        'description': 'Vidange, réparation, pneus, vignette',
      },
      {
        'id': 'cat_auto_insurance',
        'name': 'Assurance voiture',
        'iconKey': 'insurance',
        'colorHex': '0xFF1F2937',
        'description': 'Police assurance auto annuelle ou mensuelle',
      },
      // ── 🏥 Santé ─────────────────────────────────────────
      {
        'id': 'cat_health',
        'name': 'Santé / Pharmacie',
        'iconKey': 'health',
        'colorHex': '0xFFDC2626',
        'description': 'Médecin, clinique, pharmacie, analyses',
      },
      // ── 🎓 Éducation ─────────────────────────────────────
      {
        'id': 'cat_school',
        'name': 'École / Études',
        'iconKey': 'school',
        'colorHex': '0xFF1E3A8A',
        'description': 'Frais scolarité, fournitures, cours particuliers',
      },
      // ── 💪 Sport & Bien-être ──────────────────────────────
      {
        'id': 'cat_sport',
        'name': 'Sport / Gym',
        'iconKey': 'sport',
        'colorHex': '0xFF059669',
        'description': 'Salle de sport, piscine, abonnement fitness',
      },
      {
        'id': 'cat_beauty',
        'name': 'Beauté / Hammam',
        'iconKey': 'beauty',
        'colorHex': '0xFFDB2777',
        'description': 'Coiffeur, hammam, soins, parfumerie',
      },
      // ── 🎉 Loisirs ───────────────────────────────────────
      {
        'id': 'cat_fun',
        'name': 'Loisirs / Sorties',
        'iconKey': 'fun',
        'colorHex': '0xFFF59E0B',
        'description': 'Cinéma, concerts, streaming, sorties',
      },
      // ── 👨‍👩‍👧 Famille ──────────────────────────────────────
      {
        'id': 'cat_children',
        'name': 'Enfants',
        'iconKey': 'children',
        'colorHex': '0xFF06B6D4',
        'description': 'Crèche, vêtements enfants, jouets, couches',
      },
      {
        'id': 'cat_family',
        'name': 'Famille & Solidarité',
        'iconKey': 'family',
        'colorHex': '0xFF8B5CF6',
        'description': 'Cadeaux famille, aide parents, invités',
      },
      // ── 🌙 Occasions marocaines ───────────────────────────
      {
        'id': 'cat_ramadan',
        'name': 'Ramadan',
        'iconKey': 'ramadan',
        'colorHex': '0xFF0B1F3A',
        'description': 'Ftour, s9our, zakat, cadeaux ramadan',
      },
      {
        'id': 'cat_eid',
        'name': 'Aïd / Mouton',
        'iconKey': 'gift',
        'colorHex': '0xFFD4AF37',
        'description': 'Mouton, vêtements Aïd, cadeaux',
      },
      // ── ✈️ Voyages ───────────────────────────────────────
      {
        'id': 'cat_travel',
        'name': 'Voyages / Vacances',
        'iconKey': 'plane',
        'colorHex': '0xFF0EA5E9',
        'description': 'Billets, hôtel, location, voyage intérieur/étranger',
      },
      // ── ⚠️ Imprévus ───────────────────────────────────────
      {
        'id': 'cat_unexpected',
        'name': 'Imprévus',
        'iconKey': 'warning',
        'colorHex': '0xFF94A3B8',
        'description': 'Réparations urgentes, dépenses non prévues',
      },
      // ── 💰 Épargne / Daret ─────────────────────────────────
      {
        'id': 'cat_saving',
        'name': 'Épargne / Daret',
        'iconKey': 'safe',
        'colorHex': '0xFF006747',
        'description': 'Épargne mensuelle, tontine (daret), livret',
      },
    ];

    final batch = firestore.batch();
    for (final item in items) {
      final id = item['id'] as String;
      // merge:true → mise à jour si déjà existant, création sinon
      batch.set(categories.doc(id), item, SetOptions(merge: true));
    }
    await batch.commit();
  }
}