import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';

/// Provider global pour le NotificationService.
/// Utilisé partout dans l'app pour envoyer/gérer les notifications.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});