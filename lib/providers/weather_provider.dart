// WeatherProvider fetches weather data from OpenWeatherMap and exposes it
// to the UI via ChangeNotifier.  It also computes the Bangladesh cyclone
// warning signal level from the current wind speed.
//
// On creation, demo data is loaded immediately so the Home page is always
// populated, even before GPS or the real API responds.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  static const _cacheKey = 'weather_cache_data';
  static const _cacheTimeKey = 'weather_cache_time';

  final WeatherService _service = WeatherService();

  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _error;
  int _warningLevel = 1;
  bool _fromCache = false;
  bool _isDemo = true; // Track if showing demo data
  DateTime? _cachedAt;

  WeatherProvider() {
    _loadDemoImmediately();
    _loadCache(); // load persisted data in background
  }

  // Getters
  WeatherData? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get warningLevel => _warningLevel;
  bool get fromCache => _fromCache;
  bool get isDemo => _isDemo; // Expose demo status
  DateTime? get cachedAt => _cachedAt;
  String get warningDescription =>
      WeatherService.warningDescription(_warningLevel);
  int get warningColor => WeatherService.warningColor(_warningLevel);

  /// Loads demo weather immediately (synchronously via service static method).
  void _loadDemoImmediately() {
    _weatherData = WeatherService.getDemoData();
    _warningLevel = WeatherService.calculateWarningLevel(
      _weatherData!.currentWindSpeed,
    );
    // No need to notifyListeners – called from constructor before any listeners.
  }

  /// Try to restore previously cached weather from SharedPreferences.
  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      final ts = prefs.getInt(_cacheTimeKey);

      if (raw == null || ts == null) {
        return;
      }

      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final age = DateTime.now().difference(cachedAt).inSeconds;
      // Accept cache up to 7 days old (offline safety net)
      if (age > 7 * 24 * 3600) {
        return;
      }

      final jsonData = jsonDecode(raw) as Map<String, dynamic>;
      final data = WeatherData.fromCache(jsonData);
      _weatherData = data;
      _warningLevel = WeatherService.calculateWarningLevel(
        data.currentWindSpeed,
      );
      _fromCache = true;
      _isDemo = data.isDemo; // Respect the isDemo flag from cache
      _cachedAt = cachedAt;
      notifyListeners();
    } catch (e) {
      // Silent fail - cache not available
    }
  }

  /// Persist current weather data to SharedPreferences.
  Future<void> _saveCache(WeatherData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = data.toCache();
      final jsonString = jsonEncode(jsonData);
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silent fail - cache not available
    }
  }

  /// Fetches real weather for the given [lat]/[lon] and computes warning level.
  Future<void> loadWeather(double lat, double lon) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _weatherData = await _service.fetchWeather(lat, lon);
      _warningLevel = WeatherService.calculateWarningLevel(
        _weatherData!.currentWindSpeed,
      );

      // Check if returned data is demo - DON'T cache or mark as real if demo!
      if (_weatherData!.isDemo) {
        _isDemo = true; // Keep showing demo
        _fromCache = false;
      } else {
        // Real API data - mark as real and cache it
        _fromCache = false;
        _isDemo = false; // Real API data
        _cachedAt = null;
        await _saveCache(_weatherData!);
      }
    } catch (e) {
      _error = 'Could not load weather: ${e.toString()}';
      // Keep previously loaded (demo/cached) data visible.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
