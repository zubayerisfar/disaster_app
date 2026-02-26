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
import 'services/notification_service.dart';
import 'theme.dart';
import 'guidelines_page.dart';
import 'widgets/disaster_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Set debug warning level for demonstration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 🔧 CHANGE THIS VALUE TO TEST NOTIFICATIONS (5+ triggers notification)
        context.read<WeatherProvider>().setDebugWarningLevel(7);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          debugPrint('🧪 Test button pressed');
          final notificationService = NotificationService();
          await notificationService.testNotification(7);
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.notifications_active, color: Colors.white),
        label: const Text(
          'Test Notification',
          style: TextStyle(color: Colors.white),
        ),
      ),
      appBar: const DisasterAppBar(title: 'আমার এলাকা'),
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
            SizedBox(height: 28),
            _ForecastStrip(),
            SizedBox(height: 32),
            _SectionHeader(
              title: 'কাছের আশ্রয়কেন্দ্র',
              icon: Icons.shield_outlined,
            ),
            SizedBox(height: 14),
            _NearestShelters(),
            SizedBox(height: 32),
            _SectionHeader(
              title: 'জরুরি নম্বর',
              icon: Icons.phone_in_talk_rounded,
            ),
            SizedBox(height: 14),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A6B),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 24, color: const Color(0xFF1A3A6B)),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
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

  // Bangla numerals for signal levels 0–10
  static const _bn = [
    '✓', // 0 – safe
    '১', '২', '৩', '৪', '৫',
    '৬', '৭', '৮', '৯', '১০',
  ];

  // ── Alert data: index 0 = safe, index 1–10 = BMD signals 1–10 ────────────
  static const _alerts = [
    // index 0 – নিরাপদ
    (
      icon: Icons.check_circle_rounded,
      title: 'আবহাওয়া স্বাভাবিক',
      quote:
          'কোনো সংকেত নেই। আবহাওয়া শান্ত আছে। নিরাপদে থাকুন এবং জরুরি নম্বর সংগ্রহে রাখুন।',
    ),
    // index 1 – ১ নম্বর সংকেত
    (
      icon: Icons.info_outline,
      title: '১ নম্বর সংকেত — দূরবর্তী সতর্ক সংকেত',
      quote:
          'সমুদ্রে নিম্নচাপ সৃষ্টি হয়েছে। আবহাওয়ার খবর শুনুন ও সকলকে সতর্ক থাকতে জানান।',
    ),
    // index 2 – ২ নম্বর সংকেত
    (
      icon: Icons.info_outline,
      title: '২ নম্বর সংকেত — দূরবর্তী হুঁশিয়ারি',
      quote:
          'নিম্নচাপ শক্তিশালী হচ্ছে। জরুরি খাদ্য ও পানি প্রস্তুত রাখুন। মোবাইল চার্জ রাখুন।',
    ),
    // index 3 – ৩ নম্বর সংকেত
    (
      icon: Icons.warning_amber_outlined,
      title: '৩ নম্বর সংকেত — স্থানীয় সতর্ক সংকেত',
      quote:
          'স্থানীয় ঝড় আঘাত করতে পারে। ঘরের দরজা-জানালা শক্ত করুন। অপ্রয়োজনে বাইরে যাবেন না।',
    ),
    // index 4 – ৪ নম্বর সংকেত
    (
      icon: Icons.warning_amber_outlined,
      title: '৪ নম্বর সংকেত — স্থানীয় হুঁশিয়ারি',
      quote:
          'বন্দর এলাকায় ঝড় আঘাত হানতে পারে। আশ্রয়কেন্দ্র চিহ্নিত করুন। গুরুত্বপূর্ণ কাগজ নিরাপদে রাখুন।',
    ),
    // index 5 – ৫ নম্বর সংকেত
    (
      icon: Icons.dangerous_outlined,
      title: '৫ নম্বর সংকেত — বিপদ সংকেত',
      quote:
          'মাঝারি ঘূর্ণিঝড়। আশ্রয়কেন্দ্রে যাওয়ার প্রস্তুতি নিন। শুকনো খাবার ও পানি সংগ্রহ করুন।',
    ),
    // index 6 – ৬ নম্বর সংকেত
    (
      icon: Icons.dangerous_outlined,
      title: '৬ নম্বর সংকেত — বড় বিপদ সংকেত',
      quote:
          'শক্তিশালী ঘূর্ণিঝড়। নিচু এলাকা এখনই ত্যাগ করুন। আশ্রয়কেন্দ্রে যাওয়া শুরু করুন।',
    ),
    // index 7 – ৭ নম্বর সংকেত
    (
      icon: Icons.crisis_alert,
      title: '৭ নম্বর সংকেত — অতি বিপদ সংকেত',
      quote:
          'প্রবল ঘূর্ণিঝড় ও জলোচ্ছ্বাসের আশঙ্কা। সবাই এখনই আশ্রয়কেন্দ্রে যান। দেরি করবেন না।',
    ),
    // index 8 – ৮ নম্বর সংকেত
    (
      icon: Icons.crisis_alert,
      title: '৮ নম্বর সংকেত — মহাবিপদ সংকেত',
      quote:
          'মারাত্মক ঘূর্ণিঝড় ও বড় জলোচ্ছ্বাস। অবিলম্বে আশ্রয়কেন্দ্রে যান। জানালা থেকে দূরে থাকুন।',
    ),
    // index 9 – ৯ নম্বর সংকেত
    (
      icon: Icons.crisis_alert,
      title: '৯ নম্বর সংকেত — চরম মহাবিপদ',
      quote:
          'অত্যন্ত ভয়ংকর ঘূর্ণিঝড়। বাইরে যাওয়া সম্পূর্ণ নিষেধ। আশ্রয়েই থাকুন।',
    ),
    // index 10 – ১০ নম্বর সংকেত
    (
      icon: Icons.crisis_alert,
      title: '১০ নম্বর সংকেত — সর্বোচ্চ মহাবিপদ',
      quote:
          'সুপার সাইক্লোন — ব্যাপক ধ্বংস। আশ্রয়কেন্দ্রে থাকুন। ঝড় পুরোপুরি শেষ না হওয়া পর্যন্ত বের হবেন না।',
    ),
  ];

  Color _lc(int level) {
    if (level == 0) return Colors.greenAccent.shade400;
    if (level <= 2) return Colors.greenAccent.shade400;
    if (level <= 4) return Colors.orange.shade300;
    if (level <= 7) return Colors.deepOrange.shade300;
    return Colors.red.shade400;
  }

  Color _alertAccent(int level) {
    if (level == 0) return const Color(0xFF2E7D32);
    if (level <= 2) return const Color(0xFF2E7D32);
    if (level <= 4) return const Color(0xFFF57F17);
    if (level <= 7) return const Color(0xFFE65100);
    return const Color(0xFFB71C1C);
  }

  Color _alertBg(int level) {
    if (level == 0) return const Color(0xFFE8F5E9);
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
    final alert = _alerts[level.clamp(0, 10)];

    return GestureDetector(
      onTap: () => _showDetailedWeather(context, wp),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: lc.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: lc.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Alert banner ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(alert.icon, color: accent, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          alert.quote,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF263238),
                            height: 1.6,
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
                      // Signal panel – tappable to view detailed guidelines
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () =>
                              GuidelinesPage.openSignalPage(context, level),
                          child: Container(
                            width: 126,
                            padding: const EdgeInsets.fromLTRB(14, 14, 10, 16),
                            decoration: BoxDecoration(
                              color: lc.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border(
                                left: BorderSide(color: lc, width: 5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      level == 0 ? 'নিরাপদ' : 'সংকেত',
                                      style: TextStyle(
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                        fontWeight: FontWeight.w800,
                                        color: lc,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 10,
                                      color: lc.withValues(alpha: 0.7),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _bn[level.clamp(0, 10)],
                                  style: TextStyle(
                                    fontSize: 60,
                                    fontWeight: FontWeight.w900,
                                    color: lc,
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  level == 0
                                      ? 'কোনো সংকেত নেই'
                                      : 'বিস্তারিত দেখতে চাপুন',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: lc.withValues(alpha: 0.8),
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Flexible(
                                    child: _Stat(
                                      icon: Icons.air_rounded,
                                      value:
                                          '${wp.weatherData!.currentWindSpeed.round()} কিমি/ঘন্টা',
                                      label: 'বাতাস',
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Flexible(
                                    child: _Stat(
                                      icon: Icons.water_drop_rounded,
                                      value:
                                          '${wp.weatherData!.currentHumidity.round()}%',
                                      label: 'আর্দ্রতা',
                                    ),
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

  void _showDetailedWeather(BuildContext context, WeatherProvider wp) {
    if (wp.weatherData == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1565C0), const Color(0xFF1976D2)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'আবহাওয়ার বিস্তারিত তথ্য',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Temperature
                      Center(
                        child: Column(
                          children: [
                            CachedNetworkImage(
                              imageUrl: wp.weatherData!.currentIconUrl,
                              width: 100,
                              height: 100,
                              errorWidget: (_, _, __) => const Icon(
                                Icons.wb_cloudy,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${wp.weatherData!.currentTemp.round()}',
                                  style: const TextStyle(
                                    fontSize: 72,
                                    fontWeight: FontWeight.w200,
                                    color: Color(0xFF0D1B2A),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text(
                                    '°C',
                                    style: TextStyle(
                                      fontSize: 32,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              wp.weatherData!.currentDescription.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                letterSpacing: 1.5,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Detailed Stats
                      _DetailRow(
                        icon: Icons.air_rounded,
                        label: 'বাতাসের গতি',
                        value:
                            '${wp.weatherData!.currentWindSpeed.round()} কিমি/ঘন্টা',
                        color: const Color(0xFF1565C0),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.water_drop_rounded,
                        label: 'আর্দ্রতা',
                        value: '${wp.weatherData!.currentHumidity.round()}%',
                        color: const Color(0xFF0288D1),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.thermostat_outlined,
                        label: 'তাপমাত্রার অনুভূতি',
                        value: '${wp.weatherData!.currentTemp.round()}°C',
                        color: const Color(0xFFFF6F00),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      // 7-Day Forecast Title
                      const Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xFF1565C0),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '৭ দিনের পূর্বাভাস',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D1B2A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Week forecast
                      ...wp.weatherData!.daily.map((day) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    DateFormat(
                                      'EEE',
                                    ).format(day.date).substring(0, 3),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0D1B2A),
                                    ),
                                  ),
                                ),
                                CachedNetworkImage(
                                  imageUrl: day.iconUrl,
                                  width: 40,
                                  height: 40,
                                  errorWidget: (_, _, __) =>
                                      const Icon(Icons.wb_cloudy, size: 32),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        day.description,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.water_drop,
                                            size: 12,
                                            color: Colors.blue.shade300,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${day.precipitation.round()} mm',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${day.tempMax.round()}° / ${day.tempMin.round()}°',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D1B2A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF0D1B2A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF1A3A6B), size: 22),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0D1B2A),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                softWrap: true,
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
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
          title: '৭ দিনের আবহাওয়া',
          icon: Icons.calendar_today_outlined,
        ),
        const SizedBox(height: 12),
        if (wp.isLoading &&
            (wp.weatherData == null || wp.weatherData!.daily.isEmpty))
          const LinearProgressIndicator(color: Color(0xFF1565C0))
        else if (wp.weatherData == null || wp.weatherData!.daily.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'পূর্বাভাস পাওয়া যাচ্ছে না।',
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
          )
        else
          SizedBox(
            height: 178,
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

  static const _banglaDay = {
    'Mon': 'সোম',
    'Tue': 'মঙ্গল',
    'Wed': 'বুধ',
    'Thu': 'বৃহ',
    'Fri': 'শুক্র',
    'Sat': 'শনি',
    'Sun': 'রবি',
  };

  @override
  Widget build(BuildContext context) {
    final eng = DateFormat('EEE').format(day.date);
    final bn = _banglaDay[eng] ?? eng;
    return GlassCard(
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: SizedBox(
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              bn,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF0D1B2A),
              ),
            ),
            CachedNetworkImage(
              imageUrl: day.iconUrl,
              width: 44,
              height: 44,
              errorWidget: (_, _, _) =>
                  const Icon(Icons.cloud, size: 36, color: Colors.grey),
            ),
            Column(
              children: [
                Text(
                  'সর্বোচ্চ',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${day.tempMax.round()}°',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  'সর্বনিম্ন',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF1A3A6B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${day.tempMin.round()}°',
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ],
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
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'আপনার এলাকায় কোনো আশ্রয়কেন্দ্র পাওয়া যায়নি।',
          style: TextStyle(color: Colors.black54, fontSize: 15),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A6B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shelter.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${distKm.toStringAsFixed(1)} কিমি দূরে',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _openMap(shelter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0F7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1A3A6B), width: 1.5),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_rounded, size: 22, color: Color(0xFF1A3A6B)),
                  SizedBox(height: 3),
                  Text(
                    'মানচিত্র',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A6B),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
            ),
            child: const Icon(
              Icons.phone_in_talk_rounded,
              color: Color(0xFF2E7D32),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['organisation'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  contact['phone'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1A3A6B),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _dial(contact['phone'] ?? ''),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_rounded, color: Colors.white, size: 22),
                  SizedBox(height: 3),
                  Text(
                    'কল করুন',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
