import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/app_provider.dart';
import 'widgets/disaster_app_bar.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Model
// ──────────────────────────────────────────────────────────────────────────────

class _DayForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double precipitation; // mm
  final double windSpeed; // km/h
  final double humidity; // %
  final int weatherCode; // WMO

  const _DayForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipitation,
    required this.windSpeed,
    required this.humidity,
    required this.weatherCode,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// WMO code helpers
// ──────────────────────────────────────────────────────────────────────────────

IconData _wmoIcon(int code) {
  if (code == 0) return Icons.wb_sunny_rounded;
  if (code <= 2) return Icons.wb_cloudy_rounded;
  if (code == 3) return Icons.cloud_rounded;
  if (code <= 48) return Icons.foggy;
  if (code <= 57) return Icons.grain;
  if (code <= 67) return Icons.umbrella_rounded;
  if (code <= 77) return Icons.ac_unit_rounded;
  if (code <= 82) return Icons.grain;
  if (code <= 86) return Icons.ac_unit_rounded;
  return Icons.thunderstorm_rounded;
}

Color _wmoColor(int code) {
  if (code == 0) return const Color(0xFFFF8F00);
  if (code <= 2) return const Color(0xFFFFB300);
  if (code == 3) return const Color(0xFF90A4AE);
  if (code <= 48) return const Color(0xFFB0BEC5);
  if (code <= 57) return const Color(0xFF64B5F6);
  if (code <= 67) return const Color(0xFF1565C0);
  if (code <= 77) return const Color(0xFF80DEEA);
  if (code <= 82) return const Color(0xFF1E88E5);
  if (code <= 86) return const Color(0xFF4DD0E1);
  return const Color(0xFF6A1B9A);
}

String _wmoDesc(int code) {
  if (code == 0) return 'পরিষ্কার আকাশ';
  if (code == 1) return 'প্রধানত পরিষ্কার';
  if (code == 2) return 'আংশিক মেঘলা';
  if (code == 3) return 'মেঘাচ্ছন্ন';
  if (code == 45 || code == 48) return 'কুয়াশা';
  if (code <= 55) return 'গুঁড়ি গুঁড়ি বৃষ্টি';
  if (code <= 67) return 'বৃষ্টি';
  if (code <= 77) return 'তুষারপাত';
  if (code <= 82) return 'বৃষ্টির ঝরনা';
  if (code <= 86) return 'তুষার ঝরনা';
  return 'বজ্রঝড়';
}

// Bengali day names
final _bnDayNames = {
  DateTime.monday: 'সোম',
  DateTime.tuesday: 'মঙ্গল',
  DateTime.wednesday: 'বুধ',
  DateTime.thursday: 'বৃহস্পতি',
  DateTime.friday: 'শুক্র',
  DateTime.saturday: 'শনি',
  DateTime.sunday: 'রবি',
};

// ──────────────────────────────────────────────────────────────────────────────
// Page
// ──────────────────────────────────────────────────────────────────────────────

