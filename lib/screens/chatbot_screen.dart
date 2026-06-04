import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/providers/language_provider.dart';
import '../models/chat_action.dart';
import '../models/chat_message.dart';
import '../models/procedure.dart';
import '../services/chatbot_service.dart';
import 'office_finder_screen.dart';
import 'procedure_detail_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messages.isNotEmpty) return;

    final lang =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final welcome = switch (lang) {
      AppLanguage.french =>
        'Posez une question. Je reponds avec les documents, couts, delais et actions utiles.',
      AppLanguage.darija =>
        'اسألني. نعطيك الوثائق والتكلفة والآجال والإجراء المناسب مباشرة.',
      AppLanguage.arabic =>
        'اطرح سؤالك. سأعرض الوثائق والتكلفة والمدة والإجراء المناسب مباشرة.',
    };

    _messages.add(
      ChatMessage(
        text: welcome,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    final lang =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final botResponse = await ChatbotService.getBotReply(text, lang);

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.insert(
        0,
        ChatMessage(
          text: botResponse.text,
          isUser: false,
          timestamp: DateTime.now(),
          actions: botResponse.actions,
          procedure: botResponse.procedure,
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _handleAction(ChatAction action) async {
    if (action.route == '/procedure_detail' && action.payload != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProcedureDetailScreen(procedureKey: action.payload!),
        ),
      );
      return;
    }

    if (action.route == '/office_finder') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OfficeFinderScreen(initialOfficeId: action.payload),
        ),
      );
      return;
    }

    await Navigator.pushNamed(context, action.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.smart_toy, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assistant Maak',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _isTyping ? 'Analyse en cours...' : 'Mode concis',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MaakBot extrait les donnees...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          _buildQuickActions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final lang =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final actions = [
      {
        'label': lang == AppLanguage.french ? 'Perte CIN' : 'Perte CIN',
        'query': 'Procedure perte CIN'
      },
      {
        'label': lang == AppLanguage.french ? 'Passeport' : 'Passeport',
        'query': 'Documents pour passeport'
      },
      {
        'label':
            lang == AppLanguage.french ? 'Carte handicap' : 'Carte handicap',
        'query': 'Procedure carte handicap'
      },
    ];

    return SizedBox(
      height: 52,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: actions
            .map(
              (action) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    action['label']!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF1E3A8A),
                  onPressed: () {
                    _controller.text = action['query']!;
                    _sendMessage();
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                height: 1.45,
                fontSize: 15,
              ),
            ),
            if (msg.procedure != null) ...[
              const SizedBox(height: 14),
              _buildProcedureCard(msg.procedure!),
            ],
            if (msg.actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: msg.actions
                    .map(
                      (action) => FilledButton.tonalIcon(
                        onPressed: () => _handleAction(action),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE0F2FE),
                          foregroundColor: const Color(0xFF0F766E),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(action.label),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProcedureCard(Procedure procedure) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            procedure.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          _factRow('Documents', procedure.requiredDocuments.join(', ')),
          _factRow('Cost', procedure.cost),
          _factRow('Time', procedure.timeRequired),
          _factRow('Where', procedure.whereToGo),
          if (procedure.steps.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Steps',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...procedure.steps.take(4).map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(Icons.circle, size: 7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(step)),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _factRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ecrivez votre question...',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFF1D9E75),
                child: Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
