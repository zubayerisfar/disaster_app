import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/shelter_model.dart';
import 'providers/app_provider.dart';
import 'providers/shelter_provider.dart';
import 'theme.dart';
import 'widgets/disaster_app_bar.dart';

class ShelterPage extends StatefulWidget {
  const ShelterPage({super.key});

  @override
  State<ShelterPage> createState() => _ShelterPageState();
}

class _ShelterPageState extends State<ShelterPage> {
  final MapController _mapController = MapController();
  String? _lastDistrict;
  bool _wasLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppProvider>();
    final sp = context.read<ShelterProvider>();

    // District changed → move map to district centre immediately
    if (_lastDistrict != null && _lastDistrict != app.selectedDistrict) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(LatLng(app.latitude, app.longitude), 10);
      });
    }
    _lastDistrict = app.selectedDistrict;

    // Shelters just finished loading → zoom into first shelter
    if (_wasLoading && !sp.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final shelters = context.read<ShelterProvider>().shelters;
        if (shelters.isNotEmpty) {
          _mapController.move(
            LatLng(shelters.first.lat, shelters.first.lng),
            11,
          );
        } else {
          _mapController.move(LatLng(app.latitude, app.longitude), 10);
        }
      });
    }
    _wasLoading = sp.isLoading;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final app = context.read<AppProvider>();
    await context.read<ShelterProvider>().loadShelters(
      app.selectedDistrict,
      app.latitude,
      app.longitude,
    );
  }

  List<Marker> _buildMarkers(List<Shelter> shelters) {
    return shelters
        .map(
          (s) => Marker(
            point: LatLng(s.lat, s.lng),
            width: 42,
            height: 42,
            child: GestureDetector(
              onTap: () => _showShelterSheet(s),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.house, color: Colors.white, size: 20),
              ),
            ),
          ),
        )
        .toList();
  }

  void _showShelterSheet(Shelter s) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ───────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Shelter icon + name ───────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A6B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1B2A),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0F7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'সরকারি আশ্রয়কেন্দ্র',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3A6B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFE5EAF0)),
            const SizedBox(height: 16),

            // ── Info rows ─────────────────────────────────────────────
            _InfoRow(
              icon: Icons.location_on_rounded,
              label: 'ঠিকানা',
              value: s.address,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.people_alt_rounded,
              label: 'ধারণক্ষমতা',
              value: '${s.capacity} জন',
            ),

            const SizedBox(height: 24),

            // ── Action buttons ────────────────────────────────────────
            Row(
              children: [
                // Call button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _callNumber('999');
                    },
                    icon: const Icon(Icons.call_rounded, size: 20),
                    label: const Text(
                      'কল করুন\n999',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB71C1C),
                      side: const BorderSide(
                        color: Color(0xFFB71C1C),
                        width: 2,
                      ),
                      backgroundColor: const Color(0xFFFFF5F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Directions button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openDirections(s);
                    },
                    icon: const Icon(Icons.directions_rounded, size: 20),
                    label: const Text(
                      'দিকনির্দেশনা\nখুলুন',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3A6B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openDirections(Shelter s) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${s.lat},${s.lng}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<ShelterProvider>();
    final app = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const DisasterAppBar(title: 'আশ্রয়কেন্দ্র'),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(app.latitude, app.longitude),
                    initialZoom: 10,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.disaster_app',
                    ),
                    MarkerLayer(markers: _buildMarkers(sp.shelters)),
                  ],
                ),
                if (sp.isLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x55FFFFFF),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${app.selectedDistrict}-এর আশ্রয়কেন্দ্র',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                    ),
                  ),
                  if (sp.error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        sp.error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    )
                  else if (sp.shelters.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'এলাকায় কোনো আশ্রয়কেন্দ্র পাওয়া যায়নি।',
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: sp.shelters.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final s = sp.shelters[i];
                          final dist = sp.distanceTo(
                            app.latitude,
                            app.longitude,
                            s,
                          );
                          return _ShelterListTile(
                            shelter: s,
                            distanceKm: dist,
                            onTap: () {
                              _mapController.move(LatLng(s.lat, s.lng), 14);
                              _showShelterSheet(s);
                            },
                          );
                        },
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1A3A6B), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black45,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D1B2A),
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

class _ShelterListTile extends StatelessWidget {
  final Shelter shelter;
  final double distanceKm;
  final VoidCallback? onTap;
  const _ShelterListTile({
    required this.shelter,
    required this.distanceKm,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A6B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 24,
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ধারণক্ষমতা: ${shelter.capacity} জন',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${distanceKm.toStringAsFixed(1)} কিমি',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A6B),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'বিস্তারিত >',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