class ForecastPage extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const ForecastPage({super.key, this.onMenuTap});

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  List<_DayForecast>? _forecasts;
  bool _loading = true;
  String? _error;
  bool _fromCache = false;
  DateTime? _cachedAt;

  // Track which district/coords we last fetched for, to avoid refetch
  String? _lastFetchKey;

  static String _cacheKey(double lat, double lon) =>
      'forecast_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
  static String _cacheTimeKey(double lat, double lon) =>
      'forecast_time_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';

  // ── Cache helpers ──────────────────────────────────────────────────────

  Future<List<_DayForecast>?> _loadFromCache(double lat, double lon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(lat, lon));
      final ts = prefs.getInt(_cacheTimeKey(lat, lon));
      if (raw == null || ts == null) return null;
      final age = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(ts))
          .inDays;
      if (age > 7) return null; // expired
      _cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final list = jsonDecode(raw) as List;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return _DayForecast(
          date: DateTime.parse(m['date'] as String),
          weatherCode: (m['weatherCode'] as num?)?.toInt() ?? 0,
          tempMax: (m['tempMax'] as num?)?.toDouble() ?? 0.0,
          tempMin: (m['tempMin'] as num?)?.toDouble() ?? 0.0,
          precipitation: (m['precipitation'] as num?)?.toDouble() ?? 0.0,
          windSpeed: (m['windSpeed'] as num?)?.toDouble() ?? 0.0,
          humidity: (m['humidity'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(
    double lat,
    double lon,
    List<_DayForecast> list,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = list
          .map(
            (d) => {
              'date': d.date.toIso8601String(),
              'weatherCode': d.weatherCode,
              'tempMax': d.tempMax,
              'tempMin': d.tempMin,
              'precipitation': d.precipitation,
              'windSpeed': d.windSpeed,
              'humidity': d.humidity,
            },
          )
          .toList();
      await prefs.setString(_cacheKey(lat, lon), jsonEncode(data));
      await prefs.setInt(
        _cacheTimeKey(lat, lon),
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppProvider>();
    final key = '${app.latitude},${app.longitude}';
    if (key != _lastFetchKey) {
      _lastFetchKey = key;
      _fetch(app.latitude, app.longitude);
    }
  }

  Future<void> _fetch(double lat, double lon) async {
    // 1. Try loading from cache immediately for instant offline display
    final cached = await _loadFromCache(lat, lon);
    if (cached != null && mounted) {
      setState(() {
        _forecasts = cached;
        _fromCache = true;
        _loading = false;
        _error = null;
      });
    } else if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    // 2. Try network fetch
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min'
        ',precipitation_sum,wind_speed_10m_max,relative_humidity_2m_max'
        '&timezone=auto&forecast_days=7',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final daily = json['daily'] as Map<String, dynamic>;

        final times = daily['time'] as List;
        final codes = daily['weather_code'] as List;
        final maxT = daily['temperature_2m_max'] as List;
        final minT = daily['temperature_2m_min'] as List;
        final precip = daily['precipitation_sum'] as List;
        final wind = daily['wind_speed_10m_max'] as List;
        final hum = daily['relative_humidity_2m_max'] as List;

        final list = List.generate(times.length, (i) {
          return _DayForecast(
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
        if (mounted) {
          setState(() {
            _forecasts = list;
            _fromCache = false;
            _cachedAt = null;
            _loading = false;
            _error = null;
          });
        }
      } else {
        // Network failed but we may already have cache
        if (mounted && _forecasts == null) {
          setState(() {
            _error = 'সার্ভার ত্রুটি (${res.statusCode})';
            _loading = false;
          });
        } else if (mounted) {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      if (mounted && _forecasts == null) {
        setState(() {
          _error = 'ইন্টারনেট সংযোগ পরীক্ষা করুন';
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final districtName =
        AppProvider.districtNamesBangla[app.selectedDistrict] ??
        app.selectedDistrict;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: DisasterAppBar(
        title: '৭ দিনের পূর্বাভাস',
        showMenuButton: true,
        onMenuTap: widget.onMenuTap,
      ),
      body: Builder(
        builder: (ctx) {
          if (_loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'পূর্বাভাস লোড হচ্ছে…',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: Colors.black26,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _fetch(app.latitude, app.longitude),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('আবার চেষ্টা করুন'),
                    ),
                  ],
                ),
              ),
            );
          }

          final forecasts = _forecasts ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Offline / cached data banner
              if (_fromCache && _cachedAt != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 16,
                            color: Color(0xFFE65100),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'অফলাইন — ${DateFormat('d MMM, h:mm a').format(_cachedAt!.toLocal())} এর সংরক্ষিত ডেটা',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Location header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_pin,
                        color: Color(0xFF1565C0),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        districtName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Open-Meteo',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: const Text(
                    '৭ দিনের আবহাওয়া পূর্বাভাস',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                ),
              ),

              // Forecast cards
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) =>
                        _ForecastCard(forecast: forecasts[i], isToday: i == 0),
                    childCount: forecasts.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Forecast card
// ──────────────────────────────────────────────────────────────────────────────

class _ForecastCard extends StatelessWidget {
  final _DayForecast forecast;
  final bool isToday;

  const _ForecastCard({required this.forecast, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final dayName = isToday ? 'আজ' : _bnDayNames[forecast.date.weekday] ?? '';
    final dateStr = DateFormat('d MMM').format(forecast.date);
    final iconColor = _wmoColor(forecast.weatherCode);
    final icon = _wmoIcon(forecast.weatherCode);
    final desc = _wmoDesc(forecast.weatherCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isToday
            ? Border.all(
                color: const Color(0xFF1565C0).withValues(alpha: 0.5),
                width: 1.5,
              )
            : Border.all(color: const Color(0xFFE0E7EF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            // Top row: day | icon+desc | temp range
            Row(
              children: [
                // Day & date
                SizedBox(
                  width: 72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isToday
                              ? const Color(0xFF1565C0)
                              : const Color(0xFF0D1B2A),
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),

                // Icon + description
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: iconColor, size: 26),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          desc,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Temp range
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${forecast.tempMax.round()}°',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53935),
                      ),
                    ),
                    Text(
                      '${forecast.tempMin.round()}°',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F4F8)),
            const SizedBox(height: 10),

            // Bottom row: humidity | wind | rain
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                  icon: Icons.water_drop_rounded,
                  color: const Color(0xFF1565C0),
                  label: 'আর্দ্রতা',
                  value: '${forecast.humidity.round()}%',
                ),
                _Stat(
                  icon: Icons.air_rounded,
                  color: const Color(0xFF00897B),
                  label: 'বাতাস',
                  value: '${forecast.windSpeed.round()} কিমি/ঘ',
                ),
                _Stat(
                  icon: Icons.umbrella_rounded,
                  color: const Color(0xFF0288D1),
                  label: 'বৃষ্টি',
                  value: '${forecast.precipitation.toStringAsFixed(1)} মিমি',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _Stat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D1B2A),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black45),
        ),
      ],
    );
  }
}
