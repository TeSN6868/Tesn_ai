import 'bhre_device_bridge.dart';
import 'bhre_security_intelligence.dart';

class BhreAdvancedSecurityReport {
  final BhreSecurityReport platform;
  final BhreDeviceSecuritySnapshot device;

  const BhreAdvancedSecurityReport({
    required this.platform,
    required this.device,
  });

  bool get secure {
    return platform.isPhysicalDevice &&
        !platform.isDebugBuild &&
        device.overallSecure;
  }

  List<String> get warnings {
    final result = <String>[];

    if (!platform.isPhysicalDevice) {
      result.add('Perangkat kemungkinan emulator.');
    }

    if (platform.isDebugBuild) {
      result.add('Aplikasi berjalan dalam mode debug.');
    }

    if (device.usbDebuggingEnabled) {
      result.add('USB debugging sedang aktif.');
    }

    if (device.developerOptionsEnabled) {
      result.add('Opsi pengembang aktif.');
    }

    if (!device.verifiedBootHealthy) {
      result.add(
        'Verified Boot tidak berada pada status green.',
      );
    }

    if (!device.bootloaderSecure) {
      result.add(
        'Status bootloader perlu diperiksa.',
      );
    }

    if (device.debuggableBuild) {
      result.add(
        'Android build terdeteksi sebagai debuggable.',
      );
    }

    return List.unmodifiable(result);
  }

  String get level {
    if (secure && warnings.isEmpty) {
      return 'AMAN';
    }

    if (warnings.length <= 2) {
      return 'PERLU PERHATIAN';
    }

    return 'RISIKO TINGGI';
  }

  String get summary {
    if (warnings.isEmpty) {
      return 'Kondisi keamanan perangkat terlihat aman.';
    }

    return warnings.join(' ');
  }
}

class BhreAdvancedSecurity {
  final BhreSecurityIntelligence intelligence;
  final BhreDeviceBridge deviceBridge;

  BhreAdvancedSecurity({
    BhreSecurityIntelligence? intelligence,
    BhreDeviceBridge? deviceBridge,
  })  : intelligence =
            intelligence ?? BhreSecurityIntelligence(),
        deviceBridge =
            deviceBridge ?? BhreDeviceBridge();

  Future<BhreAdvancedSecurityReport> inspect() async {
    final platformReport =
        await intelligence.inspect();

    final deviceReport =
        await deviceBridge.inspect();

    return BhreAdvancedSecurityReport(
      platform: platformReport,
      device: deviceReport,
    );
  }
}
