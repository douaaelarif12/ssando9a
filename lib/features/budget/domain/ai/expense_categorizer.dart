class ExpenseCategorizer {
  static const Map<String, String> _keywordToCategory = {
    'bim': 'cat_food',
    'marjane': 'cat_food',
    'carrefour': 'cat_food',
    'atakadao': 'cat_food',
    'labelvie': 'cat_food',
    'acima': 'cat_food',
    'epicerie': 'cat_food',
    'supermarche': 'cat_food',
    'restaurant': 'cat_food',
    'snack': 'cat_food',

    'taxi': 'cat_transport',
    'petit taxi': 'cat_transport',
    'grand taxi': 'cat_transport',
    'indrive': 'cat_transport',
    'careem': 'cat_transport',
    'bus': 'cat_transport',
    'tram': 'cat_transport',
    'essence': 'cat_transport',
     'train': 'cat_transport',
     
    'lydec': 'cat_bills',
    'amendis': 'cat_bills',
    'eau': 'cat_bills',
    'electricite': 'cat_bills',
    'internet': 'cat_bills',
    'wifi': 'cat_bills',
    'orange': 'cat_bills',
    'inwi': 'cat_bills',
    'iam': 'cat_bills',

    'pharmacie': 'cat_health',
    'medecin': 'cat_health',
    'clinique': 'cat_health',
    'analyse': 'cat_health',

    'sport': 'cat_sport',
    'gym': 'cat_sport',
    'pilates': 'cat_sport',
    'fitness': 'cat_sport',

    'cinema': 'cat_fun',
    'netflix': 'cat_fun',
    'fete': 'cat_fun',
    'sortie': 'cat_fun',

    'ecole': 'cat_children',
    'creche': 'cat_children',
    'fourniture': 'cat_children',

    'reparation': 'cat_unexpected',
    'urgence': 'cat_unexpected',
    'imprevu': 'cat_unexpected',
  };

  static String? detectCategoryId(String text) {
    final input = _normalize(text);

    if (input.isEmpty) return null;

    // 1) match direct
    for (final entry in _keywordToCategory.entries) {
      final keyword = _normalize(entry.key);
      if (input.contains(keyword)) {
        return entry.value;
      }
    }

    // 2) match approximatif mot par mot
    final words = input.split(RegExp(r'\s+'));

    for (final word in words) {
      if (word.length < 3) continue;

      for (final entry in _keywordToCategory.entries) {
        final keyword = _normalize(entry.key);

        // on ignore les expressions longues ici
        if (keyword.contains(' ')) continue;

        if (_isCloseMatch(word, keyword)) {
          return entry.value;
        }
      }
    }

    return null;
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _isCloseMatch(String inputWord, String keyword) {
    if (inputWord == keyword) return true;

    // contient partiellement
    if (keyword.contains(inputWord) || inputWord.contains(keyword)) {
      return true;
    }

    // distance max tolérée
    final distance = _levenshtein(inputWord, keyword);

    if (keyword.length <= 4) {
      return distance <= 1;
    } else if (keyword.length <= 7) {
      return distance <= 2;
    } else {
      return distance <= 3;
    }
  }

  static int _levenshtein(String s, String t) {
    final m = s.length;
    final n = t.length;

    if (m == 0) return n;
    if (n == 0) return m;

    final List<List<int>> dp =
        List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 0; i <= m; i++) {
      dp[i][0] = i;
    }

    for (int j = 0; j <= n; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;

        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[m][n];
  }
}