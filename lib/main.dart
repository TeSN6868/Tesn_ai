import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'm8_call_service.dart';
import 'm8_notification_service.dart';
import 'm8_voice_service.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

final AudioPlayer _m8CallSoundPlayer = AudioPlayer();

/// ================= M8 CALL SOUNDS =================

Timer? _m8RingingTimer;

Future<void> _m8StartCallRinging() async {
  try {
    _m8RingingTimer?.cancel();
    await _m8CallSoundPlayer.stop();
    await _m8CallSoundPlayer.setReleaseMode(ReleaseMode.release);
    await _m8CallSoundPlayer.setVolume(1.0);

    // Nada sambung telepon sederhana:
    // TUT ... jeda ... TUT ... jeda ...
    await _m8CallSoundPlayer.play(AssetSource('sounds/m8_call_ringing.wav'));

    _m8RingingTimer = Timer.periodic(const Duration(milliseconds: 1800), (
      _,
    ) async {
      try {
        await _m8CallSoundPlayer.play(
          AssetSource('sounds/m8_call_ringing.wav'),
        );
      } catch (e) {
        debugPrint('[M8 CALL SOUND] RING ERROR: $e');
      }
    });

    debugPrint('[M8 CALL SOUND] RINGING START');
  } catch (e) {
    debugPrint('[M8 CALL SOUND] RINGING ERROR: $e');
  }
}

Future<void> _m8StopCallSound() async {
  try {
    _m8RingingTimer?.cancel();
    _m8RingingTimer = null;

    await _m8CallSoundPlayer.stop();
    await _m8CallSoundPlayer.setReleaseMode(ReleaseMode.release);

    debugPrint('[M8 CALL SOUND] RINGING STOP');
  } catch (e) {
    debugPrint('[M8 CALL SOUND] STOP ERROR: $e');
  }
}

Future<void> _m8PlayCallSound(String asset) async {
  try {
    await _m8CallSoundPlayer.stop();
    await _m8CallSoundPlayer.setReleaseMode(ReleaseMode.release);
    await _m8CallSoundPlayer.setVolume(1.0);
    await _m8CallSoundPlayer.play(AssetSource(asset));
    debugPrint('[M8 CALL SOUND] PLAY: $asset');
  } catch (e) {
    debugPrint('[M8 CALL SOUND] PLAY ERROR: $e');
  }
}

Future<void> _m8CallConnectedSound() async {
  await _m8PlayCallSound('sounds/m8_call_connected.wav');
}

Future<void> _m8CallRejectedSound() async {
  await _m8PlayCallSound('sounds/m8_call_rejected.wav');
}

Future<void> _m8CallFailedSound() async {
  await _m8PlayCallSound('sounds/m8_call_failed.wav');
}

Future<void> _m8CallEndedSound() async {
  await _m8PlayCallSound('sounds/m8_call_ended.wav');
}

const String apiBase = 'https://m8-messenger-api.coolalaga686.workers.dev';

const m8Blue = Color(0xFF3D7EEB);
const m8BlueDark = Color(0xFF0B1D2E);
const m8BlueLight = Color(0xFF3D7EEB);

const m8White = Color(0xFFFFFFFF);
const m8WhiteSoft = Color(0xFFF6F8F9);
const bjoChatBackground = Color(0xFFF4F8FC);
const bjoChatBubble = Color(0xFFDCEBFA);
const bjoChatNavy = Color(0xFF12304A);
const bjoPearlWhite = Color(0xFFF8FBFF);


const m8Text = Color(0xFF172331);
const m8TextMuted = Color(0xFF6D7B87);



class _BJoMapPicker extends StatefulWidget {
  final LatLng initialLocation;
  final ValueChanged<LatLng> onSelected;

  const _BJoMapPicker({
    required this.initialLocation,
    required this.onSelected,
  });

  @override
  State<_BJoMapPicker> createState() => _BJoMapPickerState();
}

class _BJoMapPickerState extends State<_BJoMapPicker> {
  late LatLng selectedLocation;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 280,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: selectedLocation,
            initialZoom: 13,
            onTap: (_, point) {
              setState(() {
                selectedLocation = point;
              });

              widget.onSelected(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bjo.messenger',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: selectedLocation,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.location_pin,
                    color: m8Blue,
                    size: 46,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class M8DenimTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base washed blue jeans.
    final basePaint = Paint()..color = m8Blue;
    canvas.drawRect(Offset.zero & size, basePaint);

    // Serat denim diagonal terang.
    final lightThread = Paint()
      ..color = m8BlueLight.withValues(alpha: 0.19)
      ..strokeWidth = 0.85;

    // Serat denim diagonal gelap.
    final darkThread = Paint()
      ..color = m8BlueDark.withValues(alpha: 0.16)
      ..strokeWidth = 0.75;

    const double threadStep = 5.0;

    for (double x = -size.height; x < size.width + size.height; x += 5.0) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        lightThread,
      );

      canvas.drawLine(
        Offset(x + 2.8, 0),
        Offset(x + size.height + 2.8, size.height),
        darkThread,
      );
    }

    // Serat silang sangat tipis.
    final crossThread = Paint()
      ..color = m8White.withValues(alpha: 0.065)
      ..strokeWidth = 0.55;

    for (double y = 0; y < size.height; y += 4.5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 1.5), crossThread);
    }

    // Washed / faded patches.
    final fadePaint = Paint();

    final fades = [
      Rect.fromLTWH(
        size.width * 0.02,
        size.height * 0.06,
        size.width * 0.38,
        size.height * 0.20,
      ),
      Rect.fromLTWH(
        size.width * 0.55,
        size.height * 0.16,
        size.width * 0.42,
        size.height * 0.28,
      ),
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.42,
        size.width * 0.30,
        size.height * 0.25,
      ),
      Rect.fromLTWH(
        size.width * 0.48,
        size.height * 0.55,
        size.width * 0.45,
        size.height * 0.22,
      ),
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.75,
        size.width * 0.48,
        size.height * 0.18,
      ),
    ];

    for (final rect in fades) {
      fadePaint.shader = RadialGradient(
        center: Alignment.center,
        radius: 0.75,
        colors: [
          m8BlueLight.withValues(alpha: 0.19),
          m8BlueLight.withValues(alpha: 0.045),
          m8BlueLight.withValues(alpha: 0.0),
        ],
      ).createShader(rect);

      canvas.drawOval(rect, fadePaint);
    }

    // Area aus yang lebih kecil dan tidak beraturan.
    final wornPaint = Paint();

    final wornAreas = [
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.13,
        size.width * 0.18,
        size.height * 0.055,
      ),
      Rect.fromLTWH(
        size.width * 0.67,
        size.height * 0.38,
        size.width * 0.20,
        size.height * 0.065,
      ),
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.58,
        size.width * 0.25,
        size.height * 0.05,
      ),
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.84,
        size.width * 0.25,
        size.height * 0.055,
      ),
    ];

    for (final rect in wornAreas) {
      wornPaint.shader = RadialGradient(
        radius: 0.9,
        colors: [
          m8White.withValues(alpha: 0.065),
          m8White.withValues(alpha: 0.025),
          m8White.withValues(alpha: 0.0),
        ],
      ).createShader(rect);

      canvas.drawOval(rect, wornPaint);
    }
  }

  @override
  bool shouldRepaint(covariant M8DenimTexturePainter oldDelegate) {
    return false;
  }
}

class M8DenimBackground extends StatelessWidget {
  final Widget child;

  const M8DenimBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: M8DenimTexturePainter(), child: child);
  }
}

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
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: m8Blue,
        colorScheme: const ColorScheme.dark(
          primary: m8Blue,
          secondary: m8BlueLight,
          surface: m8BlueDark,
          onPrimary: m8White,
          onSecondary: m8White,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: m8Blue,
          foregroundColor: m8White,
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

      print('M8 LOGIN DEBUG STATUS: ${response.statusCode}');
      print('M8 LOGIN DEBUG BODY: ${response.body}');
      print('M8 LOGIN DEBUG URL: $apiBase/api/login');

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
            builder: (_) => BJoMainShell(
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[m8Blue, m8BlueDark, m8Blue],
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
                        border: Border.all(color: m8Blue),
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
                            cursorColor: m8BlueDark,
                            controller: pinController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              color: m8BlueDark,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'M8 PIN',
                              hintText: 'Masukkan M8 PIN',
                              labelStyle: const TextStyle(
                                color: m8Text,
                                fontWeight: FontWeight.w600,
                              ),
                              hintStyle: const TextStyle(color: m8TextMuted),
                              prefixIcon: const Icon(
                                Icons.key_rounded,
                                color: Colors.white,
                              ),
                              filled: true,
                              fillColor: m8White,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17),
                                borderSide: BorderSide(
                                  color: m8BlueDark.withValues(alpha: 0.22),
                                ),
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
                            cursorColor: m8BlueDark,
                            controller: passwordController,
                            obscureText: obscurePassword,
                            onSubmitted: (_) => login(),
                            style: const TextStyle(
                              color: m8BlueDark,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: m8BlueDark),
                              floatingLabelStyle: const TextStyle(
                                color: m8BlueDark,
                              ),
                              hintStyle: const TextStyle(color: m8TextMuted),
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
                                  color: m8BlueDark,
                                ),
                              ),
                              filled: true,
                              fillColor: m8White,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17),
                                borderSide: BorderSide(
                                  color: m8BlueDark.withValues(alpha: 0.22),
                                ),
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
                                backgroundColor: m8Blue,
                                foregroundColor: m8White,
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
                                  color: m8Blue,
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
                      style: TextStyle(
                        fontSize: 12,
                        color: m8White.withValues(alpha: 0.72),
                      ),
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
      labelStyle: const TextStyle(color: m8BlueDark),
      prefixIcon: Icon(icon, color: m8Text),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: m8White,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: m8BlueDark.withValues(alpha: 0.22)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: m8Blue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: m8Blue,
      appBar: AppBar(
        backgroundColor: m8Blue,
        foregroundColor: m8White,
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
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: m8Text,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Daftar untuk mulai menggunakan M8 Messenger',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: m8TextMuted),
                  ),

                  const SizedBox(height: 32),

                  TextField(
                    style: const TextStyle(color: m8White),
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: fieldDecoration('Nama', Icons.person_outline),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    style: const TextStyle(color: m8White),
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
                    style: const TextStyle(color: m8White),
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
                    style: const TextStyle(color: m8White),
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
                    style: const TextStyle(color: m8White),
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

// ============================================================
// B'JO MAIN SHELL
// ============================================================

class BJoMainShell extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const BJoMainShell({super.key, required this.token, required this.user});

  @override
  State<BJoMainShell> createState() => _BJoMainShellState();
}

class _BJoMainShellState extends State<BJoMainShell> {
  int currentIndex = 0;

  String get myPin =>
      widget.user['m8_pin']?.toString() ?? widget.user['pin']?.toString() ?? '';

  String get title {
    switch (currentIndex) {
      case 0:
        return "B'Jo Chat";
      case 1:
        return "B'Jo Moments";
      case 2:
        return "B'Jo Grup";
      case 3:
        return "B'Jo Beranda";
      default:
        return "B'Jo";
    }
  }

