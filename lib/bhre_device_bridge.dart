import 'package:flutter/services.dart';

class BhreDeviceBridge {
  static const MethodChannel _channel = MethodChannel('bjo/device');

  Future<int> getBootCount() async {
    return await _channel.invokeMethod<int>('getBootCount') ?? 0;
  }

  Future<bool> isUsbDebuggingEnabled() async {
    return await _channel.invokeMethod<bool>('isUsbDebuggingEnabled') ?? false;
  }

  Future<bool> isDeveloperOptionsEnabled() async {
    return await _channel.invokeMethod<bool>('isDeveloperOptionsEnabled') ??
        false;
  }

  Future<String> getVerifiedBootState() async {
    return await _channel.invokeMethod<String>('getVerifiedBootState') ??
        'unknown';
  }

  Future<String> getBootloaderLockState() async {
    return await _channel.invokeMethod<String>('getBootloaderLockState') ??
        'unknown';
  }

  Future<bool> isDebuggableBuild() async {
    return await _channel.invokeMethod<bool>('isDebuggableBuild') ?? false;
  }

  Future<BhreDeviceSecuritySnapshot> inspect() async {
    final results = await Future.wait([
      getBootCount(),
      isUsbDebuggingEnabled(),
      isDeveloperOptionsEnabled(),
      getVerifiedBootState(),
      getBootloaderLockState(),
      isDebuggableBuild(),
    ]);

    return BhreDeviceSecuritySnapshot(
      bootCount: results[0] as int,
      usbDebuggingEnabled: results[1] as bool,
      developerOptionsEnabled: results[2] as bool,
      verifiedBootState: results[3] as String,
      bootloaderLocked: results[4] as String,
      debuggableBuild: results[5] as bool,
    );
  }
}

class BhreDeviceSecuritySnapshot {
  final int bootCount;
  final bool usbDebuggingEnabled;
  final bool developerOptionsEnabled;
  final String verifiedBootState;
  final String bootloaderLocked;
  final bool debuggableBuild;

  const BhreDeviceSecuritySnapshot({
    required this.bootCount,
    required this.usbDebuggingEnabled,
    required this.developerOptionsEnabled,
    required this.verifiedBootState,
    required this.bootloaderLocked,
    required this.debuggableBuild,
  });

  bool get verifiedBootHealthy => verifiedBootState.toLowerCase() == 'green';

  bool get bootloaderSecure =>
      bootloaderLocked == '1' || bootloaderLocked.toLowerCase() == 'true';

  bool get overallSecure =>
      verifiedBootHealthy && bootloaderSecure && !debuggableBuild;

  String get summary {
    final parts = <String>[];

    parts.add(
      verifiedBootHealthy
          ? 'Verified Boot aman.'
          : 'Verified Boot perlu diperiksa.',
    );

    parts.add(
      bootloaderSecure ? 'Bootloader terkunci.' : 'Bootloader tidak terkunci.',
    );

    parts.add(
      usbDebuggingEnabled
          ? 'USB debugging aktif.'
          : 'USB debugging tidak aktif.',
    );

    parts.add(
      developerOptionsEnabled
          ? 'Opsi pengembang aktif.'
          : 'Opsi pengembang tidak aktif.',
    );

    parts.add(
      debuggableBuild
          ? 'Build aplikasi bersifat debug.'
          : 'Build aplikasi bukan debug.',
    );

    return parts.join(' ');
  }
}
