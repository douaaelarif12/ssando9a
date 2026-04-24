import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_screen.dart';
import '../../../../app/theme/sandokti_colors.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../core/pdf/pdf_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../providers/budget_providers.dart';
import 'fixed_expenses_screen.dart';

final reminderSettingsProvider =
FutureProvider.autoDispose<ReminderSettings>((ref) async {
  final ds = ref.read(budgetDsProvider);
  final enabled = await ds.getExpenseReminderEnabled();
  final time = await ds.getExpenseReminderTime();
  return ReminderSettings(enabled: enabled, time: time);
});

class ReminderSettings {
  final bool enabled;
  final String time;

  const ReminderSettings({
    required this.enabled,
    required this.time,
  });
}

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final user = authAsync.asData?.value;
    final reminderAsync = ref.watch(reminderSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plus'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _ProfileHeroCard(
            user: user,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          const _SectionTitle('Préférences'),
          const SizedBox(height: 10),
          _MenuCard(
            children: [
              _ActionTile(
                icon: Icons.picture_as_pdf_rounded,
                iconBg: const Color(0xFFFFF1F2),
                iconColor: const Color(0xFFE11D48),
                title: 'Exporter rapport PDF',
                subtitle: 'Télécharger le rapport du mois',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  try {
                    final ds = ref.read(budgetDsProvider);
                    await PdfService.generateMonthlyReport(ds: ds);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur PDF : $e')),
                    );
                  }
                },
              ),
              const _DividerLine(),
              _ActionTile(
                icon: Icons.dark_mode_rounded,
                iconBg: const Color(0xFFF3F4F6),
                iconColor: const Color(0xFF111827),
                title: 'Mode sombre',
                subtitle: "Changer le thème de l'application",
                trailing: Switch(
                  value: isDark,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).state =
                    value ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ),
              const _DividerLine(),
              _ActionTile(
                icon: Icons.account_balance_wallet_outlined,
                iconBg: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4F46E5),
                title: 'Charges fixes',
                subtitle: 'Ajouter, modifier ou supprimer',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FixedExpensesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          const _SectionTitle('Rappels'),
          const SizedBox(height: 10),
          reminderAsync.when(
            loading: () => const _LoadingCard(),
            error: (e, _) => _MenuCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erreur: $e'),
                ),
              ],
            ),
            data: (reminder) => _MenuCard(
              children: [
                _ActionTile(
                  icon: Icons.notifications_active_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: SandoktiColors.emerald,
                  title: 'Rappel quotidien',
                  subtitle: reminder.enabled
                      ? 'Actif à ${reminder.time}'
                      : 'Inactif pour le moment',
                  trailing: Switch(
                    value: reminder.enabled,
                    onChanged: (value) async {
                      final ds = ref.read(budgetDsProvider);
                      await ds.setExpenseReminderEnabled(value);
                      ref.invalidate(reminderSettingsProvider);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Rappel activé'
                                : 'Rappel désactivé',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const _DividerLine(),
                _ActionTile(
                  icon: Icons.schedule_rounded,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFEA580C),
                  title: 'Heure du rappel',
                  subtitle: 'Chaque jour à ${reminder.time}',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _parseTime(reminder.time),
                    );

                    if (picked == null) return;

                    final hh = picked.hour.toString().padLeft(2, '0');
                    final mm = picked.minute.toString().padLeft(2, '0');
                    final value = '$hh:$mm';

                    final ds = ref.read(budgetDsProvider);
                    await ds.setExpenseReminderTime(value);
                    ref.invalidate(reminderSettingsProvider);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Heure du rappel : $value'),
                      ),
                    );
                  },
                ),
                const _DividerLine(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text(
                    "Sandokti te rappelle d'ajouter tes dépenses et tes primes pour garder un budget à jour.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Center(
            child: Column(
              children: [
                Text(
                  'Sandokti',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return const TimeOfDay(hour: 21, minute: 0);
    }

    final hour = int.tryParse(parts[0]) ?? 21;
    final minute = int.tryParse(parts[1]) ?? 0;

    return TimeOfDay(hour: hour, minute: minute);
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.onTap,
  });

  final UserModel? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fullName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : 'Utilisateur';
    final email = user?.email ?? 'Aucun email';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B7A43),
              Color(0xFF0F9F58),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: SandoktiColors.emerald.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.18),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.88),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _ProfileActionButton(
                    icon: Icons.person_outline_rounded,
                    label: 'Profil',
                    onTap: onTap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProfileActionButton(
                    icon: Icons.notifications_none_rounded,
                    label: 'Rappels',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
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
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
        subtitle!,
        style: const TextStyle(fontSize: 12.5),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(
        height: 1,
        color: Colors.black.withOpacity(0.06),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _MenuCard(
      children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}