// file: services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Hiển thị thông báo ngay lập tức
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'water_reminder_channel',
      'Water Reminder',
      channelDescription: 'Nhắc nhở uống nước',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
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

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Lên lịch thông báo định kỳ trong ngày
  Future<void> scheduleDailyReminders({
    required List<int> hours, // Danh sách giờ cần nhắc (VD: [9, 12, 15, 18])
  }) async {
    await cancelAllReminders();

    for (int i = 0; i < hours.length; i++) {
      await _scheduleNotification(
        id: i,
        hour: hours[i],
        minute: 0,
        title: '💧 Đã đến giờ uống nước!',
        body: 'Đừng quên bổ sung nước cho cơ thể nhé!',
      );
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
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
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
    await _notifications.cancelAll();
  }

  // Kiểm tra và gửi thông báo nếu chưa đạt mục tiêu
  Future<void> checkAndNotify({
    required double currentIntake,
    required double goal,
  }) async {
    final progress = (currentIntake / goal * 100).toInt();
    final remaining = (goal - currentIntake).toInt();

    if (currentIntake < goal) {
      String body;
      if (progress < 30) {
        body =
            '🚨 Bạn mới uống được $progress% mục tiêu. Còn $remaining ml nữa!';
      } else if (progress < 70) {
        body =
            '⚠️ Đã đạt $progress% mục tiêu. Cố gắng thêm nhé! Còn $remaining ml.';
      } else {
        body = '👍 Sắp đạt mục tiêu rồi! Chỉ còn $remaining ml nữa thôi!';
      }

      await showInstantNotification(
        title: '💧 Nhắc nhở uống nước',
        body: body,
      );
    }
  }
}
