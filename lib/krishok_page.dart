import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'widgets/disaster_app_bar.dart';
import 'theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/plant_disease_service.dart';

class KrishokPage extends StatelessWidget {
  final VoidCallback? onMenuTap;
  const KrishokPage({super.key, this.onMenuTap});

  // Current month → season
  static String _getSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'বসন্ত/গ্রীষ্ম';
    if (month >= 6 && month <= 9) return 'বর্ষা';
    if (month >= 10 && month <= 11) return 'শরৎ/হেমন্ত';
    return 'শীত';
  }

  static int _getSeasonIndex() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 0;
    if (month >= 6 && month <= 9) return 1;
    if (month >= 10 && month <= 11) return 2;
    return 3;
  }

  // Season-based crop recommendations
  static const _seasonCrops = [
    // বসন্ত/গ্রীষ্ম
    [
      _CropInfo(
        name: 'পাট',
        icon: '🌿',
        sow: 'মার্চ–এপ্রিল',
        harvest: 'জুলাই–আগস্ট',
        tip: 'পর্যাপ্ত সেচ দিন, আগাছামুক্ত রাখুন।',
        color: Color(0xFF16A34A),
        lightColor: Color(0xFFDCFCE7),
      ),
      _CropInfo(
        name: 'আউশ ধান',
        icon: '🌾',
        sow: 'মার্চ–মে',
        harvest: 'জুলাই–আগস্ট',
        tip: 'উচ্চফলনশীল জাত ব্যবহার করুন।',
        color: Color(0xFFCA8A04),
        lightColor: Color(0xFFFEF9C3),
      ),
      _CropInfo(
        name: 'মরিচ',
        icon: '🌶️',
        sow: 'ফেব্রুয়ারি–মার্চ',
        harvest: 'মে–জুন',
        tip: 'রোদ বেশি থাকলে সেচ ঘন ঘন দিন।',
        color: Color(0xFFDC2626),
        lightColor: Color(0xFFFEE2E2),
      ),
      _CropInfo(
        name: 'তরমুজ',
        icon: '🍉',
        sow: 'জানুয়ারি–ফেব্রুয়ারি',
        harvest: 'এপ্রিল–মে',
        tip: 'বালু মিশ্রিত মাটিতে ভালো ফলন হয়।',
        color: Color(0xFFDB2777),
        lightColor: Color(0xFFFDF2F8),
      ),
    ],
    // বর্ষা
    [
      _CropInfo(
        name: 'আমন ধান',
        icon: '🌾',
        sow: 'জুন–জুলাই',
        harvest: 'নভেম্বর–ডিসেম্বর',
        tip: 'বন্যাসহিষ্ণু জাত বেছে নিন।',
        color: Color(0xFFCA8A04),
        lightColor: Color(0xFFFEF9C3),
      ),
      _CropInfo(
        name: 'পাট',
        icon: '🌿',
        sow: 'জুন–জুলাই',
        harvest: 'সেপ্টেম্বর–অক্টোবর',
        tip: 'জলাবদ্ধতা এড়াতে উঁচু জমি বেছে নিন।',
        color: Color(0xFF16A34A),
        lightColor: Color(0xFFDCFCE7),
      ),
      _CropInfo(
        name: 'করলা',
        icon: '🥒',
        sow: 'জুন',
        harvest: 'আগস্ট–সেপ্টেম্বর',
        tip: 'মাচা তৈরি করে চাষ করুন।',
        color: Color(0xFF059669),
        lightColor: Color(0xFFF0FDF4),
      ),
      _CropInfo(
        name: 'ঝিঙ্গা',
        icon: '🫑',
        sow: 'মে–জুন',
        harvest: 'আগস্ট–সেপ্টেম্বর',
        tip: 'নিয়মিত পানি দিন।',
        color: Color(0xFF0891B2),
        lightColor: Color(0xFFECFEFF),
      ),
    ],
    // শরৎ/হেমন্ত
    [
      _CropInfo(
        name: 'আলু',
        icon: '🥔',
        sow: 'অক্টোবর–নভেম্বর',
        harvest: 'জানুয়ারি–ফেব্রুয়ারি',
        tip: 'ভালো নিষ্কাশন ব্যবস্থা রাখুন।',
        color: Color(0xFFB45309),
        lightColor: Color(0xFFFFFBEB),
      ),
      _CropInfo(
        name: 'সরিষা',
        icon: '🌻',
        sow: 'অক্টোবর–নভেম্বর',
        harvest: 'জানুয়ারি–ফেব্রুয়ারি',
        tip: 'শুষ্ক আবহাওয়ায় ভালো ফলন হয়।',
        color: Color(0xFFCA8A04),
        lightColor: Color(0xFFFEF9C3),
      ),
      _CropInfo(
        name: 'মসুর',
        icon: '🫘',
        sow: 'অক্টোবর–নভেম্বর',
        harvest: 'মার্চ–এপ্রিল',
        tip: 'কম সেচে ভালো ফলন দেয়।',
        color: Color(0xFF0284C7),
        lightColor: Color(0xFFF0F9FF),
      ),
      _CropInfo(
        name: 'ফুলকপি',
        icon: '🥦',
        sow: 'সেপ্টেম্বর–অক্টোবর',
        harvest: 'ডিসেম্বর–জানুয়ারি',
        tip: 'ঠান্ডা আবহাওয়ায় ভালো জন্মে।',
        color: Color(0xFF16A34A),
        lightColor: Color(0xFFDCFCE7),
      ),
    ],
    // শীত
    [
      _CropInfo(
        name: 'বোরো ধান',
        icon: '🌾',
        sow: 'জানুয়ারি–ফেব্রুয়ারি',
        harvest: 'মে–জুন',
        tip: 'পর্যাপ্ত সার ও সেচ দিন।',
        color: Color(0xFFCA8A04),
        lightColor: Color(0xFFFEF9C3),
      ),
      _CropInfo(
        name: 'গম',
        icon: '🌾',
        sow: 'নভেম্বর–ডিসেম্বর',
        harvest: 'মার্চ–এপ্রিল',
        tip: 'কম আর্দ্রতায় চাষ উপযোগী।',
        color: Color(0xFFB45309),
        lightColor: Color(0xFFFFFBEB),
      ),
      _CropInfo(
        name: 'টমেটো',
        icon: '🍅',
        sow: 'অক্টোবর–নভেম্বর',
        harvest: 'জানুয়ারি–ফেব্রুয়ারি',
        tip: 'ঠান্ডা আবহাওয়ায় উৎপাদন বেশি।',
        color: Color(0xFFDC2626),
        lightColor: Color(0xFFFEE2E2),
      ),
      _CropInfo(
        name: 'পেঁয়াজ',
        icon: '🧅',
        sow: 'নভেম্বর',
        harvest: 'মার্চ–এপ্রিল',
        tip: 'শুষ্ক মাটি ও রোদ প্রয়োজন।',
        color: Color(0xFFDB2777),
        lightColor: Color(0xFFFDF2F8),
      ),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherProvider>();
    final seasonIdx = _getSeasonIndex();
    final crops = _seasonCrops[seasonIdx];
    final currentSeason = _getSeason();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      extendBodyBehindAppBar: true,
      appBar: DisasterAppBar(
        title: 'কৃষক সেবা',
        showMenuButton: true,
        onMenuTap: onMenuTap,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 116 + 12,
          16,
          120,
        ),
        children: [
          // Page header
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'কৃষক সেবা',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Weather Summary Card ──────────────────────────────────────
          _WeatherSummaryCard(weather: weather),
          const SizedBox(height: 18),

          // ── Crop Alert based on weather ───────────────────────────────
          _CropWeatherAlert(weather: weather),
          const SizedBox(height: 18),

          // ── Plant Disease Detection (HIGHLIGHTED) ─────────────────────
          const _PlantDiseaseDetectionSection(),
          const SizedBox(height: 18),

          // ── Detectable Crops Info ─────────────────────────────────────
          const _DetectableCropsInfo(),
          const SizedBox(height: 18),

          // ── Disease Guidelines ────────────────────────────────────────────
          const _DiseaseGuidelinesSection(),
          const SizedBox(height: 18),

          // ── Cyclone Signal Guidance ───────────────────────────────────
          const _CycloneSignalGuidance(),
          const SizedBox(height: 18),

          // ── Seasonal Crop Recommendations ─────────────────────────────
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 8),
              Text(
                '$currentSeason মৌসুমের ফসল',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: crops.length,
            itemBuilder: (context, i) => _CropCard(info: crops[i]),
          ),
          const SizedBox(height: 20),

          // ── Farming Tips ─────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_rounded,
                color: Color(0xFFCA8A04),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'কৃষি পরামর্শ',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _FarmingTips(),
          const SizedBox(height: 20),

          // ── Soil & Fertilizer Tips ────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.agriculture_rounded,
                color: Color(0xFFB45309),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'মাটি ও সার ব্যবস্থাপনা',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _SoilFertilizerSection(),
          const SizedBox(height: 20),

          // ── Emergency Contacts for Farmers ───────────────────────────
          Row(
            children: [
              const Icon(
                Icons.phone_in_talk_rounded,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'কৃষি হেল্পলাইন',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _AgriHelplines(),
        ],
      ),
    );
  }
}

