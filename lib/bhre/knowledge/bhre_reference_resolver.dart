import 'bhre_relation.dart';
import 'bhre_relation_engine.dart';

class BhreReferenceMatch {
  final String reference;
  final BhreEntity? entity;
  final double confidence;
  final String reason;

  const BhreReferenceMatch({
    required this.reference,
    required this.entity,
    required this.confidence,
    required this.reason,
  });

  bool get resolved => entity != null;

  @override
  String toString() {
    return 'BhreReferenceMatch('
        'reference: "$reference", '
        'entity: ${entity?.value}, '
        'confidence: $confidence, '
        'reason: $reason)';
  }
}

class BhreReferenceResolver {
  const BhreReferenceResolver();

  BhreReferenceMatch resolve(
    String reference,
    BhreKnowledgeGraph graph, {
    BhreEntityType? expectedType,
  }) {
    final normalized = reference.trim().toLowerCase();

    if (normalized.isEmpty) {
      return const BhreReferenceMatch(
        reference: '',
        entity: null,
        confidence: 0.0,
        reason: 'Referensi kosong.',
      );
    }

    final candidates = graph.entities.where((entity) {
      if (expectedType != null && entity.type != expectedType) {
        return false;
      }

      return true;
    }).toList();

    if (candidates.isEmpty) {
      return BhreReferenceMatch(
        reference: reference,
        entity: null,
        confidence: 0.0,
        reason: 'Tidak ada kandidat dalam knowledge graph.',
      );
    }

    // Untuk referensi temporal seperti "yang kemarin",
    // prioritaskan entity yang memiliki hubungan dengan tanggal kemarin.
    if (normalized.contains('kemarin')) {
      final yesterday = candidates.where(
        (entity) =>
            entity.type == BhreEntityType.date &&
            entity.value.toLowerCase() == 'kemarin',
      );

      if (yesterday.isNotEmpty) {
        return BhreReferenceMatch(
          reference: reference,
          entity: yesterday.first,
          confidence: 0.85,
          reason: 'Referensi mengandung penanda waktu "kemarin".',
        );
      }
    }

    // Referensi "ini/itu/tersebut" belum boleh dipaksakan.
    // Kandidat ambigu harus menghasilkan unresolved.
    if (candidates.length == 1) {
      return BhreReferenceMatch(
        reference: reference,
        entity: candidates.first,
        confidence: 0.65,
        reason: 'Hanya ada satu kandidat.',
      );
    }

    return BhreReferenceMatch(
      reference: reference,
      entity: null,
      confidence: 0.0,
      reason: 'Referensi ambigu; diperlukan konteks tambahan.',
    );
  }
}
