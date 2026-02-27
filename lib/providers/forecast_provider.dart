import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ── Public models ─────────────────────────────────────────────────────────────

class CurrentWeather {
  final double temperature; // °C
  final double humidity; // %
  final double windSpeed; // km/h
  final int weatherCode; // WMO

  const CurrentWeather({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
  });

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'weatherCode': weatherCode,
  };

  factory CurrentWeather.fromJson(Map<String, dynamic> m) => CurrentWeather(
    temperature: (m['temperature'] as num?)?.toDouble() ?? 0.0,
    humidity: (m['humidity'] as num?)?.toDouble() ?? 0.0,
    windSpeed: (m['windSpeed'] as num?)?.toDouble() ?? 0.0,
    weatherCode: (m['weatherCode'] as num?)?.toInt() ?? 0,
  );
}

class ForecastDay {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double precipitation; // mm
  final double windSpeed; // km/h
  final double humidity; // %
  final int weatherCode; // WMO

  const ForecastDay({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipitation,
    required this.windSpeed,
    required this.humidity,
    required this.weatherCode,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weatherCode': weatherCode,
    'tempMax': tempMax,
    'tempMin': tempMin,
    'precipitation': precipitation,
    'windSpeed': windSpeed,
    'humidity': humidity,
  };

  factory ForecastDay.fromJson(Map<String, dynamic> m) => ForecastDay(
    date: DateTime.parse(m['date'] as String),
    weatherCode: (m['weatherCode'] as num?)?.toInt() ?? 0,
    tempMax: (m['tempMax'] as num?)?.toDouble() ?? 0.0,
    tempMin: (m['tempMin'] as num?)?.toDouble() ?? 0.0,
    precipitation: (m['precipitation'] as num?)?.toDouble() ?? 0.0,
    windSpeed: (m['windSpeed'] as num?)?.toDouble() ?? 0.0,
    humidity: (m['humidity'] as num?)?.toDouble() ?? 0.0,
  );
}

// ── Provider ──────────────────────────────────────────────────────────────────

class ForecastProvider extends ChangeNotifier {
  List<ForecastDay>? _forecasts;
  CurrentWeather? _currentWeather;
  bool _loading = false;
  String? _error;
  bool _fromCache = false;
  DateTime? _cachedAt;
  String? _lastFetchKey;

  List<ForecastDay>? get forecasts => _forecasts;
  CurrentWeather? get currentWeather => _currentWeather;
  bool get loading => _loading;
  String? get error => _error;
  bool get fromCache => _fromCache;
  DateTime? get cachedAt => _cachedAt;

  static String _cacheKey(double lat, double lon) =>
      'forecast_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
  static String _cacheTimeKey(double lat, double lon) =>
      'forecast_time_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
  static String _currentCacheKey(double lat, double lon) =>
      'current_weather_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
  static String _currentCacheTimeKey(double lat, double lon) =>
      'current_weather_time_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';

  /// Call this when the user's location changes (from AppProvider).
  Future<void> fetchForLocation(double lat, double lon) async {
    final key = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';

    // Skip only if already loading for this location
    if (key == _lastFetchKey && _loading) {
      return;
    }

    _lastFetchKey = key;

    // 1. Load cache immediately
    final cached = await _loadFromCache(lat, lon);
    final cachedCurrent = await _loadCurrentFromCache(lat, lon);
    if (cached != null) {
      _forecasts = cached;
      _currentWeather = cachedCurrent;
      _fromCache = true;
      _loading = true; // Keep loading to indicate fresh fetch in progress
      _error = null;
      notifyListeners();
    } else {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    // 2. Fetch fresh from network
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min'
        ',precipitation_sum,wind_speed_10m_max,relative_humidity_2m_max'
        '&timezone=auto&forecast_days=7',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;

        // Parse current weather
        final current = json['current'] as Map<String, dynamic>?;

        CurrentWeather? currentWeather;
        if (current != null) {
          currentWeather = CurrentWeather(
            temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
            humidity:
                (current['relative_humidity_2m'] as num?)?.toDouble() ?? 0.0,
            windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
            weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
          );
        }

        final daily = json['daily'] as Map<String, dynamic>;

        final times = daily['time'] as List;
        final codes = daily['weather_code'] as List;
        final maxT = daily['temperature_2m_max'] as List;
        final minT = daily['temperature_2m_min'] as List;
        final precip = daily['precipitation_sum'] as List;
        final wind = daily['wind_speed_10m_max'] as List;
        final hum = daily['relative_humidity_2m_max'] as List;

        final list = List.generate(times.length, (i) {
          return ForecastDay(
            date: DateTime.parse(times[i] as String),
            weatherCode: (codes[i] as num?)?.toInt() ?? 0,
            tempMax: (maxT[i] as num?)?.toDouble() ?? 0.0,
            tempMin: (minT[i] as num?)?.toDouble() ?? 0.0,
            precipitation: (precip[i] as num?)?.toDouble() ?? 0.0,
            windSpeed: (wind[i] as num?)?.toDouble() ?? 0.0,
            humidity: (hum[i] as num?)?.toDouble() ?? 0.0,
          );
        });

        await _saveToCache(lat, lon, list);
        if (currentWeather != null) {
          await _saveCurrentToCache(lat, lon, currentWeather);
        }

        _forecasts = list;
        _currentWeather = currentWeather;
        _fromCache = false;
        _cachedAt = null;
        _loading = false;
        _error = null;
        notifyListeners();
      } else {
        if (_forecasts == null) {
          _error = 'সার্ভার ত্রুটি (${res.statusCode})';
          _loading = false;
          notifyListeners();
        } else {
          _loading = false;
          notifyListeners();
        }
      }
    } catch (e) {
      if (_forecasts == null) {
        _error = 'ইন্টারনেট সংযোগ নেই';
        _loading = false;
        notifyListeners();
      } else {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Force-refresh ignoring the last-fetch-key guard.
  Future<void> refresh(double lat, double lon) async {
    _lastFetchKey = null;
    await fetchForLocation(lat, lon);
  }

  // ── Cache helpers ──────────────────────────────────────────────────────────

  Future<List<ForecastDay>?> _loadFromCache(double lat, double lon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(lat, lon));
      final ts = prefs.getInt(_cacheTimeKey(lat, lon));
      if (raw == null || ts == null) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final age = DateTime.now().difference(cachedAt);
      if (age.inDays > 7) return null;
      _cachedAt = cachedAt;
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => ForecastDay.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(
    double lat,
    double lon,
    List<ForecastDay> list,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey(lat, lon),
        jsonEncode(list.map((d) => d.toJson()).toList()),
      );
      await prefs.setInt(
        _cacheTimeKey(lat, lon),
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<CurrentWeather?> _loadCurrentFromCache(double lat, double lon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_currentCacheKey(lat, lon));
      if (raw == null) return null;
      final ts = prefs.getInt(_currentCacheTimeKey(lat, lon));
      if (ts == null) return null;
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(ts),
      );
      if (age.inDays > 7) return null;
      final weather = CurrentWeather.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return weather;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCurrentToCache(
    double lat,
    double lon,
    CurrentWeather current,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _currentCacheKey(lat, lon),
        jsonEncode(current.toJson()),
      );
      await prefs.setInt(
        _currentCacheTimeKey(lat, lon),
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }
}
