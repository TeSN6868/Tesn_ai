import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TeSNAI());
}

class TeSNAI extends StatelessWidget {
  const TeSNAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TeSN AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const String backendUrl =
      'https://tesn-ai.coolalaga686.workers.dev/api';

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode inputFocus = FocusNode();

  final List<Map<String, String>> messages = [
    {
      'role': 'ai',
      'text':
          'Halo! Saya TeSN AI. 👋\n\nSaya siap membantu kamu. Silakan tanyakan apa saja.',
    },
  ];

  bool loading = false;

  Future<void> sendMessage() async {
    final text = controller.text.trim();

    if (text.isEmpty || loading) return;

    controller.clear();

    setState(() {
      messages.add({
        'role': 'user',
        'text': text,
      });
      loading = true;
    });

    _scrollToBottom();

    try {
      final response = await http
          .post(
            Uri.parse('$backendUrl/chat'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'message': text,
              'history': messages
                  .map((m) => {
                        'role': m['role'] == 'ai' ? 'model' : 'user',
                        'text': m['text'] ?? '',
                      })
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final reply = data['reply']?.toString();

        setState(() {
          messages.add({
            'role': 'ai',
            'text': reply?.isNotEmpty == true
                ? reply!
                : 'TeSN AI tidak menerima jawaban dari server.',
          });
        });
      } else {
        setState(() {
          messages.add({
            'role': 'ai',
            'text':
                'Maaf, server TeSN AI mengalami masalah.\n\nKode: ${response.statusCode}',
          });
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messages.add({
          'role': 'ai',
          'text':
              'TeSN AI tidak dapat terhubung ke server.\n\nPeriksa koneksi internet kamu lalu coba lagi.',
        });
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jawaban disalin'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome),
            SizedBox(width: 8),
            Text(
              'TeSN AI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                itemCount: messages.length + (loading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (loading && index == messages.length) {
                    return const _ThinkingBubble();
                  }

                  final message = messages[index];
                  final isUser = message['role'] == 'user';
                  final text = message['text'] ?? '';

                  return _MessageBubble(
                    text: text,
                    isUser: isUser,
                    onCopy: isUser ? null : () => copyMessage(text),
                  );
                },
              ),
            ),

            // Kotak input
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.25),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: inputFocus,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan untuk TeSN AI...',
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: loading ? null : sendMessage,
                    icon: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final VoidCallback? onCopy;

  const _MessageBubble({
    required this.text,
    required this.isUser,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 340,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        decoration: BoxDecoration(
          color: isUser
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
              ),
            ),
            if (!isUser && onCopy != null)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Salin',
                  onPressed: onCopy,
                  icon: const Icon(
                    Icons.copy_outlined,
                    size: 17,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 10),
            Text('TeSN AI sedang berpikir...'),
          ],
        ),
      ),
    );
  }
}
