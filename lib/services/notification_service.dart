import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/weather_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  BuildContext? _context;
  VoidCallback? _navigateToGuidelinesCallback;
  int _lastWarningLevel = 0;
  bool _hasNotified = false;
  bool _isInitialized = false;

  Future<void> initialize(
    BuildContext context,
    VoidCallback navigateToGuidelinesCallback,
  ) async {
    _context = context;
    _navigateToGuidelinesCallback = navigateToGuidelinesCallback;

    if (_isInitialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android 8.0+
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImpl != null) {
        const channel = AndroidNotificationChannel(
          'disaster_alerts',
          'Disaster Alerts',
          description: 'Emergency disaster warning notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await androidImpl.createNotificationChannel(channel);
        debugPrint('✅ Notification channel created');

        // Request permissions for Android 13+
        final granted = await androidImpl.requestNotificationsPermission();
        debugPrint('📱 Notification permission: $granted');
      }

      _isInitialized = true;
      debugPrint('✅ Local notifications initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize notifications: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    if (_navigateToGuidelinesCallback != null) {
      _navigateToGuidelinesCallback!();
    }
  }

  /// Manual test function to trigger notification
  Future<void> testNotification(int level) async {
    debugPrint('🧪 MANUAL TEST: Triggering notification for level $level');
    debugPrint('🔍 Initialized: $_isInitialized');

    if (!_isInitialized) {
      debugPrint('⚠️ Notification service not initialized!');
      return;
    }

    // Check permission status
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl != null) {
      final hasPermission =
          await androidImpl.areNotificationsEnabled() ?? false;
      debugPrint('📱 Notification permission granted: $hasPermission');

      if (!hasPermission) {
        debugPrint('⚠️ Requesting notification permission...');
        final granted = await androidImpl.requestNotificationsPermission();
        debugPrint('📱 Permission request result: $granted');

        if (granted != true) {
          debugPrint('❌ Notification permission denied!');
          return;
        }
      }
    }

    debugPrint('🚀 Sending system notification...');
    _showEvacuationNotification(level);
  }

  void checkWarningLevel(WeatherProvider weatherProvider) {
    final currentLevel = weatherProvider.warningLevel;

    // Debug logging
    debugPrint(
      '🔔 NotificationService: Checking level=$currentLevel, hasNotified=$_hasNotified, lastLevel=$_lastWarningLevel, context=${_context != null ? "exists" : "null"}, mounted=${_context?.mounted ?? false}',
    );

    // Notify when level is above 4 AND (hasn't been notified OR level has increased)
    if (currentLevel > 4) {
      if (!_hasNotified || currentLevel > _lastWarningLevel) {
        debugPrint(
          '🚨 Triggering evacuation notification for level $currentLevel',
        );
        _showEvacuationNotification(currentLevel);
        _hasNotified = true;
      } else {
        debugPrint('⏭️ Same or lower level, skipping...');
      }
    } else {
      // Reset notification flag when level drops to 4 or below
      if (_hasNotified) {
        debugPrint(
          '✅ Level dropped to $currentLevel, resetting notification flag',
        );
      }
      _hasNotified = false;
    }

    _lastWarningLevel = currentLevel;
  }

  void _showEvacuationNotification(int warningLevel) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Notifications not initialized yet');
      return;
    }

    // Define notification details
    final androidDetails = AndroidNotificationDetails(
      'disaster_alerts',
      'Disaster Alerts',
      channelDescription: 'Emergency disaster warning notifications',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFD32F2F),
      styleInformation: BigTextStyleInformation(
        'সংকেত নং $warningLevel ঘোষণা করা হয়েছে। শিশু, নারী ও বয়স্কদের অবিলম্বে নিকটস্থ আশ্রয়কেন্দ্রে পাঠান। জরুরি প্রয়োজনীয় জিনিসপত্র সঙ্গে নিন।',
        htmlFormatBigText: true,
        contentTitle: '🚨 জরুরি দুর্যোগ সতর্কতা',
        htmlFormatContentTitle: true,
        summaryText: 'সংকেত নং $warningLevel',
        htmlFormatSummaryText: true,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification.aiff',
      interruptionLevel: InterruptionLevel.critical,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      debugPrint('📤 Calling _notificationsPlugin.show()...');
      debugPrint('   - ID: $warningLevel');
      debugPrint('   - Title: 🚨 জরুরি দুর্যোগ সতর্কতা');
      debugPrint(
        '   - Body: সংকেত নং $warningLevel - শিশু, নারী ও বয়স্কদের আশ্রয়কেন্দ্রে পাঠান',
      );

      // Show the notification
      await _notificationsPlugin.show(
        warningLevel, // Use warning level as notification ID
        '🚨 জরুরি দুর্যোগ সতর্কতা',
        'সংকেত নং $warningLevel - শিশু, নারী ও বয়স্কদের আশ্রয়কেন্দ্রে পাঠান',
        notificationDetails,
        payload: 'guidelines',
      );

      debugPrint(
        '✅ Local notification sent successfully for warning level $warningLevel',
      );
      debugPrint('📱 Check your notification tray now!');

      // Also show in-app dialog for immediate visibility
      _showInAppAlert(warningLevel);
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to show notification: $e');
      debugPrint('Stack trace: $stackTrace');
      // Fallback to in-app alert only
      _showInAppAlert(warningLevel);
    }
  }

  void _showInAppAlert(int warningLevel) {
    if (_context == null || !_context!.mounted) return;

    final messenger = ScaffoldMessenger.of(_context!);

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 12,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon, title and close button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFD32F2F),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'জরুরি দুর্যোগ সতর্কতা',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => messenger.hideCurrentSnackBar(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    iconSize: 24,
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'সংকেত নং $warningLevel ঘোষণা করা হয়েছে',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'শিশু, নারী ও বয়স্কদের অবিলম্বে নিকটস্থ আশ্রয়কেন্দ্রে পাঠান',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Action button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    _navigateToGuidelines();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFD32F2F),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'নির্দেশিকা দেখুন',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Removed duplicate dialog - only showing SnackBar in-app
  }

  void _navigateToGuidelines() {
    if (_navigateToGuidelinesCallback != null) {
      _navigateToGuidelinesCallback!();
    }
  }

  /// Reset notification flag for testing - allows notification to show again
  void resetNotificationFlag() {
    _hasNotified = false;
  }

  void dispose() {
    _context = null;
    _navigateToGuidelinesCallback = null;
    _lastWarningLevel = 0;
    _hasNotified = false;
  }
}
