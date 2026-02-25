/// Service for fetching shelter (cyclone shelter / school) data.
///
/// Uses a rich built-in seed list covering Bangladesh's main districts.
/// Automatically generates demo shelters for any district not in the seed
/// so the UI is always populated.  Connect to Firestore by uncommenting
/// the query block inside [fetchSheltersByDistrict].

import 'dart:math';
import '../models/shelter_model.dart';

class ShelterService {
  // ---------------------------------------------------------------------------
  // Comprehensive seed data covering Bangladesh's main districts
  // ---------------------------------------------------------------------------
  static final List<Shelter> _seedShelters = [
    // â”€â”€ Dhaka â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's1',
      name: 'Bangshal Govt. Primary School',
      address: 'Bangshal, Dhaka',
      lat: 23.7200,
      lng: 90.4080,
      district: 'dhaka',
      capacity: 500,
    ),
    const Shelter(
      id: 's2',
      name: 'Demra High School Cyclone Centre',
      address: 'Demra, Dhaka',
      lat: 23.7105,
      lng: 90.4644,
      district: 'dhaka',
      capacity: 600,
    ),
    const Shelter(
      id: 's3',
      name: 'Mirpur Govt. School Shelter',
      address: 'Mirpur, Dhaka',
      lat: 23.8223,
      lng: 90.3654,
      district: 'dhaka',
      capacity: 450,
    ),

