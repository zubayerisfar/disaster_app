// Represents an emergency message document stored in the Firestore
// "messages" collection. Fields mirror the Firestore schema.

class EmergencyMessage {
  final String id;
  final String category; // e.g. "cyclone", "flood"
  final int level; // warning signal level 1–10
  final String message;
  final double windSpeed; // km/h used to derive warning level
  final DateTime createdAt;
  final String location; // district name

  const EmergencyMessage({
    required this.id,
    required this.category,
    required this.level,
    required this.message,
    required this.windSpeed,
    required this.createdAt,
    required this.location,
  });

  /// Constructs a model from a Firestore document snapshot map.
  factory EmergencyMessage.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return EmergencyMessage(
      id: docId,
      category: data['category'] as String? ?? '',
      level: (data['level'] as num?)?.toInt() ?? 0,
      message: data['message'] as String? ?? '',
      windSpeed: (data['windSpeed'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate() as DateTime
          : DateTime.now(),
      location: data['location'] as String? ?? '',
    );
  }
}
