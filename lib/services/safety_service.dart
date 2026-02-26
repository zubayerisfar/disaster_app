// SafetyService handles Women & Children emergency alerts.
//
// Provides one-tap direct phone call (no dialer confirmation) and
// programmatic SMS delivery (no messaging app needed).
//
// Bangladesh helplines used by default:
//   • 109  — National Women Violence Helpline (MOWCA)
//   • 999  — National Emergency Service

import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';

import 'sms_channel.dart';

class SafetyService {
  static const String womenHelpline = '01571231302';
  static const String nationalEmergency = '999';

  // ─── Permissions ──────────────────────────────────────────────────────────

  /// Requests CALL_PHONE and SEND_SMS permissions if not already granted.
  /// Returns true when both are granted.
  Future<bool> requestPermissions() async {
    final statuses = await [Permission.phone, Permission.sms].request();
    return statuses[Permission.phone]!.isGranted &&
        statuses[Permission.sms]!.isGranted;
  }

  /// Returns true if CALL_PHONE permission is already granted.
  Future<bool> hasCallPermission() async => await Permission.phone.isGranted;

  /// Returns true if SEND_SMS permission is already granted.
  Future<bool> hasSmsPermission() async => await Permission.sms.isGranted;

  // ─── Direct Call ──────────────────────────────────────────────────────────

  /// Places a direct phone call to [number] without opening the dialer.
  /// The system will ask for CALL_PHONE permission on first use.
  ///
  /// Returns true if the call was initiated successfully.
  Future<bool> directCall(String number) async {
    try {
      final result = await FlutterPhoneDirectCaller.callNumber(number);
      return result ?? false;
    } catch (e) {
      debugPrint('SafetyService.directCall error: $e');
      return false;
    }
  }

  // ─── Direct SMS ───────────────────────────────────────────────────────────

  /// Sends an SMS to [to] with [message] body directly via Android SmsManager.
  /// No messaging app opens. Requests SEND_SMS permission if not yet granted.
  ///
  /// Returns true if the SMS was queued for delivery.
  Future<bool> sendSms({required String to, required String message}) async {
    try {
      // Ensure runtime SEND_SMS permission is granted before invoking native
      final status = await Permission.sms.request();
      if (!status.isGranted) {
        debugPrint('SafetyService.sendSms: SEND_SMS permission denied');
        return false;
      }
      return await SmsChannel.sendSms(to: to, message: message);
    } catch (e) {
      debugPrint('SafetyService.sendSms error: $e');
      return false;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Builds the emergency alert text from the victim's name and location.
  /// Emoji-free so SmsManager uses standard GSM-Unicode encoding without issues.
  static String buildAlertMessage({
    required String name,
    required String location,
  }) {
    return 'EMERGENCY: জরুরি সাহায্য দরকার!\n'
        'নাম: $name\n'
        'অবস্থান: $location\n'
        'অনুগ্রহ করে দ্রুত সাহায্য করুন।';
  }

  /// Builds the "I am safe" confirmation message.
  static String buildSafeMessage({required String name}) {
    return 'SAFE: আমি এখন নিরাপদ আছি।\n'
        'নাম: $name\n'
        'ধন্যবাদ।';
  }
}
