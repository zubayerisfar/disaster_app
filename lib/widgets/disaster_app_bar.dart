import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/shelter_provider.dart';
import '../providers/admin_notification_provider.dart';

class DisasterAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// When true shows a hamburger icon on the left and centres location/time.
  final bool showMenuButton;
  final VoidCallback? onMenuTap;

  /// When true shows the scrolling notification stripe below the toolbar.
  /// Should only be true on the Home page.
  final bool showTickerTape;

  const DisasterAppBar({
    super.key,
    required this.title,
    this.showMenuButton = false,
    this.onMenuTap,
    this.showTickerTape = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(116 + (showTickerTape ? 24 : 0));

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final toolbarHeight = 90.0;

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            border: const Border(
              bottom: BorderSide(color: Color(0x20E0E7EF), width: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: toolbarHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: showMenuButton
                        ? _homeLayout(context, app)
                        : _defaultLayout(context, app),
                  ),
                ),
                if (showTickerTape)
                  const SizedBox(height: 24, child: _TickerTape()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Home layout: hamburger | centred location+time | SOS ─────────────────
  Widget _homeLayout(BuildContext context, AppProvider app) {
    return Row(
      children: [
        // Hamburger with unread-notification dot
        Consumer<AdminNotificationProvider>(
          builder: (ctx, notifProvider, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: onMenuTap,
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF0D1B2A),
                    size: 28,
                  ),
                  tooltip: 'Menu',
                ),
                if (notifProvider.hasUnread)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // Centred location + time
        Expanded(
          child: GestureDetector(
            onTap: () => _showDistrictPicker(context, app),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_pin,
                      color: Color(0xFF1565C0),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppProvider.districtNamesBangla[app.selectedDistrict] ??
                          app.selectedDistrict,
                      style: const TextStyle(
                        color: Color(0xFF0D1B2A),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF1565C0),
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  app.dateTimeString,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        // SOS button — larger
        GestureDetector(
          onTap: () => _dialSOS(context),
          child: Container(
            width: 112,
            height: 62,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 240, 3, 50),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(height: 2),
                Text(
                  'জরুরি সাহায্য',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Default layout (all other pages) ─────────────────────────────────────
  Widget _defaultLayout(BuildContext context, AppProvider app) {
    return Row(
      children: [
        // Location + time
        Expanded(
          child: GestureDetector(
            onTap: () => _showDistrictPicker(context, app),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_pin,
                      color: Color(0xFF1565C0),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppProvider.districtNamesBangla[app.selectedDistrict] ??
                          app.selectedDistrict,
                      style: const TextStyle(
                        color: Color(0xFF0D1B2A),
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF1565C0),
                      size: 22,
                    ),
                  ],
                ),
                Text(
                  app.dateTimeString,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        // SOS button
        GestureDetector(
          onTap: () => _dialSOS(context),
          child: Container(
            width: 95,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'জরুরি সাহায্য',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Future<void> _dialSOS(BuildContext context) async {
    final app = context.read<AppProvider>();
    final uri = Uri.parse('tel:${app.sosNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot place call on this device.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDistrictPicker(BuildContext context, AppProvider app) {
    // Capture providers before showing bottom sheet
    final weatherProvider = context.read<WeatherProvider>();
    final shelterProvider = context.read<ShelterProvider>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'অবস্থান নির্বাচন করুন',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 20),

            // Network Location Option
            _LocationOptionTile(
              icon: Icons.wifi_rounded,
              title: 'নেটওয়ার্ক থেকে',
              subtitle: 'ইন্টারনেট ব্যবহার করে অবস্থান',
              color: const Color(0xFF1565C0),
              onTap: () {
                Navigator.pop(context);
                // Start async work without blocking
                Future.microtask(() async {
                  await app.fetchCurrentLocation();
                  weatherProvider.loadWeather(app.latitude, app.longitude);
                  shelterProvider.loadShelters(
                    app.selectedDistrict,
                    app.latitude,
                    app.longitude,
                  );
                });
              },
            ),

            const SizedBox(height: 12),

            // GPS Location Option
            _LocationOptionTile(
              icon: Icons.gps_fixed_rounded,
              title: 'GPS থেকে',
              subtitle: 'স্যাটেলাইট দিয়ে সঠিক অবস্থান',
              color: const Color(0xFF2E7D32),
              onTap: () {
                Navigator.pop(context);
                // Start async work without blocking
                Future.microtask(() async {
                  await app.fetchCurrentLocation();
                  weatherProvider.loadWeather(app.latitude, app.longitude);
                  shelterProvider.loadShelters(
                    app.selectedDistrict,
                    app.latitude,
                    app.longitude,
                  );
                });
              },
            ),

            const SizedBox(height: 12),

            // Manual Selection Option
            _LocationOptionTile(
              icon: Icons.edit_location_alt_rounded,
              title: 'ম্যানুয়াল নির্বাচন',
              subtitle: 'জেলা তালিকা থেকে নির্বাচন করুন',
              color: const Color(0xFFE65100),
              onTap: () {
                Navigator.pop(context);
                _showManualDistrictPicker(context, app);
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showManualDistrictPicker(BuildContext context, AppProvider app) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'জেলা নির্বাচন করুন',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: AppProvider.allDistricts.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 16),
                  itemBuilder: (_, i) {
                    final d = AppProvider.allDistricts[i];
                    final selected = d == app.selectedDistrict;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
                      title: Text(
                        AppProvider.districtNamesBangla[d] ?? d,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected
                              ? const Color(0xFF1565C0)
                              : const Color(0xFF0D1B2A),
                        ),
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF1565C0),
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        app.setDistrict(d);
                        Navigator.pop(ctx);
                        // Reload weather & shelters for the newly selected district.
                        // app.latitude/longitude are already updated by setDistrict.
                        context.read<WeatherProvider>().loadWeather(
                          app.latitude,
                          app.longitude,
                        );
                        context.read<ShelterProvider>().loadShelters(
                          app.selectedDistrict,
                          app.latitude,
                          app.longitude,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Helper widget for location option tiles
class _LocationOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _LocationOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            borderRadius: BorderRadius.circular(16),
            color: color.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF546E7A),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ── Scrolling ticker tape ─────────────────────────────────────────────────────

class _TickerTape extends StatefulWidget {
  const _TickerTape();

  @override
  State<_TickerTape> createState() => _TickerTapeState();
}

class _TickerTapeState extends State<_TickerTape>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  String _lastText = '';
  double _lastWidth = 0;

  static const _style = TextStyle(
    fontSize: 11.5,
    color: Color(0xFF1A3A6B),
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  // pixels per second scrolling speed
  static const double _speed = 52.0;

  double _textWidth(String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return tp.width;
  }

  void _restart(String text, double containerWidth) {
    _ctrl?.dispose();
    final tw = _textWidth(text);
    final total = containerWidth + tw;
    final ms = (total / _speed * 1000).round().clamp(4000, 60000);
    _ctrl =
        AnimationController(
            vsync: this,
            duration: Duration(milliseconds: ms),
          )
          ..addListener(() {
            if (mounted) setState(() {});
          })
          ..repeat();
    _lastText = text;
    _lastWidth = containerWidth;
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context
        .watch<AdminNotificationProvider>()
        .notifications;
    final text = notifications.isEmpty
        ? '📢  আপনার জেলার সর্বশেষ বিজ্ঞপ্তিগুলো এখানে দেখা যাবে'
        : '📢  ${notifications.map((n) => n.title).join('   •   ')}   ';

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = constraints.maxWidth;

        if (_ctrl == null || text != _lastText || (w - _lastWidth).abs() > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && (text != _lastText || (w - _lastWidth).abs() > 1)) {
              _restart(text, w);
            }
          });
        }

        final value = _ctrl?.value ?? 0.0;
        final tw = _textWidth(text);
        final offset = w - value * (w + tw);

        return Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0x18003A8C), width: 0.8),
            ),
            color: Color(0x0E1565C0),
          ),
          child: ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(offset, 0),
                child: Text(text, style: _style, maxLines: 1, softWrap: false),
              ),
            ),
          ),
        );
      },
    );
  }
}
