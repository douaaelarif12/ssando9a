import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/sandokti_colors.dart';
import '../providers/budget_providers.dart';
import '../../domain/services/budget_assistant_service.dart';
import '../dashboard_controller.dart';

// ─────────────────────────────────────────────
// Langue de l'assistant
// ─────────────────────────────────────────────

enum AssistantLanguage { french, arabic, darija }

extension AssistantLanguageExt on AssistantLanguage {
  String get hintText {
    switch (this) {
      case AssistantLanguage.french:
        return 'Écris ta réponse...';
      case AssistantLanguage.arabic:
        return 'اكتب ردك...';
      case AssistantLanguage.darija:
        return 'Suwelni marhba...';
    }
  }

  String buildPersona() {
    switch (this) {
      case AssistantLanguage.french:
        return '''
Tu es Sandokti, un assistant budgétaire marocain sympa et naturel.
Tu parles uniquement en français correct et décontracté — comme un ami, pas comme un robot.
Tu NE glisses JAMAIS de mots en darija ou en arabe. Tout est en français.
Tu réponds UNIQUEMENT à ce que l'utilisateur te demande. Ne donne pas de conseils non demandés.
Si l'utilisateur pose une question précise, réponds à cette question précisément.
Si l'utilisateur veut juste causer, cause naturellement sans sortir des chiffres.
Sois concis : 2 à 4 lignes maximum. Pas de listes à puces sauf si l'utilisateur le demande.
N'utilise jamais de formules comme "Bien sûr !" ou "Absolument !" — parle naturellement.
''';
      case AssistantLanguage.arabic:
        return '''
أنت Sandokti، مساعد مالي مغربي ودود وطبيعي.
⚠️ قاعدة صارمة: تجيب بالعربية الفصحى الخالصة فقط — ممنوع تماماً استخدام أي كلمة بالفرنسية أو الإنجليزية أو الدارجة أو أي لغة أخرى.
لا تكتب أرقام الفصول أو العناوين — تحدث بشكل طبيعي كالصديق.
تجيب فقط على ما يسأل عنه المستخدم. لا تعطي نصائح غير مطلوبة.
إذا كان السؤال محدداً، أجب بدقة. إذا أراد المستخدم فقط محادثة، تحدث معه بشكل طبيعي.
كن موجزاً: من 2 إلى 4 أسطر فقط. لا قوائم إلا إذا طُلب منك ذلك.
لا تبدأ بعبارات مثل "بالتأكيد!" أو "حسناً!" — تكلم بشكل طبيعي.
تذكر دائماً: عربية فصحى خالصة — هذا شرط لا يُكسر أبداً.
''';
      case AssistantLanguage.darija:
        return '''
You are Sandokti, a Moroccan budget assistant who speaks Darija written in Latin letters (Franco-Arab style).
Use Darija transliterated in French letters only — never write in Arabic script.
Examples of how you write: "wach", "mzyan", "3lach", "bghiti", "b-ssif", "kayn", "ma3endkch", "suwwel", "hna", "dyal", "l-flous", "hadchi", "walo", "gha", "tqdar", "3andek".
You reply ONLY to what the user asks. No unsolicited advice.
If the question is specific, answer precisely. If the user just wants to chat, chat naturally without numbers.
Be concise: 2 to 4 lines max. No bullet points unless asked.
Never start with "Bien sûr !" or "Absolument !" — speak naturally like a friend.
''';
    }
  }
}

// ─────────────────────────────────────────────
// Détection de langue depuis le message user
// ─────────────────────────────────────────────

AssistantLanguage? _detectLanguageChoice(String text) {
  final t = text.toLowerCase().trim();

  // Darija — checker AVANT arabe
  if (t.contains('darija') ||
      t.contains('دارجة') ||
      t.contains('درجة') ||
      t.contains('darja') ||
      t == '3') {
    return AssistantLanguage.darija;
  }

  // Français
  if (t.contains('français') ||
      t.contains('francais') ||
      t.contains('french') ||
      t == 'fr' ||
      t == '1') {
    return AssistantLanguage.french;
  }

  // Arabe
  if (t.contains('arabe') ||
      t.contains('arabic') ||
      t.contains('عربية') ||
      t.contains('عربي') ||
      t == '2') {
    return AssistantLanguage.arabic;
  }

  return null;
}

