import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service centralisé pour toutes les notifications locales de Sandokti.
///
/// Types de notifications gérés :
///  1. Rappel quotidien (saisie de dépenses)          → ID 1
///  2. Alerte dépassement de budget par catégorie      → ID 100+
///  3. Notification fin de mois (résumé budget)        → ID 2
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── IDs fixes ───────────────────────────────────────────────────────────
  static const int _dailyReminderId = 1;
  static const int _monthSummaryId = 2;
  static const int _budgetAlertBaseId = 100;

  // ─── Canaux Android ──────────────────────────────────────────────────────
  static const _channelReminder = AndroidNotificationChannel(
    'sandokti_reminder',
    'Rappels quotidiens',
    description: 'Rappel pour saisir tes dépenses du jour',
    importance: Importance.high,
  );

  static const _channelAlert = AndroidNotificationChannel(
    'sandokti_budget_alert',
    'Alertes budget',
    description: 'Alertes quand tu dépasses un seuil de budget',
    importance: Importance.max,
  );

  static const _channelSummary = AndroidNotificationChannel(
    'sandokti_summary',
    'Résumé mensuel',
    description: 'Résumé de ton budget en fin de mois',
    importance: Importance.defaultImportance,
  );

  // ─── Initialisation ──────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // Timezones
    tz.initializeTimeZones();
    final timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    // Crée les canaux Android
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_channelReminder);
      await androidPlugin.createNotificationChannel(_channelAlert);
      await androidPlugin.createNotificationChannel(_channelSummary);
    }

    _initialized = true;
  }

  // ─── Permissions ─────────────────────────────────────────────────────────

  /// Demande les permissions de notification. Retourne true si accordées.
  Future<bool> requestPermissions() async {
    await initialize();

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  // ─── Rappel quotidien ────────────────────────────────────────────────────

  /// Programme (ou reprogramme) le rappel quotidien à [hhmm] (ex: "21:00").
  Future<void> scheduleDaily(String hhmm) async {
    await initialize();
    await _plugin.cancel(_dailyReminderId);

    final parts = hhmm.split(':');
    final hour = int.tryParse(parts[0]) ?? 21;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si l'heure est déjà passée aujourd'hui → programmer pour demain
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      '🔔 Sandokti - Bilan du jour',
      "As-tu pensé à noter tes dépenses aujourd'hui ? 💸",
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelReminder.id,
          _channelReminder.name,
          channelDescription: _channelReminder.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Annule le rappel quotidien.
  Future<void> cancelDaily() async {
    await initialize();
    await _plugin.cancel(_dailyReminderId);
  }

  // ─── Alertes budget ──────────────────────────────────────────────────────

  /// Envoie une notification immédiate quand une catégorie dépasse son budget.
  ///
  /// [categoryLabel] : ex "Nourriture"
  /// [ratio]         : ex 1.15 → 115%
  /// [severity]      : 'warning' (80-99%) ou 'danger' (≥100%)
  Future<void> sendBudgetAlert({
    required String categoryId,
    required String categoryLabel,
    required double ratio,
    required String severity,
  }) async {
    await initialize();

    final percent = (ratio * 100).round();
    final isDanger = severity == 'danger';

    final title = isDanger
        ? '🚨 Budget dépassé — $categoryLabel'
        : '⚠️ Budget presque atteint — $categoryLabel';

    final body = isDanger
        ? 'Tu as dépensé $percent% de ton budget $categoryLabel ce mois-ci.'
        : 'Tu as dépensé $percent% de ton budget $categoryLabel. Attention !';

    // ID unique par catégorie pour pouvoir les annuler individuellement
    final notifId = _budgetAlertBaseId + categoryId.hashCode.abs() % 900;

    await _plugin.show(
      notifId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelAlert.id,
          _channelAlert.name,
          channelDescription: _channelAlert.description,
          importance: isDanger ? Importance.max : Importance.high,
          priority: isDanger ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
          color: isDanger
              ? const Color(0xFFDC2626) // rouge
              : const Color(0xFFD97706), // orange
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Annule toutes les alertes budget.
  Future<void> cancelAllBudgetAlerts() async {
    await initialize();
    // Annule par plage d'IDs (100 → 999)
    for (int i = _budgetAlertBaseId; i < 1000; i++) {
      await _plugin.cancel(i);
    }
  }

  // ─── Résumé mensuel ──────────────────────────────────────────────────────

  /// Programme la notification de résumé mensuel (dernier jour du mois à 18h).
  Future<void> scheduleMonthSummary() async {
    await initialize();
    await _plugin.cancel(_monthSummaryId);

    final now = tz.TZDateTime.now(tz.local);
    // Dernier jour du mois courant
    final lastDay = DateTime(now.year, now.month + 1, 0);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      lastDay.year,
      lastDay.month,
      lastDay.day,
      18,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      // Passer au mois suivant
      final nextLastDay = DateTime(now.year, now.month + 2, 0);
      scheduledDate = tz.TZDateTime(
        tz.local,
        nextLastDay.year,
        nextLastDay.month,
        nextLastDay.day,
        18,
        0,
      );
    }

    await _plugin.zonedSchedule(
      _monthSummaryId,
      '📊 Bilan du mois — Sandokti',
      'Le mois se termine. Consulte ton résumé budgétaire.',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelSummary.id,
          _channelSummary.name,
          channelDescription: _channelSummary.description,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Annule le résumé mensuel.
  Future<void> cancelMonthSummary() async {
    await initialize();
    await _plugin.cancel(_monthSummaryId);
  }

  // ─── Notification de test ────────────────────────────────────────────────

  /// Envoie une notification immédiate pour tester que tout fonctionne.
  Future<void> sendTestNotification() async {
    await initialize();
    await _plugin.show(
      999,
      '🔔 Sandokti - Bilan du jour',
      "As-tu pensé à noter tes dépenses aujourd'hui ? 💸",
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelReminder.id,
          _channelReminder.name,
          channelDescription: _channelReminder.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ─── Utilitaires ─────────────────────────────────────────────────────────

  /// Annule toutes les notifications planifiées.
  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }
}