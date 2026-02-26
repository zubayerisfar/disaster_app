// Service that fetches weather data from the AccuWeather API.
//
// Flow per fetch:
//   1. Geoposition search  →  locationKey  (cached per lat/lon)
//   2. Current Conditions  →  temp, wind, humidity, description
//   3. 5-Day Daily Forecast → daily min/max, icon, rain
//
// Falls back to realistic demo data when the API key is missing or any
// request fails.  AccuWeather free tier: 50 calls/day.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _apiKey = Secrets.accuWeatherApiKey;

  static const String _base = 'https://dataservice.accuweather.com';

  // Cache locationKey per "lat,lon" to avoid redundant geoposition calls.
  static final Map<String, String> _locationKeyCache = {};

  static Map<String, String> get _authHeader => {
    'Authorization': 'Bearer $_apiKey',
  };

  /// Fetches weather for the given [lat]/[lon].
  /// Makes up to 3 API calls (geoposition, current, forecast).
  /// Falls back to demo data on any failure.
  Future<WeatherData> fetchWeather(double lat, double lon) async {
    try {
      final locationKey = await _getLocationKey(lat, lon);
      if (locationKey == null) {
        debugPrint('WeatherService: could not get location key – demo data.');
        return _demoWeatherData();
      }

      // Fetch current conditions and 5-day forecast in parallel.
      final results = await Future.wait([
        http
            .get(
              Uri.parse(
                '$_base/currentconditions/v1/$locationKey?details=true',
              ),
              headers: _authHeader,
            )
            .timeout(const Duration(seconds: 10)),
        http
            .get(
              Uri.parse(
                '$_base/forecasts/v1/daily/5day/$locationKey?metric=true&details=true',
              ),
              headers: _authHeader,
            )
            .timeout(const Duration(seconds: 10)),
      ]);

      final currentRes = results[0];
      final forecastRes = results[1];

      if (currentRes.statusCode == 200 && forecastRes.statusCode == 200) {
        final currentJson =
            (jsonDecode(currentRes.body) as List).first as Map<String, dynamic>;
        final forecastJson =
            jsonDecode(forecastRes.body) as Map<String, dynamic>;
        return _parse(currentJson, forecastJson);
      } else {
        debugPrint(
          'WeatherService: HTTP ${currentRes.statusCode}/${forecastRes.statusCode} – demo data.',
        );
        return _demoWeatherData();
      }
    } catch (e) {
      debugPrint('WeatherService: error ($e) – demo data.');
      return _demoWeatherData();
    }
  }

  /// Calls the AccuWeather Geoposition endpoint to get the location key for
  /// the given coordinates.  Result is cached so subsequent calls for the
  /// same location cost no extra API quota.
  Future<String?> _getLocationKey(double lat, double lon) async {
    final cacheKey = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
    if (_locationKeyCache.containsKey(cacheKey)) {
      return _locationKeyCache[cacheKey];
    }

    final uri = Uri.parse(
      '$_base/locations/v1/cities/geoposition/search?q=$lat,$lon',
    );
    final res = await http
        .get(uri, headers: _authHeader)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final key = json['Key'] as String?;
      if (key != null) _locationKeyCache[cacheKey] = key;
      return key;
    }
    debugPrint('WeatherService: geoposition HTTP ${res.statusCode}');
    return null;
  }

  /// Parses AccuWeather current + forecast responses into [WeatherData].
  static WeatherData _parse(
    Map<String, dynamic> current,
    Map<String, dynamic> forecast,
  ) {
    // ── Current conditions ────────────────────────────────────────────────
    final temp =
        (current['Temperature'] as Map)['Metric'] as Map<String, dynamic>;
    final wind =
        ((current['Wind'] as Map)['Speed'] as Map)['Metric']
            as Map<String, dynamic>;
    final humidity = (current['RelativeHumidity'] as num?)?.toDouble() ?? 0.0;
    final currentIconCode = _acuIconToOwm(current['WeatherIcon'] as int? ?? 1);

    // ── 5-day daily forecast ──────────────────────────────────────────────
    final dailyList = (forecast['DailyForecasts'] as List)
        .cast<Map<String, dynamic>>();

    final daily = dailyList.map((d) {
      final date = DateTime.parse(d['Date'] as String);
      final minT =
          ((d['Temperature'] as Map)['Minimum'] as Map)['Value'] as num;
      final maxT =
          ((d['Temperature'] as Map)['Maximum'] as Map)['Value'] as num;
      final daySegment = d['Day'] as Map<String, dynamic>;
      final icon = _acuIconToOwm(daySegment['Icon'] as int? ?? 1);
      final phrase = daySegment['IconPhrase'] as String? ?? '';
      final windSpeed =
          (((daySegment['Wind'] as Map?)?['Speed'] as Map?)?['Value'] as num?)
              ?.toDouble() ??
          0.0; // already km/h from metric=true
      final rainMm =
          ((daySegment['Rain'] as Map?)?['Value'] as num?)?.toDouble() ?? 0.0;
      final humidityDay =
          ((daySegment['RelativeHumidity'] as Map?)?['Average'] as num?)
              ?.toDouble() ??
          humidity;

      return DayForecast(
        date: DateTime(date.year, date.month, date.day),
        tempMin: minT.toDouble(),
        tempMax: maxT.toDouble(),
        humidity: humidityDay,
        windSpeed: windSpeed,
        description: phrase,
        iconCode: icon,
        precipitation: rainMm,
      );
    }).toList();

    return WeatherData(
      currentTemp: (temp['Value'] as num).toDouble(),
      currentWindSpeed: (wind['Value'] as num).toDouble(),
      currentHumidity: humidity,
      currentDescription: current['WeatherText'] as String? ?? '',
      currentIconCode: currentIconCode,
      daily: daily,
    );
  }

  /// Maps AccuWeather icon codes (1–44) to equivalent OpenWeatherMap icon
  /// codes so the existing [DayForecast.iconUrl] getter keeps working.
  static String _acuIconToOwm(int icon) {
    if (icon <= 2) return '01d'; // sunny
    if (icon <= 5) return '02d'; // partly cloudy / haze
    if (icon <= 7) return '03d'; // mostly cloudy
    if (icon == 8) return '04d'; // overcast
    if (icon == 11) return '50d'; // fog
    if (icon == 12) return '09d'; // showers
    if (icon <= 14) return '10d'; // rain
    if (icon <= 17) return '11d'; // t-storm
    if (icon == 18) return '10d'; // rain
    if (icon <= 29) return '13d'; // snow / ice / sleet
    if (icon <= 32) return '50d'; // hot / cold / windy
    if (icon <= 34) return '01n'; // clear night
    if (icon <= 37) return '02n'; // partly cloudy night
    if (icon == 38) return '03n'; // mostly cloudy night
    if (icon <= 40) return '09n'; // showers night
    if (icon <= 42) return '11n'; // t-storm night
    return '13n'; // snow night (43–44)
  }

  // ---------------------------------------------------------------------------
  // Demo / mock weather data – mirrors Bangladesh pre-monsoon conditions
  // ---------------------------------------------------------------------------

  /// Public accessor used by [WeatherProvider] constructor to seed the UI
  /// immediately before any real API call completes.
  static WeatherData getDemoData() => _demoWeatherData();

  /// Returns realistic sample weather data for Bangladesh so the UI is
  /// always populated even without a real API key or internet connection.
  static WeatherData _demoWeatherData() {
    final now = DateTime.now();
    final icons = ['04d', '10d', '09d', '11d', '10d', '02d', '01d'];
    final descs = [
      'overcast clouds',
      'moderate rain',
      'light rain',
      'thunderstorm',
      'light rain',
      'few clouds',
      'clear sky',
    ];
    final maxTemps = [33.0, 30.0, 28.0, 27.0, 29.0, 32.0, 34.0];
    final minTemps = [26.0, 24.0, 23.0, 22.0, 24.0, 25.0, 26.0];
    final winds = [22.0, 35.0, 28.0, 55.0, 18.0, 12.0, 10.0]; // km/h
    final humidities = [85.0, 90.0, 92.0, 88.0, 82.0, 75.0, 70.0];
    final rains = [0.0, 12.0, 5.0, 20.0, 3.0, 0.0, 0.0];

    final daily = List.generate(7, (i) {
      return DayForecast(
        date: now.add(Duration(days: i)),
        tempMin: minTemps[i],
        tempMax: maxTemps[i],
        humidity: humidities[i],
        windSpeed: winds[i],
        description: descs[i],
        iconCode: icons[i],
        precipitation: rains[i],
      );
    });

    return WeatherData(
      currentTemp: 32.0,
      currentWindSpeed: 22.0,
      currentHumidity: 85.0,
      currentDescription: 'overcast clouds',
      currentIconCode: '04d',
      daily: daily,
    );
  }

  // ---------------------------------------------------------------------------
  // Warning level helpers
  // ---------------------------------------------------------------------------

  /// Maps a wind speed (km/h) to the Bangladesh Meteorological Department
  /// cyclone warning signal number (0 = no signal / safe, 1–10 = BMD signals).
  static int calculateWarningLevel(double windSpeedKmh) {
    if (windSpeedKmh < 40) return 0; // Safe – no warning signal
    if (windSpeedKmh < 51) return 1; // Signal 1 – distant caution  (40–50)
    if (windSpeedKmh < 62) return 2; // Signal 2 – distant warning  (51–61)
    if (windSpeedKmh < 71) return 4; // Signal 4 – local warning    (62–70)
    if (windSpeedKmh < 81) return 5; // Signal 5 – danger           (71–80)
    if (windSpeedKmh < 91) return 6; // Signal 6 – big danger       (81–90)
    if (windSpeedKmh < 111) return 7; // Signal 7 – great danger    (91–110)
    if (windSpeedKmh < 121) return 8; // Signal 8 – catastrophic    (111–120)
    if (windSpeedKmh < 151) return 9; // Signal 9 – extreme         (121–150)
    return 10; // Signal 10 – super-cyclone (≥151)
  }

  /// Returns a short human-readable description for a given warning level
  /// (0 = safe, 1–10 = BMD warning signals).
  static String warningDescription(int level) {
    if (level == 0) return 'আবহাওয়া স্বাভাবিক। কোনো সংকেত নেই।';
    if (level <= 2) return 'সাধারণ সতর্কতা। আবহাওয়ার খবর অনুসরণ করুন।';
    if (level <= 4) return 'স্থানীয় হুঁশিয়ারি সংকেত। সতর্ক থাকুন।';
    if (level <= 6) return 'বিপদ সংকেত! ঝড় আসছে। আশ্রয়ের প্রস্তুতি নিন।';
    if (level <= 8) return 'মহাবিপদ সংকেত! অবিলম্বে আশ্রয়ে যান।';
    return 'সর্বোচ্চ বিপদ! সুপার সাইক্লোন। বের হবেন না।';
  }

  /// Returns the background colour associated with a warning level.
  static int warningColor(int level) {
    if (level <= 2) return 0xFF4CAF50; // green
    if (level <= 4) return 0xFFFF9800; // orange
    if (level <= 7) return 0xFFFF5722; // deep-orange
    return 0xFFB71C1C; // dark red
  }
}
