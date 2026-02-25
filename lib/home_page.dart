import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/shelter_model.dart';
import 'models/weather_model.dart';
import 'providers/app_provider.dart';
import 'providers/shelter_provider.dart';
import 'providers/weather_provider.dart';
import 'services/contact_service.dart';
import 'services/weather_service.dart';
import 'theme.dart';
import 'widgets/disaster_app_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const DisasterAppBar(title: 'Home'),
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF1E88E5),
        onRefresh: () async {
          final app = context.read<AppProvider>();
          await Future.wait([
            context.read<WeatherProvider>().loadWeather(
              app.latitude,
              app.longitude,
            ),
            context.read<ShelterProvider>().loadShelters(
              app.selectedDistrict,
              app.latitude,
              app.longitude,
            ),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 52),
          children: const [
            _WeatherHeroCard(),
            SizedBox(height: 26),
            _ForecastStrip(),
            SizedBox(height: 30),
            _SectionHeader(
              title: 'Nearest Shelters',
              icon: Icons.location_city_outlined,
            ),
            SizedBox(height: 12),
            _NearestShelters(),
            SizedBox(height: 30),
            _SectionHeader(
              title: 'Emergency Numbers',
              icon: Icons.phone_in_talk_outlined,
            ),
            SizedBox(height: 12),
            _EmergencyContacts(),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1565C0)),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B2A),
          ),
        ),
      ],
    );
  }
}

// ─── Weather Hero Card (merged with Signal Alert) ──────────────────────────
class _WeatherHeroCard extends StatelessWidget {
  const _WeatherHeroCard();

  // ── Alert data keyed by warning level (1–10) ────────────────────────────
  static const _alerts = [
    (
      icon: Icons.check_circle_outline,
      title: 'All Clear',
      quote:
          'Weather conditions are normal. Stay informed and keep emergency contacts handy.',
    ),
    (
      icon: Icons.info_outline,
      title: 'Stay Alert',
      quote:
          'Minor weather disturbance possible. Monitor Bangladesh Meteorological Department updates.',
    ),
    (
      icon: Icons.warning_amber_outlined,
      title: 'Squally Weather',
      quote:
          'Gusty winds up to 50 km/h expected. Secure loose objects and avoid open water.',
    ),
    (
      icon: Icons.warning_amber_outlined,
      title: 'Cyclone Possible',
      quote:
          'A cyclone may be forming nearby. Identify your nearest shelter and prepare emergency supplies.',
    ),
    (
      icon: Icons.dangerous_outlined,
      title: 'Danger Signal',
      quote:
          'Storm is approaching. Move away from low-lying areas. Be ready to evacuate on short notice.',
    ),
    (
      icon: Icons.dangerous_outlined,
      title: 'Danger Signal',
      quote:
          'Strong storm with destructive winds. Move to a sturdy cyclone shelter immediately.',
    ),
    (
      icon: Icons.crisis_alert,
      title: 'Great Danger',
      quote:
          'Extremely dangerous cyclone approaching. Evacuate to the nearest shelter NOW. Do not delay.',
    ),
    (
      icon: Icons.crisis_alert,
      title: 'Great Danger',
      quote:
          'Severe cyclone imminent. Seek shelter immediately. Stay away from windows and flood-prone areas.',
    ),
    (
      icon: Icons.crisis_alert,
      title: 'Catastrophic Risk',
      quote:
          'Catastrophic storm. Follow all evacuation orders without hesitation. Your life is at risk.',
    ),
    (
      icon: Icons.crisis_alert,
      title: 'Maximum Alert',
      quote:
          'MAXIMUM DANGER. Catastrophic cyclone with violent winds. Remain in shelter — do NOT venture outside.',
    ),
  ];

  Color _lc(int level) {
    if (level <= 2) return Colors.greenAccent.shade400;
    if (level <= 4) return Colors.orange.shade300;
    if (level <= 7) return Colors.deepOrange.shade300;
    return Colors.red.shade400;
  }

  Color _alertAccent(int level) {
    if (level <= 2) return const Color(0xFF2E7D32);
    if (level <= 4) return const Color(0xFFF57F17);
    if (level <= 7) return const Color(0xFFE65100);
    return const Color(0xFFB71C1C);
  }

  Color _alertBg(int level) {
    if (level <= 2) return const Color(0xFFE8F5E9);
    if (level <= 4) return const Color(0xFFFFF8E1);
    if (level <= 7) return const Color(0xFFFFF3E0);
    return const Color(0xFFFFEBEE);
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WeatherProvider>();
    final level = wp.warningLevel;
    final lc = _lc(level);
    final accent = _alertAccent(level);
    final bg = _alertBg(level);
    final alert = _alerts[(level - 1).clamp(0, 9)];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E7FF), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Alert banner ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: bg,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(alert.icon, color: accent, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.quote,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF37474F),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ────────────────────────────────────────────────────
            Divider(
              height: 1,
              thickness: 1,
              color: accent.withValues(alpha: 0.18),
            ),

