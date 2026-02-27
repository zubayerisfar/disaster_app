import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'providers/admin_notification_provider.dart';
import 'widgets/disaster_app_bar.dart';

class NotificationsPage extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const NotificationsPage({super.key, this.onMenuTap});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Simple in-app "admin" gate – any non-empty password works as a demo.
  // Change this constant to whatever password you want.
  static const _adminPassword = 'admin1234';

  bool _adminUnlocked = false;

  // ── Admin lock/unlock ───────────────────────────────────────────────────
  void _showAdminLogin(BuildContext ctx) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('অ্যাডমিন লগইন'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'পাসওয়ার্ড',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _tryLogin(dCtx, ctrl.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => _tryLogin(dCtx, ctrl.text),
            child: const Text('লগইন'),
          ),
        ],
      ),
    );
  }

  void _tryLogin(BuildContext dCtx, String pw) {
    if (pw == _adminPassword) {
      Navigator.pop(dCtx);
      setState(() => _adminUnlocked = true);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('ভুল পাসওয়ার্ড'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // ── Send notification dialog ──────────────────────────────────────────
  void _showSendDialog(BuildContext ctx) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('নতুন বিজ্ঞপ্তি পাঠান'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'শিরোনাম',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'বিস্তারিত',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () {
              final t = titleCtrl.text.trim();
              final b = bodyCtrl.text.trim();
              if (t.isEmpty || b.isEmpty) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('শিরোনাম ও বিস্তারিত লিখুন')),
                  );
                return;
              }
              ctx.read<AdminNotificationProvider>().addNotification(
                title: t,
                body: b,
              );
              Navigator.pop(dCtx);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('বিজ্ঞপ্তি পাঠানো হয়েছে'),
                    backgroundColor: Colors.green,
                  ),
                );
            },
            child: const Text('পাঠান'),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final notifications = context
        .watch<AdminNotificationProvider>()
        .notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: DisasterAppBar(
        title: 'বিজ্ঞপ্তি',
        showMenuButton: true,
        onMenuTap: widget.onMenuTap,
      ),
      body: CustomScrollView(
        slivers: [
          // Small breathing room below appbar
          SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Page title row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'সকল বিজ্ঞপ্তি',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                  ),
                  // Admin button
                  if (_adminUnlocked)
                    FilledButton.icon(
                      onPressed: () => _showSendDialog(context),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('পাঠান'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => _showAdminLogin(context),
                      icon: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Color(0xFF1565C0),
                      ),
                      tooltip: 'অ্যাডমিন',
                    ),
                ],
              ),
            ),
          ),

          // Notification list
          if (notifications.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 72,
                      color: Colors.black26,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'কোনো বিজ্ঞপ্তি নেই',
                      style: TextStyle(color: Colors.black45, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final n = notifications[i];
                  return _NotificationCard(
                    notification: n,
                    onDelete: _adminUnlocked
                        ? () => ctx
                              .read<AdminNotificationProvider>()
                              .deleteNotification(n.id)
                        : null,
                  );
                }, childCount: notifications.length),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Notification card widget ───────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final AdminNotification notification;
  final VoidCallback? onDelete;

  const _NotificationCard({required this.notification, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat(
      'd MMM y  •  h:mm a',
    ).format(notification.timestamp.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: notification.isRead
              ? const Color(0xFFE0E7EF)
              : const Color(0xFF1565C0).withValues(alpha: 0.4),
          width: notification.isRead ? 1 : 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEFF6FF),
          child: Icon(
            Icons.campaign_rounded,
            color: const Color(0xFF1565C0),
            size: 22,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
            fontSize: 15,
            color: const Color(0xFF0D1B2A),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              timeStr,
              style: const TextStyle(color: Colors.black38, fontSize: 11),
            ),
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
                onPressed: onDelete,
                tooltip: 'মুছুন',
              )
            : null,
      ),
    );
  }
}
