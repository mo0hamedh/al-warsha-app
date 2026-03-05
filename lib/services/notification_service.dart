import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  
  static Future<void> init() async {
    // طلب الإذن
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('User declined or has not accepted permission');
      // On web we often need to rely on vapid key for getToken
    }

    // Initialize Local Notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(initSettings);

    try {
      // احفظ الـ FCM Token في Firestore
      final token = await _messaging.getToken(
          vapidKey: kIsWeb ? 'YOUR_WEB_VAPID_KEY_HERE' : null // Please replace with actual VAPID key later if testing on web
      );
      if (token != null) _updateTokenInFirestore(token);
    } catch (e) {
      debugPrint("FCM Get Token Error: $e");
    }
    
    // تحديث التوكن لو اتغير
    _messaging.onTokenRefresh.listen((token) {
      _updateTokenInFirestore(token);
    });
    
    // استقبال الإشعارات وهو في التطبيق
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    tz.initializeTimeZones();
    await scheduleScheduleReminder();
    await scheduleMidnightLock();
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future scheduleScheduleReminder() async {
    await _localNotifications.cancel(10);
    
    await _localNotifications.zonedSchedule(
      10,
      '📋 جدول الورشة',
      'لا تنسَ تعليم إنجازاتك في جدول اليوم! 🌙',
      _nextInstanceOfTime(22, 0), // 10 PM
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule_reminder',
          'تذكير الجدول',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFFF6A00),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future scheduleMidnightLock() async {
    await _localNotifications.cancel(11);
    
    await _localNotifications.zonedSchedule(
      11,
      '🔒 تم حفظ يومك!',
      'تم حفظ تقدم أمس تلقائياً ✅',
      _nextInstanceOfTime(0, 0), // 12 AM
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'day_lock',
          'قفل اليوم',
          importance: Importance.defaultImportance,
          color: Color(0xFFFF6A00),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
      } catch (e) {
        debugPrint("FCM Update Token Error: $e");
      }
    }
  }
  
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'el_warsha_channel',
      'El Warsha Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }
}