// ── Weather Summary Card ───────────────────────────────────────────────────────

class _WeatherSummaryCard extends StatelessWidget {
  final WeatherProvider weather;
  const _WeatherSummaryCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final data = weather.weatherData;
    final temp = data?.currentTemp.toStringAsFixed(0) ?? '--';
    final humidity = data?.currentHumidity.toStringAsFixed(0) ?? '--';
    final wind = data?.currentWindSpeed.toStringAsFixed(0) ?? '--';
    final desc = data?.currentDescription ?? 'তথ্য নেই';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'আজকের আবহাওয়া',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _WeatherStat(
                icon: Icons.thermostat_rounded,
                label: 'তাপমাত্রা',
                value: '$temp°C',
                color: const Color(0xFFDC2626),
              ),
              const SizedBox(width: 12),
              _WeatherStat(
                icon: Icons.water_drop_rounded,
                label: 'আর্দ্রতা',
                value: '$humidity%',
                color: const Color(0xFF0284C7),
              ),
              const SizedBox(width: 12),
              _WeatherStat(
                icon: Icons.air_rounded,
                label: 'বায়ু',
                value: '$wind km/h',
                color: const Color(0xFF059669),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '☁ $desc',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _WeatherStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Crop weather alert ─────────────────────────────────────────────────────────

class _CropWeatherAlert extends StatelessWidget {
  final WeatherProvider weather;
  const _CropWeatherAlert({required this.weather});

  @override
  Widget build(BuildContext context) {
    final data = weather.weatherData;
    if (data == null) return const SizedBox.shrink();

    final temp = data.currentTemp;
    final humidity = data.currentHumidity;
    final wind = data.currentWindSpeed;

    String advice;
    Color color;
    Color lightColor;
    IconData icon;

    if (wind > 60) {
      advice =
          'বাতাসের গতি বেশি। ফসল রক্ষায় খুঁটি ও বেড়া দিন। পাকা ফসল দ্রুত কাটুন।';
      color = const Color(0xFFDC2626);
      lightColor = const Color(0xFFFEE2E2);
      icon = Icons.warning_amber_rounded;
    } else if (humidity > 85) {
      advice =
          'আর্দ্রতা বেশি থাকায় ছত্রাকজনিত রোগের ঝুঁকি আছে। ফাঙ্গিসাইড স্প্রে করুন।';
      color = const Color(0xFFCA8A04);
      lightColor = const Color(0xFFFEF9C3);
      icon = Icons.cloud_rounded;
    } else if (temp > 35) {
      advice =
          'তাপমাত্রা বেশি। সকাল বা বিকেলে সেচ দিন। ফসলের গোড়ায় মালচিং করুন।';
      color = const Color(0xFFEA580C);
      lightColor = const Color(0xFFFFEDD5);
      icon = Icons.wb_sunny_rounded;
    } else if (temp < 12) {
      advice =
          'ঠান্ডা আবহাওয়া। চারা গাছ ঢেকে রাখুন। শীতকালীন ফসলের জন্য উপযুক্ত সময়।';
      color = const Color(0xFF0284C7);
      lightColor = const Color(0xFFF0F9FF);
      icon = Icons.ac_unit_rounded;
    } else {
      advice = 'আবহাওয়া ফসল চাষের জন্য অনুকূল। নিয়মিত পরিচর্যা চালিয়ে যান।';
      color = const Color(0xFF16A34A);
      lightColor = const Color(0xFFDCFCE7);
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আবহাওয়াভিত্তিক পরামর্শ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Crop Card ─────────────────────────────────────────────────────────────────

class _CropInfo {
  final String name;
  final String icon;
  final String sow;
  final String harvest;
  final String tip;
  final Color color;
  final Color lightColor;
  const _CropInfo({
    required this.name,
    required this.icon,
    required this.sow,
    required this.harvest,
    required this.tip,
    required this.color,
    required this.lightColor,
  });
}

class _CropCard extends StatelessWidget {
  final _CropInfo info;
  const _CropCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: info.lightColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(info.icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  info.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: info.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'বপন', value: info.sow),
          const SizedBox(height: 4),
          _InfoRow(label: 'কাটা', value: info.harvest),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: info.lightColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              info.tip,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black45,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Farming Tips ──────────────────────────────────────────────────────────────

class _FarmingTips extends StatelessWidget {
  const _FarmingTips();

  static const _tips = [
    (
      icon: Icons.water_drop_rounded,
      title: 'সঠিক সেচ',
      desc: 'ভোরবেলা বা সন্ধ্যায় সেচ দিন। অতিরিক্ত সেচ শিকড় পচন সৃষ্টি করে।',
      color: Color(0xFF0284C7),
    ),
    (
      icon: Icons.bug_report_outlined,
      title: 'কীটপতঙ্গ নিয়ন্ত্রণ',
      desc: 'জৈব কীটনাশক ব্যবহার করুন। ফসলে হলুদ আঠালো ফাঁদ ব্যবহার করুন।',
      color: Color(0xFFDC2626),
    ),
    (
      icon: Icons.compost_outlined,
      title: 'জৈব সার',
      desc: 'রাসায়নিকের পাশাপাশি কম্পোস্ট ও ভার্মিকম্পোস্ট ব্যবহার করুন।',
      color: Color(0xFF16A34A),
    ),
    (
      icon: Icons.rotate_right_rounded,
      title: 'ফসল আবর্তন',
      desc:
          'একই জমিতে বারবার একই ফসল না লাগিয়ে পর্যায়ক্রমে ভিন্ন ফসল চাষ করুন।',
      color: Color(0xFFCA8A04),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _tips
          .map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tip.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(tip.icon, color: tip.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: tip.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tip.desc,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Soil & Fertilizer Section ─────────────────────────────────────────────────

class _SoilFertilizerSection extends StatelessWidget {
  const _SoilFertilizerSection();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          _SoilRow(
            title: 'মাটি পরীক্ষা',
            desc:
                'প্রতি ৩ বছরে একবার মাটি পরীক্ষা করুন। উপজেলা কৃষি অফিসে যোগাযোগ করুন।',
            icon: '🧪',
          ),
          const Divider(height: 20),
          _SoilRow(
            title: 'ইউরিয়া সার',
            desc:
                'নাইট্রোজেনের জন্য ব্যবহার করুন। অতিরিক্ত ব্যবহার ফসলের ক্ষতি করে।',
            icon: '⚗️',
          ),
          const Divider(height: 20),
          _SoilRow(
            title: 'TSP সার',
            desc: 'ফসফরাসের জন্য ব্যবহার করুন। শিকড় বৃদ্ধিতে সহায়তা করে।',
            icon: '🌱',
          ),
          const Divider(height: 20),
          _SoilRow(
            title: 'পটাশ সার',
            desc: 'ফসলের রোগ প্রতিরোধ ক্ষমতা বাড়ায়। ফলের মান উন্নত করে।',
            icon: '💪',
          ),
        ],
      ),
    );
  }
}

class _SoilRow extends StatelessWidget {
  final String title;
  final String desc;
  final String icon;
  const _SoilRow({required this.title, required this.desc, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Agri Helplines ────────────────────────────────────────────────────────────

class _AgriHelplines extends StatelessWidget {
  const _AgriHelplines();

  @override
  Widget build(BuildContext context) {
    final lines = [
      (
        number: '16123',
        label: 'কৃষি তথ্য সার্ভিস (AIS)',
        icon: Icons.agriculture_rounded,
      ),
      (
        number: '333',
        label: 'জাতীয় কৃষি হেল্পলাইন',
        icon: Icons.phone_rounded,
      ),
      (
        number: '16321',
        label: 'বাংলাদেশ কৃষি ব্যাংক',
        icon: Icons.account_balance_rounded,
      ),
      (
        number: '16180',
        label: 'কৃষি সম্প্রসারণ অধিদপ্তর',
        icon: Icons.support_agent_rounded,
      ),
    ];
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(lines.length, (i) {
          final line = lines[i];
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    line.icon,
                    color: const Color(0xFF1565C0),
                    size: 22,
                  ),
                ),
                title: Text(
                  line.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                trailing: Text(
                  line.number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
              if (i < lines.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}

// ── Plant Disease Detection Section ────────────────────────────────────────────

class _PlantDiseaseDetectionSection extends StatefulWidget {
  const _PlantDiseaseDetectionSection();

  @override
  State<_PlantDiseaseDetectionSection> createState() =>
      _PlantDiseaseDetectionSectionState();
}

class _PlantDiseaseDetectionSectionState
    extends State<_PlantDiseaseDetectionSection> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  PlantDiseaseResult? _result;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _result = null;
          _errorMessage = null;
        });
        _analyzeImage();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ছবি নির্বাচনে সমস্যা হয়েছে: $e';
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PlantDiseaseService.predictDisease(_selectedImage!);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF16A34A).withValues(alpha: 0.08),
            const Color(0xFF059669).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF16A34A).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Highlighted header with icon badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF16A34A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'রোগ শনাক্তকরণ',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'গাছের পাতার ছবি তুলে রোগ সনাক্ত করুন',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  // "Featured" badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'বিশেষ সেবা',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Image selection buttons
            Row(
              children: [
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'ক্যামেরা',
                    onTap: () => _pickImage(ImageSource.camera),
                    color: const Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'গ্যালারি',
                    onTap: () => _pickImage(ImageSource.gallery),
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),

            // Selected image preview
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            // Loading indicator
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF16A34A)),
                    SizedBox(height: 8),
                    Text(
                      'বিশ্লেষণ করা হচ্ছে...',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],

            // Result display
            if (_result != null && !_isLoading) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF16A34A),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ফলাফল',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'শনাক্তকৃত রোগ:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _result!.predictedClass,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D1B2A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF16A34A),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'নির্ভুলতা: ${_result!.confidence.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Error message
            if (_errorMessage != null && !_isLoading) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'সমস্যা হয়েছে',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detectable Crops Info ──────────────────────────────────────────────────────

class _DetectableCropsInfo extends StatelessWidget {
  const _DetectableCropsInfo();

  static const _detectableCrops = [
    (
      name: 'আলু',
      icon: '🥔',
      diseases: ['আর্লি ব্লাইট', 'লেট ব্লাইট'],
      color: Color(0xFFB45309),
    ),
    (
      name: 'টমেটো',
      icon: '🍅',
      diseases: ['লেট ব্লাইট', 'হলুদ পাতা কার্ল ভাইরাস'],
      color: Color(0xFFDC2626),
    ),
    (
      name: 'ভুট্টা',
      icon: '🌽',
      diseases: ['সাধারণ মরিচা', 'উত্তর পাতার ব্লাইট'],
      color: Color(0xFFCA8A04),
    ),
    (
      name: 'মরিচ',
      icon: '🌶️',
      diseases: ['ব্যাকটেরিয়াল স্পট'],
      color: Color(0xFFDC2626),
    ),
    (
      name: 'আপেল',
      icon: '🍎',
      diseases: ['কালো পচা', 'সিডার আপেল মরিচা'],
      color: Color(0xFFDC2626),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'যে সব ফসলের রোগ শনাক্ত করা যায়',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _detectableCrops
                .map(
                  (crop) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: crop.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: crop.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(crop.icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          crop.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: crop.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Disease Guidelines Section ─────────────────────────────────────────────────

class _DiseaseGuidelinesSection extends StatelessWidget {
  const _DiseaseGuidelinesSection();

  static const _guidelines = [
    (
      disease: 'আর্লি ব্লাইট',
      crop: 'আলু/টমেটো',
      symptoms: 'পাতায় বাদামি গোলাকার দাগ, পাতা শুকিয়ে যাওয়া',
      treatment:
          'ম্যানকোজেব ছত্রাকনাশক স্প্রে করুন। আক্রান্ত পাতা পুড়িয়ে ফেলুন। জমিতে পানি জমতে দেবেন না।',
      color: Color(0xFFEA580C),
    ),
    (
      disease: 'লেট ব্লাইট',
      crop: 'আলু/টমেটো',
      symptoms: 'পাতায় কালো দাগ, ভেজা ভেজা দাগ, সাদা ছত্রাক',
      treatment:
          'কপার অক্সিক্লোরাইড স্প্রে করুন (২ গ্রাম/লিটার)। আক্রান্ত গাছ তুলে পুড়িয়ে ফেলুন। বৃষ্টির পর অবশ্যই স্প্রে করুন।',
      color: Color(0xFFDC2626),
    ),
    (
      disease: 'হলুদ পাতা কার্ল ভাইরাস',
      crop: 'টমেটো',
      symptoms: 'পাতা হলুদ হয়ে কুঁকড়ে যাওয়া, গাছের বৃদ্ধি বন্ধ',
      treatment:
          'সাদা মাছি নিয়ন্ত্রণ করুন (ইমিডাক্লোপ্রিড)। আক্রান্ত গাছ তুলে ফেলুন। হলুদ আঠালো ফাঁদ ব্যবহার করুন।',
      color: Color(0xFFCA8A04),
    ),
    (
      disease: 'সাধারণ মরিচা',
      crop: 'ভুট্টা',
      symptoms: 'পাতায় মরিচা রঙের দাগ, পাতার উভয় পাশে',
      treatment:
          'ম্যানকোজেব ছত্রাকনাশক (২ গ্রাম/লিটার)। আক্রান্ত পাতা সরিয়ে ফেলুন। প্রতিরোধী জাত চাষ করুন।',
      color: Color(0xFFF97316),
    ),
    (
      disease: 'ব্যাকটেরিয়াল স্পট',
      crop: 'মরিচ/টমেটো',
      symptoms: 'পাতায় ছোট কালো দাগ, পাতা ঝরে পড়া',
      treatment:
          'স্ট্রেপ্টোমাইসিন সালফেট স্প্রে করুন। আক্রান্ত অংশ কেটে পুড়িয়ে ফেলুন। বীজ শোধন করে লাগান।',
      color: Color(0xFF7C2D12),
    ),
    (
      disease: 'কালো পচা',
      crop: 'আপেল',
      symptoms: 'ফলে কালো গোলাকার দাগ, পচন শুরু',
      treatment:
          'কপার ফাঙ্গিসাইড স্প্রে করুন। আক্রান্ত ফল ও পাতা সরিয়ে ফেলুন। বাগান পরিষ্কার রাখুন।',
      color: Color(0xFF78350F),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      title: Row(
        children: [
          const Icon(
            Icons.medical_services_rounded,
            color: Color(0xFF16A34A),
            size: 18,
          ),
          const SizedBox(width: 8),
          const Text(
            'রোগের লক্ষণ ও চিকিৎসা',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B2A),
            ),
          ),
        ],
      ),
      children: _guidelines
          .map(
            (guide) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: guide.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: guide.color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: guide.color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          guide.disease,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        guide.crop,
                        style: TextStyle(
                          fontSize: 11,
                          color: guide.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'লক্ষণ: ${guide.symptoms}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.medical_information_outlined,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'চিকিৎসা: ${guide.treatment}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
// ── Cyclone Signal-Based Farmer Guidance ───────────────────────────────────────

class _CycloneSignalGuidance extends StatelessWidget {
  const _CycloneSignalGuidance();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ঝড় সংকেত ও করণীয়',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                    Text(
                      'প্রতিটি সংকেতে কৃষকের জন্য নির্দেশনা',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ..._signalGuidelines.map((guide) => _SignalGuideCard(guide: guide)),
        ],
      ),
    );
  }
}

class _SignalGuideCard extends StatefulWidget {
  final _SignalGuide guide;

  const _SignalGuideCard({required this.guide});

  @override
  State<_SignalGuideCard> createState() => _SignalGuideCardState();
}

class _SignalGuideCardState extends State<_SignalGuideCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.guide.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.guide.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: widget.guide.color,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: widget.guide.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.guide.signal,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.guide.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: widget.guide.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.guide.windSpeed,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: widget.guide.color,
                      size: 24,
                    ),
                  ],
                ),
                // Expandable content
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.agriculture_rounded,
                              size: 16,
                              color: Colors.black87,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'কৃষকের করণীয়:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...widget.guide.actions.map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    action,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Signal guide data model
class _SignalGuide {
  final String signal;
  final String name;
  final String windSpeed;
  final Color color;
  final List<String> actions;

  const _SignalGuide({
    required this.signal,
    required this.name,
    required this.windSpeed,
    required this.color,
    required this.actions,
  });
}

// Cyclone warning signals for Bangladesh
final List<_SignalGuide> _signalGuidelines = [
  _SignalGuide(
    signal: '১',
    name: 'দূরবর্তী সতর্কতা-১',
    windSpeed: 'বাতাস: ৪০-৫০ কিমি/ঘণ্টা',
    color: const Color(0xFF059669),
    actions: [
      'আবহাওয়া পূর্বাভাস নিয়মিত শুনুন',
      'জরুরি সরঞ্জাম প্রস্তুত রাখুন',
      'ফসলের অবস্থা পরীক্ষা করুন',
    ],
  ),
  _SignalGuide(
    signal: '২',
    name: 'দূরবর্তী সতর্কতা-২',
    windSpeed: 'বাতাস: ৫০-৬০ কিমি/ঘণ্টা',
    color: const Color(0xFF0284C7),
    actions: [
      'দুর্বল গাছের ডালপালা কেটে ফেলুন',
      'সেচ বন্ধ রাখুন',
      'পশুখাদ্য সংরক্ষণ করুন',
    ],
  ),
  _SignalGuide(
    signal: '৩',
    name: 'দূরবর্তী হুঁশিয়ারি-৩',
    windSpeed: 'বাতাস: ৬০-৮০ কিমি/ঘণ্টা',
    color: const Color(0xFFEAB308),
    actions: [
      'পাকা ফসল দ্রুত সংগ্রহ করুন',
      'জলাবদ্ধতা নিষ্কাশনের ব্যবস্থা করুন',
      'মাছ চাষের জাল পরীক্ষা করুন',
      'গবাদি পশু নিরাপদ স্থানে সরান',
    ],
  ),
  _SignalGuide(
    signal: '৪',
    name: 'স্থানীয় সতর্কতা-৪',
    windSpeed: 'বাতাস: ৮০-৮৯ কিমি/ঘণ্টা',
    color: const Color(0xFFF59E0B),
    actions: [
      'ফসলের মাঠে কাজ বন্ধ রাখুন',
      'সার ও কীটনাশক সুরক্ষিত রাখুন',
      'কৃষি যন্ত্রপাতি ঘরে তুলুন',
      'পুকুরে বাঁধ মজবুত করুন',
    ],
  ),
  _SignalGuide(
    signal: '৫',
    name: 'নদীবন্দর সতর্কতা',
    windSpeed: 'বাতাস: ৪০-৬১ কিমি/ঘণ্টা (নদী)',
    color: const Color(0xFF7C3AED),
    actions: [
      'নদীতীরে চাষাবাদ স্থগিত রাখুন',
      'বন্যার পূর্বাভাসে সতর্ক থাকুন',
      'নিচু জমির ফসল সরিয়ে নিন',
    ],
  ),
  _SignalGuide(
    signal: '৬',
    name: 'সমুদ্রবন্দর সতর্কতা',
    windSpeed: 'বাতাস: ৬১-৮৮ কিমি/ঘণ্টা (সমুদ্র)',
    color: const Color(0xFF2563EB),
    actions: [
      'উপকূলীয় এলাকায় চাষ বন্ধ রাখুন',
      'লবণ পানির প্রভাব থেকে জমি রক্ষা করুন',
      'ধান ক্ষেতে বাঁধ দিন',
    ],
  ),
  _SignalGuide(
    signal: '৭',
    name: 'বিপদ সংকেত-৭',
    windSpeed: 'বাতাস: ৮৯-১১৭ কিমি/ঘণ্টা',
    color: const Color(0xFFDC2626),
    actions: [
      'সব ধরনের কৃষিকাজ বন্ধ রাখুন',
      'ফসল রক্ষায় আর্মি রোপা করুন',
      'জমিতে না যাবেন',
      'নিরাপদ আশ্রয়ে যান',
    ],
  ),
  _SignalGuide(
    signal: '৮',
    name: 'মহাবিপদ সংকেত-৮',
    windSpeed: 'বাতাস: ১১৮-১৩৩ কিমি/ঘণ্টা',
    color: const Color(0xFF991B1B),
    actions: [
      'শক্ত আশ্রয়ে অবস্থান করুন',
      'সব কৃষি কার্যক্রম পরিত্যাগ করুন',
      'ঝড়ের পরে জমির ক্ষতি পরিমাপ করুন',
    ],
  ),
  _SignalGuide(
    signal: '৯',
    name: 'মহাবিপদ সংকেত-৯',
    windSpeed: 'বাতাস: ১৩৪-১৬৬ কিমি/ঘণ্টা',
    color: const Color(0xFF7F1D1D),
    actions: [
      'আশ্রয়কেন্দ্রে অবস্থান করুন',
      'পরিবারের সদস্যদের একসাথে রাখুন',
      'জরুরি খাবার ও পানি সাথে রাখুন',
    ],
  ),
  _SignalGuide(
    signal: '১০',
    name: 'মহাবিপদ সংকেত-১০',
    windSpeed: 'বাতাস: >১৬৬ কিমি/ঘণ্টা',
    color: const Color(0xFF450A0A),
    actions: [
      'পাকা আশ্রয়কেন্দ্রেই থাকুন',
      'বাহিরে একদম যাবেন না',
      'ঝড় শেষে স্থানীয় প্রশাসনের নির্দেশ মেনে চলুন',
    ],
  ),
];
