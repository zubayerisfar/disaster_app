// SmsChannel wraps the native Android SmsManager via a Flutter MethodChannel.
//
// Sends SMS directly, bypassing any messaging app, using only the
// android.telephony.SmsManager API declared in MainActivity.kt.
// Requires the SEND_SMS permission (android.permission.SEND_SMS).

import 'package:flutter/services.dart';

class SmsChannel {
  static const _channel = MethodChannel('com.disaster_app/sms');

  /// Sends an SMS to [to] with [message] body without opening the messaging app.
  ///
  /// Returns true if the native layer queued the message successfully.
  /// Throws a [PlatformException] if SEND_SMS permission is missing or if the
  /// SmsManager throws.
  static Future<bool> sendSms({
    required String to,
    required String message,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendSms', {
        'to': to,
        'message': message,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('SMS failed: ${e.message}');
    }
  }
}
