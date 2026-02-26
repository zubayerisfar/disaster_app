// ContactProvider manages the cascading division → district → upazila
// dropdown state and loads matching contacts from Firestore.

import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';

class ContactProvider extends ChangeNotifier {
  final ContactService _service = ContactService();

  List<String> _divisions = [];
  List<String> _districts = [];
  List<String> _upazilas = [];
  List<EmergencyContact> _contacts = [];

  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedUpazila;

  bool _isLoadingDivisions = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingUpazilas = false;
  bool _isLoadingContacts = false;
  String? _error;

  // Getters
  List<String> get divisions => _divisions;
  List<String> get districts => _districts;
  List<String> get upazilas => _upazilas;
  List<EmergencyContact> get contacts => _contacts;
  String? get selectedDivision => _selectedDivision;
  String? get selectedDistrict => _selectedDistrict;
  String? get selectedUpazila => _selectedUpazila;
  bool get isLoadingDivisions => _isLoadingDivisions;
  bool get isLoadingDistricts => _isLoadingDistricts;
  bool get isLoadingUpazilas => _isLoadingUpazilas;
  bool get isLoadingContacts => _isLoadingContacts;
  String? get error => _error;

  // ──────────────────────────────────────────────────────────────────────────
  // Load divisions (called once on page init)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> loadDivisions() async {
    _isLoadingDivisions = true;
    _error = null;
    notifyListeners();

    try {
      _divisions = await _service.fetchDivisions();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingDivisions = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Division selected → load districts
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> selectDivision(String division) async {
    _selectedDivision = division;
    _selectedDistrict = null;
    _selectedUpazila = null;
    _districts = [];
    _upazilas = [];
    _contacts = [];
    _isLoadingDistricts = true;
    _error = null;
    notifyListeners();

    try {
      _districts = await _service.fetchDistricts(division);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingDistricts = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // District selected → load upazilas
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> selectDistrict(String district) async {
    _selectedDistrict = district;
    _selectedUpazila = null;
    _upazilas = [];
    _contacts = [];
    _isLoadingUpazilas = true;
    _error = null;
    notifyListeners();

    try {
      _upazilas = await _service.fetchUpazilas(_selectedDivision!, district);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingUpazilas = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Upazila selected → load contacts
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> selectUpazila(String upazila) async {
    _selectedUpazila = upazila;
    _contacts = [];
    _isLoadingContacts = true;
    _error = null;
    notifyListeners();

    try {
      _contacts = await _service.fetchContacts(
        division: _selectedDivision!,
        district: _selectedDistrict!,
        upazila: upazila,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingContacts = false;
      notifyListeners();
    }
  }
}
