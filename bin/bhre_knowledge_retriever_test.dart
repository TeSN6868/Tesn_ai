import 'dart:io';

import '../lib/bhre/knowledge/bhre_knowledge_domain.dart';
import '../lib/bhre/knowledge/bhre_knowledge_record.dart';
import '../lib/bhre/knowledge/bhre_knowledge_retriever.dart';
import '../lib/bhre/knowledge/bhre_memory_knowledge_store.dart';

void main() async {
  final store = BhreMemoryKnowledgeStore();

  final now = DateTime(2026, 8, 26, 10, 0);

  await store.save(
    BhreKnowledgeRecord(
      id: 'gempa-001',
      topic: 'Gempa terbaru di Indonesia',
      content: 'BMKG melaporkan aktivitas gempa terbaru.',
      domain: BhreKnowledgeDomain.naturalDisaster,
      createdAt: now,
      observedAt: now,
      confidence: 0.95,
      verified: true,
      generatedBy: 'BHRE_SOURCE_AGGREGATOR',
    ),
  );

  await store.save(
    BhreKnowledgeRecord(
      id: 'gempa-002',
      topic: 'Aktivitas gempa Indonesia',
      content: 'Data ilmiah mengenai aktivitas seismik Indonesia.',
      domain: BhreKnowledgeDomain.naturalDisaster,
      createdAt: now,
      observedAt: now,
      confidence: 0.85,
      verified: true,
      generatedBy: 'BHRE_SOURCE_AGGREGATOR',
    ),
  );

  await store.save(
    BhreKnowledgeRecord(
      id: 'blockchain-001',
      topic: 'Apa itu blockchain?',
      content: 'Blockchain adalah teknologi distributed ledger.',
      domain: BhreKnowledgeDomain.technology,
      createdAt: now,
      confidence: 0.90,
      verified: true,
      generatedBy: 'BHRE_SOURCE_AGGREGATOR',
    ),
  );

  final retriever = BhreKnowledgeRetriever(
    store: store,
  );

  final results = await retriever.retrieve(
    query: 'Gempa terbaru di Indonesia',
    domain: BhreKnowledgeDomain.naturalDisaster,
    limit: 5,
  );

  if (results.isEmpty) {
    throw StateError('Retriever tidak menghasilkan candidate.');
  }

  if (results.first.record.id != 'gempa-001') {
    throw StateError(
      'Candidate dengan topic paling relevan harus berada di posisi pertama.',
    );
  }

  if (results.first.score <= results.last.score && results.length > 1) {
    throw StateError(
      'Ranking candidate tidak terurut dari score tertinggi.',
    );
  }

  final domainResults = await retriever.retrieve(
    query: 'blockchain',
    domain: BhreKnowledgeDomain.technology,
  );

  if (domainResults.length != 1) {
    throw StateError(
      'Domain filtering menghasilkan jumlah candidate yang salah.',
    );
  }

  if (!domainResults.first.reasons.contains('domain_match')) {
    throw StateError(
      'Domain match tidak tercatat sebagai alasan ranking.',
    );
  }

  stdout.writeln('');
  stdout.writeln('RESULTS: ${results.length}');
  stdout.writeln(
    'TOP: ${results.first.record.id} | score=${results.first.score}',
  );
  stdout.writeln(
    'REASONS: ${results.first.reasons}',
  );
  stdout.writeln(
    'DOMAIN FILTER RESULTS: ${domainResults.length}',
  );
  stdout.writeln('');
  stdout.writeln('BHRE KNOWLEDGE RETRIEVER TEST: PASS');
}
