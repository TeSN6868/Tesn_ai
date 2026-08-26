/// Core IT security knowledge domains for Bree.
///
/// These domains describe what Bree should understand and reason about.
/// They are knowledge taxonomy, not offensive tooling.
class BhreItSecurityDomain {
  final String id;
  final String name;
  final String description;
  final List<String> topics;
  final List<String> capabilities;

  const BhreItSecurityDomain({
    required this.id,
    required this.name,
    required this.description,
    required this.topics,
    required this.capabilities,
  });
}

/// The two primary security domains of Bree.
class BhreItSecurityDomains {
  BhreItSecurityDomains._();

  static const cybersecurity = BhreItSecurityDomain(
    id: 'cybersecurity',
    name: 'Cybersecurity',
    description:
        'Keamanan sistem, jaringan, aplikasi, data, identitas, '
        'cloud, perangkat dan infrastruktur digital.',
    topics: [
      'security fundamentals',
      'authentication',
      'authorization',
      'identity and access management',
      'password security',
      'multi-factor authentication',
      'cryptography',
      'encryption',
      'hashing',
      'digital signatures',
      'PKI',
      'TLS and HTTPS',
      'network security',
      'firewalls',
      'VPN',
      'zero trust',
      'endpoint security',
      'mobile security',
      'web security',
      'API security',
      'cloud security',
      'database security',
      'secure software development',
      'OWASP',
      'vulnerability management',
      'threat intelligence',
      'security monitoring',
      'security operations',
      'incident response',
      'malware awareness',
      'phishing awareness',
      'privacy',
      'security architecture',
      'risk assessment',
    ],
    capabilities: [
      'identify security concepts',
      'explain security risks',
      'analyze security symptoms',
      'classify vulnerabilities',
      'recommend defensive mitigations',
      'reason about authentication and authorization failures',
      'analyze logs and security events',
      'correlate indicators of compromise',
      'explain secure architecture',
      'assist defensive incident response',
    ],
  );

  static const digitalForensics = BhreItSecurityDomain(
    id: 'digital_forensics',
    name: 'Digital Forensics & Incident Response',
    description:
        'Identifikasi, preservasi, akuisisi, pemeriksaan, analisis, '
        'korelasi dan pelaporan bukti digital secara forensik.',
    topics: [
      'digital evidence',
      'evidence preservation',
      'evidence acquisition',
      'chain of custody',
      'forensic integrity',
      'hash verification',
      'disk forensics',
      'filesystem forensics',
      'deleted file recovery',
      'file carving',
      'metadata analysis',
      'timeline analysis',
      'Windows forensics',
      'Linux forensics',
      'macOS forensics',
      'Android forensics',
      'iOS forensics',
      'mobile application artifacts',
      'browser forensics',
      'email forensics',
      'database forensics',
      'memory forensics',
      'network forensics',
      'packet analysis',
      'PCAP analysis',
      'cloud forensics',
      'log forensics',
      'malware analysis',
      'artifact correlation',
      'indicator of compromise',
      'threat hunting',
      'incident response',
      'forensic reporting',
      'forensic hypothesis testing',
    ],
    capabilities: [
      'identify potential digital evidence',
      'distinguish evidence from assumptions',
      'preserve evidence integrity',
      'construct forensic timelines',
      'correlate events across artifacts',
      'analyze logs and metadata',
      'reason about filesystem artifacts',
      'reason about mobile artifacts',
      'reason about network artifacts',
      'reason about memory artifacts',
      'identify possible indicators of compromise',
      'support incident triage',
      'produce structured forensic findings',
      'separate facts, indicators, hypotheses and conclusions',
      'assign confidence to investigative findings',
    ],
  );

  static const all = <BhreItSecurityDomain>[cybersecurity, digitalForensics];

  static BhreItSecurityDomain? resolve(String query) {
    final value = query.toLowerCase();

    if (_containsAny(value, [
      'cybersecurity',
      'cyber security',
      'keamanan siber',
      'keamanan cyber',
      'security',
      'vulnerability',
      'firewall',
      'encryption',
      'malware',
      'phishing',
      'owasp',
      'zero trust',
    ])) {
      return cybersecurity;
    }

    if (_containsAny(value, [
      'digital forensics',
      'digital forensic',
      'forensik digital',
      'forensik',
      'dfir',
      'incident response',
      'bukti digital',
      'digital evidence',
      'timeline forensik',
      'memory forensics',
      'network forensics',
      'mobile forensics',
      'disk forensics',
    ])) {
      return digitalForensics;
    }

    return null;
  }

  static bool _containsAny(String value, List<String> terms) {
    return terms.any(value.contains);
  }
}
