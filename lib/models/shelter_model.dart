/// Represents a shelter (cyclone shelter / school) stored locally or from
/// Firestore.  The [lat] and [lng] fields are used to place markers on
/// the Google Map and to calculate distance from the user.

class Shelter {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String district;
  final int capacity;

  const Shelter({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.district,
    required this.capacity,
  });

  factory Shelter.fromFirestore(Map<String, dynamic> data, String docId) {
    return Shelter(
      id: docId,
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      district: data['district'] as String? ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
    );
  }
}
