import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const String apiBase =
    'https://m8-messenger-api.coolalaga686.workers.dev';

void main() {
  runApp(const M8App());
}

class M8App extends StatelessWidget {
  const M8App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'M8 Messenger',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF123A63),
        scaffoldBackgroundColor: const Color(0xFF071522),
      ),
      home: const LoginPage(),
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final pinController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  Future<void> login() async {
    final pin = pinController.text.trim();
    final password = passwordController.text;

    if (pin.isEmpty || password.isEmpty) {
      showMessage('M8 PIN dan password wajib diisi');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http
          .post(
            Uri.parse('$apiBase/api/login'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'm8_pin': pin,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['token']?.toString();

        if (token == null || token.isEmpty) {
          showMessage('Token login tidak diterima server');
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomePage(
              token: token,
              user: Map<String, dynamic>.from(data['user']),
            ),
          ),
        );
      } else {
        showMessage(
          data['error']?.toString() ?? 'Login gagal',
        );
      }
    } catch (_) {
      if (!mounted) return;

      showMessage(
        'Tidak dapat terhubung ke server M8.',
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    pinController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1E5C91),
                          Color(0xFF0B2945),
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 25,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      size: 48,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'M8 Messenger',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Private. Secure. Connected.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.65),
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 42),

                  TextField(
                    controller: pinController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'M8 PIN',
                      hintText: 'Contoh: TEST0002',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: Colors.white.withOpacity(.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    onSubmitted: (_) => login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: loading ? null : login,
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'MASUK KE M8',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'M8 Messenger API • Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const HomePage({
    super.key,
    required this.token,
    required this.user,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  String get name => widget.user['name']?.toString() ?? 'M8 User';

  String get pin => widget.user['m8_pin']?.toString() ?? '';

  void logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ChatsPage(
        token: widget.token,
        myPin: pin,
      ),
      const CallsPage(),
      ProfilePage(
        user: widget.user,
        onLogout: logout,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentIndex == 0
              ? 'M8 Messenger'
              : currentIndex == 1
                  ? 'Panggilan'
                  : 'Profil',
        ),
        actions: [
          if (currentIndex == 0)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
        ],
      ),
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.call_outlined),
            selectedIcon: Icon(Icons.call),
            label: 'Panggilan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHATS
// ============================================================

class ChatsPage extends StatefulWidget {
  final String token;
  final String myPin;

  const ChatsPage({
    super.key,
    required this.token,
    required this.myPin,
  });

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  bool loading = true;
  List<Map<String, dynamic>> chats = [];

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  Future<void> loadChats() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/api/chats'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final list = data['chats'];

        if (list is List) {
          chats = list
              .map(
                (e) => Map<String, dynamic>.from(e),
              )
              .toList();
        }
      }
    } catch (_) {
      // UI tetap dapat ditampilkan.
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> createChat() async {
    final controller = TextEditingController();

    final pin = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chat baru'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'M8 PIN tujuan',
              hintText: 'Contoh: TEST0001',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BATAL'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  controller.text.trim(),
                );
              },
              child: const Text('MULAI'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (pin == null || pin.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$apiBase/api/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'participant_2_pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['message']?.toString() ??
                data['error']?.toString() ??
                'Selesai',
          ),
        ),
      );

      await loadChats();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat terhubung ke M8'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (loading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (chats.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 70,
                    color: Colors.white.withOpacity(.3),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Belum ada percakapan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mulai percakapan pertama kamu di M8.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          RefreshIndicator(
            onRefresh: loadChats,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];

                final p1 =
                    chat['participant_1_pin']?.toString() ?? '';

                final p2 =
                    chat['participant_2_pin']?.toString() ?? '';

                final other =
                    p1 == widget.myPin ? p2 : p1;

                return ListTile(
                  leading: CircleAvatar(
                    radius: 27,
                    child: Text(
                      other.isNotEmpty
                          ? other.substring(
                              0,
                              other.length > 2 ? 2 : other.length,
                            )
                          : '?',
                    ),
                  ),
                  title: Text(
                    other,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Percakapan M8',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomPage(
                          token: widget.token,
                          myPin: widget.myPin,
                          chat: chat,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: createChat,
            child: const Icon(Icons.chat_rounded),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CHAT ROOM
// ============================================================

class ChatRoomPage extends StatefulWidget {
  final String token;
  final String myPin;
  final Map<String, dynamic> chat;

  const ChatRoomPage({
    super.key,
    required this.token,
    required this.myPin,
    required this.chat,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p1 =
        widget.chat['participant_1_pin']?.toString() ?? '';

    final p2 =
        widget.chat['participant_2_pin']?.toString() ?? '';

    final other = p1 == widget.myPin ? p2 : p1;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              child: Icon(Icons.person),
            ),
            const SizedBox(width: 10),
            Text(other),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 42,
                    color: Colors.white.withOpacity(.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Percakapan M8',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chat ID: ${widget.chat['id']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle_outline),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan...',
                      filled: true,
                      fillColor: Colors.white.withOpacity(.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: () {},
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CALLS
// ============================================================

class CallsPage extends StatelessWidget {
  const CallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.call,
            size: 70,
            color: Colors.white.withOpacity(.25),
          ),
          const SizedBox(height: 18),
          const Text(
            'Panggilan M8',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fitur panggilan akan kita aktifkan berikutnya.',
            style: TextStyle(
              color: Colors.white.withOpacity(.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['name']?.toString() ?? 'M8 User';
    final pin = user['m8_pin']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        const Center(
          child: CircleAvatar(
            radius: 48,
            child: Icon(
              Icons.person,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Text(
            pin,
            style: TextStyle(
              color: Colors.white.withOpacity(.55),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('M8 PIN'),
                subtitle: Text(pin),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(
                  email.isEmpty ? 'Belum diatur' : email,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Keluar'),
        ),
      ],
    );
  }
}