  Widget page() {
    switch (currentIndex) {
      case 0:
        return ChatsPage(token: widget.token, myPin: myPin);

      case 1:
        return StoryPage(user: widget.user);

      case 2:
        return BJoGroupsPage(token: widget.token, myPin: myPin);

      case 3:
        return BJoBerandaPage(user: widget.user);

      default:
        return ChatsPage(token: widget.token, myPin: myPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: m8WhiteSoft,
      appBar: AppBar(
        backgroundColor: m8Blue,
        foregroundColor: m8White,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: "Profil B'Jo",
            icon: const Icon(Icons.person_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BJoProfilePage(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: m8WhiteSoft,
        child: page(),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: m8Blue,
        indicatorColor: m8BlueDark,
        surfaceTintColor: Colors.transparent,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, color: m8WhiteSoft),
            selectedIcon: Icon(Icons.chat_bubble, color: m8White),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined, color: m8WhiteSoft),
            selectedIcon: Icon(Icons.auto_awesome, color: m8White),
            label: 'Moments',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined, color: m8WhiteSoft),
            selectedIcon: Icon(Icons.groups, color: m8White),
            label: 'Grup',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: m8WhiteSoft),
            selectedIcon: Icon(Icons.dashboard, color: m8White),
            label: 'Beranda',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// B'JO BERANDA
// ============================================================
class BJoBerandaPage extends StatelessWidget {
  final Map<String, dynamic> user;

  const BJoBerandaPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user['name']?.toString().trim();
    final displayName =
        (name == null || name.isEmpty) ? "Pengguna" : name;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        // HEADER
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: m8Blue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: m8Blue.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "B'J",
                  style: TextStyle(
                    color: m8White,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selamat datang",
                    style: TextStyle(
                      color: m8TextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: bjoChatNavy,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: m8White,
                shape: BoxShape.circle,
                border: Border.all(
                  color: m8Blue.withValues(alpha: 0.18),
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: bjoChatNavy,
                size: 21,
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // HERO
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                m8BlueDark,
                bjoChatNavy,
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: m8BlueDark.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "B'Jo",
                      style: TextStyle(
                        color: m8White,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      "Satu ruang untuk komunikasi,\naktivitas, dan kehidupanmu.",
                      style: TextStyle(
                        color: m8White.withValues(alpha: 0.76),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: m8White.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: m8White.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: bjoPearlWhite,
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Private by design",
                            style: TextStyle(
                              color: bjoPearlWhite,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: m8White.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: m8White.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: bjoPearlWhite,
                  size: 30,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const _BJoHomeSectionTitle(
          title: "Produktivitas",
          subtitle: "Atur harimu tanpa keluar dari B'Jo",
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _BJoBerandaCard(
                Icons.calendar_month_rounded,
                "Agenda",
                "Jadwal",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BJoBerandaCard(
                Icons.menu_book_rounded,
                "Jurnal",
                "Catatan",
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        const _BJoHomeSectionTitle(
          title: "Market",
          subtitle: "Pantau pergerakan finansial",
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _BJoBerandaCard(
                Icons.trending_up_rounded,
                "Saham",
                "Pergerakan",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BJoBerandaCard(
                Icons.currency_exchange_rounded,
                "Kurs",
                "Nilai tukar",
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _BJoWideHomeCard(
          icon: Icons.account_balance_wallet_rounded,
          title: "Keuangan",
          subtitle: "Kelola dan pantau keuangan pribadi",
        ),

        const SizedBox(height: 24),

        // PREMIUM
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: m8White,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: m8Blue.withValues(alpha: 0.20),
            ),
            boxShadow: [
              BoxShadow(
                color: m8BlueDark.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: m8Blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: m8BlueDark,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "B'Jo Premium",
                      style: TextStyle(
                        color: bjoChatNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Analitik • Private Vault • Smart Alert",
                      style: TextStyle(
                        color: m8TextMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: m8Blue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: m8BlueDark,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BJoHomeSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BJoHomeSectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: bjoChatNavy,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: m8TextMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _BJoBerandaCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BJoBerandaCard(
    this.icon,
    this.title,
    this.subtitle,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: m8White,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: m8Blue.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: m8BlueDark.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: m8Blue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: m8BlueDark,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: bjoChatNavy,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: m8TextMuted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _BJoWideHomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BJoWideHomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: m8White,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: m8Blue.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: m8BlueDark.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: m8Blue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: m8BlueDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: bjoChatNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: m8TextMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: m8Blue,
            size: 22,
          ),
        ],
      ),
    );
  }
}
// ============================================================

// ============================================================
// B'JO GROUPS PAGE
// ============================================================

class BJoGroupsPage extends StatefulWidget {
  final String token;
  final String myPin;

  const BJoGroupsPage({super.key, required this.token, required this.myPin});

  @override
  State<BJoGroupsPage> createState() => _BJoGroupsPageState();
}

class _BJoGroupsPageState extends State<BJoGroupsPage> {
  bool loading = true;
  List<Map<String, dynamic>> groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$apiBase/api/groups?m8_pin=${Uri.encodeComponent(widget.myPin)}',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil daftar grup.');
      }

      final data = jsonDecode(response.body);
      final list = data['groups'];

      if (list is List) {
        groups = list.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        groups = [];
      }
    } catch (e) {
      debugPrint('BJoGroupsPage error: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat grup: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _openGroup(Map<String, dynamic> group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => M8GroupChatPage(
          token: widget.token,
          myPin: widget.myPin,
          group: group,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: m8White));
    }

    if (groups.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadGroups,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
          children: const [
            Icon(Icons.groups_rounded, size: 78, color: m8White),
            SizedBox(height: 20),
            Text(
              "Belum ada grup",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: m8White,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Grup B'Jo yang kamu ikuti akan muncul di sini.",
              textAlign: TextAlign.center,
              style: TextStyle(color: m8BlueLight, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];

          final name = group['name']?.toString().trim().isNotEmpty == true
              ? group['name'].toString()
              : "Grup B'Jo";

          final description = group['description']?.toString().trim() ?? '';

          final memberCount = group['member_count']?.toString() ?? '0';

          final photoUrl = group['photo_url']?.toString().trim() ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: m8White,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: m8Blue.withValues(alpha: 0.18)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: CircleAvatar(
                radius: 27,
                backgroundColor: m8BlueDark,
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? const Icon(Icons.groups_rounded, color: m8White, size: 28)
                    : null,
              ),
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: m8BlueDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  description.isNotEmpty
                      ? '$memberCount anggota • $description'
                      : '$memberCount anggota',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: m8TextMuted, fontSize: 12),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: m8Blue),
              onTap: () => _openGroup(group),
            ),
          );
        },
      ),
    );
  }
}

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
    try {
      final calls = await _incomingCallService.getIncomingCalls(pin);

      if (!mounted || calls.isEmpty) return;

      final call = calls.first;
      final incomingId = call['id']?.toString();

      if (incomingId == null || incomingId == _lastIncomingCallId) {
        return;
      }

      _lastIncomingCallId = incomingId;

      final callerPin = call['caller_pin']?.toString() ?? '';
      final callType = call['call_type']?.toString() ?? 'voice';
      final isVideoCall = callType == 'video';

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
            videoCall: isVideoCall,
          ),
        ),
      );
    } catch (e) {
      debugPrint('M8 INCOMING CALL ERROR: $e');
    }
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
      backgroundColor: m8WhiteSoft,
      appBar: AppBar(
        backgroundColor: m8Blue,
        foregroundColor: m8White,
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
      body: M8DenimBackground(child: pages[currentIndex]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: m8Blue,
        indicatorColor: m8Blue,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: const WidgetStatePropertyAll<TextStyle?>(
          TextStyle(color: m8WhiteSoft, fontWeight: FontWeight.w600),
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
  final AudioPlayer _ringtonePlayer = AudioPlayer();

  bool soundEnabled = true;
  bool vibrationEnabled = true;

  String selectedRingtone = 'M8 Sound Pack 01';

  static const List<Map<String, String>> ringtonePacks = [
    {'name': 'M8 Sound Pack 01', 'asset': 'sounds/m8_ringtone.wav'},
    {'name': 'M8 Sound Pack 02', 'asset': 'sounds/m8_ringtone_02.wav'},
    {'name': 'M8 Sound Pack 03', 'asset': 'sounds/m8_ringtone_03.wav'},
    {'name': 'M8 Sound Pack 04', 'asset': 'sounds/m8_ringtone_04.wav'},
    {'name': 'M8 Sound Pack 05', 'asset': 'sounds/m8_ringtone_05.wav'},
    {'name': 'M8 Sound Pack 06', 'asset': 'sounds/m8_ringtone_06.wav'},
  ];

  Future<void> _loadRingtonePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('m8_selected_ringtone');

    if (!mounted) return;

    if (saved != null && ringtonePacks.any((pack) => pack['name'] == saved)) {
      setState(() {
        selectedRingtone = saved;
      });
    }
  }

  Future<void> _selectRingtone(String name) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('m8_selected_ringtone', name);

    if (!mounted) return;

    setState(() {
      selectedRingtone = name;
    });
  }

  Future<void> _previewRingtone(String asset) async {
    if (!soundEnabled) return;

    try {
      await _ringtonePlayer.stop();
      await _ringtonePlayer.setVolume(1.0);
      await _ringtonePlayer.play(AssetSource(asset));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nada dering gagal diputar: $e')));
    }
  }

  Future<void> _testHeySound() async {
    try {
      await _heyPlayer.stop();

      await _heyPlayer.setVolume(1.0);
      await _heyPlayer.play(AssetSource('sounds/m8_hey.wav'));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nada Hi! gagal diputar: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRingtonePreference();
  }

  @override
  void dispose() {
    _heyPlayer.dispose();
    _ringtonePlayer.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: m8Blue,
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
      color: m8White,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: m8WhiteSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: m8Blue),
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
      backgroundColor: m8WhiteSoft,
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: m8Blue,
        foregroundColor: m8White,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _sectionTitle('Notifikasi'),

          Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            color: m8White,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: soundEnabled,
                  activeThumbColor: m8Blue,
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
                    color: m8Blue,
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
                  activeThumbColor: m8Blue,
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
                    color: m8Blue,
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

          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.music_note_rounded, color: m8Blue),
            title: const Text(
              'Nada dering M8',
              style: TextStyle(color: m8Text, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              selectedRingtone,
              style: const TextStyle(color: m8TextMuted),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: m8Blue),
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: m8WhiteSoft,
                builder: (context) {
                  return SafeArea(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        const ListTile(
                          title: Text(
                            'Nada Dering M8',
                            style: TextStyle(
                              color: m8Blue,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        ...ringtonePacks.map((pack) {
                          final name = pack['name']!;
                          final asset = pack['asset']!;
                          final selected = selectedRingtone == name;

                          return ListTile(
                            leading: Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected ? m8Blue : m8Blue,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                color: m8Text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.play_circle_outline_rounded,
                                color: m8Blue,
                              ),
                              onPressed: () => _previewRingtone(asset),
                            ),
                            onTap: () async {
                              await _selectRingtone(name);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                          );
                        }),
                        const SizedBox(height: 18),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            color: m8White,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  leading: Icon(
                    Icons.notifications_active_outlined,
                    color: m8Blue,
                  ),
                  title: Text(
                    'HI !',
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
                      label: const Text('Tes Nada Hi!'),
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
            color: m8White,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Icon(
                Icons.info_outline_rounded,
                color: m8Blue,
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
  bool groupsLoading = false;

  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> groups = [];

  int selectedTab = 0;

  Timer? _chatListPollTimer;
  bool _loadingChatsInProgress = false;

  @override
  void initState() {
    super.initState();
    loadMessenger();

    _chatListPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (mounted && !_loadingChatsInProgress) {
          loadChats();
        }
      },
    );
  }

  @override
  void dispose() {
    _chatListPollTimer?.cancel();
    super.dispose();
  }

  Future<void> loadMessenger() async {
    await Future.wait([loadChats(), loadGroups()]);

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> loadChats() async {
    if (_loadingChatsInProgress) return;

    _loadingChatsInProgress = true;

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
      debugPrint('M8 loadChats error: $e');
    } finally {
      _loadingChatsInProgress = false;
    }
  }

  Future<void> loadGroups() async {
    if (mounted) {
      setState(() {
        groupsLoading = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$apiBase/api/groups?m8_pin=${Uri.encodeComponent(widget.myPin)}',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      debugPrint('M8 GROUP GET ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['groups'];

        if (list is List) {
          groups = list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('M8 loadGroups error: $e');
    }

    if (mounted) {
      setState(() {
        groupsLoading = false;
      });
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
            style: const TextStyle(color: m8BlueDark),
            decoration: const InputDecoration(
              labelText: 'M8 PIN tujuan',
              hintText: 'Contoh: TEST0001',
              labelStyle: TextStyle(color: m8BlueDark),
              hintStyle: TextStyle(color: m8TextMuted),
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

      if (mounted) {
        setState(() {
          selectedTab = 1;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat terhubung ke M8')),
      );
    }
  }

  Future<void> createGroup() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final membersController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Grup baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: m8White),
                  controller: nameController,
                  autofocus: true,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Nama grup',
                    hintText: 'Contoh: Keluarga M8',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(color: m8White),
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    hintText: 'Deskripsi grup (opsional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(color: m8White),
                  controller: membersController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'PIN anggota',
                    hintText: 'PIN dipisahkan koma',
                    helperText: 'Kamu otomatis menjadi anggota grup.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BATAL'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.group_add),
              label: const Text('BUAT'),
              onPressed: () {
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'members': membersController.text.trim(),
                });
              },
            ),
          ],
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    membersController.dispose();

    if (result == null || result['name']!.isEmpty) return;

    final members = result['members']!
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    try {
      final response = await http.post(
        Uri.parse('$apiBase/api/groups'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'owner_pin': widget.myPin,
          'name': result['name'],
          'description': result['description'],
          'members': members,
        }),
      );

      debugPrint('M8 CREATE GROUP ${response.statusCode}: ${response.body}');

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grup M8 berhasil dibuat.')),
        );

        await loadGroups();

        if (mounted) {
          setState(() {
            selectedTab = 2;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error']?.toString() ?? 'Gagal membuat grup.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat terhubung ke M8')),
      );
    }
  }

  Future<void> showNewChatMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mulai percakapan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: m8Text,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: m8Blue,
                  child: Icon(Icons.person_add_alt_1, color: m8White),
                ),
                title: const Text('Chat baru'),
                subtitle: const Text('Mulai percakapan pribadi'),
                onTap: () => Navigator.pop(context, 'chat'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: m8Blue,
                  child: Icon(Icons.group_add, color: m8White),
                ),
                title: const Text('Grup baru'),
                subtitle: const Text('Buat percakapan bersama beberapa orang'),
                onTap: () => Navigator.pop(context, 'group'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (action == 'chat') {
      await createChat();
    } else if (action == 'group') {
      await createGroup();
    }
  }

  Widget buildMessengerTabs() {
    const tabs = ['Semua', 'Pribadi', 'Grup'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTab = index;
                });

                if (index == 2) {
                  loadGroups();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: EdgeInsets.only(
                  right: index == tabs.length - 1 ? 0 : 8,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? m8Blue
                      : m8White.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? m8White : m8TextMuted,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget buildEmptyMessenger() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: m8Blue.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32,
                color: m8Blue,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum ada percakapan',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: m8Text,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Mulai percakapan pribadi atau buat grup baru.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: m8TextMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: showNewChatMenu,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Mulai Chat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumAvatar({
    required String name,
    String photoUrl = '',
    bool group = false,
  }) {

    return CircleAvatar(
      radius: 25,
      backgroundColor: m8Blue.withValues(alpha: 0.12),
      backgroundImage:
          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: photoUrl.isEmpty
          ? Icon(
              group
                  ? Icons.groups_rounded
                  : Icons.person_rounded,
              color: m8Blue,
              size: group ? 25 : 23,
            )
          : null,
    );
  }

  Widget _buildPrivateChatTile(
    Map<String, dynamic> chat,
  ) {
    final p1 =
        chat['participant_1_pin']?.toString() ?? '';
    final p2 =
        chat['participant_2_pin']?.toString() ?? '';

    final other = p1 == widget.myPin ? p2 : p1;

    final otherUser = chat['other_user'] is Map
        ? Map<String, dynamic>.from(chat['other_user'])
        : <String, dynamic>{};

    final name =
        otherUser['name']?.toString().trim().isNotEmpty == true
            ? otherUser['name'].toString().trim()
            : other;

    final photo =
        otherUser['profile_photo_url']
                ?.toString()
                .trim() ??
            '';

    final lastMessage =
        chat['last_message']?.toString().trim() ?? '';

    final unreadCount =
        int.tryParse(chat['unread_count']?.toString() ?? '0') ?? 0;

    final lastMessageTime =
        chat['last_message_time']?.toString() ?? '';

    String formatChatTime(String value) {
      if (value.isEmpty) return '';

      final timestamp = int.tryParse(value);
      if (timestamp == null) return '';

      final date = DateTime.fromMillisecondsSinceEpoch(
        timestamp,
      );

      final now = DateTime.now();

      final sameDay =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      if (sameDay) {
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }

      final yesterday = now.subtract(const Duration(days: 1));

      final isYesterday =
          date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day;

      if (isYesterday) {
        return 'Kemarin';
      }

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}';
    }

    final timeText = formatChatTime(lastMessageTime);

    return InkWell(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        child: Row(
          children: [
            _buildPremiumAvatar(
              name: name,
              photoUrl: photo,
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: m8Text,
                            fontSize: 15,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                      ),

                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style: TextStyle(
                            color: unreadCount > 0
                                ? m8Blue
                                : m8TextMuted,
                            fontSize: 11,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage.isNotEmpty
                              ? lastMessage
                              : 'Belum ada pesan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unreadCount > 0
                                ? m8Text
                                : m8TextMuted,
                            fontSize: 12,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),

                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: m8Blue,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount > 99
                                ? '99+'
                                : '$unreadCount',
                            style: const TextStyle(
                              color: m8White,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: m8TextMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupChatTile(
    Map<String, dynamic> group,
  ) {
    final name =
        group['name']?.toString().trim().isNotEmpty == true
            ? group['name'].toString().trim()
            : 'Grup B’Jo';

    final description =
        group['description']?.toString().trim() ?? '';

    final count =
        group['member_count']?.toString() ?? '0';

    final photo =
        group['photo_url']?.toString().trim() ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => M8GroupChatPage(
              token: widget.token,
              myPin: widget.myPin,
              group: group,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        child: Row(
          children: [
            _buildPremiumAvatar(
              name: name,
              photoUrl: photo,
              group: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: m8Text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description.isNotEmpty
                        ? '$count anggota • $description'
                        : '$count anggota',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: m8TextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: m8TextMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPrivateChats() {
    if (chats.isEmpty) {
      return buildEmptyMessenger();
    }

    return RefreshIndicator(
      onRefresh: loadChats,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 90),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          return _buildPrivateChatTile(chats[index]);
        },
      ),
    );
  }

  Widget buildGroupList() {
    if (groupsLoading && groups.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (groups.isEmpty) {
      return buildEmptyMessenger();
    }

    return RefreshIndicator(
      onRefresh: loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 90),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return _buildGroupChatTile(groups[index]);
        },
      ),
    );
  }

  Widget buildAllMessenger() {
    if (chats.isEmpty && groups.isEmpty) {
      return buildEmptyMessenger();
    }

    return RefreshIndicator(
      onRefresh: loadMessenger,
      child: ListView(
        padding: const EdgeInsets.only(
          top: 4,
          bottom: 90,
        ),
        children: [
          if (chats.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                10,
                18,
                4,
              ),
              child: Text(
                'Percakapan',
                style: TextStyle(
                  color: m8TextMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            ...chats.map(_buildPrivateChatTile),
          ],
          if (groups.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                4,
              ),
              child: Text(
                'Grup',
                style: TextStyle(
                  color: m8TextMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            ...groups.map(_buildGroupChatTile),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildMessengerTabs(),
        Expanded(
          child: Stack(
            children: [
              if (loading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (selectedTab == 0)
                buildAllMessenger()
              else if (selectedTab == 1)
                buildPrivateChats()
              else
                buildGroupList(),

              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton(
                  onPressed: showNewChatMenu,
                  child: const Icon(
                    Icons.add_comment_rounded,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CHAT ROOM
// ============================================================

// ============================================================
// M8 GROUP CHAT
// ============================================================

class M8GroupChatPage extends StatefulWidget {
  final String token;
  final String myPin;
  final Map<String, dynamic> group;

  const M8GroupChatPage({
    super.key,
    required this.token,
    required this.myPin,
    required this.group,
  });

  @override
  State<M8GroupChatPage> createState() => _M8GroupChatPageState();
}

class _M8GroupInfoPage extends StatelessWidget {
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> members;
  final Future<void> Function() onAddMember;
  final VoidCallback onEditName;

  const _M8GroupInfoPage({
    required this.group,
    required this.members,
    required this.onAddMember,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    final name = group['name']?.toString().trim().isNotEmpty == true
        ? group['name'].toString().trim()
        : 'Grup M8';

    final description = group['description']?.toString().trim() ?? '';

    final photoUrl = group['photo_url']?.toString().trim() ?? '';

    return Scaffold(
      backgroundColor: m8WhiteSoft,
      appBar: AppBar(
        backgroundColor: m8BlueDark,
        foregroundColor: m8White,
        elevation: 0,
        title: const Text(
          'Info Grup',
          style: TextStyle(color: m8White, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit nama grup',
            onPressed: onEditName,
            icon: const Icon(Icons.edit_rounded, color: m8White),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
            decoration: const BoxDecoration(
              color: m8BlueDark,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: m8Blue,
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? const Icon(
                          Icons.groups_rounded,
                          color: m8White,
                          size: 52,
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: m8White,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${members.length} anggota',
                  style: TextStyle(
                    color: m8White.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: m8White.withValues(alpha: 0.88),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: m8White,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: m8Blue,
                child: Icon(Icons.person_add_alt_1_rounded, color: m8White),
              ),
              title: const Text(
                'Tambah anggota',
                style: TextStyle(color: m8Text, fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Tambahkan pengguna menggunakan PIN M8',
                style: TextStyle(color: m8TextMuted, fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: m8Blue),
              onTap: onAddMember,
            ),
          ),

          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Text(
              'ANGGOTA GRUP (${members.length})',
              style: const TextStyle(
                color: m8TextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: m8White,
              borderRadius: BorderRadius.circular(18),
            ),
            child: members.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Belum ada anggota.',
                        style: TextStyle(color: m8TextMuted),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: m8Blue.withValues(alpha: 0.08),
                    ),
                    itemBuilder: (context, index) {
                      final member = members[index];

                      final pin = member['member_pin']?.toString() ?? '';

                      final memberName =
                          member['name']?.toString().trim().isNotEmpty == true
                          ? member['name'].toString().trim()
                          : pin;

                      final role = member['role']?.toString() ?? 'member';

                      final memberPhoto =
                          member['profile_photo_url']?.toString().trim() ?? '';

                      final isOwner = role == 'owner';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: m8Blue,
                          backgroundImage: memberPhoto.isNotEmpty
                              ? NetworkImage(memberPhoto)
                              : null,
                          child: memberPhoto.isEmpty
                              ? Text(
                                  memberName.isNotEmpty
                                      ? memberName
                                            .substring(
                                              0,
                                              memberName.length > 2
                                                  ? 2
                                                  : memberName.length,
                                            )
                                            .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: m8White,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : null,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                memberName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: m8Text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (isOwner) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                size: 17,
                                color: m8Blue,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          isOwner ? 'Pemilik grup • $pin' : 'Anggota • $pin',
                          style: const TextStyle(
                            color: m8TextMuted,
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _M8GroupChatPageState extends State<M8GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool loading = true;
  bool sending = false;

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> members = [];

  int get groupId => int.tryParse(widget.group['id']?.toString() ?? '') ?? 0;

  String get groupName =>
      widget.group['name']?.toString().trim().isNotEmpty == true
      ? widget.group['name'].toString().trim()
      : 'Grup M8';

  @override
  void initState() {
    super.initState();
    loadGroup();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadGroup() async {
    await Future.wait([loadGroupMessages(), loadGroupMembers()]);

    if (mounted) {
      setState(() {
        loading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> loadGroupMessages() async {
    if (groupId <= 0) return;

    try {
      final response = await http.get(
        Uri.parse(
          '$apiBase/api/group-messages'
          '?group_id=$groupId'
          '&m8_pin=${Uri.encodeComponent(widget.myPin)}',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode != 200) {
        debugPrint(
          'M8 group messages ${response.statusCode}: ${response.body}',
        );
        return;
      }

      final data = jsonDecode(response.body);
      final list = data['messages'];

      if (list is List && mounted) {
        setState(() {
          messages = list.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('M8 loadGroupMessages error: $e');
    }
  }

  Future<void> loadGroupMembers() async {
    if (groupId <= 0) return;

    try {
      final response = await http.get(
        Uri.parse(
          '$apiBase/api/groups/members'
          '?group_id=$groupId'
          '&m8_pin=${Uri.encodeComponent(widget.myPin)}',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode != 200) {
        debugPrint('M8 group members ${response.statusCode}: ${response.body}');
        return;
      }

      final data = jsonDecode(response.body);
      final list = data['members'];

      if (list is List && mounted) {
        setState(() {
          members = list.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('M8 loadGroupMembers error: $e');
    }
  }

  Future<void> sendGroupMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || sending || groupId <= 0) {
      return;
    }

    setState(() {
      sending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBase/api/group-messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'group_id': groupId,
          'sender_pin': widget.myPin,
          'message': text,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _messageController.clear();

        await loadGroupMessages();
        _scrollToBottom();
      } else {
        debugPrint(
          'M8 send group message ${response.statusCode}: '
          '${response.body}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pesan gagal dikirim: ${response.body}')),
          );
        }
      }
    } catch (e) {
      debugPrint('M8 sendGroupMessage error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat terhubung ke M8')),
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _memberName(String pin) {
    for (final member in members) {
      if (member['member_pin']?.toString() == pin) {
        final name = member['name']?.toString().trim();

        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    }

    return pin;
  }

  String _formatTime(dynamic value) {
    final timestamp = int.tryParse(value?.toString() ?? '');

    if (timestamp == null) return '';

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> _addGroupMember() async {
    final controller = TextEditingController();

    final pin = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Tambah Anggota',
            style: TextStyle(color: m8Text, fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            cursorColor: m8White,
            style: const TextStyle(color: m8White, fontWeight: FontWeight.w700),
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              labelText: 'PIN M8',
              hintText: 'Masukkan PIN M8',
              labelStyle: const TextStyle(
                color: m8White,
                fontWeight: FontWeight.w700,
              ),
              hintStyle: TextStyle(color: m8White.withValues(alpha: 0.65)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: m8Blue),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('BATAL'),
            ),
            FilledButton.icon(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('LANJUT'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (pin == null || pin.isEmpty || !mounted) return;

    try {
      final response = await http.post(
        Uri.parse('$apiBase/api/groups/members'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'group_id': groupId,
          'requester_pin': widget.myPin,
          'member_pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      final success =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? m8BlueDark : Colors.red.shade700,
          content: Text(
            success
                ? (data['message']?.toString() ??
                      'Anggota berhasil ditambahkan.')
                : (data['error']?.toString() ??
                      'PIN M8 anggota tidak ditemukan.'),
            style: const TextStyle(color: m8White, fontWeight: FontWeight.w700),
          ),
        ),
      );

      if (success) {
        await loadGroupMembers();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Tidak dapat terhubung ke M8.',
            style: TextStyle(color: m8White, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
  }

  Future<void> _editGroupName() async {
    final controller = TextEditingController(
      text: widget.group['name']?.toString() ?? '',
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: m8White,
          title: const Text(
            'Edit Nama Grup',
            style: TextStyle(color: m8Text, fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 80,
            style: const TextStyle(color: m8Text),
            decoration: const InputDecoration(
              labelText: 'Nama grup',
              hintText: 'Masukkan nama grup',
              labelStyle: TextStyle(color: m8TextMuted),
              hintStyle: TextStyle(color: m8TextMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('BATAL'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: const Text('SIMPAN'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null || newName.trim().isEmpty || !mounted) {
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('$apiBase/api/groups'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'group_id': groupId,
          'requester_pin': widget.myPin,
          'name': newName.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true) {
        setState(() {
          widget.group['name'] = newName.trim();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: m8BlueDark,
            content: Text(
              'Nama grup berhasil diperbarui.',
              style: TextStyle(color: m8White, fontWeight: FontWeight.w700),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
              data['error']?.toString() ?? 'Gagal mengubah nama grup.',
              style: const TextStyle(
                color: m8White,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Tidak dapat terhubung ke M8.',
            style: TextStyle(color: m8White, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
  }

  Future<void> _showMembers() async {
    await loadGroupMembers();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _M8GroupInfoPage(
          group: widget.group,
          members: members,
          onAddMember: _addGroupMember,
          onEditName: _editGroupName,
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final sender = message['sender_pin']?.toString() ?? '';

    final mine = sender == widget.myPin;

    final text = message['message']?.toString() ?? '';

    final senderName = mine ? 'Kamu' : _memberName(sender);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            padding: const EdgeInsets.fromLTRB(13, 9, 13, 7),
            decoration: BoxDecoration(
              color: mine ? bjoChatBubble : bjoChatBubble,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(mine ? 16 : 4),
                bottomRight: Radius.circular(mine ? 4 : 16),
              ),
              border: mine
                  ? null
                  : Border.all(color: m8Blue.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!mine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      senderName,
                      style: const TextStyle(
                        color: m8Blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Text(
                  text,
                  style: TextStyle(
                    color: bjoChatNavy,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatTime(message['timestamp']),
                    style: TextStyle(
                      color: mine
                          ? m8White.withValues(alpha: 0.72)
                          : m8TextMuted,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bjoChatBackground,
      appBar: AppBar(
        backgroundColor: m8BlueDark,
        foregroundColor: m8Text,
        elevation: 0,
        titleSpacing: 0,
        title: InkWell(
          onTap: _showMembers,
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: m8Blue,
                backgroundImage:
                    widget.group['photo_url']?.toString().isNotEmpty == true
                    ? NetworkImage(widget.group['photo_url'].toString())
                    : null,
                child: widget.group['photo_url']?.toString().isNotEmpty == true
                    ? null
                    : const Icon(Icons.groups_rounded, color: m8White),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: bjoPearlWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${members.length} anggota',
                      style: TextStyle(
                      color: bjoPearlWhite.withValues(alpha: 0.72),
                      fontSize: 10,
                    ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Anggota',
            onPressed: _showMembers,
            icon: const Icon(Icons.groups_outlined, color: m8Blue),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: bjoChatBackground,
              child: RefreshIndicator(
                onRefresh: loadGroup,
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: m8Blue,
                        ),
                      )
                    : messages.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 180),
                              Icon(
                                Icons.forum_outlined,
                                size: 64,
                                color: m8Blue,
                              ),
                              SizedBox(height: 16),
                              Center(
                                child: Text(
                                  'Belum ada pesan',
                                  style: TextStyle(
                                    color: m8Text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              SizedBox(height: 6),
                              Center(
                                child: Text(
                                  'Mulai percakapan di grup ini.',
                                  style: TextStyle(
                                    color: m8TextMuted,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              return _buildMessage(messages[index]);
                            },
                          ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
              decoration: BoxDecoration(
                color: m8White,
                border: Border(
                  top: BorderSide(color: m8Blue.withValues(alpha: 0.10)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Lampiran',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: sending
                        ? null
                        : () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: m8White,
                              showDragHandle: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (sheetContext) {
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
                                            'Lampiran',
                                            style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w800,
                                              color: m8Text,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        GridView.count(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          crossAxisCount: 3,
                                          mainAxisSpacing: 16,
                                          crossAxisSpacing: 14,
                                          childAspectRatio: 0.92,
                                          children: [
                                            _AttachmentItem(
                                              icon: Icons.camera_alt_rounded,
                                              label: 'Kamera',
                                              onTap: () {
                                                Navigator.pop(sheetContext);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Kamera grup akan diaktifkan berikutnya.',
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            _AttachmentItem(
                                              icon: Icons.photo_library_rounded,
                                              label: 'Gambar',
                                              onTap: () {
                                                Navigator.pop(sheetContext);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Gambar grup akan diaktifkan berikutnya.',
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            _AttachmentItem(
                                              icon: Icons
                                                  .insert_drive_file_rounded,
                                              label: 'File',
                                              onTap: () {
                                                Navigator.pop(sheetContext);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'File grup akan diaktifkan berikutnya.',
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            _AttachmentItem(
                                              icon: Icons.location_on_rounded,
                                              label: 'Lokasi',
                                              onTap: () {
                                                Navigator.pop(sheetContext);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Lokasi grup akan diaktifkan berikutnya.',
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            _AttachmentItem(
                                              icon: Icons.music_note_rounded,
                                              label: 'Musik',
                                              onTap: () {
                                                Navigator.pop(sheetContext);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Musik grup akan diaktifkan berikutnya.',
                                                    ),
                                                  ),
                                                );
                                              },
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
                      Icons.add_circle_outline_rounded,
                      color: m8Blue,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: m8Text, fontSize: 15),
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan ke grup...',
                        hintStyle: const TextStyle(color: m8TextMuted),
                        filled: true,
                        fillColor: m8WhiteSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                      ),
                      onSubmitted: (_) {
                        if (!sending) {
                          sendGroupMessage();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 3),
                  FloatingActionButton(
                    mini: true,
                    elevation: 0,
                    backgroundColor: m8Blue,
                    foregroundColor: m8White,
                    onPressed: sending ? null : sendGroupMessage,
                    child: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: m8White,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class M8GamelanWallpaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Wallpaper Sage M8: teduh tetapi tetap hidup.
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bg);

    final line = Paint()
      ..color = m8Blue.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = const Color(0xFF3D7EEB).withValues(alpha: 0.065)
      ..style = PaintingStyle.fill;

    // Motif kecil-kecil dan cukup rapat seperti wallpaper messenger.
    const cellW = 72.0;
    const cellH = 66.0;

    for (int row = -1; row < (size.height / cellH).ceil() + 1; row++) {
      for (int col = -1; col < (size.width / cellW).ceil() + 1; col++) {
        final x = col * cellW + (row.isEven ? 4 : 36);
        final y = row * cellH + 4;

        canvas.save();
        canvas.translate(x, y);
        canvas.scale(0.75, 0.75);

        switch ((row * 3 + col).abs() % 5) {
          case 0:
            _gong(canvas, line, fill);
            break;
          case 1:
            _kendang(canvas, line, fill);
            break;
          case 2:
            _saron(canvas, line, fill);
            break;
          case 3:
            _bonang(canvas, line, fill);
            break;
          default:
            _siter(canvas, line, fill);
            break;
        }

        canvas.restore();
      }
    }
  }

  // Gong kecil.
  void _gong(Canvas c, Paint line, Paint fill) {
    final oval = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 10, 30, 24),
      const Radius.circular(15),
    );

    c.drawRRect(oval, fill);
    c.drawRRect(oval, line);
    c.drawCircle(const Offset(23, 22), 4, line);
    c.drawCircle(const Offset(23, 22), 1.4, line);

    c.drawLine(const Offset(11, 34), const Offset(7, 39), line);
    c.drawLine(const Offset(35, 34), const Offset(39, 39), line);
    c.drawLine(const Offset(7, 39), const Offset(39, 39), line);
  }

  // Kendang kecil.
  void _kendang(Canvas c, Paint line, Paint fill) {
    final path = Path()
      ..moveTo(10, 12)
      ..lineTo(34, 12)
      ..lineTo(31, 32)
      ..lineTo(13, 32)
      ..close();

    c.drawPath(path, fill);
    c.drawPath(path, line);

    c.drawOval(const Rect.fromLTWH(7, 8, 30, 8), line);
    c.drawOval(const Rect.fromLTWH(9, 28, 26, 8), line);

    c.drawLine(const Offset(14, 15), const Offset(17, 29), line);
    c.drawLine(const Offset(20, 15), const Offset(21, 29), line);
    c.drawLine(const Offset(26, 15), const Offset(25, 29), line);
    c.drawLine(const Offset(32, 15), const Offset(29, 29), line);
  }

  // Saron kecil.
  void _saron(Canvas c, Paint line, Paint fill) {
    final base = RRect.fromRectAndRadius(
      const Rect.fromLTWH(6, 27, 34, 7),
      const Radius.circular(2),
    );

    c.drawRRect(base, fill);
    c.drawRRect(base, line);

    for (int i = 0; i < 6; i++) {
      final x = 8.0 + i * 5.2;
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 11 + (i.isEven ? 0 : 2), 4.2, 17),
        const Radius.circular(1.5),
      );
      c.drawRRect(bar, fill);
      c.drawRRect(bar, line);
    }

    c.drawLine(const Offset(10, 38), const Offset(35, 38), line);
  }

  // Bonang kecil.
  void _bonang(Canvas c, Paint line, Paint fill) {
    for (int i = 0; i < 3; i++) {
      final x = 9.0 + i * 11;
      c.drawOval(Rect.fromLTWH(x, 13, 9, 7), fill);
      c.drawOval(Rect.fromLTWH(x, 13, 9, 7), line);
      c.drawCircle(Offset(x + 4.5, 16.5), 1.4, line);
    }

    c.drawLine(const Offset(7, 22), const Offset(39, 22), line);
    c.drawLine(const Offset(9, 22), const Offset(9, 31), line);
    c.drawLine(const Offset(37, 22), const Offset(37, 31), line);
    c.drawLine(const Offset(9, 31), const Offset(37, 31), line);
  }

  // Siter kecil.
  void _siter(Canvas c, Paint line, Paint fill) {
    final body = Path()
      ..moveTo(6, 27)
      ..lineTo(39, 27)
      ..lineTo(34, 34)
      ..lineTo(11, 34)
      ..close();

    c.drawPath(body, fill);
    c.drawPath(body, line);

    c.drawLine(const Offset(10, 10), const Offset(36, 10), line);
    c.drawLine(const Offset(10, 14), const Offset(36, 14), line);
    c.drawLine(const Offset(10, 18), const Offset(36, 18), line);
    c.drawLine(const Offset(10, 22), const Offset(36, 22), line);

    for (int i = 0; i < 7; i++) {
      final x = 11.0 + i * 4.0;
      c.drawLine(Offset(x, 10), Offset(x + 3, 27), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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

  // B'Jo Voice Message
  final M8VoiceService _voiceService = M8VoiceService();
  bool _isRecordingVoice = false;
  DateTime? _voiceRecordingStartedAt;
  Timer? _voiceRecordingTimer;
  int _voiceRecordingSeconds = 0;

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

  Future<void> startVoiceRecording() async {
    if (_isRecordingVoice || sending) return;

    try {
      final allowed = await _voiceService.hasPermission();

      if (!allowed) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin mikrofon belum diberikan.'),
          ),
        );
        return;
      }

      final directory = await getTemporaryDirectory();

      final filePath =
          '${directory.path}/bjo_voice_${DateTime.now().microsecondsSinceEpoch}.m4a';

      await _voiceService.start(filePath);

      if (!mounted) return;

      setState(() {
        _isRecordingVoice = true;
        _voiceRecordingStartedAt = DateTime.now();
        _voiceRecordingSeconds = 0;
      });

      _voiceRecordingTimer?.cancel();
      _voiceRecordingTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (!mounted || !_isRecordingVoice) return;

          final started = _voiceRecordingStartedAt;

          if (started == null) return;

          setState(() {
            _voiceRecordingSeconds =
                DateTime.now().difference(started).inSeconds;
          });
        },
      );
    } catch (e) {
      debugPrint('[BJO VOICE] START ERROR: $e');

      _voiceRecordingTimer?.cancel();
      _voiceRecordingTimer = null;

      if (mounted) {
        setState(() {
          _isRecordingVoice = false;
          _voiceRecordingStartedAt = null;
          _voiceRecordingSeconds = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulai rekaman suara: $e'),
          ),
        );
      }
    }
  }

  Future<String?> stopVoiceRecording() async {
    if (!_isRecordingVoice) return null;

    try {
      _voiceRecordingTimer?.cancel();
      _voiceRecordingTimer = null;

      final path = await _voiceService.stop();

      if (mounted) {
        setState(() {
          _isRecordingVoice = false;
          _voiceRecordingStartedAt = null;
        });
      }

      if (!_voiceService.fileExists(path)) {
        throw Exception('File rekaman tidak ditemukan.');
      }

      debugPrint('[BJO VOICE] RECORDING READY: $path');

      return path;
    } catch (e) {
      debugPrint('[BJO VOICE] STOP ERROR: $e');

      if (mounted) {
        setState(() {
          _isRecordingVoice = false;
          _voiceRecordingStartedAt = null;
          _voiceRecordingSeconds = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghentikan rekaman: $e'),
          ),
        );
      }

      return null;
    }
  }

  Future<void> cancelVoiceRecording() async {
    if (!_isRecordingVoice) return;

    try {
      _voiceRecordingTimer?.cancel();
      _voiceRecordingTimer = null;

      await _voiceService.cancel();

      if (mounted) {
        setState(() {
          _isRecordingVoice = false;
          _voiceRecordingStartedAt = null;
          _voiceRecordingSeconds = 0;
        });
      }
    } catch (e) {
      debugPrint('[BJO VOICE] CANCEL ERROR: $e');
    }
  }

  String _formatVoiceDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = null;

    typingTimer?.cancel();
    typingPollTimer?.cancel();
    messagePollTimer?.cancel();

    controller.dispose();
    _chatHeyPlayer.dispose();
    _chatScrollController.dispose();
    _voiceService.dispose();

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
            style: const TextStyle(color: m8BlueDark),
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

    final rawOtherUser = widget.chat["other_user"];
    final otherUser = rawOtherUser is Map
        ? Map<String, dynamic>.from(rawOtherUser)
        : <String, dynamic>{};

    final otherName = otherUser["name"]?.toString().trim().isNotEmpty == true
        ? otherUser["name"].toString().trim()
        : "M8 User";

    final otherPhotoUrl =
        otherUser["profile_photo_url"]?.toString().trim() ?? "";

    final otherPin = otherUser["m8_pin"]?.toString().trim().isNotEmpty == true
        ? otherUser["m8_pin"].toString().trim()
        : other;

    debugPrint("M8 CHAT HEADER otherUser = $otherUser");
    debugPrint("M8 CHAT HEADER name = $otherName");
    debugPrint("M8 CHAT HEADER pin = $otherPin");
    debugPrint("M8 CHAT HEADER photo = $otherPhotoUrl");

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: m8Blue,
        foregroundColor: m8White,
        elevation: 0,
        toolbarHeight: 74,
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: m8BlueDark,
                  backgroundImage: otherPhotoUrl.isNotEmpty
                      ? NetworkImage(otherPhotoUrl)
                      : null,
                  child: otherPhotoUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: m8Blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: m8Text, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "M8 PIN: $otherPin",
                      style: const TextStyle(fontSize: 11, color: m8White),
                    ),
                    const Text(
                      "Online",
                      style: TextStyle(fontSize: 10, color: m8WhiteSoft),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => startVoiceCall(other),
            icon: const Icon(Icons.call_outlined, color: m8White),
          ),
          IconButton(
            tooltip: 'Panggilan video',
            onPressed: () => startVideoCall(other),
            icon: const Icon(Icons.videocam_outlined, color: m8White),
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
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: M8GamelanWallpaperPainter()),
          ),
          Container(
            color: Colors.transparent,
            child: Column(
              children: [
                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(color: m8Blue),
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
                                ? m8Blue
                                : const Color(0xFF071A2E);
                            final rawTime = msg["timestamp"]?.toString() ?? "";

                            String time = "";
                            if (rawTime.isNotEmpty) {
                              try {
                                final millis = int.parse(rawTime);
                                final date =
                                    DateTime.fromMillisecondsSinceEpoch(
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
                                    messages[index - 1]["timestamp"]
                                            ?.toString() ??
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
                                        color: m8White,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: m8Blue.withOpacity(0.45),
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
                                            !text.startsWith(
                                              "__M8_IMAGE_URL__:",
                                            )
                                        ? () => editMessage(msg)
                                        : null,
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            .78,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 7),
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        1,
                                        8,
                                        1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: mine
                                            ? const Color(0xFFF2EEE4)
                                            : m8White,
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
                                          color: m8Blue,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (text.startsWith(
                                            "__M8_IMAGE_URL__:",
                                          ))
                                            Builder(
                                              builder: (context) {
                                                final imageUrl = text
                                                    .substring(
                                                      "__M8_IMAGE_URL__:"
                                                          .length,
                                                    )
                                                    .trim();

                                                return GestureDetector(
                                                  onTap: () {
                                                    showDialog(
                                                      context: context,
                                                      barrierColor:
                                                          Colors.black87,
                                                      builder: (_) {
                                                        return Scaffold(
                                                          backgroundColor:
                                                              Colors.black,
                                                          appBar: AppBar(
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
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
                                                                fit: BoxFit
                                                                    .contain,
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
                                                                        width:
                                                                            42,
                                                                        height:
                                                                            42,
                                                                        child: CircularProgressIndicator(
                                                                          color:
                                                                              Colors.white,
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
                                                                        size:
                                                                            56,
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
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
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
                                                            if (progress ==
                                                                null) {
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
                                                                  Alignment
                                                                      .center,
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
                                                  final payload = text
                                                      .substring(
                                                        "__M8_IMAGE_BASE64__:"
                                                            .length,
                                                      );

                                                  final separator = payload
                                                      .indexOf(":");

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

                                                  final imageBytes =
                                                      base64Decode(base64Data);

                                                  return ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
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
                                                                  Alignment
                                                                      .center,
                                                              color: mine
                                                                  ? m8BlueDark
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
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: mine
                                                          ? m8Blue
                                                          : m8White,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      "Gambar gagal dibaca\\n${e.toString()}",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: mine
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF1C2820,
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
                                                      ? const Color(0xFF071A2E)
                                                      : m8Text,
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
                                                      ? const Color(0xFF071A2E)
                                                      : m8Text,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 1),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                time,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: mine
                                                      ? const Color(0xFF071A2E)
                                                      : m8TextMuted,
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
                      color: m8White,
                      border: Border(
                        top: BorderSide(color: m8Blue, width: 0.8),
                      ),
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
                                  borderRadius: BorderRadius.circular(18),
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
                                        color: m8BlueDark,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 15,
                                        color: m8White,
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

                                      if (label == "Kamera" ||
                                          label == "Galeri") {
                                        try {
                                          final picker = ImagePicker();
                                          final image = await picker.pickImage(
                                            source: label == "Kamera"
                                                ? ImageSource.camera
                                                : ImageSource.gallery,
                                            imageQuality: 85,
                                          );

                                          if (image == null ||
                                              !context.mounted) {
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

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                                  color: m8Text,
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
                                                  icon:
                                                      Icons.camera_alt_rounded,
                                                  label: "Kamera",
                                                  onTap: () => selectAttachment(
                                                    "Kamera",
                                                  ),
                                                ),
                                                _AttachmentItem(
                                                  icon: Icons
                                                      .photo_library_rounded,
                                                  label: "Galeri",
                                                  onTap: () => selectAttachment(
                                                    "Galeri",
                                                  ),
                                                ),
                                                _AttachmentItem(
                                                  icon: Icons
                                                      .insert_drive_file_rounded,
                                                  label: "Dokumen",
                                                  onTap: () => selectAttachment(
                                                    "Dokumen",
                                                  ),
                                                ),
                                                _AttachmentItem(
                                                  icon:
                                                      Icons.location_on_rounded,
                                                  label: "Lokasi",
                                                  onTap: () => selectAttachment(
                                                    "Lokasi",
                                                  ),
                                                ),
                                                _AttachmentItem(
                                                  icon: Icons.person_rounded,
                                                  label: "Kontak M8",
                                                  onTap: () => selectAttachment(
                                                    "Kontak M8",
                                                  ),
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
                                color: m8Blue,
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
                                  color: m8White,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Tulis pesan...",
                                  hintStyle: TextStyle(color: m8TextMuted),
                                  filled: true,
                                  fillColor: m8WhiteSoft,
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
                                foregroundColor: m8BlueDark,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 9,
                                ),
                                minimumSize: const Size(0, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                  side: const BorderSide(
                                    color: m8Blue,
                                    width: 1,
                                  ),
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

                            if (_isRecordingVoice)
                              Expanded(
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: m8WhiteSoft,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: m8Blue.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.fiber_manual_record_rounded,
                                        color: m8Blue,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        _formatVoiceDuration(
                                          _voiceRecordingSeconds,
                                        ),
                                        style: const TextStyle(
                                          color: m8Text,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: cancelVoiceRecording,
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: m8TextMuted,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () async {
                                          final path =
                                              await stopVoiceRecording();

                                          if (path != null && mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Rekaman suara siap dikirim.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Icon(
                                          Icons.stop_circle_rounded,
                                          color: m8Blue,
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else ...[
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onLongPressStart: (_) {
                                    startVoiceRecording();
                                  },
                                  onLongPressEnd: (_) async {
                                    if (_isRecordingVoice) {
                                      final path =
                                          await stopVoiceRecording();

                                      if (path != null && mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Rekaman suara siap dikirim.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: m8WhiteSoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.mic_rounded,
                                      color: m8Blue,
                                      size: 21,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: IconButton.filled(
                                  onPressed:
                                      sending ? null : sendMessage,
                                  style: IconButton.styleFrom(
                                    backgroundColor: m8Blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: sending
                                      ? const SizedBox(
                                          width: 19,
                                          height: 19,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send_rounded,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      color: m8WhiteSoft,
      padding: const EdgeInsets.fromLTRB(12, 10, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'M8 STORY',
              style: TextStyle(
                color: m8BlueDark,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ),
          SizedBox(
            height: 76,
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
                const _M8StoryMiniCard(
                  title: 'Moments',
                  subtitle: 'Lihat Moments',
                ),
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 68,
        height: 68,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isMine ? m8BlueDark : m8White,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: m8Blue.withValues(alpha: 0.7), width: 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isMine ? m8Blue : m8BlueDark,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                isMine ? Icons.add_rounded : Icons.auto_awesome_rounded,
                size: 18,
                color: isMine ? m8White : m8BlueLight,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isMine ? m8White : m8BlueDark,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const StoryPage({super.key, required this.user});

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  bool loading = true;
  bool posting = false;
  List<Map<String, dynamic>> posts = [];

  String get myPin =>
      widget.user['m8_pin']?.toString() ?? widget.user['pin']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      if (myPin.isEmpty) {
        throw Exception("B'Jo PIN tidak ditemukan.");
      }

      final response = await http
          .get(
            Uri.parse(
              '$apiBase/api/stories?m8_pin=${Uri.encodeComponent(myPin)}',
            ),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error']?.toString() ?? 'Gagal mengambil feed.');
      }

      final raw = data['stories'];

      final result = <Map<String, dynamic>>[];

      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            result.add(Map<String, dynamic>.from(item));
          }
        }
      }

      if (!mounted) return;

      setState(() {
        posts = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Feed belum dapat dimuat: $e")));
    }
  }

  Future<void> _openComposer() async {
    final textController = TextEditingController();

    XFile? selectedMedia;
    String? mediaType;
    LatLng? selectedLocation;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> chooseImage() async {
              final picker = ImagePicker();

              final file = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 90,
                maxWidth: 1600,
                maxHeight: 1600,
              );

              if (file != null) {
                setSheetState(() {
                  selectedMedia = file;
                  mediaType = 'image';
                });
              }
            }

            Future<void> chooseVideo() async {
              final picker = ImagePicker();

              final file = await picker.pickVideo(source: ImageSource.gallery);

              if (file != null) {
                setSheetState(() {
                  selectedMedia = file;
                  mediaType = 'video';
                });
              }
            }

            Future<void> chooseLocation() async {
              LatLng pickedLocation =
                  selectedLocation ??
                  const LatLng(-6.9175, 107.6191);

              final result = await showModalBottomSheet<LatLng>(
                context: sheetContext,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (mapContext) {
                  return StatefulBuilder(
                    builder: (context, setMapState) {
                      return SafeArea(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: m8White,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(26),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Pilih Lokasi',
                                    style: TextStyle(
                                      color: m8BlueDark,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.pop(mapContext),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Sentuh peta untuk memilih lokasi.',
                                style: TextStyle(
                                  color: m8TextMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _BJoMapPicker(
                                initialLocation: pickedLocation,
                                onSelected: (point) {
                                  pickedLocation = point;
                                  setMapState(() {});
                                },
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => Navigator.pop(
                                    mapContext,
                                    pickedLocation,
                                  ),
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text('Gunakan Lokasi Ini'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );

              if (result != null) {
                setSheetState(() {
                  selectedLocation = result;
                });
              }
            }

            return SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 18,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                decoration: const BoxDecoration(
                  color: m8White,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Buat Posting",
                          style: TextStyle(
                            color: m8BlueDark,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: textController,
                      maxLines: 6,
                      maxLength: 5000,
                      decoration: InputDecoration(
                        hintText: "Bagikan sesuatu yang berarti…",
                        filled: true,
                        fillColor: m8WhiteSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (selectedMedia != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            if (mediaType == 'image')
                              Image.file(
                                File(selectedMedia!.path),
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                              )
                            else
                              Container(
                                width: double.infinity,
                                height: 220,
                                color: m8BlueDark,
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: m8White,
                                    size: 64,
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Material(
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  onPressed: () {
                                    setSheetState(() {
                                      selectedMedia = null;
                                      mediaType = null;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: m8White,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (selectedLocation != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: m8WhiteSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: m8Blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lokasi dipilih: '
                                '${selectedLocation!.latitude.toStringAsFixed(5)}, '
                                '${selectedLocation!.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  color: m8BlueDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setSheetState(() {
                                  selectedLocation = null;
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: chooseImage,
                          icon: const Icon(Icons.photo_rounded),
                          label: const Text("Foto"),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: chooseVideo,
                          icon: const Icon(Icons.videocam_rounded),
                          label: const Text("Video"),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: chooseLocation,
                          icon: const Icon(Icons.location_on_rounded),
                          label: const Text("Lokasi"),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () async {
                            final text = textController.text.trim();

                            if (text.isEmpty && selectedMedia == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Tulis sesuatu atau pilih foto/video.",
                                  ),
                                ),
                              );
                              return;
                            }

                            Navigator.pop(sheetContext);

                            await _publishPost(
                              text: text,
                              media: selectedMedia,
                              mediaType: mediaType,
                              latitude: selectedLocation?.latitude,
                              longitude: selectedLocation?.longitude,
                            );
                          },
                          child: const Text("Posting"),
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
    );

    textController.dispose();
  }

  Future<void> _publishPost({
    required String text,
    required XFile? media,
    required String? mediaType,
    double? latitude,
    double? longitude,
  }) async {
    if (posting) return;

    try {
      setState(() {
        posting = true;
      });

      String mediaUrl = '';
      String type = 'text';

      if (media != null && mediaType != null) {
        final bytes = await media.readAsBytes();

        if (bytes.isEmpty) {
          throw Exception("File media kosong.");
        }

        if (bytes.length > 25 * 1024 * 1024) {
          throw Exception("Ukuran media maksimal 25 MB.");
        }

        final extension = media.name.contains('.')
            ? media.name.split('.').last.toLowerCase()
            : mediaType == 'video'
            ? 'mp4'
            : 'jpg';

        final contentType = mediaType == 'video'
            ? switch (extension) {
                'webm' => 'video/webm',
                'mov' => 'video/quicktime',
                _ => 'video/mp4',
              }
            : switch (extension) {
                'png' => 'image/png',
                'webp' => 'image/webp',
                _ => 'image/jpeg',
              };

        final uploadResponse = await http
            .post(
              Uri.parse('$apiBase/api/upload'),
              headers: {'Content-Type': contentType},
              body: bytes,
            )
            .timeout(const Duration(seconds: 60));

        final uploadData = jsonDecode(uploadResponse.body);

        if (uploadResponse.statusCode != 201 || uploadData['success'] != true) {
          throw Exception(
            uploadData['error']?.toString() ?? "Upload media gagal.",
          );
        }

        mediaUrl = uploadData['url']?.toString() ?? '';

        if (mediaUrl.isEmpty) {
          throw Exception("Server tidak memberikan URL media.");
        }

        type = mediaType;
      }

      final response = await http
          .post(
            Uri.parse('$apiBase/api/stories'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'm8_pin': myPin,
              'media_url': mediaUrl,
              'media_type': type,
              'caption': text,
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode != 201 || data['success'] != true) {
        throw Exception(data['error']?.toString() ?? "Posting gagal.");
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Posting berhasil dibagikan.")),
      );

      await _loadPosts();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal membuat posting: $e")));
    } finally {
      if (mounted) {
        setState(() {
          posting = false;
        });
      }
    }
  }

  String _timeAgo(dynamic value) {
    final timestamp = int.tryParse(value?.toString() ?? '');

    if (timestamp == null) return '';

    final created = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    final difference = DateTime.now().difference(created);

    if (difference.inSeconds < 60) {
      return "baru saja";
    }

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} m";
    }

    if (difference.inHours < 24) {
      return "${difference.inHours} j";
    }

    if (difference.inDays < 7) {
      return "${difference.inDays} h";
    }

    return "${created.day}/${created.month}/${created.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: m8WhiteSoft,
      floatingActionButton: FloatingActionButton(
        backgroundColor: m8Blue,
        foregroundColor: m8White,
        onPressed: posting ? null : _openComposer,
        child: posting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: m8White,
                ),
              )
            : const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                itemCount: posts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _BJoComposerCard(
                      user: widget.user,
                      onTap: posting ? null : _openComposer,
                    );
                  }

                  final post = posts[index - 1];

                  return _BJoPostCard(
                    post: post,
                    currentPin: myPin,
                    timeAgo: _timeAgo(post['created_at']),
                  );
                },
              ),
      ),
    );
  }
}

class _BJoComposerCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onTap;

  const _BJoComposerCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = user['name']?.toString().trim().isNotEmpty == true
        ? user['name'].toString()
        : "Pengguna B'Jo";

    final photo = user['profile_photo_url']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: m8White,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: m8BlueDark,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty
                ? const Icon(Icons.person_rounded, color: m8White)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: m8WhiteSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  "Apa yang ingin kamu bagikan?",
                  style: TextStyle(color: m8TextMuted, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BJoPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String currentPin;
  final String timeAgo;

  const _BJoPostCard({
    required this.post,
    required this.currentPin,
    required this.timeAgo,
  });

  @override
  State<_BJoPostCard> createState() => _BJoPostCardState();
}

class _BJoPostCardState extends State<_BJoPostCard> {
  bool _working = false;

  late bool liked;
  late int likeCount;
  late int viewCount;

  String get storyId => widget.post['story_id']?.toString().trim() ?? '';

  String get ownerPin => widget.post['user_pin']?.toString().trim() ?? '';

  bool get isOwner =>
      widget.currentPin.isNotEmpty && widget.currentPin == ownerPin;

  @override
  void initState() {
    super.initState();

    liked = _toBool(widget.post['liked']);

    likeCount = int.tryParse(widget.post['like_count']?.toString() ?? '0') ?? 0;

    viewCount = int.tryParse(widget.post['view_count']?.toString() ?? '0') ?? 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().toLowerCase().trim();

    return text == 'true' || text == '1';
  }

  Future<void> _toggleLike() async {
    if (_working || storyId.isEmpty || widget.currentPin.isEmpty) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$apiBase/api/stories/love'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'story_id': storyId,
              'm8_pin': widget.currentPin,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error']?.toString() ?? 'Gagal mengubah Suka.');
      }

      if (!mounted) return;

      setState(() {
        liked = data['liked'] == true;
        likeCount = int.tryParse(data['like_count']?.toString() ?? '0') ?? 0;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah Suka: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _recordView() async {
    if (storyId.isEmpty || widget.currentPin.isEmpty) {
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$apiBase/api/stories/view'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'story_id': storyId,
              'm8_pin': widget.currentPin,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;

        setState(() {
          viewCount =
              int.tryParse(data['view_count']?.toString() ?? '0') ?? viewCount;
        });
      }
    } catch (e) {
      debugPrint('BJO MOMENT VIEW ERROR: $e');
    }
  }

  Future<void> _openMedia() async {
    if (storyId.isEmpty) return;

    await _recordView();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _M8StoryViewer(
          stories: [Map<String, dynamic>.from(widget.post)],
          initialIndex: 0,
        ),
      ),
    );
  }

  Future<void> _deletePost() async {
    if (!isOwner || _working || storyId.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Moment?'),
          content: const Text(
            'Moment ini akan dihapus dari feed B’Jo. '
            'Data Love dan penonton juga akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _working = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$apiBase/api/stories/delete'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'story_id': storyId,
              'm8_pin': widget.currentPin,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error']?.toString() ?? 'Gagal menghapus Moment.');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Moment berhasil dihapus.')));

      setState(() {
        widget.post['is_active'] = 0;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus Moment: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _showViewers() async {
    if (!isOwner || storyId.isEmpty) return;

    try {
      final uri = Uri.parse(
        '$apiBase/api/stories/viewers'
        '?story_id=${Uri.encodeComponent(storyId)}'
        '&m8_pin=${Uri.encodeComponent(widget.currentPin)}',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(
          data['error']?.toString() ?? 'Gagal mengambil penonton.',
        );
      }

      final raw = data['viewers'];

      final viewers = <Map<String, dynamic>>[];

      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            viewers.add(Map<String, dynamic>.from(item));
          }
        }
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        backgroundColor: m8White,
        builder: (sheetContext) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.55,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      children: [
                        Icon(Icons.visibility_rounded, color: m8Blue),
                        SizedBox(width: 8),
                        Text(
                          'Yang Melihat Moment',
                          style: TextStyle(
                            color: m8BlueDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: viewers.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada yang melihat Moment ini.',
                              style: TextStyle(color: m8TextMuted),
                            ),
                          )
                        : ListView.builder(
                            itemCount: viewers.length,
                            itemBuilder: (_, index) {
                              final viewer = viewers[index];

                              final name = viewer['viewer_name']
                                  ?.toString()
                                  .trim();

                              final pin =
                                  viewer['viewer_pin']?.toString().trim() ?? '';

                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: m8BlueDark,
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: m8White,
                                  ),
                                ),
                                title: Text(
                                  name?.isNotEmpty == true
                                      ? name!
                                      : 'Pengguna B’Jo',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  '@$pin',
                                  style: const TextStyle(color: m8TextMuted),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil daftar penonton: $e')),
      );
    }
  }

  Future<void> _showMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: m8White,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.visibility_rounded, color: m8Blue),
                  title: const Text('Lihat Penonton'),
                  subtitle: Text('$viewCount orang'),
                  onTap: () {
                    Navigator.pop(sheetContext, 'viewers');
                  },
                ),
              if (isOwner)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: const Text('Hapus Moment'),
                  onTap: () {
                    Navigator.pop(sheetContext, 'delete');
                  },
                ),
              if (!isOwner)
                const ListTile(
                  leading: Icon(Icons.flag_outlined),
                  title: Text('Laporkan'),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (action == 'viewers') {
      await _showViewers();
    } else if (action == 'delete') {
      await _deletePost();
    }
  }

  Future<void> _openPostLocation(
    double latitude,
    double longitude,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (mapContext) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.72,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            decoration: const BoxDecoration(
              color: m8White,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: m8Blue,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Lokasi Moment',
                      style: TextStyle(
                        color: m8BlueDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(mapContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          latitude,
                          longitude,
                        ),
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.bjo.messenger',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                latitude,
                                longitude,
                              ),
                              width: 56,
                              height: 56,
                              child: const Icon(
                                Icons.location_pin,
                                color: m8Blue,
                                size: 52,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${latitude.toStringAsFixed(5)}, '
                  '${longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    color: m8TextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    final name = post['user_name']?.toString().trim().isNotEmpty == true
        ? post['user_name'].toString()
        : "Pengguna B'Jo";

    final pin = post['user_pin']?.toString() ?? '';
    final type = post['media_type']?.toString() ?? 'text';
    final text = post['caption']?.toString().trim() ?? '';
    final mediaUrl = post['media_url']?.toString().trim() ?? '';

    final latitude = double.tryParse(
      post['latitude']?.toString() ?? '',
    );

    final longitude = double.tryParse(
      post['longitude']?.toString() ?? '',
    );

    final hasLocation =
        latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;

    if (post['is_active']?.toString() == '0') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: m8White,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: m8BlueDark,
                backgroundImage:
                    post['user_photo_url']?.toString().trim().isNotEmpty == true
                        ? NetworkImage(
                            post['user_photo_url'].toString().trim(),
                          )
                        : null,
                child:
                    post['user_photo_url']?.toString().trim().isNotEmpty == true
                        ? null
                        : const Icon(
                            Icons.person_rounded,
                            color: m8White,
                          ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: m8BlueDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "@$pin",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: m8TextMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "• ${widget.timeAgo}",
                      style: const TextStyle(color: m8TextMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _working ? null : _showMenu,
                icon: const Icon(Icons.more_horiz_rounded, color: m8TextMuted),
              ),
            ],
          ),

          if (text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                color: m8BlueDark,
                fontSize: 16,
                height: 1.35,
              ),
            ),
          ],

          if (hasLocation) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _openPostLocation(
                latitude!,
                longitude!,
              ),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: m8WhiteSoft,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: m8Blue.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: m8Blue.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: m8Blue,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokasi Moment',
                            style: TextStyle(
                              color: m8BlueDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ketuk untuk melihat di peta',
                            style: TextStyle(
                              color: m8TextMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: m8TextMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (type == 'image' && mediaUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _openMedia,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 230,
                  child: Image.network(
                    mediaUrl,
                    width: double.infinity,
                    height: 230,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        height: 230,
                        color: m8WhiteSoft,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_rounded,
                          size: 42,
                          color: m8TextMuted,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],

          if (type == 'video' && mediaUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _openMedia,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: m8BlueDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_fill_rounded,
                      color: m8White,
                      size: 64,
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: m8White,
                              size: 14,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Putar',
                              style: TextStyle(
                                color: m8White,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          Row(
            children: [
              Text(
                '$likeCount Suka',
                style: const TextStyle(color: m8TextMuted, fontSize: 12),
              ),
              const Spacer(),
              InkWell(
                onTap: isOwner ? _showViewers : null,
                child: Text(
                  '$viewCount dilihat',
                  style: TextStyle(
                    color: isOwner ? m8Blue : m8TextMuted,
                    fontSize: 12,
                    fontWeight: isOwner ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          const Divider(height: 1),

          Row(
            children: [
              Expanded(
                child: _BJoPostAction(
                  icon: liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: liked ? 'Suka $likeCount' : 'Suka',
                  onTap: _working ? () {} : _toggleLike,
                  active: liked,
                ),
              ),
              Expanded(
                child: _BJoPostAction(
                  icon: Icons.repeat_rounded,
                  label: "Bagikan",
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BJoPostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _BJoPostAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: active ? m8Blue : m8TextMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? m8Blue : m8TextMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _M8LiveStoryCard extends StatelessWidget {
  final Map<String, dynamic> story;
  final VoidCallback onTap;

  const _M8LiveStoryCard({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = story['user_name']?.toString().trim().isNotEmpty == true
        ? story['user_name'].toString()
        : 'Pengguna M8';

    final type = story['media_type']?.toString() ?? 'image';
    final url = story['media_url']?.toString().trim() ?? '';
    final caption = story['caption']?.toString().trim() ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: m8White,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: m8Blue.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 62,
                height: 62,
                child: type == 'image' && url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: m8BlueDark,
                            child: const Icon(
                              Icons.broken_image_rounded,
                              color: m8BlueLight,
                              size: 30,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: m8BlueDark,
                        child: Icon(
                          type == 'video'
                              ? Icons.videocam_rounded
                              : Icons.photo_rounded,
                          color: m8BlueLight,
                          size: 30,
                        ),
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
                      color: m8BlueDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    caption.isEmpty
                        ? type == 'video'
                              ? 'Video Moment'
                              : 'Foto Moment'
                        : caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: m8TextMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: m8Blue),
          ],
        ),
      ),
    );
  }
}

class _M8StoryViewer extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;

  const _M8StoryViewer({required this.stories, required this.initialIndex});

  @override
  State<_M8StoryViewer> createState() => _M8StoryViewerState();
}

class _M8StoryViewerState extends State<_M8StoryViewer> {
  late int index;

  VideoPlayerController? _videoController;
  bool _videoLoading = false;
  bool _videoMuted = false;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    _prepareVideo();
  }

  Future<void> _prepareVideo() async {
    await _disposeVideoController();

    if (!mounted) return;

    final story = widget.stories[index];
    final type = story['media_type']?.toString() ?? 'image';
    final url = story['media_url']?.toString().trim() ?? '';

    if (type != 'video' || url.isEmpty) {
      setState(() {
        _videoLoading = false;
      });
      return;
    }

    setState(() {
      _videoLoading = true;
      _videoMuted = false;
    });

    debugPrint('BJO MOMENT VIDEO URL: $url');
    debugPrint('BJO MOMENT VIDEO TYPE: $type');

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: const {'Accept': 'video/mp4,video/webm,video/*,*/*'},
    );

    try {
      debugPrint('BJO MOMENT VIDEO: initialize mulai...');
      await controller.initialize();
      debugPrint(
        'BJO MOMENT VIDEO: initialize berhasil '
        'duration=${controller.value.duration} '
        'size=${controller.value.size} '
        'aspect=${controller.value.aspectRatio}',
      );

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.setVolume(1.0);

      setState(() {
        _videoController = controller;
        _videoLoading = false;
      });

      await controller.play();
    } catch (e, stack) {
      debugPrint('================================================');
      debugPrint('BJO MOMENT VIDEO ERROR');
      debugPrint('URL: $url');
      debugPrint('TYPE: $type');
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stack');
      debugPrint('================================================');

      await controller.dispose();

      if (!mounted) return;

      setState(() {
        _videoController = null;
        _videoLoading = false;
      });
    }
  }

  Future<void> _disposeVideoController() async {
    final controller = _videoController;
    _videoController = null;

    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _next() async {
    if (index >= widget.stories.length - 1) {
      await _disposeVideoController();

      if (mounted) {
        Navigator.pop(context);
      }

      return;
    }

    setState(() {
      index++;
    });

    await _prepareVideo();
  }

  Future<void> _previous() async {
    if (index <= 0) return;

    setState(() {
      index--;
    });

    await _prepareVideo();
  }

  Future<void> _toggleVideoPlayback() async {
    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleVideoMute() async {
    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final muted = !_videoMuted;

    await controller.setVolume(muted ? 0.0 : 1.0);

    if (mounted) {
      setState(() {
        _videoMuted = muted;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _videoController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[index];

    final name = story['user_name']?.toString() ?? 'Pengguna M8';

    final url = story['media_url']?.toString() ?? '';

    final type = story['media_type']?.toString() ?? 'image';

    final caption = story['caption']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (type == 'image')
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (_, error, ___) {
                          debugPrint('M8 STORY IMAGE ERROR: $error');

                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.white,
                                  size: 70,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Foto Moment tidak dapat dimuat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text(
                          'URL foto Moment kosong',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              )
            else
              Center(
                child: _videoLoading
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 42,
                            height: 42,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Memuat video...',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      )
                    : _videoController != null &&
                          _videoController!.value.isInitialized
                    ? GestureDetector(
                        onTap: _toggleVideoPlayback,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                            if (!_videoController!.value.isPlaying)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 54,
                                ),
                              ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.white,
                            size: 70,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Video tidak dapat diputar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
              ),

            if (_videoController != null &&
                _videoController!.value.isInitialized)
              Positioned(
                right: 18,
                bottom: caption.trim().isNotEmpty ? 100 : 24,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: _toggleVideoPlayback,
                        color: Colors.white,
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: _toggleVideoMute,
                        color: Colors.white,
                        icon: Icon(
                          _videoMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: m8Blue,
                    child: Icon(Icons.person_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              top: 80,
              bottom: 80,
              width: 90,
              child: GestureDetector(onTap: _previous),
            ),

            Positioned(
              right: 0,
              top: 80,
              bottom: 80,
              width: 90,
              child: GestureDetector(onTap: _next),
            ),

            if (caption.trim().isNotEmpty)
              Positioned(
                left: 18,
                right: 18,
                bottom: 28,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// B'JO PROFILE
// ============================================================

class BJoProfilePage extends StatelessWidget {
  final Map<String, dynamic> user;

  const BJoProfilePage({super.key, required this.user});

  String get name => user['name']?.toString().trim().isNotEmpty == true
      ? user['name'].toString()
      : "Pengguna B'Jo";

  String get pin => user['m8_pin']?.toString() ?? user['pin']?.toString() ?? '';

  void _comingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title akan diaktifkan berikutnya.')),
    );
  }

  Widget _securityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: m8White,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: m8Blue.withValues(alpha: 0.16)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: m8BlueDark,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: m8White),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: m8BlueDark,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: m8TextMuted, fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: m8Blue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return M8DenimBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          // HEADER PROFIL
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: m8BlueDark,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: m8BlueLight.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: m8White,
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'B',
                    style: const TextStyle(
                      color: m8BlueDark,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: m8White,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        pin.isEmpty
                            ? "PIN B'Jo belum tersedia"
                            : "PIN B'Jo • $pin",
                        style: const TextStyle(
                          color: m8BlueLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'KEAMANAN',
            style: TextStyle(
              color: m8White,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 10),

          _securityItem(
            context,
            icon: Icons.pin_rounded,
            title: "PIN B'Jo",
            subtitle: 'Kelola PIN akun B’Jo',
            onTap: () => _comingSoon(context, "PIN B'Jo"),
          ),

          _securityItem(
            context,
            icon: Icons.devices_rounded,
            title: 'Otorisasi perangkat',
            subtitle: 'Kelola perangkat yang dipercaya',
            onTap: () => _comingSoon(context, 'Otorisasi perangkat'),
          ),

          _securityItem(
            context,
            icon: Icons.phonelink_lock_rounded,
            title: 'Sesi aktif',
            subtitle: 'Lihat perangkat yang sedang login',
            onTap: () => _comingSoon(context, 'Sesi aktif'),
          ),

          _securityItem(
            context,
            icon: Icons.verified_user_rounded,
            title: 'Verifikasi server',
            subtitle: 'Periksa status koneksi dan server B’Jo',
            onTap: () => _comingSoon(context, 'Verifikasi server'),
          ),

          _securityItem(
            context,
            icon: Icons.lock_rounded,
            title: 'Kunci aplikasi',
            subtitle: 'Lindungi aplikasi dengan penguncian',
            onTap: () => _comingSoon(context, 'Kunci aplikasi'),
          ),

          _securityItem(
            context,
            icon: Icons.lock_person_rounded,
            title: 'Private Vault',
            subtitle: 'Ruang pribadi untuk data sensitif',
            onTap: () => _comingSoon(context, 'Private Vault'),
          ),

          _securityItem(
            context,
            icon: Icons.login_rounded,
            title: 'Login perangkat baru',
            subtitle: 'Tambahkan perangkat baru secara aman',
            onTap: () => _comingSoon(context, 'Login perangkat baru'),
          ),

          const SizedBox(height: 8),

          _securityItem(
            context,
            icon: Icons.logout_rounded,
            title: 'Logout semua perangkat',
            subtitle: 'Keluar dari seluruh sesi B’Jo',
            onTap: () => _comingSoon(context, 'Logout semua perangkat'),
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
      await _heyPlayer.play(AssetSource('sounds/m8_hey.wav'));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nada Hi! gagal diputar: $e')));
    }
  }

  void _copyPin(String pin) {
    Clipboard.setData(ClipboardData(text: pin));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('M8 PIN berhasil disalin'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _changeProfilePhoto() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('Foto kosong.');
      }

      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('Foto terlalu besar. Maksimal 5 MB.');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mengupload foto profil...'),
          duration: Duration(seconds: 2),
        ),
      );

      final extension = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : 'jpg';

      final contentType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };

      final uploadResponse = await http
          .post(
            Uri.parse('$apiBase/api/upload'),
            headers: {'Content-Type': contentType},
            body: bytes,
          )
          .timeout(const Duration(seconds: 30));

      final uploadData = jsonDecode(uploadResponse.body);

      if (uploadResponse.statusCode != 201 || uploadData['success'] != true) {
        throw Exception(
          uploadData['error']?.toString() ?? 'Gagal mengupload foto.',
        );
      }

      final photoUrl = uploadData['url']?.toString();

      if (photoUrl == null || photoUrl.isEmpty) {
        throw Exception('URL foto tidak diterima server.');
      }

      final userId = widget.user['id'];

      print('M8 PHOTO DEBUG user = ${widget.user}');
      print('M8 PHOTO DEBUG userId = $userId');
      print('M8 PHOTO DEBUG userIdType = ${userId.runtimeType}');

      if (userId == null) {
        throw Exception('ID akun M8 tidak tersedia.');
      }

      final saveResponse = await http
          .post(
            Uri.parse('$apiBase/api/profile/photo'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId, 'photo_url': photoUrl}),
          )
          .timeout(const Duration(seconds: 20));

      final saveData = jsonDecode(saveResponse.body);

      if (saveResponse.statusCode != 200 || saveData['success'] != true) {
        throw Exception(
          saveData['error']?.toString() ?? 'Gagal menyimpan foto profil.',
        );
      }

      widget.user['profile_photo_url'] = photoUrl;

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil diperbarui.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengganti foto profil: $e')),
      );
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(
      text: widget.user['name']?.toString() ?? '',
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Nama'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 50,
            style: const TextStyle(
              color: m8BlueDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: m8Blue,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama M8',
              hintText: 'Masukkan nama kamu',
              labelStyle: TextStyle(color: m8TextMuted),
              hintStyle: TextStyle(color: m8TextMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama minimal 2 karakter.')),
                  );
                  return;
                }

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null || newName.trim().isEmpty) return;

    final pin = widget.user['m8_pin']?.toString() ?? '';

    if (pin.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('M8 PIN tidak tersedia.')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiBase/api/profile/name'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'m8_pin': pin, 'name': newName.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final updatedUser = data['user'];

        if (updatedUser is Map) {
          widget.user['name'] = updatedUser['name'];
        } else {
          widget.user['name'] = newName.trim();
        }

        if (!mounted) return;

        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama berhasil diperbarui.')),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error']?.toString() ?? 'Gagal memperbarui nama.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui nama: $e')));
    }
  }

  void _comingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title segera hadir di M8.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: m8BlueDark,
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool danger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: m8White,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: danger
              ? Colors.red.withValues(alpha: 0.10)
              : m8Blue.withValues(alpha: 0.08),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: danger
                ? Colors.red.withValues(alpha: 0.07)
                : m8Blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: danger ? Colors.red : m8Blue),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: danger ? Colors.red : m8Text,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: m8TextMuted, fontSize: 12),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: danger ? Colors.red : m8TextMuted,
        ),
        onTap: onTap,
      ),
    );
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

    return Container(
      color: m8WhiteSoft,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: BoxDecoration(
              color: m8BlueDark,
              borderRadius: BorderRadius.circular(26),
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
                    border: Border.all(color: m8Blue, width: 2),
                  ),
                  child: GestureDetector(
                    onTap: _changeProfilePhoto,
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: m8White,
                      backgroundImage:
                          (widget.user['profile_photo_url']
                                  ?.toString()
                                  .isNotEmpty ??
                              false)
                          ? NetworkImage(
                              widget.user['profile_photo_url'].toString(),
                            )
                          : const AssetImage('assets/m8_icon-final.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: _changeProfilePhoto,
                  child: const Text(
                    'Ganti Foto',
                    style: TextStyle(
                      color: m8BlueLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: m8BlueLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: m8BlueLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Terhubung melalui M8 Messenger',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: m8White,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: m8Blue.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: m8BlueDark,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.pin_rounded, color: m8BlueLight),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'M8 PIN',
                        style: TextStyle(
                          fontSize: 12,
                          color: m8TextMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pin.isEmpty ? 'Belum tersedia' : pin,
                        style: const TextStyle(
                          fontSize: 17,
                          color: m8BlueDark,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Salin M8 PIN',
                  onPressed: pin.isEmpty ? null : () => _copyPin(pin),
                  icon: const Icon(Icons.copy_rounded, color: m8Blue),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _sectionTitle('Profil Saya'),

          _menuItem(
            icon: Icons.person_outline_rounded,
            title: 'Nama',
            subtitle: name,
            onTap: _editName,
          ),

          _menuItem(
            icon: Icons.photo_camera_outlined,
            title: 'Foto Profil',
            subtitle: 'Atur foto profil M8 kamu',
            onTap: () => _comingSoon('Foto profil'),
          ),

          _menuItem(
            icon: Icons.info_outline_rounded,
            title: 'Tentang Saya',
            subtitle: 'Tambahkan informasi singkat tentang kamu',
            onTap: () => _comingSoon('Tentang Saya'),
          ),

          const SizedBox(height: 8),

          _sectionTitle('Akun'),

          _menuItem(
            icon: Icons.security_rounded,
            title: 'Keamanan',
            subtitle: 'Kelola keamanan akun M8',
            onTap: () => _comingSoon('Keamanan'),
          ),

          _menuItem(
            icon: Icons.pin_outlined,
            title: 'M8 PIN',
            subtitle: 'PIN unik untuk terhubung dengan pengguna lain',
            onTap: () => _comingSoon('M8 PIN'),
          ),

          _menuItem(
            icon: Icons.volume_up_outlined,
            title: 'Nada M8',
            subtitle: 'Tes nada khas M8 Messenger',
            onTap: _testHeySound,
          ),

          const SizedBox(height: 8),

          _menuItem(
            icon: Icons.contacts_outlined,
            title: 'Kontak & Akun',
            subtitle: 'Kelola informasi kontak akun M8',
            onTap: () => _comingSoon('Kontak & Akun'),
          ),

          _menuItem(
            icon: Icons.lock_outline_rounded,
            title: 'Privasi',
            subtitle: 'Kelola privasi dan visibilitas profil',
            onTap: () => _comingSoon('Privasi'),
          ),

          const SizedBox(height: 8),

          _sectionTitle('Preferensi'),

          _menuItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notifikasi',
            subtitle: 'Atur pemberitahuan pesan dan aktivitas M8',
            onTap: () => _comingSoon('Notifikasi'),
          ),

          _menuItem(
            icon: Icons.palette_outlined,
            title: 'Tampilan',
            subtitle: 'Atur tampilan dan nuansa M8 Messenger',
            onTap: () => _comingSoon('Tampilan'),
          ),

          _menuItem(
            icon: Icons.language_rounded,
            title: 'Bahasa',
            subtitle: 'Pilih bahasa yang digunakan di M8',
            onTap: () => _comingSoon('Bahasa'),
          ),

          const SizedBox(height: 8),
          _sectionTitle('Aplikasi'),

          _menuItem(
            icon: Icons.info_outline_rounded,
            title: 'Tentang M8 Messenger',
            subtitle: 'Messenger dengan identitas M8 PIN',
            onTap: () => _comingSoon('Tentang M8 Messenger'),
          ),

          const SizedBox(height: 10),

          _menuItem(
            icon: Icons.logout_rounded,
            title: 'Keluar',
            subtitle: 'Keluar dari akun M8',
            danger: true,
            onTap: widget.onLogout,
          ),
        ],
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
              color: m8White,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: m8Blue, size: 25),
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
  bool speakerOn = false;
  bool endingCall = false;

  String callStatus = 'Menghubungkan...';

  @override
  void initState() {
    super.initState();

    widget.call.onCallStatusChanged = _handleCallStatus;

    _startCall();
  }

  void _handleCallStatus(String status) {
    if (!mounted) return;

    setState(() {
      switch (status) {
        case 'ringing':
          callStatus = 'Berdering...';
          connecting = true;
          break;

        case 'connecting':
          callStatus = 'Menghubungkan...';
          connecting = true;
          break;

        case 'connected':
          callStatus = widget.videoCall
              ? 'Video call terhubung'
              : 'Panggilan suara terhubung';
          connecting = false;

          timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) {
              setState(() => seconds++);
            }
          });
          break;

        case 'disconnected':
          timer?.cancel();
          timer = null;
          callStatus = 'Koneksi terputus';
          connecting = false;
          break;

        case 'failed':
          timer?.cancel();
          timer = null;
          callStatus = 'Panggilan gagal';
          connecting = false;
          break;

        case 'rejected':
          timer?.cancel();
          timer = null;
          callStatus = 'Panggilan ditolak';
          connecting = false;
          break;

        case 'ended':
          timer?.cancel();
          timer = null;
          callStatus = 'Panggilan berakhir';
          connecting = false;
          break;

        default:
          callStatus = status;
          connecting = true;
      }
    });
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
        cameraOff = !widget.videoCall;
      });

      // Status panggilan dan timer dikendalikan oleh
      // M8CallService melalui onCallStatusChanged.
      if (widget.call.callStatus == 'connected') {
        _handleCallStatus('connected');
      }
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
    if (!mounted || endingCall) return;

    final newState = !speakerOn;

    try {
      await Helper.setSpeakerphoneOn(newState);

      if (!mounted) return;

      setState(() {
        speakerOn = newState;
      });

      debugPrint('[BJO AUDIO] SPEAKER ${newState ? 'ON' : 'OFF'}');
    } catch (e) {
      debugPrint('[BJO AUDIO] SPEAKER ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState
                ? 'Speaker tidak dapat diaktifkan'
                : 'Receiver tidak dapat dipilih',
          ),
        ),
      );
    }
  }

  Future<void> hangUp() async {
    // Pastikan cleanup hanya dijalankan satu kali.
    if (!mounted || endingCall) return;

    setState(() {
      endingCall = true;
      callStatus = 'Mengakhiri panggilan...';
      connecting = false;
    });

    timer?.cancel();

    // Cleanup WebRTC HARUS dilakukan sebelum halaman ditutup.
    // Ini menghentikan microphone, audio track, peer connection,
    // polling signaling, dan membersihkan audio routing Android.
    try {
      await widget.call.hangUp();
    } catch (e) {
      print('[M8 CALL UI] HANGUP ERROR: $e');
    }

    // Setelah WebRTC benar-benar dihentikan, baru kembali
    // dari halaman panggilan ke halaman aplikasi sebelumnya.
    if (mounted && Navigator.of(context).canPop()) {
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
          Text(label, style: const TextStyle(color: m8TextMuted, fontSize: 11)),
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
                      color: m8Blue,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 52,
                              backgroundColor: m8Blue,
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
                                color: m8TextMuted,
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
                                  color: m8Blue,
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
                            color: m8TextMuted,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            if (widget.videoCall && widget.call.localRenderer.srcObject != null)
              Positioned(
                top: 82,
                right: 18,
                child: Container(
                  width: 105,
                  height: 145,
                  decoration: BoxDecoration(
                    color: m8Blue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: m8White.withValues(alpha: 0.78),
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: endingCall ? null : hangUp,
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
                    style: TextStyle(color: m8TextMuted, fontSize: 12),
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
              color: m8BlueLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 27),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: m8TextMuted, fontSize: 12)),
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
          Icon(Icons.call, size: 70, color: m8Blue),
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
