import 'package:flutter/material.dart';
import '../providers/weather_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  BuildContext? _context;
  VoidCallback? _navigateToGuidelinesCallback;
  int _lastWarningLevel = 0;
  bool _hasNotified = false;

  void initialize(
    BuildContext context,
    VoidCallback navigateToGuidelinesCallback,
  ) {
    _context = context;
    _navigateToGuidelinesCallback = navigateToGuidelinesCallback;
  }

  void checkWarningLevel(WeatherProvider weatherProvider) {
    final currentLevel = weatherProvider.warningLevel;

    // Only notify when level increases above 4
    if (currentLevel > 4 && currentLevel > _lastWarningLevel && !_hasNotified) {
      _showEvacuationNotification(currentLevel);
      _hasNotified = true;
    } else if (currentLevel <= 4) {
      // Reset notification flag when level drops
      _hasNotified = false;
    }

    _lastWarningLevel = currentLevel;
  }

  void _showEvacuationNotification(int warningLevel) {
    if (_context == null || !_context!.mounted) return;

    final messenger = ScaffoldMessenger.of(_context!);

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 8,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        duration: const Duration(seconds: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFD32F2F),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'জরুরি দুর্যোগ সতর্কতা',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'সংকেত নং $warningLevel ঘোষণা করা হয়েছে',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'শিশু, নারী ও বয়স্কদের অবিলম্বে নিকটস্থ আশ্রয়কেন্দ্রে পাঠান',
              style: TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'নির্দেশিকা দেখুন',
          textColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          onPressed: () {
            _navigateToGuidelines();
          },
        ),
      ),
    );

    // Also show a dialog for more prominent notification
    _showEvacuationDialog(warningLevel);
  }

  void _showEvacuationDialog(int warningLevel) {
    if (_context == null || !_context!.mounted) return;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFD32F2F),
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'জরুরি সতর্কতা',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'সংকেত নং $warningLevel',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD32F2F),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'দুর্যোগ সংকেত জারি করা হয়েছে। অনুগ্রহ করে নিম্নলিখিত ব্যবস্থা গ্রহণ করুন:',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF0D1B2A),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildInstruction(
              'শিশু, নারী ও বয়স্কদের অবিলম্বে নিকটস্থ আশ্রয়কেন্দ্রে পাঠান',
            ),
            const SizedBox(height: 8),
            _buildInstruction('জরুরি প্রয়োজনীয় জিনিসপত্র সঙ্গে নিন'),
            const SizedBox(height: 8),
            _buildInstruction('নির্দেশিকা পড়ুন এবং সতর্কতা অবলম্বন করুন'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'বুঝেছি',
              style: TextStyle(fontSize: 16, color: Color(0xFF6C757D)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToGuidelines();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'নির্দেশিকা দেখুন',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF1565C0),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0D1B2A),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToGuidelines() {
    if (_navigateToGuidelinesCallback != null) {
      _navigateToGuidelinesCallback!();
    }
  }

  void dispose() {
    _context = null;
    _navigateToGuidelinesCallback = null;
    _lastWarningLevel = 0;
    _hasNotified = false;
  }
}
