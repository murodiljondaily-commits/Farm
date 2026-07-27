import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'vet_ai_service.dart';

/// Push notifications for the daily digest and weather warnings. Short
/// custom alert tone, no TTS/spoken content -- a standard system
/// notification composed server-side in each device's own locale.
class PushService {
  // Must match push.py's ANDROID_CHANNEL_ID / ANDROID_SOUND_NAME exactly.
  static const _channelId = 'agrivet_alerts';
  static const _channelName = 'AgriVet ogohlantirishlari';
  static const _channelDescription =
      "Ob-havo ogohlantirishlari va kunlik hisobot bildirishnomalari";
  static const _soundResourceName = 'agrivet_alert';

  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Sets up the notification channel + foreground display handling. Safe to
  /// call more than once (no-ops after the first successful run). Does NOT
  /// register a token by itself -- call [registerToken] once a farm/user is
  /// known (see FarmProvider.init()).
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound(_soundResourceName),
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      // Android does not auto-show a system notification for foreground
      // FCM messages (only background/terminated) -- display it ourselves,
      // on the same channel so the custom sound still plays.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final n = message.notification;
        if (n == null) return;
        _localNotifications.show(
          message.hashCode,
          n.title,
          n.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.high,
              priority: Priority.high,
              sound: RawResourceAndroidNotificationSound(_soundResourceName),
            ),
          ),
        );
      });

      _initialized = true;
    } catch (e) {
      debugPrint('[PushService] init error: $e');
    }
  }

  /// Fetches this device's FCM token and registers it with the backend for
  /// [farmId]/[userId] in [localeStr] (e.g. 'uz', 'uz_Cyrl', 'ru' -- same
  /// encoding LocaleProvider already persists). Also listens for token
  /// refresh so a rotated token doesn't silently stop receiving pushes.
  static Future<void> registerToken({
    required String farmId,
    required String userId,
    required String localeStr,
  }) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await VetAiService.registerPushToken(
          farmId: farmId,
          token: token,
          userId: userId,
          locale: localeStr,
        );
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        VetAiService.registerPushToken(
          farmId: farmId,
          token: newToken,
          userId: userId,
          locale: localeStr,
        );
      });
    } catch (e) {
      debugPrint('[PushService] registerToken error: $e');
    }
  }
}
