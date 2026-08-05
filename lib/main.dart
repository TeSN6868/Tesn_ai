import 'dart:convert';
import 'package:flutter/material.dart';
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
      theme: ThemeData.dark(useMaterial3: true),
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
  final controller = TextEditingController();
  final scrollController = ScrollController();

  // Alamat backend.
  // Nanti kita ganti dengan alamat server online.
  static const backendUrl = 'https://tesn-ai.coolalaga686.workers.dev/api';

  final messages = <Map<String, String>>[
    {
      'role': 'ai',
      'text': 'Halo! Saya TeSN AI. Silakan kirim pesan.'
    }
  ];

  bool loading = false;

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || loading) return;

    controller.clear();

    setState(() {
      messages.add({'role': 'user', 'text': text});
      loading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$backendUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': text}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          messages.add({
            'role': 'ai',
            'text': data['reply']?.toString() ?? 'Tidak ada jawaban.'
          });
        });
      } else {
        setState(() {
          messages.add({
            'role': 'ai',
            'text': 'Backend mengembalikan error ${response.statusCode}.'
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({
          'role': 'ai',
          'text':
              'Belum dapat terhubung ke server TeSN AI. Backend online akan kita siapkan berikutnya.'
        });
      });
    } finally {
      setState(() {
        loading = false;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TeSN AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message['role'] == 'user';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 330),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser

