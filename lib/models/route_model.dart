class TrainRoute {
  final String id;
  final String origin;
  final String destination;
  final double distanceKm;
  final double basePrice;

  TrainRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.basePrice,
  });

  factory TrainRoute.fromMap(Map<String, dynamic> map) {
    return TrainRoute(
      id: map['id'],
      origin: map['origin'],
      destination: map['destination'],
      distanceKm: (map['distance_km'] as num).toDouble(),
      basePrice: (map['base_price'] as num).toDouble(),
    );
  }
}