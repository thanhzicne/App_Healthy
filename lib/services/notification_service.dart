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

      // Tạo Android Notification Channels
      const waterChannel = AndroidNotificationChannel(
        'water_reminder_channel',
        'Water Reminder',
        description: 'Nhắc nhở uống nước định kỳ',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF42A5F5),
      );

      // ✅ THÊM: Channel cho Steps Reminder
      const stepsChannel = AndroidNotificationChannel(
        'steps_reminder_channel',
        'Steps Reminder',
        description: 'Nhắc nhở đi bộ đạt mục tiêu',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF9C27B0),
      );
      //  THÊM: Channel cho Weight Reminder
      const weightChannel = AndroidNotificationChannel(
        'weight_reminders_channel', // Key mới
        'Weight Reminder',
        description: 'Nhắc nhở đo cân nặng hàng tuần',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFF57C00), // Màu cam
      );
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Tạo channels trên Android
      await androidPlugin?.createNotificationChannel(waterChannel);
      await androidPlugin?.createNotificationChannel(stepsChannel);
      await androidPlugin?.createNotificationChannel(weightChannel);
      // Cấu hình khởi tạo
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
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

  void _onNotificationTap(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
  }

  Future<void> _requestPermissions() async {
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final granted = await android?.requestNotificationsPermission();
      print('📲 Android notification permission: $granted');

      final exactAlarmGranted = await android?.requestExactAlarmsPermission();
      print('⏰ Exact alarm permission: $exactAlarmGranted');

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
    String channelId = 'water_reminder_channel',
    String channelName = 'Water Reminder',
    Color? color,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Thông báo nhắc nhở',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        enableLights: true,
        color: color ?? const Color(0xFF42A5F5),
        ledColor: color ?? const Color(0xFF42A5F5),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
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

  // ✅ WATER: Lên lịch thông báo định kỳ trong ngày
  Future<void> scheduleDailyWaterReminders({
    required List<int> hours,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      await cancelWaterReminders();
      print('🗑️ Đã xóa tất cả water reminder cũ');

      for (int i = 0; i < hours.length; i++) {
        await _scheduleNotification(
          id: 100 + i, // ID từ 100-199 cho water
          hour: hours[i],
          minute: 0,
          title: '💧 Đã đến giờ uống nước!',
          body: 'Đừng quên bổ sung nước cho cơ thể nhé!',
          channelId: 'water_reminder_channel',
          channelName: 'Water Reminder',
          color: const Color(0xFF42A5F5),
        );
        print('⏰ Đã lên lịch water reminder lúc ${hours[i]}:00');
      }

      print('✅ Đã lên lịch ${hours.length} water reminder');
    } catch (e) {
      print('❌ Lỗi lên lịch water reminder: $e');
    }
  }

  // ✅ STEPS: Lên lịch nhắc nhở đi bộ
  Future<void> scheduleDailyStepsReminders({
    List<int>? customHours, // Nếu null, dùng mặc định
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      await cancelStepsReminders();
      print('🗑️ Đã xóa tất cả steps reminder cũ');

      // Giờ nhắc nhở mặc định: 10h, 14h, 17h, 20h
      final hours = customHours ?? [10, 14, 17, 20];

      for (int i = 0; i < hours.length; i++) {
        await _scheduleNotification(
          id: 200 + i, // ID từ 200-299 cho steps
          hour: hours[i],
          minute: 0,
          title: '🚶 Đã đến giờ vận động!',
          body: 'Hãy đi bộ để đạt mục tiêu 10,000 bước mỗi ngày nhé!',
          channelId: 'steps_reminder_channel',
          channelName: 'Steps Reminder',
          color: const Color(0xFF9C27B0),
        );
        print('⏰ Đã lên lịch steps reminder lúc ${hours[i]}:00');
      }

      print('✅ Đã lên lịch ${hours.length} steps reminder');
    } catch (e) {
      print('❌ Lỗi lên lịch steps reminder: $e');
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required Color color,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Nhắc nhở định kỳ',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          color: color,
        ),
        iOS: const DarwinNotificationDetails(
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

  // ✅ WATER: Kiểm tra và gửi thông báo nếu chưa đạt mục tiêu
  Future<void> checkWaterGoalAndNotify({
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
          body =
              '$emoji Bạn mới uống được $progress% mục tiêu. Còn $remaining ml nữa!';
        } else if (progress < 70) {
          emoji = '⚠️';
          body =
              '$emoji Đã đạt $progress% mục tiêu. Cố gắng thêm nhé! Còn $remaining ml.';
        } else {
          emoji = '👍';
          body = '$emoji Sắp đạt mục tiêu rồi! Chỉ còn $remaining ml nữa thôi!';
        }

        await showInstantNotification(
          title: '💧 Nhắc nhở uống nước',
          body: body,
          channelId: 'water_reminder_channel',
          channelName: 'Water Reminder',
          color: const Color(0xFF42A5F5),
        );
      } else {
        await showInstantNotification(
          title: '🎉 Chúc mừng!',
          body: 'Bạn đã hoàn thành mục tiêu uống nước hôm nay!',
          channelId: 'water_reminder_channel',
          channelName: 'Water Reminder',
          color: const Color(0xFF4CAF50),
        );
      }
    } catch (e) {
      print('❌ Lỗi checkWaterGoalAndNotify: $e');
    }
  }

  // ✅ STEPS: Kiểm tra và gửi thông báo nếu chưa đạt mục tiêu
  Future<void> checkStepsGoalAndNotify({
    required int currentSteps,
    required int goal,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final progress = (currentSteps / goal * 100).toInt();
      final remaining = goal - currentSteps;

      if (currentSteps < goal) {
        String body;
        String emoji;

        if (progress < 30) {
          emoji = '🚨';
          body =
              '$emoji Bạn mới đi được $currentSteps/$goal bước ($progress%). Còn $remaining bước nữa!';
        } else if (progress < 70) {
          emoji = '⚠️';
          body =
              '$emoji Đã đạt $progress% mục tiêu. Cố gắng thêm nhé! Còn $remaining bước.';
        } else {
          emoji = '👍';
          body =
              '$emoji Sắp đạt mục tiêu rồi! Chỉ còn $remaining bước nữa thôi!';
        }

        await showInstantNotification(
          title: '🚶 Nhắc nhở đi bộ',
          body: body,
          channelId: 'steps_reminder_channel',
          channelName: 'Steps Reminder',
          color: const Color(0xFF9C27B0),
        );
      } else {
        await showInstantNotification(
          title: '🎉 Chúc mừng!',
          body: 'Bạn đã hoàn thành mục tiêu $goal bước hôm nay!',
          channelId: 'steps_reminder_channel',
          channelName: 'Steps Reminder',
          color: const Color(0xFF4CAF50),
        );
      }
    } catch (e) {
      print('❌ Lỗi checkStepsGoalAndNotify: $e');
    }
  }

  // ✅ STEPS: Gửi thông báo động viên theo milestone
  Future<void> notifyStepsMilestone({
    required int currentSteps,
    required int goal,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final milestones = [2500, 5000, 7500, 10000];

    for (var milestone in milestones) {
      if (currentSteps >= milestone && currentSteps < milestone + 100) {
        String title = '';
        String body = '';

        switch (milestone) {
          case 2500:
            title = '🎯 Cột mốc 2,500 bước!';
            body = 'Khởi đầu tốt đấy! Tiếp tục phấn đấu nhé!';
            break;
          case 5000:
            title = '🔥 Đã đi được 5,000 bước!';
            body = 'Bạn đã hoàn thành 50% mục tiêu rồi đấy!';
            break;
          case 7500:
            title = '💪 Đã vượt 7,500 bước!';
            body = 'Tuyệt vời! Còn 2,500 bước nữa là đạt mục tiêu!';
            break;
          case 10000:
            title = '🏆 Hoàn thành 10,000 bước!';
            body = 'Xuất sắc! Bạn đã đạt mục tiêu hôm nay!';
            break;
        }

        await showInstantNotification(
          title: title,
          body: body,
          channelId: 'steps_reminder_channel',
          channelName: 'Steps Reminder',
          color: const Color(0xFF9C27B0),
        );
        break;
      }
    }
  }

  // Hủy tất cả thông báo
  Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancelAll();
      print('✅ Đã hủy tất cả reminder');
    } catch (e) {
      print('❌ Lỗi hủy reminder: $e');
    }
  }

  // Hủy chỉ water reminders
  Future<void> cancelWaterReminders() async {
    try {
      for (int i = 100; i < 200; i++) {
        await _notifications.cancel(i);
      }
      print('✅ Đã hủy tất cả water reminder');
    } catch (e) {
      print('❌ Lỗi hủy water reminder: $e');
    }
  }

  // Hủy chỉ steps reminders
  Future<void> cancelStepsReminders() async {
    try {
      for (int i = 200; i < 300; i++) {
        await _notifications.cancel(i);
      }
      print('✅ Đã hủy tất cả steps reminder');
    } catch (e) {
      print('❌ Lỗi hủy steps reminder: $e');
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
  //  THÊM: Lên lịch hàng tuần (cho cân nặng)
  Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required int weekday, // 1 = Thứ 2, 7 = Chủ Nhật
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      await _notifications.cancel(id); // Hủy lịch cũ trước khi đặt mới

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Tính toán ngày Chủ Nhật (hoặc ngày weekday) tiếp theo
      scheduledDate = scheduledDate.add(Duration(days: (weekday - now.weekday + 7) % 7));
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'weight_reminders_channel', // Dùng channel của cân nặng
            'Weight Reminder',
            channelDescription: 'Nhắc nhở đo cân nặng hàng tuần',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            color: const Color(0xFFF57C00),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // QUAN TRỌNG: Lặp lại hàng tuần
      );
      print('⏰ Đã lên lịch weight reminder (ID $id) vào $weekday lúc $hour:$minute hàng tuần');
    } catch (e) {
      print('❌ Lỗi scheduleWeeklyReminder: $e');
    }
  }

//  THÊM: Hủy chỉ weight reminders
  Future<void> cancelWeightReminders() async {
    try {
      // Giả sử ID của weight là 300-399
      for (int i = 300; i < 400; i++) {
        await _notifications.cancel(i);
      }
      print('✅ Đã hủy tất cả weight reminder');
    } catch (e) {
      print('❌ Lỗi hủy weight reminder: $e');
    }
  }
}
