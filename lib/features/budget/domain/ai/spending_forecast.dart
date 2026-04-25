/// Modèle de prévision de dépenses de fin de mois.
class SpendingForecast {
  final int predictedExpenseCents;
  final int predictedOverrunCents;
  final bool willOverrun;

  const SpendingForecast({
    required this.predictedExpenseCents,
    required this.predictedOverrunCents,
    required this.willOverrun,
  });
}

/// Moteur de prévision linéaire — messages en contexte marocain (DH).
class SpendingForecastEngine {
  /// Nombre minimum de jours avant d'activer la prévision
  static const int _minDaysBeforeForecast = 7;

  static SpendingForecast forecast({
    required int currentExpenseCents,
    required int availableBudgetCents,
    required int currentDay,
    required int totalDaysInMonth,
  }) {
    if (currentDay < _minDaysBeforeForecast ||
        totalDaysInMonth <= 0 ||
        currentExpenseCents <= 0) {
      return const SpendingForecast(
        predictedExpenseCents: 0,
        predictedOverrunCents: 0,
        willOverrun: false,
      );
    }

    final predicted =
        ((currentExpenseCents / currentDay) * totalDaysInMonth).round();

    final overrun =
        predicted > availableBudgetCents ? predicted - availableBudgetCents : 0;

    return SpendingForecast(
      predictedExpenseCents: predicted,
      predictedOverrunCents: overrun,
      willOverrun: overrun > 0,
    );
  }

  static String buildMessage(SpendingForecast forecast) {
    final predictedDh = (forecast.predictedExpenseCents / 100).round();
    final overrunDh = (forecast.predictedOverrunCents / 100).round();

    if (forecast.willOverrun) {
      return 'Au rythme actuel, tu risques de dépasser ton budget de $overrunDh DH avant la fin du mois. Surveille tes dépenses.';
    }

    if (predictedDh == 0) {
      return 'Pas encore assez de données pour une prévision fiable (saisie au moins 7 jours).';
    }

    return 'Prévision fin de mois : environ $predictedDh DH de dépenses. Tu es dans les limites de ton budget, continue !';
  }
}
