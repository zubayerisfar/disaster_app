import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists volunteer registration info locally via SharedPreferences.
class VolunteerService {
  static const _profileKey = 'volunteer_profile';
  static const _volunteersKey = 'all_volunteers';
  static const _sheltersKey = 'volunteer_shelters';

  // ── Profile ──────────────────────────────────────────────────────────────

  Future<bool> isRegistered() async {
    final p = await SharedPreferences.getInstance();
    return p.containsKey(_profileKey);
  }

  Future<void> saveProfile(VolunteerProfile profile) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_profileKey, jsonEncode(profile.toJson()));

    // Also add to all_volunteers list
    final volunteers = await getAllVolunteers();
    final existingIndex = volunteers.indexWhere(
      (v) => v.phone == profile.phone,
    );
    if (existingIndex >= 0) {
      volunteers[existingIndex] = profile;
    } else {
      volunteers.add(profile);
    }
    await p.setString(
      _volunteersKey,
      jsonEncode(volunteers.map((e) => e.toJson()).toList()),
    );
  }

  Future<VolunteerProfile?> getProfile() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_profileKey);
    if (s == null) return null;
    return VolunteerProfile.fromJson(jsonDecode(s));
  }

  // ── All Volunteers ─────────────────────────────────────────────────────────

  Future<List<VolunteerProfile>> getAllVolunteers() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_volunteersKey);
    if (s == null) return [];
    final List<dynamic> list = jsonDecode(s);
    return list.map((e) => VolunteerProfile.fromJson(e)).toList();
  }

  // ── Volunteer-added shelters ─────────────────────────────────────────────

  Future<List<VolunteerShelter>> getShelters() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_sheltersKey);
    if (s == null) return [];
    final List<dynamic> list = jsonDecode(s);
    return list.map((e) => VolunteerShelter.fromJson(e)).toList();
  }

  Future<void> addShelter(VolunteerShelter shelter) async {
    final p = await SharedPreferences.getInstance();
    final existing = await getShelters();
    existing.add(shelter);
    await p.setString(
      _sheltersKey,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class VolunteerProfile {
  final String name;
  final String phone;
  final String area;
  final String skills;
  final double lat;
  final double lng;
  final DateTime registeredAt;

  const VolunteerProfile({
    required this.name,
    required this.phone,
    required this.area,
    required this.skills,
    required this.lat,
    required this.lng,
    required this.registeredAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'area': area,
    'skills': skills,
    'lat': lat,
    'lng': lng,
    'registeredAt': registeredAt.toIso8601String(),
  };

  factory VolunteerProfile.fromJson(Map<String, dynamic> j) => VolunteerProfile(
    name: j['name'] ?? '',
    phone: j['phone'] ?? '',
    area: j['area'] ?? '',
    skills: j['skills'] ?? '',
    lat: (j['lat'] as num?)?.toDouble() ?? 0.0,
    lng: (j['lng'] as num?)?.toDouble() ?? 0.0,
    registeredAt: DateTime.parse(
      j['registeredAt'] ?? DateTime.now().toIso8601String(),
    ),
  );
}

class VolunteerShelter {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String district;
  final int capacity;
  final String addedBy; // volunteer name
  final DateTime addedAt;

  const VolunteerShelter({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.district,
    required this.capacity,
    required this.addedBy,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'lat': lat,
    'lng': lng,
    'district': district,
    'capacity': capacity,
    'addedBy': addedBy,
    'addedAt': addedAt.toIso8601String(),
  };

  factory VolunteerShelter.fromJson(Map<String, dynamic> j) => VolunteerShelter(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    address: j['address'] ?? '',
    lat: (j['lat'] as num?)?.toDouble() ?? 0.0,
    lng: (j['lng'] as num?)?.toDouble() ?? 0.0,
    district: j['district'] ?? '',
    capacity: (j['capacity'] as num?)?.toInt() ?? 0,
    addedBy: j['addedBy'] ?? '',
    addedAt: DateTime.parse(j['addedAt'] ?? DateTime.now().toIso8601String()),
  );
}
