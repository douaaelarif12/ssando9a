/// Catégoriseur automatique de dépenses — contexte 100% marocain.
/// Supporte le français, la darija translittérée et les noms de marques locales.
class ExpenseCategorizer {
  static const Map<String, String> _keywordToCategory = {
    // ── Courses / Épicerie (cat_food) ─────────────────────────────────
    'bim': 'cat_food',
    'marjane': 'cat_food',
    'carrefour': 'cat_food',
    'atakadao': 'cat_food',
    'labelvie': 'cat_food',
    'acima': 'cat_food',
    'metro': 'cat_food',
    'aswak': 'cat_food',
    'epicerie': 'cat_food',
    'hanout': 'cat_food',
    'hanut': 'cat_food',
    'supermarche': 'cat_food',
    'superette': 'cat_food',
    'courses': 'cat_food',
    'provisions': 'cat_food',
    'alimentation': 'cat_food',
    'lait': 'cat_food',
    'pain': 'cat_food',
    'khobz': 'cat_food',
    'sucre': 'cat_food',
    'huile': 'cat_food',
    'farine': 'cat_food',
    'viande': 'cat_food',
    'lahm': 'cat_food',
    'poulet': 'cat_food',
    'djaj': 'cat_food',
    'poisson': 'cat_food',
    'legumes': 'cat_food',
    'fruits': 'cat_food',

    // ── Marché / Souk (cat_market) ────────────────────────────────────
    'souk': 'cat_market',
    'derb': 'cat_market',
    'marche': 'cat_market',
    'joutia': 'cat_market',

    // ── Restaurant / Café (cat_restaurant) ───────────────────────────
    'restaurant': 'cat_restaurant',
    'cafe': 'cat_restaurant',
    'snack': 'cat_restaurant',
    'sandwicherie': 'cat_restaurant',
    'pizza': 'cat_restaurant',
    'burger': 'cat_restaurant',
    'mcdo': 'cat_restaurant',
    'mcdonald': 'cat_restaurant',
    'kfc': 'cat_restaurant',
    'subway': 'cat_restaurant',
    'domino': 'cat_restaurant',
    'pizzeria': 'cat_restaurant',
    'grillade': 'cat_restaurant',
    'rotisserie': 'cat_restaurant',
    'patisserie': 'cat_restaurant',
    'glace': 'cat_restaurant',
    'jus': 'cat_restaurant',
    'dejeuner': 'cat_restaurant',
    'diner': 'cat_restaurant',
    'ftour': 'cat_restaurant',

    // ── Loyer (cat_rent) ──────────────────────────────────────────────
    'loyer': 'cat_rent',
    'kira': 'cat_rent',
    'location': 'cat_rent',
    'credit immobilier': 'cat_rent',
    'appartement': 'cat_rent',
    'appart': 'cat_rent',

    // ── Eau & Électricité (cat_bills) ─────────────────────────────────
    'lydec': 'cat_bills',
    'amendis': 'cat_bills',
    'radeef': 'cat_bills',
    'onee': 'cat_bills',
    'eau': 'cat_bills',
    'electricite': 'cat_bills',
    'gaz': 'cat_bills',
    'butane': 'cat_bills',
    'qanboura': 'cat_bills',

    // ── Internet / WiFi (cat_internet) ────────────────────────────────
    'internet': 'cat_internet',
    'wifi': 'cat_internet',
    'fibre': 'cat_internet',
    'adsl': 'cat_internet',

    // ── Téléphone / Recharge (cat_phone) ─────────────────────────────
    'recharge': 'cat_phone',
    'forfait': 'cat_phone',
    'iam': 'cat_phone',
    'inwi': 'cat_phone',
    'orange': 'cat_phone',
    'mobile': 'cat_phone',
    'telephone': 'cat_phone',
    'sim': 'cat_phone',

    // ── Taxi / Transport urbain (cat_transport) ───────────────────────
    'taxi': 'cat_transport',
    'petit taxi': 'cat_transport',
    'grand taxi': 'cat_transport',
    'indrive': 'cat_transport',
    'careem': 'cat_transport',
    'heetch': 'cat_transport',
    'yassir': 'cat_transport',
    'tram': 'cat_transport',
    'tramway': 'cat_transport',
    'transport': 'cat_transport',

    // ── Bus / CTM (cat_bus) ───────────────────────────────────────────
    'bus': 'cat_bus',
    'ctm': 'cat_bus',
    'oncf': 'cat_bus',
    'train': 'cat_bus',
    'supratours': 'cat_bus',
    'autocar': 'cat_bus',

    // ── Essence / Carburant (cat_fuel) ────────────────────────────────
    'essence': 'cat_fuel',
    'gasoil': 'cat_fuel',
    'diesel': 'cat_fuel',
    'carburant': 'cat_fuel',
    'afriquia': 'cat_fuel',
    'ziz': 'cat_fuel',
    'total': 'cat_fuel',
    'shell': 'cat_fuel',
    'winxo': 'cat_fuel',

    // ── Entretien véhicule (cat_auto_maintenance) ─────────────────────
    'vidange': 'cat_auto_maintenance',
    'garage': 'cat_auto_maintenance',
    'mecanicien': 'cat_auto_maintenance',
    'pneu': 'cat_auto_maintenance',
    'vignette': 'cat_auto_maintenance',
    'visite technique': 'cat_auto_maintenance',
    'freins': 'cat_auto_maintenance',

    // ── Assurance voiture (cat_auto_insurance) ────────────────────────
    'assurance': 'cat_auto_insurance',
    'wafa assurance': 'cat_auto_insurance',
    'atlanta': 'cat_auto_insurance',
    'saham': 'cat_auto_insurance',
    'rma': 'cat_auto_insurance',
    'allianz': 'cat_auto_insurance',

    // ── Santé / Pharmacie (cat_health) ────────────────────────────────
    'pharmacie': 'cat_health',
    'medecin': 'cat_health',
    'docteur': 'cat_health',
    'clinique': 'cat_health',
    'hopital': 'cat_health',
    'analyse': 'cat_health',
    'dentiste': 'cat_health',
    'opticien': 'cat_health',
    'medicament': 'cat_health',
    'dawa': 'cat_health',
    'cnops': 'cat_health',
    'ramed': 'cat_health',
    'mutuelle': 'cat_health',

    // ── École / Études (cat_school) ───────────────────────────────────
    'ecole': 'cat_school',
    'lycee': 'cat_school',
    'universite': 'cat_school',
    'faculte': 'cat_school',
    'inscription': 'cat_school',
    'fournitures': 'cat_school',
    'cartable': 'cat_school',
    'cours particulier': 'cat_school',
    'formation': 'cat_school',

    // ── Sport / Gym (cat_sport) ───────────────────────────────────────
    'sport': 'cat_sport',
    'gym': 'cat_sport',
    'fitness': 'cat_sport',
    'piscine': 'cat_sport',
    'pilates': 'cat_sport',
    'yoga': 'cat_sport',
    'foot': 'cat_sport',
    'natation': 'cat_sport',

    // ── Beauté / Hammam (cat_beauty) ──────────────────────────────────
    'hammam': 'cat_beauty',
    'coiffeur': 'cat_beauty',
    'coiffeuse': 'cat_beauty',
    'salon': 'cat_beauty',
    'ongles': 'cat_beauty',
    'epilation': 'cat_beauty',
    'parfum': 'cat_beauty',
    'cosmetique': 'cat_beauty',
    'soin': 'cat_beauty',

    // ── Loisirs / Sorties (cat_fun) ───────────────────────────────────
    'cinema': 'cat_fun',
    'netflix': 'cat_fun',
    'spotify': 'cat_fun',
    'streaming': 'cat_fun',
    'jeu': 'cat_fun',
    'playstation': 'cat_fun',
    'sortie': 'cat_fun',
    'fete': 'cat_fun',
    'anniversaire': 'cat_fun',
    'bowling': 'cat_fun',
    'concert': 'cat_fun',

    // ── Enfants (cat_children) ────────────────────────────────────────
    'creche': 'cat_children',
    'garderie': 'cat_children',
    'couche': 'cat_children',
    'jouet': 'cat_children',
    'pediatre': 'cat_children',
    'vaccin': 'cat_children',
    'poussette': 'cat_children',

    // ── Famille & Solidarité (cat_family) ────────────────────────────
    'cadeau': 'cat_family',
    'famille': 'cat_family',
    'invites': 'cat_family',
    'mariage': 'cat_family',
    'choufa': 'cat_family',
    'ziyara': 'cat_family',
    'hadiya': 'cat_family',

    // ── Ramadan (cat_ramadan) ─────────────────────────────────────────
    'ramadan': 'cat_ramadan',
    'zakat': 'cat_ramadan',
    'sadaqa': 'cat_ramadan',
    's9our': 'cat_ramadan',
    'sohour': 'cat_ramadan',
    'chorba': 'cat_ramadan',
    'harira': 'cat_ramadan',
    'chebakia': 'cat_ramadan',
    'iftar': 'cat_ramadan',

    // ── Aïd / Mouton (cat_eid) ────────────────────────────────────────
    'mouton': 'cat_eid',
    'aid': 'cat_eid',
    'kharuf': 'cat_eid',
    'djellaba': 'cat_eid',
    'caftan': 'cat_eid',

    // ── Voyages (cat_travel) ──────────────────────────────────────────
    'voyage': 'cat_travel',
    'billet': 'cat_travel',
    'hotel': 'cat_travel',
    'riad': 'cat_travel',
    'ryanair': 'cat_travel',
    'air arabia': 'cat_travel',
    'royal air maroc': 'cat_travel',
    'ram': 'cat_travel',
    'excursion': 'cat_travel',
    'vacances': 'cat_travel',

    // ── Imprévus (cat_unexpected) ─────────────────────────────────────
    'reparation': 'cat_unexpected',
    'urgence': 'cat_unexpected',
    'imprevu': 'cat_unexpected',
    'depannage': 'cat_unexpected',
    'panne': 'cat_unexpected',
    'amende': 'cat_unexpected',
    'contravention': 'cat_unexpected',

    // ── Épargne / Daret (cat_saving) ──────────────────────────────────
    'epargne': 'cat_saving',
    'daret': 'cat_saving',
    'tontine': 'cat_saving',
    'economie': 'cat_saving',
    'livret': 'cat_saving',
  };