// ─────────────────────────────────────────────
// AssistantScreen
// ─────────────────────────────────────────────

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final BudgetAssistantService _localAssistant = const BudgetAssistantService();

  AssistantLanguage? _language;
  bool _languageChosen = false;
  bool _sending = false;

  // PAS de const ici — showLanguageButtons cause un crash avec const
  late final List<_ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      _ChatMessage(
        text:
            'Salam 👋 Ana hna m3ak — je suis Sandokti, ton assistant budgétaire !\n\nDans quelle langue tu préfères qu\'on parle ?',
        isUser: false,
        showLanguageButtons: true,
      ),
    ];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _applyLanguageChoice(AssistantLanguage lang, {String? userText}) {
    final Map<AssistantLanguage, String> confirmations = {
      AssistantLanguage.french:
          'Parfait, on parle en français alors 😄 Pose-moi tes questions sur ton budget, tes dépenses ou ton épargne !',
      AssistantLanguage.arabic:
          'ممتاز، نتحدث بالعربية إذن 😄 اسألني عن ميزانيتك، مصاريفك، أو ادخارك!',
      AssistantLanguage.darija:
          'Mzyan, nhedro b darija 😄 Suwwelni 3la l-budget dyalek, l-masruf, wla l-iddikhar!',
    };

    setState(() {
      if (userText != null) {
        _messages.add(_ChatMessage(text: userText, isUser: true));
      }
      _language = lang;
      _languageChosen = true;
      _messages.add(_ChatMessage(
        text: confirmations[lang]!,
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();

    // ── Onboarding : détecter le choix de langue ──
    if (!_languageChosen) {
      final detected = _detectLanguageChoice(text);
      if (detected != null) {
        _applyLanguageChoice(detected, userText: text);
      } else {
        setState(() {
          _messages.add(_ChatMessage(text: text, isUser: true));
          _messages.add(_ChatMessage(
            text:
                'Hmm, j\'ai pas bien compris 😅\nTape juste "Français", "Arabe" ou "Darija" — ou clique sur un bouton ci-dessus !',
            isUser: false,
          ));
        });
        _scrollToBottom();
      }
      return;
    }

    final lang = _language!;

    // ── Changement de langue en cours de conversation ──
    final langSwitch = _detectLanguageChoice(text);
    if (langSwitch != null && langSwitch != _language) {
      _applyLanguageChoice(langSwitch, userText: text);
      return;
    }

    // ── Salutations simples ──
    final simpleGreetings = [
      'salam', 'bonjour', 'salut', 'hey', 'hello', 'labas', 'la bas',
      'السلام', 'مرحبا', 'أهلا', 'سلام',
    ];
    if (simpleGreetings.contains(text.toLowerCase())) {
      final Map<AssistantLanguage, String> greetings = {
        AssistantLanguage.french:
            'Bonjour 😄 Comment je peux t\'aider avec ton budget aujourd\'hui ?',
        AssistantLanguage.arabic:
            'وعليكم السلام 😄 كيف حالك؟ اسألني عن أموالك أو أي شيء!',
        AssistantLanguage.darija:
            'Wa salam 😄 Labas? Suwwelni 3la l-flous dyalek wla ay haja!',
      };
      setState(() {
        _messages.add(_ChatMessage(text: text, isUser: true));
        _messages.add(_ChatMessage(text: greetings[lang]!, isUser: false));
      });
      _scrollToBottom();
      return;
    }

    // ── Message normal → Gemini ──
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _sending = true;
    });
    _scrollToBottom();

    try {
      final dashboard = await ref.read(dashboardProvider.future);
      final habits = dashboard.spendingHabitAnalysis;
      final appContext = _buildAppContext(
        dashboard: dashboard,
        habits: habits,
        userQuestion: text,
      );
      final gemini = ref.read(geminiServiceProvider);

      String reply;
      String? fallbackReason;

      try {
        reply = await gemini.ask(userMessage: text, appContext: appContext);
        debugPrint('✅ GEMINI A RÉPONDU : $reply');
      } catch (e) {
        final err = e.toString();
        if (err.contains('quota_cooldown')) {
          fallbackReason =
              '⚡ Mode local (quota Gemini atteint, reessaie dans quelques secondes)';
        } else if (err.contains('gemini_no_key')) {
          fallbackReason = '⚡ Mode local (clé API Gemini non configurée)';
        } else if (err.contains('gemini_bad_key')) {
          fallbackReason = '⚡ Mode local (clé API Gemini invalide)';
        } else if (err.contains('gemini_timeout')) {
          fallbackReason = '⚡ Mode local (Gemini trop lent, reessaie)';
        } else {
          fallbackReason = '⚡ Mode local (Gemini indisponible)';
        }

        reply = _localAssistant.reply(
          userMessage: text,
          dashboard: dashboard,
          habits: habits,
        );
      }

      if (!mounted) return;

      setState(() {
        if (fallbackReason != null) {
          _messages.add(_ChatMessage(
            text: fallbackReason!,
            isUser: false,
            isSystem: true,
          ));
        }
        _messages.add(_ChatMessage(text: reply, isUser: false));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Erreur : $e',
          isUser: false,
          isSystem: true,
        ));
        _sending = false;
      });
      _scrollToBottom();
    }
  }

  String _buildAppContext({
    required DashboardState dashboard,
    required dynamic habits,
    required String userQuestion,
  }) {
    final lang = _language ?? AssistantLanguage.french;

    final recommendationsText = dashboard.recommendations
        .map((e) => '${e.label}: ${_mad(e.amountCents)} (${e.percent}%)')
        .join(', ');

    final alertsText = dashboard.alerts.isEmpty
        ? 'Aucune alerte'
        : dashboard.alerts
            .map((e) =>
                '${e.label} | conseillé: ${_mad(e.recommendedCents)} | dépensé: ${_mad(e.spentCents)} | sévérité: ${e.severity}')
            .join(' ; ');

    return '''
${lang.buildPersona()}

--- Données budget de l'utilisateur ---
- Revenu du mois : ${_mad(dashboard.incomeCents)}
- Dépenses du mois : ${_mad(dashboard.expenseCents)}
- Reste : ${_mad(dashboard.realBalanceCents)}
- Taux d'épargne : ${dashboard.savingRate.toStringAsFixed(1)}%
- Variation vs mois dernier : ${dashboard.expenseVariationPercent.toStringAsFixed(1)}%
- Catégorie dominante : ${habits.topCategory ?? "Non disponible"} (${_mad(habits.topCategoryAmountCents)})
- Jour le plus coûteux : ${habits.mostExpensiveDayName ?? "Non disponible"}
- Catégorie en hausse : ${habits.risingCategory ?? "Aucune"}
- Recommandations : $recommendationsText
- Alertes : $alertsText

--- Question de l'utilisateur ---
$userQuestion

--- INSTRUCTION FINALE OBLIGATOIRE ---
${lang == AssistantLanguage.arabic ? "⚠️ عربية فصحى خالصة فقط. ممنوع الفرنسية أو الإنجليزية أو الدارجة أو أي كلمة أجنبية." : ""}
${lang == AssistantLanguage.darija ? "⚠️ Reply ONLY in Darija written in Latin letters (franco-arab). Never use Arabic script or French sentences." : ""}
${lang == AssistantLanguage.french ? "⚠️ Réponds UNIQUEMENT en français. Aucun mot en darija ou en arabe." : ""}
''';
  }

  String _mad(int cents) {
    final dh = cents / 100;
    if (dh % 1 == 0) return '${dh.toStringAsFixed(0)} DH';
    return '${dh.toStringAsFixed(2)} DH';
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final isLoadingData = dashboardAsync.isLoading;

    final hintText =
        _languageChosen ? _language!.hintText : 'Français / Arabe / Darija...';

    final textDir =
        (_language == AssistantLanguage.arabic ||
                _language == AssistantLanguage.darija)
            ? TextDirection.rtl
            : TextDirection.ltr;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Sandokti'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                // On passe explicitement languageChosen pour forcer le rebuild
                return _MessageBubble(
                  message: msg,
                  languageChosen: _languageChosen,
                  onLanguageSelected: _applyLanguageChoice,
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: null,
                      textDirection: textDir,
                      decoration: InputDecoration(
                        hintText: hintText,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: ElevatedButton(
                      onPressed:
                          (isLoadingData || _sending) ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: SandoktiColors.emerald,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
// Modèles et widgets internes
// ─────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isSystem;
  final bool showLanguageButtons;

  // PAS de const constructor — évite le crash Null/bool
  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isSystem = false,
    this.showLanguageButtons = false,
  });
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.languageChosen,
    this.onLanguageSelected,
  });

  final _ChatMessage message;
  final bool languageChosen;
  final void Function(AssistantLanguage)? onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    // ── Message système (erreur, fallback) ──
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withOpacity(0.25)),
            ),
            child: Text(
              message.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.deepOrange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    final isUser = message.isUser;
    final bgColor = isUser ? SandoktiColors.emerald : Colors.grey.shade100;
    final textColor = isUser ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Bulle de texte ──
          Align(
            alignment:
                isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SelectableText(
                message.text,
                textDirection: _detectDirection(message.text),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),

          // ── Boutons de langue (onboarding uniquement) ──
          if (message.showLanguageButtons && !languageChosen && onLanguageSelected != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _LangChip(
                  label: '🇫🇷 Français',
                  onTap: () =>
                      onLanguageSelected!(AssistantLanguage.french),
                ),
                _LangChip(
                  label: '🇸🇦 Arabe',
                  onTap: () =>
                      onLanguageSelected!(AssistantLanguage.arabic),
                ),
                _LangChip(
                  label: '🌟 Darija',
                  onTap: () =>
                      onLanguageSelected!(AssistantLanguage.darija),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  TextDirection _detectDirection(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LangChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: SandoktiColors.emerald.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: SandoktiColors.emerald,
          ),
        ),
      ),
    );
  }
}