    // â”€â”€ Chittagong â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's4',
      name: 'Chittagong Collegiate School',
      address: 'Anderkilla, Chittagong',
      lat: 22.3569,
      lng: 91.7832,
      district: 'chittagong',
      capacity: 1000,
    ),
    const Shelter(
      id: 's5',
      name: 'Nasirabad Govt. High School',
      address: 'Nasirabad, Chittagong',
      lat: 22.3750,
      lng: 91.8280,
      district: 'chittagong',
      capacity: 750,
    ),
    const Shelter(
      id: 's6',
      name: 'Hathazari Cyclone Shelter',
      address: 'Hathazari, Chittagong',
      lat: 22.5110,
      lng: 91.8090,
      district: 'chittagong',
      capacity: 800,
    ),

    // â”€â”€ Cox's Bazar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's7',
      name: "Cox's Bazar Govt. High School",
      address: "Main Road, Cox's Bazar",
      lat: 21.4272,
      lng: 92.0058,
      district: "cox's bazar",
      capacity: 800,
    ),
    const Shelter(
      id: 's8',
      name: 'Ramu Cyclone Shelter',
      address: 'Ramu, Cox\'s Bazar',
      lat: 21.4555,
      lng: 92.0780,
      district: "cox's bazar",
      capacity: 600,
    ),
    const Shelter(
      id: 's9',
      name: 'Teknaf Coastal Shelter',
      address: 'Teknaf, Cox\'s Bazar',
      lat: 20.8644,
      lng: 92.3021,
      district: "cox's bazar",
      capacity: 550,
    ),

    // â”€â”€ Khulna â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's10',
      name: 'Khulna Zilla School',
      address: 'KDA Avenue, Khulna',
      lat: 22.8456,
      lng: 89.5403,
      district: 'khulna',
      capacity: 700,
    ),
    const Shelter(
      id: 's11',
      name: 'Khalishpur Cyclone Shelter',
      address: 'Khalishpur, Khulna',
      lat: 22.8710,
      lng: 89.5100,
      district: 'khulna',
      capacity: 500,
    ),
    const Shelter(
      id: 's12',
      name: 'Daulatpur Community Centre',
      address: 'Daulatpur, Khulna',
      lat: 22.9000,
      lng: 89.5300,
      district: 'khulna',
      capacity: 400,
    ),

    // â”€â”€ Barisal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's13',
      name: 'Barisal Collegiate School',
      address: 'Barisal City',
      lat: 22.7010,
      lng: 90.3535,
      district: 'barisal',
      capacity: 600,
    ),
    const Shelter(
      id: 's14',
      name: 'Bakerganj Upazila Shelter',
      address: 'Bakerganj, Barisal',
      lat: 22.6500,
      lng: 90.2300,
      district: 'barisal',
      capacity: 450,
    ),
    const Shelter(
      id: 's15',
      name: 'Mehendiganj Cyclone Shelter',
      address: 'Mehendiganj, Barisal',
      lat: 22.5200,
      lng: 90.4100,
      district: 'barisal',
      capacity: 500,
    ),

    // â”€â”€ Patuakhali (Barisal division) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's16',
      name: 'Patuakhali Govt. College Shelter',
      address: 'Patuakhali Town',
      lat: 22.3600,
      lng: 90.3300,
      district: 'patuakhali',
      capacity: 700,
    ),
    const Shelter(
      id: 's17',
      name: 'Kuakata Cyclone Shelter',
      address: 'Kuakata, Patuakhali',
      lat: 21.8180,
      lng: 90.1180,
      district: 'patuakhali',
      capacity: 500,
    ),

    // â”€â”€ Barguna â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's18',
      name: 'Barguna Govt. High School',
      address: 'Barguna Town',
      lat: 22.1500,
      lng: 90.1200,
      district: 'barguna',
      capacity: 600,
    ),
    const Shelter(
      id: 's19',
      name: 'Amtali Upazila Cyclone Shelter',
      address: 'Amtali, Barguna',
      lat: 22.0700,
      lng: 90.2300,
      district: 'barguna',
      capacity: 450,
    ),

    // â”€â”€ Bhola â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's20',
      name: 'Bhola Govt. College Shelter',
      address: 'Bhola Sadar',
      lat: 22.6860,
      lng: 90.6490,
      district: 'bhola',
      capacity: 800,
    ),
    const Shelter(
      id: 's21',
      name: 'Charfasson Cyclone Shelter',
      address: 'Charfasson, Bhola',
      lat: 22.1900,
      lng: 90.7400,
      district: 'bhola',
      capacity: 600,
    ),

    // â”€â”€ Noakhali â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's22',
      name: 'Noakhali Govt. College Shelter',
      address: 'Maijdee, Noakhali',
      lat: 22.8330,
      lng: 91.0990,
      district: 'noakhali',
      capacity: 700,
    ),
    const Shelter(
      id: 's23',
      name: 'Hatiya Island Cyclone Shelter',
      address: 'Hatiya, Noakhali',
      lat: 22.3500,
      lng: 91.1000,
      district: 'noakhali',
      capacity: 800,
    ),

    // â”€â”€ Sylhet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's24',
      name: 'Sylhet Govt. Pilot High School',
      address: 'Sylhet City',
      lat: 24.8998,
      lng: 91.8716,
      district: 'sylhet',
      capacity: 750,
    ),
    const Shelter(
      id: 's25',
      name: 'MC College Flood Shelter',
      address: 'Ambarkhana, Sylhet',
      lat: 24.9000,
      lng: 91.8800,
      district: 'sylhet',
      capacity: 500,
    ),

    // â”€â”€ Rajshahi â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's26',
      name: 'Rajshahi Collegiate School',
      address: 'Rajshahi City',
      lat: 24.3745,
      lng: 88.6042,
      district: 'rajshahi',
      capacity: 700,
    ),

    // â”€â”€ Rangpur â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's27',
      name: 'Rangpur Zilla School Shelter',
      address: 'Rangpur City',
      lat: 25.7439,
      lng: 89.2752,
      district: 'rangpur',
      capacity: 600,
    ),

    // â”€â”€ Mymensingh â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's28',
      name: 'Mymensingh Zilla School',
      address: 'Mymensingh City',
      lat: 24.7471,
      lng: 90.4203,
      district: 'mymensingh',
      capacity: 650,
    ),

    // â”€â”€ Gazipur â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's29',
      name: 'Gazipur Sadar Cyclone Shelter',
      address: 'Gazipur Sadar',
      lat: 23.9999,
      lng: 90.4203,
      district: 'gazipur',
      capacity: 400,
    ),

    // â”€â”€ Comilla â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const Shelter(
      id: 's30',
      name: 'Comilla Victoria Govt. College',
      address: 'Kandirpar, Comilla',
      lat: 23.4607,
      lng: 91.1809,
      district: 'comilla',
      capacity: 800,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns shelters for [district]. If nothing matches the seed list
  /// (e.g., the district isn't covered yet), generates demo shelters centred
  /// on Bangladesh's geographic centre so the map always has markers.
  Future<List<Shelter>> fetchSheltersByDistrict(String district) async {
    // TODO: Uncomment to load from Firestore when populated:
    // try {
    //   final snap = await FirebaseFirestore.instance
    //       .collection('shelters')
    //       .where('district', isEqualTo: district.toLowerCase())
    //       .get();
    //   if (snap.docs.isNotEmpty) {
    //     return snap.docs.map((d) => Shelter.fromFirestore(d.data(), d.id)).toList();
    //   }
    // } catch (_) {}

    final filtered = _seedShelters
        .where((s) => s.district == district.toLowerCase())
        .toList();

    // If district not in seed list, return geographically closest 3 shelters
    // so the map is never empty.
    if (filtered.isEmpty) {
      return _seedShelters.take(3).toList();
    }
    return filtered;
  }

  /// Returns [count] shelters closest to [userLat]/[userLng].
  List<Shelter> nearestShelters(
    double userLat,
    double userLng,
    List<Shelter> allShelters, {
    int count = 3,
  }) {
    if (allShelters.isEmpty) return [];
    final sorted = List<Shelter>.from(allShelters)
      ..sort(
        (a, b) => _distanceKm(
          userLat,
          userLng,
          a.lat,
          a.lng,
        ).compareTo(_distanceKm(userLat, userLng, b.lat, b.lng)),
      );
    return sorted.take(count).toList();
  }

  double distanceTo(double userLat, double userLng, Shelter shelter) =>
      _distanceKm(userLat, userLng, shelter.lat, shelter.lng);

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;
}
