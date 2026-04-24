class BudgetAdviceEngine {
  static String buildAdvice({
    required List<String> warningCategories,
    required bool forecastWillOverrun,
    required bool hasDangerAlert,
  }) {
    if (forecastWillOverrun) {
      return "Ton budget demande un léger ajustement. Réduis quelques dépenses secondaires pour rester à l'équilibre jusqu'à la fin du mois.";
    }

    if (hasDangerAlert && warningCategories.isNotEmpty) {
      return '${warningCategories.first} dépasse nettement le niveau conseillé. Une petite réduction sur ce poste améliorera ton équilibre ce mois.';
    }

    if (warningCategories.isNotEmpty) {
      return '${warningCategories.first} prend une place importante dans ton budget actuel. Surveille cette catégorie pour garder une bonne maîtrise.';
    }

    return 'Ton budget reste bien équilibré ce mois. Continue sur ce rythme.';
  }
}