  static String? detectCategoryId(String text) {
    final input = _normalize(text);
    if (input.isEmpty) return null;

    // 1) Match direct — expressions longues en priorité
    final sortedKeys = _keywordToCategory.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedKeys) {
      if (input.contains(_normalize(key))) {
        return _keywordToCategory[key];
      }
    }

    // 2) Match approximatif mot par mot (Levenshtein)
    final words = input.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.length < 3) continue;
      for (final entry in _keywordToCategory.entries) {
        final keyword = _normalize(entry.key);
        if (keyword.contains(' ')) continue;
        if (_isCloseMatch(word, keyword)) return entry.value;
      }
    }

    return null;
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('à', 'a').replaceAll('â', 'a').replaceAll('ä', 'a')
        .replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ê', 'e').replaceAll('ë', 'e')
        .replaceAll('î', 'i').replaceAll('ï', 'i')
        .replaceAll('ô', 'o').replaceAll('ö', 'o')
        .replaceAll('ù', 'u').replaceAll('û', 'u').replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _isCloseMatch(String inputWord, String keyword) {
    if (inputWord == keyword) return true;
    if (keyword.contains(inputWord) || inputWord.contains(keyword)) return true;
    final distance = _levenshtein(inputWord, keyword);
    if (keyword.length <= 4) return distance <= 1;
    if (keyword.length <= 7) return distance <= 2;
    return distance <= 3;
  }

  static int _levenshtein(String s, String t) {
    final m = s.length;
    final n = t.length;
    if (m == 0) return n;
    if (n == 0) return m;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        dp[i][j] = [dp[i-1][j]+1, dp[i][j-1]+1, dp[i-1][j-1]+cost].reduce((a,b)=>a<b?a:b);
      }
    }
    return dp[m][n];
  }
}
