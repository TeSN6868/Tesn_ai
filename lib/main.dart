import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'm8_call_service.dart';
import 'package:http/http.dart' as http;

const String apiBase = 'https://m8-messenger-api.coolalaga686.workers.dev';

const m8Navy = Color(0xFF12335F);
const m8Navy2 = Color(0xFF1E477A);
const m8Navy3 = Color(0xFF274F7C);

const m8Gold = Color(0xFF3A6EA5);
const m8GoldLight = Color(0xFF5B84AE);

const m8Cream = Color(0xFFEEF3F7);
const m8CreamLight = Color(0xFFFFFFFF);
const m8Text = Color(0xFF0F1B2E);
const m8TextMuted = Color(0xFF6B7C93);

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
        scaffoldBackgroundColor: m8Navy,
        colorScheme: const ColorScheme.dark(
          primary: m8Gold,
          secondary: m8GoldLight,
          surface: m8Navy2,
          onPrimary: m8Navy,
          onSecondary: m8Navy,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: m8Navy,
          foregroundColor: m8GoldLight,
          elevation: 0,
        ),
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
    final m8Pin = pinController.text.trim();
    final password = passwordController.text;

    if (m8Pin.isEmpty || password.isEmpty) {
      showMessage('M8 PIN dan password wajib diisi');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http
          .post(
            Uri.parse('$apiBase/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'m8_pin': m8Pin, 'password': password}),
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
    const lightBlue = m8Navy;
    const blue = m8Navy2;
    const darkBlue = m8Navy3;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [m8Navy, m8Navy2, m8Navy],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    const Text(
                      'M8',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 2),

                    const Text(
                      'MESSENGER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Private. Secure. Connected.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .82),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: m8Gold),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 30,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: pinController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              color: Color(0xFF172033),
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'M8 PIN',
                              hintText: 'Masukkan M8 PIN',
                              labelStyle: const TextStyle(
                                color: Color(0xFF172033),
                                fontWeight: FontWeight.w600,
                              ),
                              hintStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(
                                Icons.key_rounded,
                                color: Colors.white,
                              ),
                              filled: true,
                              fillColor: m8CreamLight,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17),
                                borderSide: BorderSide(color: Colors.black12),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(17),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          TextField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            onSubmitted: (_) => login(),
                            style: const TextStyle(
                              color: Color(0xFF172033),
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(
                                color: Color(0xFF172033),
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.white,
                              ),
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
                                  color: Colors.white,
                                ),
                              ),
                              filled: true,
                              fillColor: m8CreamLight,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17),
                                borderSide: BorderSide(color: Colors.black12),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(17),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: loading ? null : login,
                              style: FilledButton.styleFrom(
                                backgroundColor: m8GoldLight,
                                foregroundColor: m8Navy,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                elevation: 8,
                              ),
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
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: TextButton(
                              onPressed: loading
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterPage(),
                                        ),
                                      );
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                              child: const Text(
                                'Belum punya akun : Daftar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'M8 Messenger API • Online',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
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
      labelStyle: const TextStyle(color: Color(0xFF172033)),
      prefixIcon: Icon(icon, color: Color(0xFF172033)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: m8CreamLight,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: m8Gold, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: m8Navy,
      appBar: AppBar(
        backgroundColor: m8Navy,
        foregroundColor: m8GoldLight,
        title: const Text('Daftar M8'),
      ),
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
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .65),
                    ),
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
      backgroundColor: m8Cream,
      appBar: AppBar(
        backgroundColor: m8Navy,
        foregroundColor: m8GoldLight,
        title: Text(
          currentIndex == 0
              ? 'M8 Messenger'
              : currentIndex == 1
              ? 'Panggilan'
              : 'Profil',
        ),
        actions: [
          if (currentIndex == 0) ...[
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    setState(() {
                      currentIndex = 2;
                    });
                    break;

                  case 'contacts':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kontak M8 segera hadir.')),
                    );
                    break;

                  case 'settings':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pengaturan M8 segera hadir.'),
                      ),
                    );
                    break;

                  case 'notifications':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifikasi M8 segera hadir.'),
                      ),
                    );
                    break;

                  case 'appearance':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tampilan M8 segera hadir.'),
                      ),
                    );
                    break;

                  case 'privacy':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privasi M8 segera hadir.')),
                    );
                    break;

                  case 'help':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bantuan M8 segera hadir.')),
                    );
                    break;

                  case 'logout':
                    logout();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline),
                      SizedBox(width: 12),
                      Text('Profil Saya'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'contacts',
                  child: Row(
                    children: [
                      Icon(Icons.people_outline),
                      SizedBox(width: 12),
                      Text('Kontak'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined),
                      SizedBox(width: 12),
                      Text('Pengaturan'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'notifications',
                  child: Row(
                    children: [
                      Icon(Icons.notifications_none),
                      SizedBox(width: 12),
                      Text('Notifikasi'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'appearance',
                  child: Row(
                    children: [
                      Icon(Icons.palette_outlined),
                      SizedBox(width: 12),
                      Text('Tampilan'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'privacy',
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline),
                      SizedBox(width: 12),
                      Text('Privasi'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'help',
                  child: Row(
                    children: [
                      Icon(Icons.help_outline),
                      SizedBox(width: 12),
                      Text('Bantuan'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 12),
                      Text('Keluar'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: m8Navy,
        indicatorColor: m8Gold,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: Color(0xFFEEF3F7), fontWeight: FontWeight.w600),
        ),
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
        Uri.parse(
          '$apiBase/api/chats?m8_pin=${Uri.encodeComponent(widget.myPin)}',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final list = data['chats'];

        if (list is List) {
          chats = list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat chat: $e')));
      }
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
        body: jsonEncode({'my_pin': widget.myPin, 'other_pin': pin}),
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
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _M8StoryRail(
            onMyStoryTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StoryPage()),
              );
            },
          ),
        ),

        Positioned(
          top: 112,
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: false,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
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
                                  color: m8Gold,
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
                                  style: TextStyle(color: m8TextMuted),
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
                                  style: const TextStyle(
                                    color: Color(0xFF172033),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Percakapan M8',
                                  style: TextStyle(color: Color(0xFF172033)),
                                ),
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
                    ],
                  ),
                ),
              ],
            ),
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
  Timer? typingTimer;
  Timer? typingPollTimer;

  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;
  bool otherTyping = false;
  XFile? pendingImage;

  String get chatId => widget.chat['id'].toString();

  @override
  void initState() {
    super.initState();
    loadMessages();
    markMessagesAsDelivered();
    markMessagesAsRead();

    typingPollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => checkOtherTyping(),
    );
  }

  @override
  void dispose() {
    typingTimer?.cancel();
    typingPollTimer?.cancel();
    setTyping(false);
    controller.dispose();
    super.dispose();
  }

  Future<void> startVoiceCall(String other) async {
    final call = M8CallService();

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            VoiceCallPage(myPin: widget.myPin, otherPin: other, call: call),
      ),
    );
  }

  Future<void> editMessage(Map<String, dynamic> msg) async {
    final messageId = msg["id"];
    final currentText = msg["message"]?.toString() ?? "";

    if (messageId == null ||
        currentText.isEmpty ||
        currentText.startsWith("__M8_IMAGE_BASE64__:")) {
      return;
    }

    final editController = TextEditingController(text: currentText);

    final editedText = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit pesan"),
          content: TextField(
            controller: editController,
            autofocus: true,
            maxLines: 5,
            minLines: 1,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: "Tulis pesan...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            FilledButton(
              onPressed: () {
                final value = editController.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(context, value);
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );

    editController.dispose();

    if (!mounted ||
        editedText == null ||
        editedText.trim().isEmpty ||
        editedText.trim() == currentText.trim()) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiBase/api/messages/edit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'message_id': messageId,
          'sender_pin': widget.myPin,
          'message': editedText.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['success'] == true &&
          data['message'] is Map) {
        final saved = Map<String, dynamic>.from(data['message']);

        if (!mounted) return;

        setState(() {
          final index = messages.indexWhere(
            (m) => m['id']?.toString() == messageId.toString(),
          );

          if (index >= 0) {
            messages[index] = {...messages[index], ...saved, '_edited': true};
          }
        });
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error']?.toString() ?? 'Gagal mengedit pesan.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengedit pesan: $e')));
    }
  }

  Future<void> loadMessages() async {
    debugPrint('M8 DEBUG CHAT ID = $chatId');
    try {
      final response = await http.get(
        Uri.parse('$apiBase/api/messages?chat_id=$chatId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final list = data['messages'];

          debugPrint(
            'M8 DEBUG messages count: '
            '${list is List ? list.length : 'NOT_LIST'}',
          );

          if (list is List) {
            for (final m in list) {
              if (m is Map) {
                final msg = m['message']?.toString() ?? '';
                final prefix = msg.length > 35 ? msg.substring(0, 35) : msg;
                debugPrint(
                  'M8 DEBUG id=${m['id']} '
                  'len=${msg.length} '
                  'prefix=$prefix',
                );
              }
            }
          }

          if (mounted) {
            final loadedMessages = List<Map<String, dynamic>>.from(list ?? []);

            debugPrint('M8 DEBUG GET messages count=${loadedMessages.length}');

            for (final msg in loadedMessages) {
              final raw = msg['message']?.toString() ?? '';
              debugPrint(
                'M8 DEBUG message id=${msg['id']} '
                'prefix=${raw.length > 30 ? raw.substring(0, 30) : raw} '
                'length=${raw.length}',
              );
            }

            setState(() {
              messages = loadedMessages;
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

  Future<void> markMessagesAsDelivered() async {
    try {
      await http.post(
        Uri.parse('$apiBase/api/messages/delivered'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'chat_id': widget.chat['id'],
          'receiver_pin': widget.myPin,
        }),
      );
    } catch (_) {}
  }

  Future<void> markMessagesAsRead() async {
    try {
      await http.post(
        Uri.parse('$apiBase/api/messages/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'chat_id': widget.chat['id'],
          'reader_pin': widget.myPin,
        }),
      );
    } catch (_) {}
  }

  Future<void> setTyping(bool typing) async {
    try {
      await http.post(
        Uri.parse('$apiBase/api/typing'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'chat_id': widget.chat['id'],
          'user_pin': widget.myPin,
          'typing': typing,
        }),
      );
    } catch (_) {}
  }

  Future<void> checkOtherTyping() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$apiBase/api/typing'
          '?chat_id=${Uri.encodeComponent(chatId)}'
          '&user_pin=${Uri.encodeComponent(widget.myPin)}',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted && data['success'] == true) {
          setState(() {
            otherTyping = data['typing'] == true;
          });
        }
      }
    } catch (_) {}
  }

  void handleTyping() {
    typingTimer?.cancel();

    setTyping(true);

    typingTimer = Timer(const Duration(milliseconds: 1500), () {
      setTyping(false);
    });
  }

  Future<void> sendHI() async {
    if (sending) return;

    const messageText = '__M8_HI__';

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
          'message': messageText,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 201 || data['success'] != true) {
        throw Exception(data['error']?.toString() ?? 'Gagal mengirim HI.');
      }

      await loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('HI gagal dikirim: $e')));
      }
    }
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    final image = pendingImage;

    if ((text.isEmpty && image == null) || sending) return;

    final tempId = 'local_${DateTime.now().microsecondsSinceEpoch}';

    setState(() {
      sending = true;
    });

    try {
      String messageText = text;

      // M8 R2: upload foto ke R2, lalu kirim URL melalui pesan.
      if (image != null) {
        final bytes = await image.readAsBytes();

        if (bytes.length > 5 * 1024 * 1024) {
          throw Exception('Foto terlalu besar. Maksimal 5 MB.');
        }

        final extension = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : 'jpg';

        final contentType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          'gif' => 'image/gif',
          _ => 'image/jpeg',
        };

        final uploadResponse = await http.post(
          Uri.parse('$apiBase/api/upload'),
          headers: {
            'Content-Type': contentType,
            'Authorization': 'Bearer ${widget.token}',
          },
          body: bytes,
        );

        final uploadData = jsonDecode(uploadResponse.body);

        if (uploadResponse.statusCode != 201 || uploadData['success'] != true) {
          throw Exception(
            uploadData['error']?.toString() ?? 'Gagal mengupload foto ke R2.',
          );
        }

        final imageUrl = uploadData['url']?.toString();

        if (imageUrl == null || imageUrl.isEmpty) {
          throw Exception('URL foto dari R2 tidak ditemukan.');
        }

        messageText = '__M8_IMAGE_URL__:$imageUrl';
      }

      final optimistic = <String, dynamic>{
        'id': tempId,
        'chat_id': widget.chat['id'],
        'sender_pin': widget.myPin,
        'message': messageText,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'created_at': DateTime.now().toIso8601String(),
        '_sending': true,
      };

      controller.clear();

      if (mounted) {
        setState(() {
          messages.add(optimistic);
          pendingImage = null;
        });
      }

      final response = await http.post(
        Uri.parse('$apiBase/api/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'chat_id': widget.chat['id'],
          'sender_pin': widget.myPin,
          'message': messageText,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final saved = data['message'];

        if (mounted && saved is Map) {
          setState(() {
            final index = messages.indexWhere(
              (m) => m['id']?.toString() == tempId,
            );

            if (index >= 0) {
              messages[index] = {
                ...Map<String, dynamic>.from(saved),
                '_sending': false,
              };
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            messages.removeWhere((m) => m['id']?.toString() == tempId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['error']?.toString() ?? 'Gagal mengirim pesan.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.removeWhere((m) => m['id']?.toString() == tempId);
          pendingImage = image;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim foto/pesan: $e')),
        );
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
    final p1 = widget.chat["participant_1_pin"]?.toString() ?? "";
    final p2 = widget.chat["participant_2_pin"]?.toString() ?? "";
    final other = p1 == widget.myPin ? p2 : p1;

    return Scaffold(
      backgroundColor: m8Cream,
      appBar: AppBar(
        backgroundColor: m8Navy,
        foregroundColor: m8GoldLight,
        elevation: 0,
        toolbarHeight: 68,
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 21,
                  backgroundColor: m8Navy2,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF35D07F),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0F1B2E),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "M8 User",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "M8 PIN: $other",
                    style: const TextStyle(fontSize: 11, color: m8TextMuted),
                  ),
                  const Text(
                    "Online",
                    style: TextStyle(fontSize: 10, color: Color(0xFF35D07F)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => startVoiceCall(other),
            icon: const Icon(Icons.call_outlined, color: m8Gold),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil kontak segera hadir.'),
                    ),
                  );
                  break;

                case 'search':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pencarian dalam chat segera hadir.'),
                    ),
                  );
                  break;

                case 'mute':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengaturan notifikasi segera hadir.'),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 12),
                    Text('Lihat profil'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 12),
                    Text('Cari dalam chat'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.notifications_off_outlined),
                    SizedBox(width: 12),
                    Text('Bisukan notifikasi'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: m8Cream,
        child: Column(
          children: [
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: m8Gold),
                    )
                  : messages.isEmpty
                  ? const Center(
                      child: Text(
                        "Mulai percakapan di M8",
                        style: TextStyle(color: m8TextMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final sender = msg["sender_pin"]?.toString() ?? "";
                        final text = msg["message"]?.toString() ?? "";
                        final mine = sender == widget.myPin;
                        final status =
                            msg["status"]?.toString().toLowerCase() ?? "";
                        final statusLabel = status == "read"
                            ? "R"
                            : status == "delivered"
                            ? "D"
                            : "✓";
                        final rawTime = msg["created_at"]?.toString() ?? "";
                        final time = rawTime.length >= 16
                            ? rawTime.substring(11, 16)
                            : rawTime;

                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: GestureDetector(
                            onLongPress:
                                mine &&
                                    !text.startsWith("__M8_IMAGE_BASE64__:") &&
                                    !text.startsWith("__M8_IMAGE_URL__:")
                                ? () => editMessage(msg)
                                : null,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * .78,
                              ),
                              margin: const EdgeInsets.only(bottom: 7),
                              padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                              decoration: BoxDecoration(
                                color: mine
                                    ? const Color(0xFFDCE9F4)
                                    : m8CreamLight,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(5),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(mine ? 16 : 5),
                                  bottomRight: Radius.circular(mine ? 5 : 16),
                                ),
                                border: Border.all(color: m8Gold, width: 0.8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (text.startsWith("__M8_IMAGE_URL__:"))
                                    Builder(
                                      builder: (context) {
                                        final imageUrl = text
                                            .substring(
                                              "__M8_IMAGE_URL__:".length,
                                            )
                                            .trim();

                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            imageUrl,
                                            width: 220,
                                            height: 220,
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (context, child, progress) {
                                                  if (progress == null)
                                                    return child;
                                                  return const SizedBox(
                                                    width: 220,
                                                    height: 220,
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  );
                                                },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    width: 220,
                                                    height: 120,
                                                    alignment: Alignment.center,
                                                    child: const Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      size: 36,
                                                    ),
                                                  );
                                                },
                                          ),
                                        );
                                      },
                                    )
                                  else if (text.startsWith(
                                    "__M8_IMAGE_BASE64__:",
                                  ))
                                    Builder(
                                      builder: (context) {
                                        try {
                                          final payload = text.substring(
                                            "__M8_IMAGE_BASE64__:".length,
                                          );

                                          final separator = payload.indexOf(
                                            ":",
                                          );

                                          if (separator <= 0) {
                                            throw Exception(
                                              "Format gambar invalid",
                                            );
                                          }

                                          final base64Data = payload
                                              .substring(separator + 1)
                                              .replaceAll(RegExp(r'\s+'), '');

                                          final imageBytes = base64Decode(
                                            base64Data,
                                          );

                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.memory(
                                              imageBytes,
                                              width: 220,
                                              height: 220,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      width: 220,
                                                      height: 120,
                                                      alignment:
                                                          Alignment.center,
                                                      color: mine
                                                          ? m8Navy2
                                                          : const Color(
                                                              0xFFFFFFFF,
                                                            ),
                                                      child: const Icon(
                                                        Icons
                                                            .broken_image_rounded,
                                                        size: 36,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          );
                                        } catch (e) {
                                          return Container(
                                            width: 220,
                                            height: 120,
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: mine
                                                  ? m8Gold
                                                  : m8CreamLight,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "Gambar gagal dibaca\\n${e.toString()}",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: mine
                                                    ? Colors.white
                                                    : const Color(0xFF172033),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  else if (text == "__M8_HI__")
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Hi !",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                          color: mine
                                              ? m8Navy2
                                              : const Color(0xFF0F1B2E),
                                        ),
                                      ),
                                    )
                                  else
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.3,
                                          color: mine
                                              ? m8Navy2
                                              : const Color(0xFF0F1B2E),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 3),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        time,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: mine
                                              ? m8GoldLight
                                              : const Color(0xFF536273),
                                        ),
                                      ),
                                      if (mine) ...[
                                        const SizedBox(width: 5),
                                        Text(
                                          statusLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: status == "read"
                                                ? m8CreamLight
                                                : m8GoldLight,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (otherTyping)
              const Padding(
                padding: EdgeInsets.only(left: 18, bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "sedang mengetik...",
                    style: TextStyle(
                      fontSize: 11,
                      color: m8TextMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(7, 6, 7, 8),
                decoration: const BoxDecoration(
                  color: m8CreamLight,
                  border: Border(top: BorderSide(color: m8Gold, width: 0.8)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pendingImage != null)
                      Container(
                        height: 82,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(pendingImage!.path),
                                width: 82,
                                height: 82,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              left: 58,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    pendingImage = null;
                                  });
                                },
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: m8Navy2,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                    color: m8CreamLight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              showDragHandle: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (sheetContext) {
                                Future<void> selectAttachment(
                                  String label,
                                ) async {
                                  Navigator.pop(sheetContext);

                                  if (label == "Kamera" || label == "Galeri") {
                                    try {
                                      final picker = ImagePicker();
                                      final image = await picker.pickImage(
                                        source: label == "Kamera"
                                            ? ImageSource.camera
                                            : ImageSource.gallery,
                                        imageQuality: 85,
                                      );

                                      if (image == null || !context.mounted)
                                        return;

                                      setState(() {
                                        pendingImage = image;
                                      });
                                    } catch (e) {
                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            label == "Kamera"
                                                ? "Gagal membuka kamera: $e"
                                                : "Gagal memilih foto: $e",
                                          ),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "$label — fitur M8 akan kita aktifkan berikutnya.",
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }

                                return SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      4,
                                      18,
                                      24,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            "Kirim ke M8",
                                            style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF172033),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        GridView.count(
                                          shrinkWrap: true,
                                          crossAxisCount: 4,
                                          mainAxisSpacing: 18,
                                          crossAxisSpacing: 12,
                                          children: [
                                            _AttachmentItem(
                                              icon: Icons.camera_alt_rounded,
                                              label: "Kamera",
                                              onTap: () =>
                                                  selectAttachment("Kamera"),
                                            ),
                                            _AttachmentItem(
                                              icon: Icons.photo_library_rounded,
                                              label: "Galeri",
                                              onTap: () =>
                                                  selectAttachment("Galeri"),
                                            ),
                                            _AttachmentItem(
                                              icon: Icons
                                                  .insert_drive_file_rounded,
                                              label: "Dokumen",
                                              onTap: () =>
                                                  selectAttachment("Dokumen"),
                                            ),
                                            _AttachmentItem(
                                              icon: Icons.location_on_rounded,
                                              label: "Lokasi",
                                              onTap: () =>
                                                  selectAttachment("Lokasi"),
                                            ),
                                            _AttachmentItem(
                                              icon: Icons.person_rounded,
                                              label: "Kontak M8",
                                              onTap: () =>
                                                  selectAttachment("Kontak M8"),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: m8Gold,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            onChanged: (_) => handleTyping(),
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.newline,
                            style: const TextStyle(
                              color: Color(0xFF172033),
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: "Tulis pesan...",
                              hintStyle: TextStyle(color: m8TextMuted),
                              filled: true,
                              fillColor: m8Cream,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(19),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        TextButton(
                          onPressed: sending ? null : sendHI,
                          style: TextButton.styleFrom(
                            foregroundColor: m8Navy2,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 9,
                            ),
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                              side: const BorderSide(color: m8Gold, width: 1),
                            ),
                          ),
                          child: const Text(
                            "Hi !",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton.filled(
                          onPressed: sending ? null : sendMessage,
                          style: IconButton.styleFrom(
                            backgroundColor: m8Gold,
                            foregroundColor: Colors.white,
                          ),
                          icon: sending
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _M8StoryRail extends StatelessWidget {
  final VoidCallback onMyStoryTap;

  const _M8StoryRail({required this.onMyStoryTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: m8Cream,
      padding: const EdgeInsets.fromLTRB(12, 10, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'M8 STORY',
              style: TextStyle(
                color: m8Navy2,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ),
          SizedBox(
            height: 82,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _M8StoryMiniCard(
                  title: 'Cerita Saya',
                  subtitle: 'Bagikan',
                  isMine: true,
                  onTap: onMyStoryTap,
                ),
                const SizedBox(width: 8),
                const _M8StoryMiniCard(title: 'M8', subtitle: 'Baru saja'),
                const SizedBox(width: 8),
                const _M8StoryMiniCard(title: 'Teman M8', subtitle: '12 menit'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _M8StoryMiniCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isMine;
  final VoidCallback? onTap;

  const _M8StoryMiniCard({
    required this.title,
    required this.subtitle,
    this.isMine = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 128,
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
        decoration: BoxDecoration(
          color: isMine ? m8Navy2 : m8CreamLight,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: m8Gold.withValues(alpha: 0.7), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isMine ? m8Gold : m8Navy2,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    isMine ? Icons.add_rounded : Icons.auto_awesome_rounded,
                    size: 17,
                    color: isMine ? m8Navy2 : m8GoldLight,
                  ),
                ),
                const Spacer(),
                if (isMine)
                  const Icon(Icons.edit_rounded, size: 14, color: m8GoldLight),
              ],
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isMine ? m8CreamLight : m8Navy2,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isMine ? m8GoldLight : m8TextMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryPage extends StatelessWidget {
  const StoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: m8Navy2,
      appBar: AppBar(
        backgroundColor: m8Navy2,
        foregroundColor: m8CreamLight,
        elevation: 0,
        title: const Text(
          "M8 Story",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            color: m8GoldLight,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            "CERITA SAYA",
            style: TextStyle(
              color: m8GoldLight,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _M8MyStoryCard(onTap: () {}),
          const SizedBox(height: 24),
          const Text(
            "CERITA TERBARU",
            style: TextStyle(
              color: m8GoldLight,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _M8StoryCard(
            name: "M8",
            time: "Baru saja",
            text: "Selamat datang di M8 Story",
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _M8StoryCard(
            name: "Teman M8",
            time: "12 menit",
            text: "Cerita baru untuk kamu",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _M8MyStoryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _M8MyStoryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: m8CreamLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: m8Gold, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: m8Navy2,
                shape: BoxShape.circle,
                border: Border.all(color: m8Gold, width: 2),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: m8GoldLight,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Cerita Saya",
                    style: TextStyle(
                      color: m8Navy2,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Bagikan sesuatu ke teman M8",
                    style: TextStyle(color: m8TextMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: m8Gold),
          ],
        ),
      ),
    );
  }
}

class _M8StoryCard extends StatelessWidget {
  final String name;
  final String time;
  final String text;
  final VoidCallback onTap;

  const _M8StoryCard({
    required this.name,
    required this.time,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: m8CreamLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: m8Gold.withValues(alpha: 0.55), width: 0.7),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: m8Navy2,
                shape: BoxShape.circle,
                border: Border.all(color: m8Gold, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: m8CreamLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: m8Navy2,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF536273),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    time,
                    style: const TextStyle(
                      color: m8Gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: m8Gold,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: m8CreamLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: m8Gold, size: 25),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: m8TextMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class VoiceCallPage extends StatefulWidget {
  final String myPin;
  final String otherPin;
  final M8CallService call;

  const VoiceCallPage({
    super.key,
    required this.myPin,
    required this.otherPin,
    required this.call,
  });

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  Timer? timer;
  int seconds = 0;
  bool connecting = true;
  String callStatus = 'Memanggil...';

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      await widget.call.startCall(
        callerPin: widget.myPin,
        calleePin: widget.otherPin,
      );

      if (!mounted) return;

      setState(() {
        connecting = false;
        callStatus = 'Terhubung';
      });

      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => seconds++);
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        connecting = false;
        callStatus = 'Panggilan gagal';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Panggilan gagal: $e')));
    }
  }

  String get durationText {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> hangUp() async {
    timer?.cancel();

    try {
      await widget.call.hangUp();
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: m8Navy,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 70),

            const CircleAvatar(
              radius: 58,
              backgroundColor: m8Gold,
              child: Icon(Icons.person, size: 62, color: Colors.white),
            ),

            const SizedBox(height: 22),

            const Text(
              'M8 User',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'M8 PIN: ${widget.otherPin}',
              style: TextStyle(color: m8TextMuted, fontSize: 13),
            ),

            const SizedBox(height: 18),

            Text(
              callStatus,
              style: TextStyle(
                color: callStatus == 'Panggilan gagal'
                    ? Colors.redAccent
                    : const Color(0xFF35D07F),
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 8),

            if (!connecting && callStatus == 'Terhubung')
              Text(
                durationText,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallButton(icon: Icons.mic, label: 'Mikrofon', onTap: () {}),
                _CallButton(
                  icon: Icons.volume_up,
                  label: 'Speaker',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 45),

            GestureDetector(
              onTap: hangUp,
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Akhiri',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),

            const SizedBox(height: 45),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: m8Navy3,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 27),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class CallsPage extends StatelessWidget {
  const CallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.call, size: 70, color: m8Gold),
          const SizedBox(height: 18),
          const Text(
            'Panggilan M8',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Fitur panggilan akan kita aktifkan berikutnya.',
            style: TextStyle(color: m8TextMuted),
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

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 24),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: m8CreamLight,
              child: Icon(Icons.person, size: 52, color: m8Gold),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    pin,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172033),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Center(
          child: Text(
            'Status pengguna',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172033),
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Center(
          child: Text(
            'Online',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: m8Gold,
            ),
          ),
        ),
      ],
    );
  }
}
