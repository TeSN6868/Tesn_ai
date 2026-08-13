import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'm8_call_service.dart';
import 'm8_notification_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await M8NotificationService.initialize();
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
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode({'m8_pin': m8Pin, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

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
            colors: <Color>[m8Navy, m8Navy2, m8Navy],
            stops: <double>[0.0, 0.48, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: <Widget>[
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
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 30,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
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
            headers: <String, String>{'Content-Type': 'application/json'},
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

  final M8CallService _incomingCallService = M8CallService();
  final AudioPlayer _incomingRingtonePlayer = AudioPlayer();

  Future<void> _startIncomingRingtone() async {
    try {
      await _incomingRingtonePlayer.stop();
      await _incomingRingtonePlayer.setReleaseMode(ReleaseMode.loop);
      await _incomingRingtonePlayer.setVolume(1.0);
      await _incomingRingtonePlayer.play(AssetSource('sounds/m8_ringtone.wav'));
      debugPrint('M8 RINGTONE: START');
    } catch (e) {
      debugPrint('M8 RINGTONE ERROR: $e');
    }
  }

  Future<void> _stopIncomingRingtone() async {
    try {
      await _incomingRingtonePlayer.stop();
      debugPrint('M8 RINGTONE: STOP');
    } catch (e) {
      debugPrint('M8 RINGTONE STOP ERROR: $e');
    }
  }

  Timer? _incomingCallTimer;
  String? _lastIncomingCallId;

  @override
  void initState() {
    super.initState();

    _incomingCallTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkIncomingCalls(),
    );

    _checkIncomingCalls();
  }

  Future<void> _checkIncomingCalls() async {
    final calls = await _incomingCallService.getIncomingCalls(pin);

    if (!mounted || calls.isEmpty) return;

    final call = calls.first;
    final incomingId = call['id']?.toString();

    if (incomingId == null || incomingId == _lastIncomingCallId) {
      return;
    }

    _lastIncomingCallId = incomingId;

    final callerPin = call['caller_pin']?.toString() ?? '';

    if (callerPin.isEmpty) return;

    await _startIncomingRingtone();
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Panggilan masuk'),
          content: Text('Ada panggilan masuk dari PIN $callerPin.'),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await _incomingCallService.rejectCall(
                    incomingCallId: incomingId,
                    calleePin: pin,
                  );
                } finally {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(false);
                  }
                }
              },
              child: const Text('Tolak'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Terima'),
            ),
          ],
        );
      },
    );

    await _stopIncomingRingtone();

    if (!mounted || accepted != true) return;

    final callService = M8CallService();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceCallPage(
          myPin: pin,
          otherPin: callerPin,
          call: callService,
          incomingCallId: incomingId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _incomingCallTimer?.cancel();
    _incomingRingtonePlayer.stop();
    _incomingRingtonePlayer.dispose();
    super.dispose();
  }

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
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
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
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.person_outline),
                      SizedBox(width: 12),
                      Text('Profil Saya'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'contacts',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.people_outline),
                      SizedBox(width: 12),
                      Text('Kontak'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.settings_outlined),
                      SizedBox(width: 12),
                      Text('Pengaturan'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'notifications',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.notifications_none),
                      SizedBox(width: 12),
                      Text('Notifikasi'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'appearance',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.palette_outlined),
                      SizedBox(width: 12),
                      Text('Tampilan'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'privacy',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.lock_outline),
                      SizedBox(width: 12),
                      Text('Privasi'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'help',
                  child: Row(
                    children: <Widget>[
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
                    children: <Widget>[
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
        labelTextStyle: const WidgetStatePropertyAll<TextStyle?>(
          TextStyle(color: Color(0xFFEEF3F7), fontWeight: FontWeight.w600),
        ),
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: <Widget>[
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
// SETTINGS
// ============================================================

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AudioPlayer _heyPlayer = AudioPlayer();

  bool soundEnabled = true;
  bool vibrationEnabled = true;

  Future<void> _testHeySound() async {
    try {
      await _heyPlayer.stop();

      await _heyPlayer.setVolume(1.0);
      await _heyPlayer.play(AssetSource('sounds/m8_hey.wav'));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nada HEY gagal diputar: $e')));
    }
  }

  @override
  void dispose() {
    _heyPlayer.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: m8Navy,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: m8CreamLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: m8Navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: m8Navy),
        ),
        title: Text(
          title,
          style: const TextStyle(color: m8Text, fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: const TextStyle(color: m8TextMuted, fontSize: 12.5),
          ),
        ),
        trailing:
            trailing ??
            const Icon(Icons.chevron_right_rounded, color: m8TextMuted),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: m8Cream,
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: m8Navy,
        foregroundColor: m8GoldLight,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _sectionTitle('Notifikasi'),

          Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            color: m8CreamLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: soundEnabled,
                  activeThumbColor: m8Gold,
                  title: const Text(
                    'Suara pesan masuk',
                    style: TextStyle(
                      color: m8Text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Putar nada saat pesan baru diterima',
                    style: TextStyle(color: m8TextMuted),
                  ),
                  secondary: const Icon(
                    Icons.volume_up_outlined,
                    color: m8Navy,
                  ),
                  onChanged: (value) {
                    setState(() {
                      soundEnabled = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: vibrationEnabled,
                  activeThumbColor: m8Gold,
                  title: const Text(
                    'Getar',
                    style: TextStyle(
                      color: m8Text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Getarkan perangkat saat pesan baru diterima',
                    style: TextStyle(color: m8TextMuted),
                  ),
                  secondary: const Icon(
                    Icons.vibration_outlined,
                    color: m8Navy,
                  ),
                  onChanged: (value) {
                    setState(() {
                      vibrationEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _sectionTitle('Nada HEY'),

          Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            color: m8CreamLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  leading: Icon(
                    Icons.notifications_active_outlined,
                    color: m8Navy,
                  ),
                  title: Text(
                    'HEY',
                    style: TextStyle(
                      color: m8Text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Nada khas pesan M8 Messenger',
                    style: TextStyle(color: m8TextMuted),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: soundEnabled ? _testHeySound : null,
                      icon: const Icon(Icons.volume_up_rounded),
                      label: const Text('Tes Nada HEY'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _sectionTitle('Chat'),

          _settingsCard(
            icon: Icons.keyboard_return_rounded,
            title: 'Pengiriman pesan',
            subtitle: 'Atur cara pesan dikirim',
          ),

          _settingsCard(
            icon: Icons.photo_library_outlined,
            title: 'Media',
            subtitle: 'Pengaturan foto dan media chat',
          ),

          _settingsCard(
            icon: Icons.done_all_rounded,
            title: 'Status pesan',
            subtitle: 'Terkirim, diterima, dan dibaca',
          ),

          const SizedBox(height: 18),

          _sectionTitle('Privasi & Keamanan'),

          _settingsCard(
            icon: Icons.lock_outline_rounded,
            title: 'Keamanan',
            subtitle: 'Kelola keamanan akun M8',
          ),

          _settingsCard(
            icon: Icons.block_outlined,
            title: 'Kontak diblokir',
            subtitle: 'Kelola kontak yang diblokir',
          ),

          const SizedBox(height: 18),

          _sectionTitle('Akun'),

          _settingsCard(
            icon: Icons.person_outline_rounded,
            title: 'Profil',
            subtitle: 'Nama dan informasi akun M8',
          ),

          _settingsCard(
            icon: Icons.pin_outlined,
            title: 'M8 PIN',
            subtitle: 'PIN unik untuk terhubung dengan pengguna lain',
          ),

          const SizedBox(height: 18),

          _sectionTitle('Tentang M8'),

          Card(
            elevation: 0,
            color: m8CreamLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Icon(
                Icons.info_outline_rounded,
                color: m8Navy,
                size: 30,
              ),
              title: Text(
                'M8 Messenger',
                style: TextStyle(color: m8Text, fontWeight: FontWeight.w800),
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  'Messenger dengan identitas M8 PIN',
                  style: TextStyle(color: m8TextMuted),
                ),
              ),
            ),
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
  final AudioPlayer _chatHeyPlayer = AudioPlayer();
  bool _chatLoadedOnce = false;
  final Set<String> _heyPlayedMessageIds = <String>{};
  final Set<String> _notificationShownMessageIds = <String>{};

  final controller = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  Timer? typingTimer;
  Timer? typingPollTimer;
  Timer? messagePollTimer;

  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;
  bool otherTyping = false;
  bool _loadingMessagesInProgress = false;
  bool _chatInitializing = true;
  XFile? pendingImage;

  String get chatId => widget.chat['id'].toString();

  String _chatDateLabel(String rawDate) {
    if (rawDate.isEmpty) return '';

    try {
      final millis = int.parse(rawDate);
      final date = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();

      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);
      final messageDay = DateTime(date.year, date.month, date.day);
      final difference = today.difference(messageDay).inDays;

      if (difference == 0) return 'Hari ini';
      if (difference == 1) return 'Kemarin';

      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];

      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }

  void _scrollChatToBottom({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) return;

      final position = _chatScrollController.position.maxScrollExtent;

      if (animated) {
        _chatScrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _chatScrollController.jumpTo(position);
      }

      // Pastikan ListView sudah selesai menghitung semua pesan.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_chatScrollController.hasClients) return;

        final latestPosition = _chatScrollController.position.maxScrollExtent;

        if (_chatScrollController.offset < latestPosition) {
          _chatScrollController.jumpTo(latestPosition);
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeChatStatus();
  }

  Future<void> _initializeChatStatus() async {
    await loadMessages();
    await markMessagesAsDelivered();
    await markMessagesAsRead();

    if (mounted) {
      await loadMessages();

      _chatInitializing = false;

      typingPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted) {
          checkOtherTyping();
        }
      });

      messagePollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted && !_chatInitializing) {
          loadMessages();
        }
      });
    }
  }

  @override
  void dispose() {
    typingTimer?.cancel();
    typingPollTimer?.cancel();
    messagePollTimer?.cancel();
    controller.dispose();
    _chatHeyPlayer.dispose();
    _chatScrollController.dispose();
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

  Future<void> startVideoCall(String other) async {
    final call = M8CallService();

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceCallPage(
          myPin: widget.myPin,
          otherPin: other,
          call: call,
          videoCall: true,
        ),
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

  Future<void> _playChatHey() async {
    try {
      await _chatHeyPlayer.stop();

      await _chatHeyPlayer.setVolume(1.0);

      await _chatHeyPlayer.play(AssetSource('sounds/m8_hey.wav'));

      debugPrint('M8 HEY CHAT: SOUND PLAY');
    } catch (e) {
      debugPrint('M8 HEY CHAT ERROR: $e');
    }
  }

  String _formatChatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String _formatChatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.length >= 16 ? raw.substring(11, 16) : raw;
    }
  }

  Future<void> loadMessages() async {
    if (_loadingMessagesInProgress) return;
    _loadingMessagesInProgress = true;

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

          if (mounted) {
            final loadedMessages = List<Map<String, dynamic>>.from(list ?? []);

            if (_chatLoadedOnce) {
              for (final msg in loadedMessages) {
                final messageId = msg['id']?.toString() ?? '';
                final sender = msg['sender_pin']?.toString() ?? '';
                final message = msg['message']?.toString() ?? '';

                if (messageId.isEmpty) continue;

                if (sender != widget.myPin &&
                    !_notificationShownMessageIds.contains(messageId)) {
                  _notificationShownMessageIds.add(messageId);

                  final notificationMessage = message == '__M8_HI__'
                      ? 'Mengirim HI 👋'
                      : message;

                  debugPrint(
                    'M8 NOTIFICATION: pesan baru dari $sender id=$messageId',
                  );

                  await M8NotificationService.showChatNotification(
                    sender: sender,
                    message: notificationMessage,
                  );
                }

                if (sender != widget.myPin &&
                    message == '__M8_HI__' &&
                    !_heyPlayedMessageIds.contains(messageId)) {
                  _heyPlayedMessageIds.add(messageId);

                  debugPrint('M8 HEY CHAT: HI BARU dari $sender id=$messageId');

                  await _playChatHey();
                }
              }
            } else {
              for (final msg in loadedMessages) {
                final messageId = msg['id']?.toString() ?? '';

                if (messageId.isNotEmpty) {
                  _heyPlayedMessageIds.add(messageId);
                }
              }

              _chatLoadedOnce = true;
            }

            final wasNearBottom =
                !_chatScrollController.hasClients ||
                (_chatScrollController.position.maxScrollExtent -
                        _chatScrollController.offset) <
                    120;

            setState(() {
              messages = loadedMessages;
              loading = false;
            });

            if (wasNearBottom) {
              _scrollChatToBottom();
            }
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
    } finally {
      _loadingMessagesInProgress = false;
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
          final newTyping = data['typing'] == true;

          if (newTyping != otherTyping) {
            setState(() {
              otherTyping = newTyping;
            });
          }
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
          IconButton(
            tooltip: 'Panggilan video',
            onPressed: () => startVideoCall(other),
            icon: const Icon(Icons.videocam_outlined, color: m8Gold),
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
            itemBuilder: (context) => [
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
                      controller: _chatScrollController,
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

                        final statusColor = status == "read"
                            ? const Color(0xFF0E5F91)
                            : const Color(0xFF7A8794);
                        final rawTime = msg["timestamp"]?.toString() ?? "";

                        String time = "";
                        if (rawTime.isNotEmpty) {
                          try {
                            final millis = int.parse(rawTime);
                            final date = DateTime.fromMillisecondsSinceEpoch(
                              millis,
                            ).toLocal();

                            time =
                                '${date.hour.toString().padLeft(2, '0')}:'
                                '${date.minute.toString().padLeft(2, '0')}';
                          } catch (_) {
                            time = "";
                          }
                        }

                        final currentDateLabel = _chatDateLabel(rawTime);
                        final previousDateLabel = index > 0
                            ? _chatDateLabel(
                                messages[index - 1]["timestamp"]?.toString() ??
                                    "",
                              )
                            : "";

                        final showDateSeparator =
                            currentDateLabel.isNotEmpty &&
                            currentDateLabel != previousDateLabel;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showDateSeparator)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: m8CreamLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: m8Gold.withOpacity(0.45),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Text(
                                    currentDateLabel,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: m8TextMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: GestureDetector(
                                onLongPress:
                                    mine &&
                                        !text.startsWith(
                                          "__M8_IMAGE_BASE64__:",
                                        ) &&
                                        !text.startsWith("__M8_IMAGE_URL__:")
                                    ? () => editMessage(msg)
                                    : null,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * .78,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 7),
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    5,
                                    10,
                                    5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mine
                                        ? const Color(0xFFDCE9F4)
                                        : m8CreamLight,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(5),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(
                                        mine ? 16 : 5,
                                      ),
                                      bottomRight: Radius.circular(
                                        mine ? 5 : 16,
                                      ),
                                    ),
                                    border: Border.all(
                                      color: m8Gold,
                                      width: 0.8,
                                    ),
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

                                            return GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  barrierColor: Colors.black87,
                                                  builder: (_) {
                                                    return Scaffold(
                                                      backgroundColor:
                                                          Colors.black,
                                                      appBar: AppBar(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        foregroundColor:
                                                            Colors.white,
                                                        elevation: 0,
                                                      ),
                                                      body: Center(
                                                        child: InteractiveViewer(
                                                          minScale: 1.0,
                                                          maxScale: 4.0,
                                                          child: Image.network(
                                                            imageUrl,
                                                            fit: BoxFit.contain,
                                                            loadingBuilder:
                                                                (
                                                                  context,
                                                                  child,
                                                                  progress,
                                                                ) {
                                                                  if (progress ==
                                                                      null) {
                                                                    return child;
                                                                  }
                                                                  return const SizedBox(
                                                                    width: 42,
                                                                    height: 42,
                                                                    child: CircularProgressIndicator(
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  );
                                                                },
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) {
                                                                  return const Icon(
                                                                    Icons
                                                                        .broken_image_rounded,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 56,
                                                                  );
                                                                },
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.network(
                                                  imageUrl,
                                                  width: 220,
                                                  height: 220,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (
                                                        context,
                                                        child,
                                                        progress,
                                                      ) {
                                                        if (progress == null) {
                                                          return child;
                                                        }
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
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          width: 220,
                                                          height: 120,
                                                          alignment:
                                                              Alignment.center,
                                                          child: const Icon(
                                                            Icons
                                                                .broken_image_rounded,
                                                            size: 36,
                                                          ),
                                                        );
                                                      },
                                                ),
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
                                                  .replaceAll(
                                                    RegExp(r'\s+'),
                                                    '',
                                                  );

                                              final imageBytes = base64Decode(
                                                base64Data,
                                              );

                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.memory(
                                                  imageBytes,
                                                  width: 220,
                                                  height: 220,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
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
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
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
                                                        : const Color(
                                                            0xFF172033,
                                                          ),
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
                                                fontWeight: FontWeight.w900,
                                                color: statusColor,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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

                                      if (image == null || !context.mounted) {
                                        return;
                                      }

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
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          crossAxisCount: 4,
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 8,
                                          childAspectRatio: 0.75,
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
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton.filled(
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
  final bool videoCall;
  final String? incomingCallId;

  const VoiceCallPage({
    super.key,
    required this.myPin,
    required this.otherPin,
    required this.call,
    this.videoCall = false,
    this.incomingCallId,
  });

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  Timer? timer;
  int seconds = 0;

  bool connecting = true;
  bool muted = false;
  bool cameraOff = false;
  bool speakerOn = true;

  String callStatus = 'Menghubungkan...';

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      await widget.call.initializeRenderers();

      if (widget.incomingCallId != null) {
        await widget.call.acceptCall(
          incomingCallId: widget.incomingCallId!,
          calleePin: widget.myPin,
          videoCall: widget.videoCall,
        );
      } else {
        await widget.call.startCall(
          callerPin: widget.myPin,
          calleePin: widget.otherPin,
          videoCall: widget.videoCall,
        );
      }

      if (!mounted) return;

      // Voice Call = audio saja.
      // Video Call = kamera tetap aktif.
      if (!widget.videoCall) {
        final stream = widget.call.localStream;
        for (final track in stream?.getVideoTracks() ?? []) {
          track.enabled = false;
        }
      }

      setState(() {
        connecting = false;
        cameraOff = !widget.videoCall;
        callStatus = widget.videoCall ? 'Video call...' : 'Panggilan suara...';
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

    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  void toggleMute() {
    final stream = widget.call.localStream;
    if (stream == null) return;

    for (final track in stream.getAudioTracks()) {
      track.enabled = !track.enabled;
    }

    setState(() {
      muted = !muted;
    });
  }

  void toggleCamera() {
    final stream = widget.call.localStream;
    if (stream == null) return;

    for (final track in stream.getVideoTracks()) {
      track.enabled = !track.enabled;
    }

    setState(() {
      cameraOff = !cameraOff;
    });
  }

  Future<void> switchCamera() async {
    final stream = widget.call.localStream;
    if (stream == null) return;

    final tracks = stream.getVideoTracks();
    if (tracks.isEmpty) return;

    await Helper.switchCamera(tracks.first);
  }

  Future<void> toggleSpeaker() async {
    final newState = !speakerOn;

    setState(() {
      speakerOn = newState;
    });

    try {
      await Helper.setSpeakerphoneOn(newState);
    } catch (_) {}
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

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: widget.call.remoteRenderer.srcObject != null
                  ? RTCVideoView(
                      widget.call.remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : Container(
                      color: m8Navy,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 52,
                              backgroundColor: m8Gold,
                              child: Icon(
                                Icons.person,
                                size: 55,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'M8 User',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'M8 PIN: ${widget.otherPin}',
                              style: TextStyle(
                                color: m8TextMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              callStatus,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if (connecting) ...[
                              const SizedBox(height: 16),
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: m8Gold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),

            Positioned(
              top: 18,
              left: 18,
              right: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: hangUp,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        callStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!connecting)
                        Text(
                          durationText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            if (widget.call.localRenderer.srcObject != null)
              Positioned(
                top: 82,
                right: 18,
                child: Container(
                  width: 105,
                  height: 145,
                  decoration: BoxDecoration(
                    color: m8Navy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(blurRadius: 14, spreadRadius: 1),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: cameraOff
                      ? const Center(
                          child: Icon(
                            Icons.videocam_off,
                            color: Colors.white,
                            size: 30,
                          ),
                        )
                      : RTCVideoView(
                          widget.call.localRenderer,
                          mirror: true,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                ),
              ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _controlButton(
                        icon: muted ? Icons.mic_off : Icons.mic,
                        label: muted ? 'Nyalakan' : 'Bisukan',
                        onTap: toggleMute,
                        active: !muted,
                      ),
                      _controlButton(
                        icon: speakerOn ? Icons.volume_up : Icons.volume_off,
                        label: 'Speaker',
                        onTap: toggleSpeaker,
                        active: speakerOn,
                      ),
                      _controlButton(
                        icon: cameraOff ? Icons.videocam_off : Icons.videocam,
                        label: 'Kamera',
                        onTap: toggleCamera,
                        active: !cameraOff,
                      ),
                      _controlButton(
                        icon: Icons.flip_camera_ios,
                        label: 'Balik',
                        onTap: switchCamera,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: hangUp,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Akhiri',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
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

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.user, required this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AudioPlayer _heyPlayer = AudioPlayer();

  Future<void> _testHeySound() async {
    try {
      await _heyPlayer.stop();

      await _heyPlayer.setVolume(1.0);

      _heyPlayer.onPlayerStateChanged.listen((state) {
        if (!mounted) return;

        final message = state == PlayerState.playing
            ? '🔊 HEY PLAYING'
            : 'HEY: $state';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      });

      await _heyPlayer.play(AssetSource('sounds/m8_hey.wav'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Nada HEY gagal diputar: $e')));
      }
    }
  }

  @override
  void dispose() {
    _heyPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name']?.toString() ?? 'M8 User';
    final pin = widget.user['m8_pin']?.toString() ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        const SizedBox(height: 8),

        // PROFILE HEADER
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          decoration: BoxDecoration(
            color: m8Navy2,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: m8Gold, width: 1),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                offset: Offset(0, 8),
                color: Color(0x22000000),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: m8Gold, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 52,
                  backgroundColor: m8CreamLight,
                  child: Icon(Icons.person_rounded, size: 58, color: m8Gold),
                ),
              ),

              const SizedBox(height: 15),

              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 7),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: m8GoldLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: m8GoldLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // M8 PIN
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: m8CreamLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: m8Gold, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: m8Navy2,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.key_rounded,
                  color: m8GoldLight,
                  size: 22,
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'M8 PIN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: m8TextMuted,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'PIN identitas akun',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: m8Text,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                pin,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: m8Navy2,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // EDIT PROFILE
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.edit_rounded),
            label: const Text(
              'Edit Profil',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: m8Navy2,
              disabledForegroundColor: m8TextMuted,
              side: const BorderSide(color: m8Gold, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        const SizedBox(height: 18),

        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _testHeySound,
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text(
              'Tes Nada HEY',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: m8Navy2,
              side: const BorderSide(color: m8Gold, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 9),
          child: Text(
            'Akun',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: m8Navy2,
            ),
          ),
        ),

        // LOGOUT
        Container(
          decoration: BoxDecoration(
            color: m8CreamLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2D9C5)),
          ),
          child: ListTile(
            onTap: widget.onLogout,
            leading: const Icon(Icons.logout_rounded, color: m8Gold),
            title: const Text(
              'Keluar',
              style: TextStyle(fontWeight: FontWeight.w800, color: m8Text),
            ),
            subtitle: const Text(
              'Keluar dari akun M8',
              style: TextStyle(fontSize: 12, color: m8TextMuted),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: m8TextMuted,
            ),
          ),
        ),
      ],
    );
  }
}
