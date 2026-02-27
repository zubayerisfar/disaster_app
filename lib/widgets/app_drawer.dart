import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_notification_provider.dart';

/// Shared Application Drawer
///
/// Place this on the root [MainScaffold] Scaffold. Each page receives
/// `onMenuTap` which calls `scaffoldKey.currentState?.openDrawer()`.
///
/// [currentIndex] : the currently visible page (0-5)
/// [onNavigate]   : called with the target page index when user taps an item
class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final void Function(int index) onNavigate;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 28,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A3A6B), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'দুর্যোগ সেবা',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bangladesh Disaster Management',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // ── Menu Items ───────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // 7-day Forecast
                _DrawerItem(
                  icon: Icons.wb_sunny_rounded,
                  label: '৭ দিনের পূর্বাভাস',
                  selected: currentIndex == 9,
                  onTap: () {
                    Navigator.pop(context);
                    onNavigate(9);
                  },
                ),
                const Divider(indent: 16, endIndent: 16, height: 24),
                // Notifications (with unread badge)
                Consumer<AdminNotificationProvider>(
                  builder: (ctx, notifProvider, _) {
                    final unread = notifProvider.unreadCount;
                    return _DrawerItem(
                      icon: Icons.notifications_rounded,
                      label: 'বিজ্ঞপ্তি',
                      selected: currentIndex == 8,
                      badge: unread,
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate(8);
                      },
                    );
                  },
                ),
                const Divider(indent: 16, endIndent: 16, height: 24),
                _DrawerItem(
                  icon: Icons.grass_rounded,
                  label: 'কৃষক সেবা',
                  selected: currentIndex == 7,
                  onTap: () {
                    Navigator.pop(context);
                    onNavigate(7);
                  },
                ),
                const Divider(indent: 16, endIndent: 16, height: 24),
                _DrawerItem(
                  icon: Icons.volunteer_activism_rounded,
                  label: 'স্বেচ্ছাসেবী',
                  selected: currentIndex == 4,
                  onTap: () {
                    Navigator.pop(context);
                    onNavigate(4);
                  },
                ),
                _DrawerItem(
                  icon: Icons.shield_rounded,
                  label: 'নারী ও শিশু সুরক্ষা',
                  selected: currentIndex == 5,
                  onTap: () {
                    Navigator.pop(context);
                    onNavigate(5);
                  },
                ),
                const Divider(indent: 16, endIndent: 16, height: 24),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  label: 'সেটিংস',
                  selected: currentIndex == 6,
                  onTap: () {
                    Navigator.pop(context);
                    onNavigate(6);
                  },
                ),
                _DrawerItem(
                  icon: Icons.info_outline_rounded,
                  label: 'অ্যাপ সম্পর্কে',
                  onTap: () => Navigator.pop(context),
                  comingSoon: true,
                ),
              ],
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Text(
              'দুর্যোগ সেবা v1.0.0',
              style: TextStyle(color: Colors.black38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool comingSoon;
  final int badge;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.comingSoon = false,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? const Color(0xFF1565C0) : const Color(0xFF1A3A6B),
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? const Color(0xFF1565C0) : const Color(0xFF0D1B2A),
        ),
      ),
      tileColor: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      trailing: badge > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : comingSoon
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: const Text(
                'শীঘ্রই',
                style: TextStyle(fontSize: 11, color: Color(0xFF1565C0)),
              ),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: onTap,
    );
  }
}
