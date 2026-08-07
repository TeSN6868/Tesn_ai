import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const String apiBase = 'https://m8-messenger-api.coolalaga686.workers.dev';

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
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'m8_pin': pin, 'password': password}),
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
        showMessage(data['error']?.toString() ?? 'Login gagal');
      }
    } catch (e) {
      if (!mounted) return;

      showMessage('Error login M8: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                        colors: [Color(0xFF1E5C91), Color(0xFF0B2945)],
                      ),
                      boxShadow: const [
                        BoxShadow(blurRadius: 25, color: Colors.black54),
                      ],
                    ),
                    child: const Icon(Icons.forum_rounded, size: 48),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: loading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                      child: const Text(
                        'DAFTAR AKUN M8',
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
// REGISTER
// ============================================================

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final identifierController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  Future<void> register(String pin) async {
    final name = nameController.text.trim();
    final identifier = identifierController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    if (name.isEmpty ||
        identifier.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage('Semua data wajib diisi');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Konfirmasi password tidak cocok');
      return;
    }

    setState(() => loading = true);

    try {
      final isEmail = identifier.contains('@');

      final response = await http
          .post(
            Uri.parse('$apiBase/api/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': isEmail ? identifier : '',
              'phone': phone,
              'password': password,
              'confirm_password': confirmPassword,
              'm8_pin': pin,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 && data['success'] == true) {
        showMessage('Akun M8 berhasil dibuat');

        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        Navigator.of(context).pop();
      } else {
        showMessage(data['error']?.toString() ?? 'Pendaftaran M8 gagal');
      }
    } catch (_) {
      if (!mounted) return;

      showMessage('Tidak dapat terhubung ke server M8.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  String _generateM8Pin() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    final random = Random.secure();

    final generatedLetters = List.generate(
      4,
      (_) => letters[random.nextInt(letters.length)],
    ).join();

    final generatedNumbers = List.generate(
      4,
      (_) => numbers[random.nextInt(numbers.length)],
    ).join();

    return '$generatedLetters$generatedNumbers';
  }

  Future<void> _showPinDialog() async {
    final pin = _generateM8Pin();

    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified_user_outlined),
              SizedBox(width: 10),
              Expanded(child: Text('PIN M8 Kamu')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PIN M8 dibuat otomatis oleh sistem. '
                'Kamu tidak dapat memilih atau mengubah PIN ini.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                child: SelectableText(
                  pin,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Simpan PIN ini. PIN akan digunakan sebagai identitas akun M8.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('LANJUT DAFTAR'),
            ),
          ],
        );
      },
    );

    if (!mounted || proceed != true) return;

    await register(pin);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    nameController.dispose();
    identifierController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar M8')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, size: 64),

                  const SizedBox(height: 18),

                  const Text(
                    'Buat Akun M8',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Daftar untuk mulai menggunakan M8 Messenger',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(.65)),
                  ),

                  const SizedBox(height: 32),

                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: fieldDecoration('Nama', Icons.person_outline),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: identifierController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: fieldDecoration(
                      'Email / Nomor HP',
                      Icons.alternate_email,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: fieldDecoration(
                      'Nomor HP',
                      Icons.phone_outlined,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: fieldDecoration(
                      'Password',
                      Icons.lock_outline,
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
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    textInputAction: TextInputAction.next,
                    decoration: fieldDecoration(
                      'Konfirmasi Password',
                      Icons.lock_reset_outlined,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: loading ? null : _showPinDialog,
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'DAFTAR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: loading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Sudah punya akun? MASUK'),
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

  const HomePage({super.key, required this.token, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  String get name => widget.user['name']?.toString() ?? 'M8 User';

  String get pin => widget.user['m8_pin']?.toString() ?? '';

  void logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ChatsPage(token: widget.token, myPin: pin),
      const CallsPage(),
      ProfilePage(user: widget.user, onLogout: logout),
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
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
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

  const ChatsPage({super.key, required this.token, required this.myPin});

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
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final list = data['chats'];

        if (list is List) {
          chats = list.map((e) => Map<String, dynamic>.from(e)).toList();
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
                Navigator.pop(context, controller.text.trim());
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
        body: jsonEncode({'participant_2_pin': pin}),
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
        const SnackBar(content: Text('Tidak dapat terhubung ke M8')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (loading)
          const Center(child: CircularProgressIndicator())
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mulai percakapan pertama kamu di M8.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(.6)),
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

                final p1 = chat['participant_1_pin']?.toString() ?? '';

                final p2 = chat['participant_2_pin']?.toString() ?? '';

                final other = p1 == widget.myPin ? p2 : p1;

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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Percakapan M8'),
                  trailing: const Icon(Icons.chevron_right),
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

  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;

  String get chatId => widget.chat['id'].toString();

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> loadMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/api/messages?chat_id=$chatId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final list = data['messages'];

          if (mounted) {
            setState(() {
              messages = List<Map<String, dynamic>>.from(list ?? []);
              loading = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();

    if (text.isEmpty || sending) return;

    setState(() {
      sending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBase/api/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'chat_id': widget.chat['id'],
          'sender_pin': widget.myPin,
          'message': text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        controller.clear();

        final saved = data['message'];

        if (saved != null && mounted) {
          setState(() {
            messages.add(Map<String, dynamic>.from(saved));
          });
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error']?.toString() ?? 'Gagal mengirim pesan.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Koneksi gagal: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p1 = widget.chat['participant_1_pin']?.toString() ?? '';
    final p2 = widget.chat['participant_2_pin']?.toString() ?? '';

    final other = p1 == widget.myPin ? p2 : p1;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(radius: 18, child: Icon(Icons.person)),
            const SizedBox(width: 10),
            Text(other),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? Center(
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
                          'Belum ada pesan',
                          style: TextStyle(color: Colors.white.withOpacity(.5)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mulai percakapan M8',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(.35),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: false,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];

                      final sender = msg['sender_pin']?.toString() ?? '';

                      final text = msg['message']?.toString() ?? '';

                      final mine = sender == widget.myPin;

                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * .78,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: mine
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white.withOpacity(.08),
                          ),
                          child: Text(
                            text,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      );
                    },
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
                    textInputAction: TextInputAction.newline,
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
                  onPressed: sending ? null : sendMessage,
                  icon: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
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
          Icon(Icons.call, size: 70, color: Colors.white.withOpacity(.25)),
          const SizedBox(height: 18),
          const Text(
            'Panggilan M8',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Fitur panggilan akan kita aktifkan berikutnya.',
            style: TextStyle(color: Colors.white.withOpacity(.55)),
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

  const ProfilePage({super.key, required this.user, required this.onLogout});

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
          child: CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Text(
            pin,
            style: TextStyle(color: Colors.white.withOpacity(.55)),
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
                subtitle: Text(email.isEmpty ? 'Belum diatur' : email),
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
