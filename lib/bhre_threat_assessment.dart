import 'bhre_advanced_security.dart';

enum BhreThreatLevel { normal, warning, high, critical }

class BhreThreatFactor {
  final String id;
  final String title;
  final String description;
  final int score;

  const BhreThreatFactor({
    required this.id,
    required this.title,
    required this.description,
    required this.score,
  });
}

class BhreThreatAssessment {
  final int score;
  final BhreThreatLevel level;
  final List<BhreThreatFactor> factors;
  final double confidence;
  final DateTime checkedAt;

  const BhreThreatAssessment({
    required this.score,
    required this.level,
    required this.factors,
    required this.confidence,
    required this.checkedAt,
  });

  String get levelName {
    switch (level) {
      case BhreThreatLevel.normal:
        return 'NORMAL';
      case BhreThreatLevel.warning:
        return 'WARNING';
      case BhreThreatLevel.high:
        return 'HIGH';
      case BhreThreatLevel.critical:
        return 'CRITICAL';
    }
  }

  String get grade {
    if (score <= 10) return 'A';
    if (score <= 25) return 'B';
    if (score <= 45) return 'C';
    if (score <= 70) return 'D';
    return 'E';
  }

  bool get requiresAttention =>
      level == BhreThreatLevel.high || level == BhreThreatLevel.critical;

  String get summary {
    if (level == BhreThreatLevel.normal) {
      return 'Tidak ditemukan indikator risiko keamanan yang signifikan.';
    }

    return 'Ditemukan ${factors.length} indikator yang perlu diperhatikan.';
  }
}

class BhreThreatAssessmentEngine {
  BhreThreatAssessment analyze(BhreAdvancedSecurityReport report) {
    final factors = <BhreThreatFactor>[];

    if (!report.platform.isPhysicalDevice) {
      factors.add(
        const BhreThreatFactor(
          id: 'virtual_device',
          title: 'Virtual Device',
          description: 'Perangkat kemungkinan berjalan pada emulator.',
          score: 20,
        ),
      );
    }

    if (report.platform.isDebugBuild) {
      factors.add(
        const BhreThreatFactor(
          id: 'debug_application',
          title: 'Debug Application',
          description: 'Aplikasi berjalan dalam mode debug.',
          score: 15,
        ),
      );
    }

    if (report.device.usbDebuggingEnabled) {
      factors.add(
        const BhreThreatFactor(
          id: 'usb_debugging',
          title: 'USB Debugging',
          description: 'USB debugging sedang aktif.',
          score: 15,
        ),
      );
    }

    if (report.device.developerOptionsEnabled) {
      factors.add(
        const BhreThreatFactor(
          id: 'developer_options',
          title: 'Developer Options',
          description: 'Opsi pengembang Android aktif.',
          score: 5,
        ),
      );
    }

    if (!report.device.verifiedBootHealthy) {
      factors.add(
        const BhreThreatFactor(
          id: 'verified_boot',
          title: 'Verified Boot',
          description: 'Verified Boot tidak berada pada status green.',
          score: 30,
        ),
      );
    }

    if (!report.device.bootloaderSecure) {
      factors.add(
        const BhreThreatFactor(
          id: 'bootloader',
          title: 'Bootloader',
          description: 'Status bootloader tidak menunjukkan kondisi terkunci.',
          score: 30,
        ),
      );
    }

    if (report.device.debuggableBuild) {
      factors.add(
        const BhreThreatFactor(
          id: 'debuggable_android',
          title: 'Debuggable Android',
          description: 'Build Android terdeteksi debuggable.',
          score: 20,
        ),
      );
    }

    var score = factors.fold<int>(0, (total, factor) => total + factor.score);

    if (score > 100) {
      score = 100;
    }

    final level = _calculateLevel(score);

    final confidence = _calculateConfidence(report);

    return BhreThreatAssessment(
      score: score,
      level: level,
      factors: List.unmodifiable(factors),
      confidence: confidence,
      checkedAt: DateTime.now(),
    );
  }

  BhreThreatLevel _calculateLevel(int score) {
    if (score <= 15) {
      return BhreThreatLevel.normal;
    }

    if (score <= 40) {
      return BhreThreatLevel.warning;
    }

    if (score <= 70) {
      return BhreThreatLevel.high;
    }

    return BhreThreatLevel.critical;
  }

  double _calculateConfidence(BhreAdvancedSecurityReport report) {
    var confidence = 0.70;

    if (report.platform.isAndroid) {
      confidence += 0.10;
    }

    if (report.platform.isPhysicalDevice) {
      confidence += 0.05;
    }

    if (report.device.verifiedBootState != 'unknown') {
      confidence += 0.05;
    }

    if (report.device.bootloaderLocked != 'unknown') {
      confidence += 0.05;
    }

    if (report.device.bootCount >= 0) {
      confidence += 0.05;
    }

    if (confidence > 1.0) {
      confidence = 1.0;
    }

    return confidence;
  }
}
