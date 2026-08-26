import 'package:flutter/material.dart';

import 'bhre/core/bhre_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BhreRootApp());
}

class BhreRootApp extends StatefulWidget {
  const BhreRootApp({super.key});

  @override
  State<BhreRootApp> createState() => _BhreRootAppState();
}

class _BhreRootAppState extends State<BhreRootApp> {
  final BhreApp _bhre = BhreApp();

  @override
  void initState() {
    super.initState();
    _bhre.start();
  }

  @override
  void dispose() {
    _bhre.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bree',
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: BhreHomePage(bhre: _bhre),
    );
  }
}

class BhreHomePage extends StatefulWidget {
  final BhreApp bhre;

  const BhreHomePage({super.key, required this.bhre});

  @override
  State<BhreHomePage> createState() => _BhreHomePageState();
}

class _BhreHomePageState extends State<BhreHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _response = 'Bree siap mendengarkan.';

  Future<void> _send() async {
    final message = _controller.text.trim();

    if (message.isEmpty) return;

    _controller.clear();

    final response = await widget.bhre.sendMessage(message);

    if (!mounted) return;

    setState(() {
      _response = response.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bree')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    _response,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan untuk Bree...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
