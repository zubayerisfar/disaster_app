import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/forecast_provider.dart';
import 'providers/weather_provider.dart';
import 'models/weather_model.dart';
import 'widgets/disaster_app_bar.dart';

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

// ── Convert AccuWeather DayForecast to ForecastDay format ──────────────────────
List<ForecastDay> _convertAccuWeatherToForecast(List<DayForecast> accuDaily) {
  return accuDaily.map((day) {
    // Map AccuWeather icon code to WMO-like code
    int weatherCode = _iconCodeToWMO(day.iconCode);

    return ForecastDay(
      date: day.date,
      tempMax: day.tempMax,
      tempMin: day.tempMin,
      precipitation: day.precipitation,
      windSpeed: day.windSpeed,
      humidity: day.humidity,
      weatherCode: weatherCode,
    );
  }).toList();
}

// Convert icon codes to approximate WMO weather codes
int _iconCodeToWMO(String iconCode) {
  if (iconCode.startsWith('01')) return 0; // clear sky
  if (iconCode.startsWith('02')) return 2; // partly cloudy
  if (iconCode.startsWith('03')) return 3; // cloudy
  if (iconCode.startsWith('04')) return 3; // overcast
  if (iconCode.startsWith('09')) return 61; // rain
  if (iconCode.startsWith('10')) return 63; // rain
  if (iconCode.startsWith('11')) return 95; // thunderstorm
  if (iconCode.startsWith('13')) return 71; // snow
  if (iconCode.startsWith('50')) return 45; // fog
  return 3; // default to cloudy
}

// ──────────────────────────────────────────────────────────────────────────────
// Page
// ──────────────────────────────────────────────────────────────────────────────

class ForecastPage extends StatelessWidget {
  final VoidCallback? onMenuTap;
  const ForecastPage({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final fp = context.watch<ForecastProvider>();
    final wp = context.watch<WeatherProvider>();
    final districtName =
        AppProvider.districtNamesBangla[app.selectedDistrict] ??
        app.selectedDistrict;

    // Priority: AccuWeather daily → Open-Meteo forecasts
    final useAccuWeather =
        !wp.isDemo &&
        wp.weatherData?.daily != null &&
        wp.weatherData!.daily.isNotEmpty;
    final isLoading = useAccuWeather ? wp.isLoading : fp.loading;
    final hasError = useAccuWeather ? (wp.error != null) : (fp.error != null);
    final fromCache = useAccuWeather ? wp.fromCache : fp.fromCache;
    final cachedAt = useAccuWeather ? wp.cachedAt : fp.cachedAt;
    final dataSource = useAccuWeather ? 'AccuWeather' : 'Open-Meteo';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: DisasterAppBar(
        title: '৭ দিনের পূর্বাভাস',
        showMenuButton: true,
        onMenuTap: onMenuTap,
      ),
      body: Builder(
        builder: (ctx) {
          // Show loading only if no data available from either source
          final hasData =
              useAccuWeather ||
              (fp.forecasts != null && fp.forecasts!.isNotEmpty);

          if (isLoading && !hasData) {
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

          if (hasError && !hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: Colors.black26,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      useAccuWeather
                          ? (wp.error ?? 'ত্রুটি ঘটেছে')
                          : (fp.error ?? 'ত্রুটি ঘটেছে'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () async {
                        await wp.loadWeather(app.latitude, app.longitude);
                        await fp.refresh(app.latitude, app.longitude);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('আবার চেষ্টা করুন'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Convert AccuWeather DayForecast to ForecastDay format (or use Open-Meteo directly)
          final forecasts = useAccuWeather
              ? _convertAccuWeatherToForecast(wp.weatherData!.daily)
              : (fp.forecasts ?? []);

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Offline / cached data banner
              if (fromCache && cachedAt != null)
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
                              'অফলাইন — ${DateFormat('d MMM, h:mm a').format(cachedAt!.toLocal())} এর সংরক্ষিত ডেটা',
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
                        dataSource,
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
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
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
  final ForecastDay forecast;
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
