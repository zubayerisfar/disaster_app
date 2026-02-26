// AppProvider manages shared app-level state: selected district, current
// location coordinates, and the date/time display string.
//
// It is the single source of truth for location-dependent data loading;
// other providers listen for [selectedDistrict] changes and reload data.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  // ──────────────────────────────────────────────────────────────────────────
  // State
  // ──────────────────────────────────────────────────────────────────────────

  String _selectedDistrict = 'Dhaka';
  double _latitude = 23.8103; // default: Dhaka
  double _longitude = 90.4125;
  String _dateTimeString = '';
  bool _isLocating = false;
  String? _locationError;
  String _sosNumber = '999'; // Default SOS number

  // ──────────────────────────────────────────────────────────────────────────
  // Getters
  // ──────────────────────────────────────────────────────────────────────────

  String get selectedDistrict => _selectedDistrict;
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get dateTimeString => _dateTimeString;
  bool get isLocating => _isLocating;
  String? get locationError => _locationError;
  String get sosNumber => _sosNumber;

  // ──────────────────────────────────────────────────────────────────────────
  // Date / Time
  // ──────────────────────────────────────────────────────────────────────────

  /// Updates the displayed date and time string in Asia/Dhaka timezone.
  /// Call this every minute from a periodic timer in main.dart.
  void refreshDateTime() {
    // intl's DateFormat uses the local timezone; ensure the device is set to
    // Asia/Dhaka or convert manually if needed.
    _dateTimeString = DateFormat('EEE, d MMM yyyy').format(DateTime.now());
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Location
  // ──────────────────────────────────────────────────────────────────────────

  /// Requests the device's current GPS position and updates [_latitude] and
  /// [_longitude].  Uses [geolocator] for cross-platform location access.
  /// Also detects and sets the nearest district based on coordinates.
  Future<void> fetchCurrentLocation() async {
    _isLocating = true;
    _locationError = null;
    notifyListeners();

    try {
      // Check/request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Auto-detect nearest district from coordinates
      _selectedDistrict = _detectNearestDistrict(_latitude, _longitude);
    } catch (e) {
      _locationError = e.toString();
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }

  /// Detects the nearest district from given coordinates using distance calculation
  String _detectNearestDistrict(double lat, double lon) {
    String nearestDistrict = 'Dhaka';
    double minDistance = double.infinity;

    _districtCoords.forEach((district, coords) {
      final districtLat = coords.$1;
      final districtLon = coords.$2;

      // Calculate distance using Haversine formula
      final distance = _calculateDistance(lat, lon, districtLat, districtLon);

      if (distance < minDistance) {
        minDistance = distance;
        nearestDistrict = district;
      }
    });

    return nearestDistrict;
  }

  /// Calculate distance between two coordinates in kilometers (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;

  // ──────────────────────────────────────────────────────────────────────────
  // District selection
  // ──────────────────────────────────────────────────────────────────────────

  /// Allows the user to manually override the active district.
  /// Also updates [_latitude]/[_longitude] to the district's centre coordinates
  /// so the weather and shelter APIs fetch data for the correct location.
  void setDistrict(String district) {
    if (_selectedDistrict == district) return;
    _selectedDistrict = district;
    final coords = _districtCoords[district];
    if (coords != null) {
      _latitude = coords.$1;
      _longitude = coords.$2;
    }
    notifyListeners();
  }

  // ── District centre coordinates (lat, lon) ────────────────────────────────
  static const Map<String, (double, double)> _districtCoords = {
    'Bagerhat': (22.6602, 89.7806),
    'Bandarban': (22.1953, 92.2184),
    'Barguna': (22.0959, 90.1120),
    'Barisal': (22.7010, 90.3535),
    'Bhola': (22.6859, 90.6482),
    'Bogra': (24.8465, 89.3720),
    'Brahmanbaria': (23.9571, 91.1115),
    'Chandpur': (23.2323, 90.6717),
    'Chapainawabganj': (24.5965, 88.2778),
    'Chittagong': (22.3569, 91.7832),
    'Chuadanga': (23.6402, 88.8416),
    'Comilla': (23.4607, 91.1809),
    "Cox's Bazar": (21.4272, 92.0058),
    'Dhaka': (23.8103, 90.4125),
    'Dinajpur': (25.6279, 88.6338),
    'Faridpur': (23.6070, 89.8429),
    'Feni': (23.0159, 91.3976),
    'Gaibandha': (25.3288, 89.5281),
    'Gazipur': (23.9999, 90.4203),
    'Gopalganj': (23.0051, 89.8266),
    'Habiganj': (24.3745, 91.4154),
    'Jamalpur': (24.8949, 89.9371),
    'Jessore': (23.1664, 89.2121),
    'Jhalokati': (22.6406, 90.1983),
    'Jhenaidah': (23.5449, 89.1524),
    'Joypurhat': (25.0974, 89.0222),
    'Khagrachhari': (23.1193, 91.9847),
    'Khulna': (22.8456, 89.5403),
    'Kishoreganj': (24.4449, 90.7767),
    'Kurigram': (25.8482, 89.6363),
    'Kushtia': (23.9013, 89.1194),
    'Lakshmipur': (22.9418, 90.8412),
    'Lalmonirhat': (25.9923, 89.2847),
    'Madaripur': (23.1643, 90.1982),
    'Magura': (23.4873, 89.4192),
    'Manikganj': (23.8634, 90.0021),
    'Meherpur': (23.7623, 88.6317),
    'Moulvibazar': (24.4829, 91.7774),
    'Munshiganj': (23.5422, 90.5307),
    'Mymensingh': (24.7471, 90.4203),
    'Naogaon': (24.7936, 88.9315),
    'Narail': (23.1724, 89.5124),
    'Narayanganj': (23.6238, 90.4996),
    'Narsingdi': (23.9324, 90.7150),
    'Natore': (24.4204, 88.9882),
    'Netrokona': (24.8703, 90.7203),
    'Nilphamari': (25.9318, 88.8560),
    'Noakhali': (22.8696, 91.0993),
    'Pabna': (24.0063, 89.2372),
    'Panchagarh': (26.3411, 88.5542),
    'Patuakhali': (22.3596, 90.3290),
    'Pirojpur': (22.5841, 89.9758),
    'Rajbari': (23.7574, 89.6444),
    'Rajshahi': (24.3745, 88.6042),
    'Rangamati': (22.7324, 92.2985),
    'Rangpur': (25.7439, 89.2752),
    'Satkhira': (22.7185, 89.0705),
    'Shariatpur': (23.2424, 90.4352),
    'Sherpur': (25.0204, 90.0157),
    'Sirajganj': (24.4534, 89.7006),
    'Sunamganj': (25.0658, 91.3950),
    'Sylhet': (24.8949, 91.8687),
    'Tangail': (24.2513, 89.9167),
    'Thakurgaon': (26.0336, 88.4616),
  };

  // ──────────────────────────────────────────────────────────────────────────
  // District name translation (English → Bangla for UI display)
  // ──────────────────────────────────────────────────────────────────────────

  static const Map<String, String> districtNamesBangla = {
    'Bagerhat': 'বাগেরহাট',
    'Bandarban': 'বান্দরবান',
    'Barguna': 'বরগুনা',
    'Barisal': 'বরিশাল',
    'Bhola': 'ভোলা',
    'Bogra': 'বগুড়া',
    'Brahmanbaria': 'ব্রাহ্মণবাড়িয়া',
    'Chandpur': 'চাঁদপুর',
    'Chapainawabganj': 'চাঁপাইনবাবগঞ্জ',
    'Chittagong': 'চট্টগ্রাম',
    'Chuadanga': 'চুয়াডাঙ্গা',
    'Comilla': 'কুমিল্লা',
    "Cox's Bazar": 'কক্সবাজার',
    'Dhaka': 'ঢাকা',
    'Dinajpur': 'দিনাজপুর',
    'Faridpur': 'ফরিদপুর',
    'Feni': 'ফেনী',
    'Gaibandha': 'গাইবান্ধা',
    'Gazipur': 'গাজীপুর',
    'Gopalganj': 'গোপালগঞ্জ',
    'Habiganj': 'হবিগঞ্জ',
    'Jamalpur': 'জামালপুর',
    'Jessore': 'যশোর',
    'Jhalokati': 'ঝালকাঠি',
    'Jhenaidah': 'ঝিনাইদহ',
    'Joypurhat': 'জয়পুরহাট',
    'Khagrachhari': 'খাগড়াছড়ি',
    'Khulna': 'খুলনা',
    'Kishoreganj': 'কিশোরগঞ্জ',
    'Kurigram': 'কুড়িগ্রাম',
    'Kushtia': 'কুষ্টিয়া',
    'Lakshmipur': 'লক্ষ্মীপুর',
    'Lalmonirhat': 'লালমনিরহাট',
    'Madaripur': 'মাদারীপুর',
    'Magura': 'মাগুরা',
    'Manikganj': 'মানিকগঞ্জ',
    'Meherpur': 'মেহেরপুর',
    'Moulvibazar': 'মৌলভীবাজার',
    'Munshiganj': 'মুন্সিগঞ্জ',
    'Mymensingh': 'ময়মনসিংহ',
    'Naogaon': 'নওগাঁ',
    'Narail': 'নড়াইল',
    'Narayanganj': 'নারায়ণগঞ্জ',
    'Narsingdi': 'নরসিংদী',
    'Natore': 'নাটোর',
    'Netrokona': 'নেত্রকোনা',
    'Nilphamari': 'নীলফামারী',
    'Noakhali': 'নোয়াখালী',
    'Pabna': 'পাবনা',
    'Panchagarh': 'পঞ্চগড়',
    'Patuakhali': 'পটুয়াখালী',
    'Pirojpur': 'পিরোজপুর',
    'Rajbari': 'রাজবাড়ী',
    'Rajshahi': 'রাজশাহী',
    'Rangamati': 'রাঙ্গামাটি',
    'Rangpur': 'রংপুর',
    'Satkhira': 'সাতক্ষীরা',
    'Shariatpur': 'শরীয়তপুর',
    'Sherpur': 'শেরপুর',
    'Sirajganj': 'সিরাজগঞ্জ',
    'Sunamganj': 'সুনামগঞ্জ',
    'Sylhet': 'সিলেট',
    'Tangail': 'টাঙ্গাইল',
    'Thakurgaon': 'ঠাকুরগাঁও',
  };

  // ──────────────────────────────────────────────────────────────────────────
  // Static district list (Bangladesh)
  // ──────────────────────────────────────────────────────────────────────────

  static const List<String> allDistricts = [
    'Bagerhat',
    'Bandarban',
    'Barguna',
    'Barisal',
    'Bhola',
    'Bogra',
    'Brahmanbaria',
    'Chandpur',
    'Chapainawabganj',
    'Chittagong',
    'Chuadanga',
    'Comilla',
    "Cox's Bazar",
    'Dhaka',
    'Dinajpur',
    'Faridpur',
    'Feni',
    'Gaibandha',
    'Gazipur',
    'Gopalganj',
    'Habiganj',
    'Jamalpur',
    'Jessore',
    'Jhalokati',
    'Jhenaidah',
    'Joypurhat',
    'Khagrachhari',
    'Khulna',
    'Kishoreganj',
    'Kurigram',
    'Kushtia',
    'Lakshmipur',
    'Lalmonirhat',
    'Madaripur',
    'Magura',
    'Manikganj',
    'Meherpur',
    'Moulvibazar',
    'Munshiganj',
    'Mymensingh',
    'Naogaon',
    'Narail',
    'Narayanganj',
    'Narsingdi',
    'Natore',
    'Netrokona',
    'Nilphamari',
    'Noakhali',
    'Pabna',
    'Panchagarh',
    'Patuakhali',
    'Pirojpur',
    'Rajbari',
    'Rajshahi',
    'Rangamati',
    'Rangpur',
    'Satkhira',
    'Shariatpur',
    'Sherpur',
    'Sirajganj',
    'Sunamganj',
    'Sylhet',
    'Tangail',
    'Thakurgaon',
  ];

  // ──────────────────────────────────────────────────────────────────────────
  // SOS Number Settings
  // ──────────────────────────────────────────────────────────────────────────

  /// Load SOS number from SharedPreferences. Call this on app startup.
  Future<void> loadSosNumber() async {
    final prefs = await SharedPreferences.getInstance();
    _sosNumber = prefs.getString('sos_number') ?? '999';
    notifyListeners();
  }

  /// Save SOS number to SharedPreferences
  Future<void> setSosNumber(String number) async {
    _sosNumber = number;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sos_number', number);
    notifyListeners();
  }
}
