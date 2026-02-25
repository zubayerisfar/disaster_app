/// WeatherProvider fetches weather data from OpenWeatherMap and exposes it
/// to the UI via ChangeNotifier.  It also computes the Bangladesh cyclone
/// warning signal level from the current wind speed.
///
/// On creation, demo data is loaded immediately so the Home page is always
/// populated, even before GPS or the real API responds.

import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _service = WeatherService();

  // Start with demo data so the UI renders right away.
  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _error;
  int _warningLevel = 1;

  WeatherProvider() {
    _loadDemoImmediately();
  }

  // Getters
  WeatherData? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get warningLevel => _warningLevel;
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
    } catch (e) {
      _error = 'Could not load weather: ${e.toString()}';
      // Keep previously loaded (demo) data visible.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
