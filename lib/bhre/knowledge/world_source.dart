enum BhreWorldSourceType {
  web,
  news,
  publicData,
  weather,
  maps,
  finance,
  science,
  government,
}

class BhreWorldSource {
  final String id;
  final String name;
  final BhreWorldSourceType type;
  final String description;
  final bool enabled;

  const BhreWorldSource({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    this.enabled = true,
  });
}
