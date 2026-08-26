import 'dart:io';

class BhreSecurityReport {
  final bool isPhysicalDevice;
  final bool isAndroid;
  final bool isDebugBuild;
  final bool hasInternet;
  final String operatingSystem;
  final String operatingSystemVersion;
  final DateTime checkedAt;

  const BhreSecurityReport({
    required this.isPhysicalDevice,
    required this.isAndroid,
    required this.isDebugBuild,
    required this.hasInternet,
    required this.operatingSystem,
    required this.operatingSystemVersion,
    required this.checkedAt,
  });

  String get summary {
    final parts = <String>[];

    parts.add(isAndroid ? 'Android terdeteksi.' : 'Platform bukan Android.');

    parts.add(
      isPhysicalDevice
          ? 'Perangkat fisik terdeteksi.'
          : 'Kemungkinan emulator.',
    );

    parts.add(isDebugBuild ? 'Mode debug aktif.' : 'Mode produksi terdeteksi.');

    parts.add(
      hasInternet
          ? 'Koneksi internet tersedia.'
          : 'Koneksi internet tidak tersedia.',
    );

    return parts.join(' ');
  }
}

class BhreSecurityIntelligence {
  Future<BhreSecurityReport> inspect() async {
    final operatingSystem = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;

    final isAndroid = Platform.isAndroid;

    final isPhysicalDevice = isAndroid ? !_looksLikeEmulator() : true;

    final isDebugBuild = _detectDebugMode();

    final hasInternet = await _checkInternet();

    return BhreSecurityReport(
      isPhysicalDevice: isPhysicalDevice,
      isAndroid: isAndroid,
      isDebugBuild: isDebugBuild,
      hasInternet: hasInternet,
      operatingSystem: operatingSystem,
      operatingSystemVersion: version,
      checkedAt: DateTime.now(),
    );
  }

  bool _detectDebugMode() {
    bool result = false;

    assert(() {
      result = true;
      return true;
    }());

    return result;
  }

  bool _looksLikeEmulator() {
    final value = Platform.operatingSystemVersion.toLowerCase();

    return value.contains('emulator') ||
        value.contains('generic') ||
        value.contains('sdk');
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 3));

      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
