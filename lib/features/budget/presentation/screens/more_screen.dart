import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_screen.dart';
import 'notifications_screen.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../core/pdf/pdf_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../providers/budget_providers.dart';
import 'fixed_expenses_screen.dart';

const Color sandoktiGreen = Color(0xFF0B3A2A);

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final user = authAsync.asData?.value;

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
                iconBg: const Color(0xFFEAF4EF),
                iconColor: sandoktiGreen,
                title: 'Exporter rapport PDF',
                subtitle: 'Télécharger le rapport du mois',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: sandoktiGreen,
                ),
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
                iconBg: const Color(0xFFEAF4EF),
                iconColor: sandoktiGreen,
                title: 'Mode sombre',
                subtitle: "Changer le thème de l'application",
                trailing: Switch(
                  value: isDark,
                  activeColor: sandoktiGreen,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).state =
                        value ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ),
              const _DividerLine(),
              _ActionTile(
                icon: Icons.account_balance_wallet_outlined,
                iconBg: const Color(0xFFEAF4EF),
                iconColor: sandoktiGreen,
                title: 'Charges fixes',
                subtitle: 'Ajouter, modifier ou supprimer',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: sandoktiGreen,
                ),
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
}

class _ProfileHeroCard extends StatefulWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.onTap,
  });

  final UserModel? user;
  final VoidCallback onTap;

  @override
  State<_ProfileHeroCard> createState() => _ProfileHeroCardState();
}

class _ProfileHeroCardState extends State<_ProfileHeroCard> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  static const String _profileImageKey = 'profile_image_path';

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_profileImageKey);

    if (path == null || path.isEmpty) return;

    final file = File(path);

    if (await file.exists()) {
      setState(() {
        _profileImage = file;
      });
    }
  }

  Future<void> _saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, path);
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () async {
                  Navigator.pop(context);

                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );

                  if (picked == null) return;

                  await _saveImagePath(picked.path);

                  setState(() {
                    _profileImage = File(picked.path);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Choisir depuis la galerie'),
                onTap: () async {
                  Navigator.pop(context);

                  final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );

                  if (picked == null) return;

                  await _saveImagePath(picked.path);

                  setState(() {
                    _profileImage = File(picked.path);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.user?.fullName.trim().isNotEmpty == true
        ? widget.user!.fullName.trim()
        : 'Utilisateur';

    final email = widget.user?.email ?? 'Aucun email';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/patterns/zellige.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF051C0F).withOpacity(0.86),
                    const Color(0xFF0B3A1E).withOpacity(0.80),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
            child: Column(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.10),
                          border: Border.all(
                            color: sandoktiGreen,
                            width: 2.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: sandoktiGreen.withOpacity(0.35),
                              blurRadius: 22,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _profileImage == null
                              ? Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                )
                              : Image.file(
                                  _profileImage!,
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: sandoktiGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        sandoktiGreen.withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileActionButton(
                        icon: Icons.person_outline_rounded,
                        label: 'Profil',
                        onTap: widget.onTap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProfileActionButton(
                        icon: Icons.notifications_none_rounded,
                        label: 'Rappels',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: sandoktiGreen.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
            width: 1.1,
          ),
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
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: sandoktiGreen.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: sandoktiGreen.withOpacity(0.05),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sandoktiGreen.withOpacity(0.25),
          ),
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
        color: sandoktiGreen.withOpacity(0.14),
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
        color: sandoktiGreen,
      ),
    );
  }
}