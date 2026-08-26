import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistent memory layer untuk Bree.
///
/// Menyimpan memory penting secara lokal sehingga tidak hilang
/// ketika aplikasi ditutup atau dibuka kembali.
///
/// Layer ini sengaja dibuat terpisah dari BhreMemory lama agar
/// memory runtime yang sudah ada tetap aman.
class BhrePersistentMemory {
  static const String _memoryKey = 'bhre_persistent_memory_v2';

  final List<Map<String, dynamic>> _entries = [];

  bool _initialized = false;

  /// Apakah persistent memory sudah siap digunakan.
  bool get initialized => _initialized;

  /// Semua memory yang tersimpan.
  List<Map<String, dynamic>> get entries => List.unmodifiable(_entries);

  /// Jumlah memory.
  int get count => _entries.length;

  /// Inisialisasi dan load memory dari storage.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_memoryKey);

    _entries.clear();

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              _entries.add(Map<String, dynamic>.from(item));
            }
          }
        }
      } catch (_) {
        // Jika storage rusak, jangan membuat aplikasi gagal boot.
        _entries.clear();
      }
    }

    _initialized = true;
  }

  /// Menyimpan satu memory baru.
  Future<void> remember({
    required String content,
    String category = 'general',
    String type = 'fact',
    double confidence = 1.0,
    bool important = false,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final value = content.trim();

    if (value.isEmpty) {
      return;
    }

    final entry = <String, dynamic>{
      'id': 'pm-${DateTime.now().microsecondsSinceEpoch}',
      'content': value,
      'category': category,
      'type': type,
      'confidence': confidence.clamp(0.0, 1.0),
      'important': important,
      'createdAt': DateTime.now().toIso8601String(),
      'metadata': metadata ?? <String, dynamic>{},
    };

    _entries.add(entry);

    await _save();
  }

  /// Mencari memory berdasarkan isi, kategori atau tipe.
  List<Map<String, dynamic>> search(String query) {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return const [];
    }

    final results = _entries.where((entry) {
      final content = (entry['content'] ?? '').toString().toLowerCase();
      final category = (entry['category'] ?? '').toString().toLowerCase();
      final type = (entry['type'] ?? '').toString().toLowerCase();

      return content.contains(normalized) ||
          category.contains(normalized) ||
          type.contains(normalized);
    }).toList();

    return List.unmodifiable(results.reversed);
  }

  /// Memory terbaru.
  List<Map<String, dynamic>> recent([int limit = 20]) {
    if (limit <= 0 || _entries.isEmpty) {
      return const [];
    }

    final start = _entries.length > limit ? _entries.length - limit : 0;

    return List.unmodifiable(_entries.sublist(start).reversed);
  }

  /// Memory penting.
  List<Map<String, dynamic>> important() {
    return List.unmodifiable(
      _entries.where((entry) => entry['important'] == true).toList().reversed,
    );
  }

  /// Statistik memory.
  Map<String, dynamic> statistics() {
    final byCategory = <String, int>{};
    final byType = <String, int>{};

    for (final entry in _entries) {
      final category = (entry['category'] ?? 'general').toString();
      final type = (entry['type'] ?? 'fact').toString();

      byCategory[category] = (byCategory[category] ?? 0) + 1;

      byType[type] = (byType[type] ?? 0) + 1;
    }

    return {
      'total': _entries.length,
      'important': _entries.where((entry) => entry['important'] == true).length,
      'categories': Map.unmodifiable(byCategory),
      'types': Map.unmodifiable(byType),
      'initialized': _initialized,
    };
  }

  /// Menghapus satu memory berdasarkan ID.
  Future<bool> forget(String id) async {
    final index = _entries.indexWhere((entry) => entry['id'] == id);

    if (index == -1) {
      return false;
    }

    _entries.removeAt(index);
    await _save();
    return true;
  }

  /// Menghapus semua persistent memory.
  Future<void> clear() async {
    _entries.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_memoryKey);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_memoryKey, jsonEncode(_entries));
  }
}
