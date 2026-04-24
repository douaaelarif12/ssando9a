import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/sandokti_colors.dart';
import '../providers/budget_providers.dart';
import '../../domain/services/budget_assistant_service.dart';
import '../dashboard_controller.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final BudgetAssistantService _localAssistant = const BudgetAssistantService();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Salam \u{1F44B} Je suis ton assistant Sandokti. '
          'Pose-moi une question sur ton budget, ton epargne ou tes depenses.',
      isUser: false,
    ),
  ];

  bool _sending = false;

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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
  final simpleGreetings = ['salam', 'bonjour', 'salut', 'hey', 'hello'];

if (simpleGreetings.contains(text.toLowerCase())) {
  setState(() {
    _messages.add(_ChatMessage(text: text, isUser: true));
    _messages.add(const _ChatMessage(
      text: 'Salam 👋 Je suis là pour t’aider avec ton budget, tes dépenses et ton épargne.',
      isUser: false,
    ));
  });

  _controller.clear();
  _scrollToBottom();
  return;
}
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _sending = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final dashboard = await ref.read(dashboardProvider.future);
      final habits = dashboard.spendingHabitAnalysis;
      final appContext = _buildAppContext(dashboard: dashboard, habits: habits);
      final gemini = ref.read(geminiServiceProvider);

      String reply;
      String? fallbackReason;

      try {
        reply = await gemini.ask(userMessage: text, appContext: appContext);
        reply = await gemini.ask(userMessage: text, appContext: appContext);
debugPrint('✅ GEMINI A RÉPONDU : $reply'); // ← ajoute cette ligne
      } catch (e) {
        final err = e.toString();
        if (err.contains('quota_cooldown')) {
          fallbackReason = '\u26A1 Mode local (quota Gemini atteint, reessaie dans quelques secondes)';
        } else if (err.contains('gemini_no_key')) {
          fallbackReason = '\u26A1 Mode local (cle API Gemini non configuree)';
        } else if (err.contains('gemini_bad_key')) {
          fallbackReason = '\u26A1 Mode local (cle API Gemini invalide)';
        } else if (err.contains('gemini_timeout')) {
          fallbackReason = '\u26A1 Mode local (Gemini trop lent, reessaie)';
        } else {
          fallbackReason = '\u26A1 Mode local (Gemini indisponible)';
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
  }) {
    final recommendationsText = dashboard.recommendations
        .map((e) => '${e.label}: ${_mad(e.amountCents)} (${e.percent}%)')
        .join(', ');

    final alertsText = dashboard.alerts.isEmpty
        ? 'Aucune alerte'
        : dashboard.alerts
            .map((e) =>
                '${e.label} | conseille: ${_mad(e.recommendedCents)} | depense: ${_mad(e.spentCents)} | severite: ${e.severity}')
            .join(' ; ');

    return '''
Contexte utilisateur Sandokti :

- Revenu total du mois : ${_mad(dashboard.incomeCents)}
- Depenses du mois : ${_mad(dashboard.expenseCents)}
- Reste reel : ${_mad(dashboard.realBalanceCents)}
- Taux d epargne reel : ${dashboard.savingRate.toStringAsFixed(1)}%
- Variation vs mois precedent : ${dashboard.expenseVariationPercent.toStringAsFixed(1)}%

Analyse des habitudes :
- Nombre de depenses analysees : ${habits.expenseCount}
- Depense moyenne : ${_mad(habits.averageExpenseCents)}
- Categorie dominante : ${habits.topCategory ?? "Non disponible"}
- Montant de la categorie dominante : ${_mad(habits.topCategoryAmountCents)}
- Jour le plus couteux : ${habits.mostExpensiveDayName ?? "Non disponible"}
- Petites depenses frequentes : ${habits.smallExpensesCount}
- Part des petites depenses : ${(habits.smallExpensesShare * 100).toStringAsFixed(1)}%
- Categorie en hausse : ${habits.risingCategory ?? "Aucune"}
- Score de regularite : ${habits.spendingRegularityScore.toStringAsFixed(0)} / 100

Recommandations :
$recommendationsText

Alertes :
$alertsText

Consigne :
- Tu es un assistant financier premium de Sandokti.
- Reponds en francais simple, naturel et intelligent, avec les accents corrects.
- Base-toi uniquement sur les donnees fournies.
- Adapte ta reponse a la question exacte de l utilisateur.
- Mentionne les chiffres importants quand ils sont utiles.
- Reponse en 3 a 6 lignes maximum.
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
                return _MessageBubble(message: _messages[index]);
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
                      decoration: InputDecoration(
                        hintText: 'Ecris ta question...',
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

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isSystem;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isSystem = false,
  });
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
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

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            height: 1.45,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }
}
