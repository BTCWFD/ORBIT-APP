class PlanetInstance {
  final String id;
  final String name;
  final String url;
  final String status;

  PlanetInstance({
    required this.id,
    required this.name,
    required this.url,
    this.status = "ONLINE",
  });
}
