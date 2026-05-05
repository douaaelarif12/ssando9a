import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/sandokti_colors.dart';
import '../../../../core/firebase/user_settings_service.dart';
import '../providers/notification_provider.dart';

final reminderSettingsProvider =
    FutureProvider.autoDispose<ReminderSettings>((ref) async {
  final service = UserSettingsService.instance;
  final enabled = await service.getReminderEnabled();
  final time = await service.getReminderTime();
  return ReminderSettings(enabled: enabled, time: time);
});

class ReminderSettings {
  final bool enabled;
  final String time;
  const ReminderSettings({required this.enabled, required this.time});
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isRequestingPermission = false;

  @override
  Widget build(BuildContext context) {
    final reminderAsync = ref.watch(reminderSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: reminderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (reminder) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── Header ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: SandoktiColors.emerald.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: SandoktiColors.emerald.withOpacity(0.18),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: SandoktiColors.emerald.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: SandoktiColors.emerald,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rappels & Alertes',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Gère tes notifications Sandokti',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),
            const _SectionLabel('Rappel quotidien'),
            const SizedBox(height: 10),

            // ── Card rappel ──────────────────────────────────────────
            _NotifCard(
              children: [
                _NotifTile(
                  icon: Icons.notifications_active_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: SandoktiColors.emerald,
                  title: 'Rappel quotidien',
                  subtitle: reminder.enabled
                      ? 'Actif à ${reminder.time}'
                      : 'Inactif pour le moment',
                  trailing: Switch(
                    value: reminder.enabled,
                    activeColor: SandoktiColors.emerald,
                    onChanged: (value) async {
                      if (_isRequestingPermission) return;
                      setState(() => _isRequestingPermission = true);
                      final service = UserSettingsService.instance;
                      final notif = ref.read(notificationServiceProvider);
                      try {
                        if (value) {
                          final granted = await notif.requestPermissions();
                          if (!granted) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Permission refusée. Active-la dans les paramètres.',
                                ),
                              ),
                            );
                            return;
                          }
                          final time = await service.getReminderTime();
                          await notif.scheduleDaily(time);
                        } else {
                          await notif.cancelDaily();
                        }
                        await service.setReminderEnabled(value);
                        ref.invalidate(reminderSettingsProvider);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value ? 'Rappel activé ✓' : 'Rappel désactivé',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur : $e')),
                        );
                      } finally {
                        if (mounted) setState(() => _isRequestingPermission = false);
                      }
                    },
                  ),
                ),
                const _DivLine(),
                _NotifTile(
                  icon: Icons.schedule_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: SandoktiColors.emerald,
                  title: 'Heure du rappel',
                  subtitle: 'Chaque jour à ${reminder.time}',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final parts = reminder.time.split(':');
                    final h = int.tryParse(parts[0]) ?? 21;
                    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: h, minute: m),
                    );
                    if (picked == null) return;
                    final hh = picked.hour.toString().padLeft(2, '0');
                    final mm = picked.minute.toString().padLeft(2, '0');
                    final value = '$hh:$mm';
                    final service = UserSettingsService.instance;
                    final notif = ref.read(notificationServiceProvider);
                    await service.setReminderTime(value);
                    final enabled = await service.getReminderEnabled();
                    if (enabled) await notif.scheduleDaily(value);
                    ref.invalidate(reminderSettingsProvider);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Rappel programmé à $value ✓')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 22),
            const _SectionLabel('Alertes budget'),
            const SizedBox(height: 10),

            // ── Card alertes budget (informatif) ─────────────────────
            _NotifCard(
              children: [
                _NotifTile(
                  icon: Icons.warning_amber_rounded,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Budget presque dépassé',
                  subtitle: 'Alerte quand une catégorie atteint 80%',
                ),
                const _DivLine(),
                _NotifTile(
                  icon: Icons.error_outline_rounded,
                  iconBg: const Color(0xFFFFF1F2),
                  iconColor: const Color(0xFFE11D48),
                  title: 'Budget dépassé',
                  subtitle: 'Alerte quand une catégorie dépasse la limite',
                ),
              ],
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                "Sandokti te rappelle d'ajouter tes dépenses et tes primes pour garder un budget à jour.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.42),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12.5)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _DivLine extends StatelessWidget {
  const _DivLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, color: Colors.black.withOpacity(0.06)),
    );
  }
}