            // ── Signal + Weather ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Signal panel
                      Container(
                        width: 126,
                        padding: const EdgeInsets.fromLTRB(14, 14, 10, 16),
                        decoration: BoxDecoration(
                          color: lc.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border(left: BorderSide(color: lc, width: 5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SIGNAL',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 2.5,
                                fontWeight: FontWeight.w800,
                                color: lc,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$level',
                              style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                color: lc,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              WeatherService.warningDescription(level),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Weather details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (wp.isLoading && wp.weatherData == null)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1565C0),
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            else if (wp.weatherData != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${wp.weatherData!.currentTemp.round()}',
                                          style: const TextStyle(
                                            color: Color(0xFF0D1B2A),
                                            fontSize: 68,
                                            fontWeight: FontWeight.w200,
                                            height: 1,
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 12),
                                          child: Text(
                                            '°C',
                                            style: TextStyle(
                                              color: Colors.black45,
                                              fontSize: 22,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CachedNetworkImage(
                                    imageUrl: wp.weatherData!.currentIconUrl,
                                    width: 52,
                                    height: 52,
                                    errorWidget: (_, _, _) => const Icon(
                                      Icons.wb_cloudy,
                                      color: Colors.grey,
                                      size: 44,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                wp.weatherData!.currentDescription
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 13,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _Stat(
                                    icon: Icons.air,
                                    value:
                                        '${wp.weatherData!.currentWindSpeed.round()} km/h',
                                    label: 'Wind',
                                  ),
                                  const SizedBox(width: 20),
                                  _Stat(
                                    icon: Icons.water_drop_outlined,
                                    value:
                                        '${wp.weatherData!.currentHumidity.round()}%',
                                    label: 'Humidity',
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Refresh progress bar
                  if (wp.isLoading && wp.weatherData != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: LinearProgressIndicator(
                        backgroundColor: const Color(0xFFE0E0E0),
                        color: lc,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0D1B2A),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── 7-Day Forecast Strip ────────────────────────────────────────────────────
class _ForecastStrip extends StatelessWidget {
  const _ForecastStrip();

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WeatherProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: '7-Day Forecast',
          icon: Icons.calendar_today_outlined,
        ),
        const SizedBox(height: 12),
        if (wp.isLoading &&
            (wp.weatherData == null || wp.weatherData!.daily.isEmpty))
          const LinearProgressIndicator(color: Color(0xFF1565C0))
        else if (wp.weatherData == null || wp.weatherData!.daily.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No forecast available.',
              style: TextStyle(color: Colors.black54),
            ),
          )
        else
          SizedBox(
            height: 134,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: wp.weatherData!.daily.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) =>
                  _ForecastCard(day: wp.weatherData!.daily[i]),
            ),
          ),
      ],
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final DayForecast day;
  const _ForecastCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: SizedBox(
        width: 82,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('EEE').format(day.date),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF0D1B2A),
              ),
            ),
            CachedNetworkImage(
              imageUrl: day.iconUrl,
              width: 40,
              height: 40,
              errorWidget: (_, _, _) =>
                  const Icon(Icons.cloud, size: 32, color: Colors.grey),
            ),
            Text(
              '${day.tempMax.round()}°',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0D1B2A),
              ),
            ),
            Text(
              '${day.tempMin.round()}°',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nearest Shelters ────────────────────────────────────────────────────────
class _NearestShelters extends StatelessWidget {
  const _NearestShelters();

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<ShelterProvider>();
    final app = context.watch<AppProvider>();

    if (sp.isLoading) {
      return const LinearProgressIndicator(color: Color(0xFF1565C0));
    }
    if (sp.nearest.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No shelters found for your area.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return GlassCard(
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.zero,
      child: Column(
        children: () {
          final items = sp.nearest.map((s) {
            final dist = sp.distanceTo(app.latitude, app.longitude, s);
            return _ShelterTile(shelter: s, distKm: dist);
          }).toList();
          final rows = <Widget>[];
          for (int i = 0; i < items.length; i++) {
            rows.add(items[i]);
            if (i < items.length - 1)
              rows.add(const Divider(height: 1, indent: 16, endIndent: 16));
          }
          return rows;
        }(),
      ),
    );
  }
}

class _ShelterTile extends StatelessWidget {
  final Shelter shelter;
  final double distKm;
  const _ShelterTile({required this.shelter, required this.distKm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shelter.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${distKm.toStringAsFixed(1)} km away',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _openMap(shelter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1565C0), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 15, color: Color(0xFF1565C0)),
                  SizedBox(width: 5),
                  Text(
                    'Show on Map',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMap(Shelter s) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${s.lat},${s.lng}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ─── Emergency Contacts ──────────────────────────────────────────────────────
class _EmergencyContacts extends StatelessWidget {
  const _EmergencyContacts();

  @override
  Widget build(BuildContext context) {
    final contacts = ContactService.criticalContacts;
    return GlassCard(
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.zero,
      child: Column(
        children: () {
          final rows = <Widget>[];
          for (int i = 0; i < contacts.length; i++) {
            rows.add(_ContactCallCard(contact: contacts[i]));
            if (i < contacts.length - 1)
              rows.add(const Divider(height: 1, indent: 16, endIndent: 16));
          }
          return rows;
        }(),
      ),
    );
  }
}

class _ContactCallCard extends StatelessWidget {
  final Map<String, String> contact;
  const _ContactCallCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['organisation'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact['phone'] ?? '',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _dial(contact['phone'] ?? ''),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade700, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 15,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Call',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dial(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
