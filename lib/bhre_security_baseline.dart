import 'bhre_threat_assessment.dart';

class BhreSecurityBaseline {
  final int bootCount;
  final bool usbDebuggingEnabled;
  final bool developerOptionsEnabled;
  final String verifiedBootState;
  final String bootloaderLocked;
  final bool debuggableBuild;
  final DateTime createdAt;

  const BhreSecurityBaseline({
    required this.bootCount,
    required this.usbDebuggingEnabled,
    required this.developerOptionsEnabled,
    required this.verifiedBootState,
    required this.bootloaderLocked,
    required this.debuggableBuild,
    required this.createdAt,
  });
}

class BhreSecurityChange {
  final String id;
  final String title;
  final String description;
  final int severity;

  const BhreSecurityChange({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
  });
}

class BhreSecurityBaselineResult {
  final bool baselineCreated;
  final List<BhreSecurityChange> changes;
  final int anomalyScore;
  final DateTime checkedAt;

  const BhreSecurityBaselineResult({
    required this.baselineCreated,
    required this.changes,
    required this.anomalyScore,
    required this.checkedAt,
  });

  bool get hasChanges => changes.isNotEmpty;

  String get level {
    if (anomalyScore <= 10) {
      return 'NORMAL';
    }

    if (anomalyScore <= 30) {
      return 'WARNING';
    }

    if (anomalyScore <= 60) {
      return 'HIGH';
    }

    return 'CRITICAL';
  }

  String get summary {
    if (baselineCreated) {
      return 'Baseline keamanan Bree berhasil dibuat.';
    }

    if (!hasChanges) {
      return 'Tidak ditemukan perubahan keamanan dari baseline.';
    }

    return 'Terdeteksi ${changes.length} perubahan keamanan.';
  }
}

class BhreSecurityBaselineEngine {
  BhreSecurityBaseline? _baseline;

  BhreSecurityBaseline? get baseline => _baseline;

  BhreSecurityBaselineResult compare(BhreThreatAssessment assessment) {
    final report = _extractBaseline(assessment);

    if (_baseline == null) {
      _baseline = report;

      return BhreSecurityBaselineResult(
        baselineCreated: true,
        changes: const [],
        anomalyScore: 0,
        checkedAt: DateTime.now(),
      );
    }

    final changes = <BhreSecurityChange>[];

    if (_baseline!.usbDebuggingEnabled != report.usbDebuggingEnabled) {
      changes.add(
        BhreSecurityChange(
          id: 'usb_debugging_changed',
          title: 'USB Debugging berubah',
          description: 'Status USB debugging berbeda dari baseline sebelumnya.',
          severity: 20,
        ),
      );
    }

    if (_baseline!.developerOptionsEnabled != report.developerOptionsEnabled) {
      changes.add(
        BhreSecurityChange(
          id: 'developer_options_changed',
          title: 'Developer Options berubah',
          description:
              'Status Developer Options berbeda dari baseline sebelumnya.',
          severity: 10,
        ),
      );
    }

    if (_baseline!.verifiedBootState != report.verifiedBootState) {
      changes.add(
        BhreSecurityChange(
          id: 'verified_boot_changed',
          title: 'Verified Boot berubah',
          description: 'Status Verified Boot berbeda dari baseline sebelumnya.',
          severity: 40,
        ),
      );
    }

    if (_baseline!.bootloaderLocked != report.bootloaderLocked) {
      changes.add(
        BhreSecurityChange(
          id: 'bootloader_changed',
          title: 'Bootloader berubah',
          description: 'Status bootloader berbeda dari baseline sebelumnya.',
          severity: 40,
        ),
      );
    }

    if (_baseline!.debuggableBuild != report.debuggableBuild) {
      changes.add(
        BhreSecurityChange(
          id: 'debuggable_build_changed',
          title: 'Debuggable Build berubah',
          description:
              'Status debug aplikasi berbeda dari baseline sebelumnya.',
          severity: 25,
        ),
      );
    }

    if (_baseline!.bootCount != report.bootCount) {
      changes.add(
        BhreSecurityChange(
          id: 'device_reboot',
          title: 'Perangkat mengalami reboot',
          description: 'Boot count berubah sejak pemeriksaan baseline.',
          severity: 5,
        ),
      );
    }

    var anomalyScore = changes.fold<int>(
      0,
      (total, change) => total + change.severity,
    );

    if (anomalyScore > 100) {
      anomalyScore = 100;
    }

    return BhreSecurityBaselineResult(
      baselineCreated: false,
      changes: List.unmodifiable(changes),
      anomalyScore: anomalyScore,
      checkedAt: DateTime.now(),
    );
  }

  void reset() {
    _baseline = null;
  }

  BhreSecurityBaseline _extractBaseline(BhreThreatAssessment assessment) {
    var usbDebugging = false;
    var developerOptions = false;
    var verifiedBoot = 'unknown';
    var bootloader = 'unknown';
    var debuggable = false;
    var bootCount = 0;

    for (final factor in assessment.factors) {
      switch (factor.id) {
        case 'usb_debugging':
          usbDebugging = true;
          break;

        case 'developer_options':
          developerOptions = true;
          break;

        case 'verified_boot':
          verifiedBoot = 'changed';
          break;

        case 'bootloader':
          bootloader = 'unlocked';
          break;

        case 'debuggable_android':
        case 'debug_application':
          debuggable = true;
          break;
      }
    }

    return BhreSecurityBaseline(
      bootCount: bootCount,
      usbDebuggingEnabled: usbDebugging,
      developerOptionsEnabled: developerOptions,
      verifiedBootState: verifiedBoot,
      bootloaderLocked: bootloader,
      debuggableBuild: debuggable,
      createdAt: DateTime.now(),
    );
  }
}
