import 'dart:io';

import '../lib/bhre/knowledge/bhre_knowledge_domain.dart';
import '../lib/bhre/knowledge/bhre_knowledge_record.dart';
import '../lib/bhre/knowledge/bhre_memory_knowledge_store.dart';

void main() async {
  final store = BhreMemoryKnowledgeStore();

  final record = BhreKnowledgeRecord(
    id: 'test-gempa-001',
    topic: 'Gempa terbaru di Indonesia',
    content: 'Gempa M 5.2 terdeteksi di Indonesia.',
    domain: BhreKnowledgeDomain.naturalDisaster,
    createdAt: DateTime(2026, 8, 26, 10, 0),
    observedAt: DateTime(2026, 8, 26, 10, 0),
    confidence: 0.85,
    verified: true,
    generatedBy: 'BHRE_SOURCE_AGGREGATOR',
  );

  await store.save(record);

  final byId = await store.getById('test-gempa-001');

  if (byId == null) {
    throw StateError('Record gagal disimpan.');
  }

  if (byId.id != record.id) {
    throw StateError('ID record tidak sesuai.');
  }

  final domainResults = await store.findByDomain(
    BhreKnowledgeDomain.naturalDisaster,
  );

  if (domainResults.length != 1) {
    throw StateError('Pencarian berdasarkan domain gagal.');
  }

  final searchResults = await store.search('Gempa terbaru');

  if (searchResults.length != 1) {
    throw StateError('Pencarian knowledge gagal.');
  }

  await store.clear();

  final afterClear = await store.getById('test-gempa-001');

  if (afterClear != null) {
    throw StateError('Store gagal dibersihkan.');
  }

  stdout.writeln('');
  stdout.writeln('SAVED: ${record.id}');
  stdout.writeln('DOMAIN RESULTS: ${domainResults.length}');
  stdout.writeln('SEARCH RESULTS: ${searchResults.length}');
  stdout.writeln('CLEAR: PASS');
  stdout.writeln('');
  stdout.writeln('BHRE KNOWLEDGE STORE TEST: PASS');
}
