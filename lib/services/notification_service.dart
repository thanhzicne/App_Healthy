// file: services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Khởi tạo timezone
      tz.initializeTimeZones();

      // Tạo Android Notification Channel
      const androidChannel = AndroidNotificationChannel(
        'water_reminder_channel',
        'Water Reminder',
        description: 'Nhắc nhở uống nước định kỳ',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF42A5F5),
      );

      // Tạo channel trên Android
      await _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Cấu hình khởi tạo
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Khởi tạo plugin
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      print('📱 Notification initialized: $initialized');

      // Yêu cầu quyền
      await _requestPermissions();

      _initialized = true;
      print('✅ NotificationService khởi tạo thành công');
    } catch (e) {
      print('❌ Lỗi khởi tạo NotificationService: $e');
    }
  }

  // Xử lý khi người dùng tap vào notification
  void _onNotificationTap(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // Có thể thêm navigation hoặc action tại đây
  }

  Future<void> _requestPermissions() async {
    try {
      // Android 13+ (API 33+)
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final granted = await android?.requestNotificationsPermission();
      print('📲 Android notification permission: $granted');

      // Request exact alarm permission cho Android 12+
      final exactAlarmGranted = await android?.requestExactAlarmsPermission();
      print('⏰ Exact alarm permission: $exactAlarmGranted');

      // iOS
      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      final iosGranted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('🍎 iOS notification permission: $iosGranted');
    } catch (e) {
      print('❌ Lỗi yêu cầu quyền: $e');
    }
  }

  // Hiển thị thông báo ngay lập tức
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      print('⚠️ NotificationService chưa được khởi tạo');
      await initialize();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'water_reminder_channel',
        'Water Reminder',
        channelDescription: 'Nhắc nhở uống nước',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        enableLights: true,
        color: Color(0xFF42A5F5),
        ledColor: Color(0xFF42A5F5),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      print('✅ Đã gửi notification #$id: $title');
    } catch (e) {
      print('❌ Lỗi gửi notification: $e');
      rethrow;
    }
  }

  // Lên lịch thông báo định kỳ trong ngày
  Future<void> scheduleDailyReminders({
    required List<int> hours, // VD: [9, 12, 15, 18]
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      await cancelAllReminders();
      print('🗑️ Đã xóa tất cả reminder cũ');

      for (int i = 0; i < hours.length; i++) {
        await _scheduleNotification(
          id: i,
          hour: hours[i],
          minute: 0,
          title: '💧 Đã đến giờ uống nước!',
          body: 'Đừng quên bổ sung nước cho cơ thể nhé!',
        );
        print('⏰ Đã lên lịch reminder lúc ${hours[i]}:00');
      }

      print('✅ Đã lên lịch ${hours.length} reminder');
    } catch (e) {
      print('❌ Lỗi lên lịch reminder: $e');
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // Nếu thời gian đã qua trong ngày hôm nay, lên lịch cho ngày mai
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_reminder_channel',
          'Water Reminder',
          channelDescription: 'Nhắc nhở uống nước',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          color: Color(0xFF42A5F5),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Hủy tất cả thông báo đã lên lịch
  Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancelAll();
      print('✅ Đã hủy tất cả reminder');
    } catch (e) {
      print('❌ Lỗi hủy reminder: $e');
    }
  }

  // Hủy một notification cụ thể
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print('✅ Đã hủy notification #$id');
    } catch (e) {
      print('❌ Lỗi hủy notification: $e');
    }
  }

  // Kiểm tra và gửi thông báo nếu chưa đạt mục tiêu
  Future<void> checkAndNotify({
    required double currentIntake,
    required double goal,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final progress = (currentIntake / goal * 100).toInt();
      final remaining = (goal - currentIntake).toInt();

      if (currentIntake < goal) {
        String body;
        String emoji;

        if (progress < 30) {
          emoji = '🚨';
          body = '$emoji Bạn mới uống được $progress% mục tiêu. Còn $remaining ml nữa!';
        } else if (progress < 70) {
          emoji = '⚠️';
          body = '$emoji Đã đạt $progress% mục tiêu. Cố gắng thêm nhé! Còn $remaining ml.';
        } else {
          emoji = '👍';
          body = '$emoji Sắp đạt mục tiêu rồi! Chỉ còn $remaining ml nữa thôi!';
        }

        await showInstantNotification(
          title: '💧 Nhắc nhở uống nước',
          body: body,
        );
      } else {
        await showInstantNotification(
          title: '🎉 Chúc mừng!',
          body: 'Bạn đã hoàn thành mục tiêu uống nước hôm nay!',
        );
      }
    } catch (e) {
      print('❌ Lỗi checkAndNotify: $e');
    }
  }

  // Lấy danh sách pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 Có ${pending.length} pending notifications');
      return pending;
    } catch (e) {
      print('❌ Lỗi lấy pending notifications: $e');
      return [];
    }
  }
}