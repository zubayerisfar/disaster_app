import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/shelter_provider.dart';

class DisasterAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const DisasterAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E7EF), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
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
                              AppProvider.districtNamesBangla[app
                                      .selectedDistrict] ??
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
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // SOS button
                GestureDetector(
                  onTap: () => _dialSOS(context),
                  child: Container(
                    width: 72,
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
                        'জরুরি',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _dialSOS(BuildContext context) async {
    final uri = Uri.parse('tel:999');
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
                  'Select District',
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
