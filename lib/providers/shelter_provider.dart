/// ShelterProvider loads shelter data for the selected district and computes
/// distances from the user's current location.
///
/// Demo shelters for Dhaka are pre-loaded on creation so the Shelters page
/// is never blank.

import 'package:flutter/material.dart';
import '../models/shelter_model.dart';
import '../services/shelter_service.dart';

class ShelterProvider extends ChangeNotifier {
  final ShelterService _service = ShelterService();

  List<Shelter> _shelters = [];
  List<Shelter> _nearest = [];
  bool _isLoading = false;
  String? _error;

  List<Shelter> get shelters => _shelters;
  List<Shelter> get nearest => _nearest;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ShelterProvider() {
    // Pre-load Dhaka shelters so the Shelter page renders immediately.
    _loadDefault();
  }

  Future<void> _loadDefault() async {
    _shelters = await _service.fetchSheltersByDistrict('dhaka');
    _nearest = _service.nearestShelters(23.8103, 90.4125, _shelters);
    // No notifyListeners – before any listener is attached.
  }

  /// Fetches shelters for [district] and determines the [count] nearest ones
  /// based on [userLat]/[userLng].
  Future<void> loadShelters(
    String district,
    double userLat,
    double userLng, {
    int nearestCount = 3,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _shelters = await _service.fetchSheltersByDistrict(district);
      _nearest = _service.nearestShelters(
        userLat,
        userLng,
        _shelters,
        count: nearestCount,
      );
    } catch (e) {
      _error = 'Could not load shelters: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double distanceTo(double userLat, double userLng, Shelter shelter) =>
      _service.distanceTo(userLat, userLng, shelter);
}
