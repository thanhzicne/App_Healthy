// file: services/water_notification_handler.dart

import 'package:flutter/material.dart';
import 'notification_service.dart';

class WaterNotificationHandler {
  static final WaterNotificationHandler _instance =
      WaterNotificationHandler._internal();

  factory WaterNotificationHandler() => _instance;
  WaterNotificationHandler._internal();

  final NotificationService _notificationService = NotificationService();

  /// Xử lý thông báo dựa trên lượng nước hiện tại
  Future<void> handleWaterIntakeNotification({
    required double currentIntake,
    required double goal,
    required DateTime timestamp,
  }) async {
    try {
      final progress = (currentIntake / goal * 100).toInt();
      final remaining = (goal - currentIntake).toInt();

      // Xóa thông báo cũ trước khi gửi cái mới
      await _notificationService.cancelNotification(1);

      if (currentIntake >= goal * 1.5) {
        // Đã vượt mục tiêu
        await _sendOverLimitNotification(currentIntake, goal);
      } else if (currentIntake >= goal) {
        // Đã đạt mục tiêu
        await _sendGoalAchievedNotification(currentIntake, goal);
      } else if (currentIntake >= goal * 0.75) {
        // Gần đạt mục tiêu (75-99%)
        await _sendNearGoalNotification(progress, remaining);
      } else if (currentIntake >= goal * 0.50) {
        // Nửa đường (50-74%)
        await _sendHalfwayNotification(progress, remaining);
      } else if (currentIntake > 0) {
        // Mới bắt đầu (1-49%)
        await _sendStartedNotification(progress, remaining);
      } else {
        // Chưa uống gì
        await _sendRemindStartNotification(goal.toInt());
      }

      print('✅ Thông báo lượng nước đã được xử lý - Progress: $progress%');
    } catch (e) {
      print('❌ Lỗi xử lý thông báo lượng nước: $e');
    }
  }

  /// Thông báo nhắc nhở bắt đầu uống nước
  Future<void> _sendRemindStartNotification(int goalMl) async {
    await _notificationService.showInstantNotification(
      title: '🌅 Bắt đầu uống nước thôi!',
      body: 'Hôm nay bạn cần uống $goalMl ml nước. Cùng bắt đầu nào!',
      payload: 'start_drinking',
    );
  }

  /// Thông báo mới bắt đầu
  Future<void> _sendStartedNotification(int progress, int remaining) async {
    await _notificationService.showInstantNotification(
      title: '💧 Tốt lắm!',
      body:
          '🎯 Bạn đã uống được $progress% mục tiêu. Cố gắng thêm nhé! Còn $remaining ml nữa thôi.',
      payload: 'progress_started',
    );
  }

  /// Thông báo nửa đường
  Future<void> _sendHalfwayNotification(int progress, int remaining) async {
    await _notificationService.showInstantNotification(
      title: '⚡ Đã nửa đường rồi!',
      body:
          '✨ Bạn đã đạt $progress% mục tiêu. Tiếp tục giữ vững nhé! Còn $remaining ml nữa.',
      payload: 'progress_halfway',
    );
  }

  /// Thông báo gần đạt mục tiêu
  Future<void> _sendNearGoalNotification(int progress, int remaining) async {
    await _notificationService.showInstantNotification(
      title: '🔥 Sắp xong rồi!',
      body:
          '🎉 Bạn đã đạt $progress% mục tiêu. Chỉ còn $remaining ml nữa thôi!',
      payload: 'progress_near',
    );
  }

  /// Thông báo đạt mục tiêu
  Future<void> _sendGoalAchievedNotification(
      double currentIntake, double goal) async {
    final surplus = (currentIntake - goal).toInt();
    await _notificationService.showInstantNotification(
      title: '🎉 Chúc mừng!',
      body:
          '🏆 Bạn đã hoàn thành mục tiêu uống nước hôm nay! (Uống thêm ${surplus}ml)',
      payload: 'goal_achieved',
    );
  }

  /// Thông báo vượt mục tiêu
  Future<void> _sendOverLimitNotification(
      double currentIntake, double goal) async {
    final excess = (currentIntake - goal * 1.5).toInt();
    await _notificationService.showInstantNotification(
      title: '⚠️ Cảnh báo!',
      body:
          '🚨 Bạn đã uống quá nhiều nước (${currentIntake.toInt()}ml). Hãy giảm lượng nước để tránh nguy hiểm cho sức khỏe. (Vượt ${excess}ml)',
      payload: 'over_limit',
    );
  }

  /// Gửi thông báo nhắc nhở định kỳ trong ngày
  Future<void> scheduleWaterReminders({
    required List<int> reminderHours,
    required double goal,
  }) async {
    try {
      print('📅 Đang lên lịch nhắc nhở uống nước...');
      await _notificationService.scheduleDailyWaterReminders(
        hours: reminderHours,
      );
      print('✅ Đã lên lịch ${reminderHours.length} nhắc nhở');
    } catch (e) {
      print('❌ Lỗi lên lịch nhắc nhở: $e');
    }
  }

  /// Thông báo nhắc nhở uống nước vào giờ cụ thể
  Future<void> sendScheduledReminder(int hour, double goal) async {
    try {
      final remainingGoal = goal.toInt();
      await _notificationService.showInstantNotification(
        title: '⏰ Giờ uống nước rồi!',
        body:
            '💧 Đã đến ${hour}:00. Bạn cần uống khoảng $remainingGoal ml nước để đạt mục tiêu hôm nay.',
        payload: 'scheduled_reminder_$hour',
      );
      print('✅ Đã gửi nhắc nhở lúc $hour:00');
    } catch (e) {
      print('❌ Lỗi gửi nhắc nhở: $e');
    }
  }

  /// Thông báo thống kê hàng ngày
  Future<void> sendDailySummary({
    required num totalIntake, //Chấp nhận cả int và double
    required num goal,
    required int daysStreak,
  }) async {
    try {
      final percentage = (totalIntake / goal * 100).toInt();
      final status = totalIntake >= goal ? '✅ Đạt mục tiêu' : '❌ Chưa đạt';

      await _notificationService.showInstantNotification(
        title: '📊 Tóm tắt ngày hôm nay',
        body:
            'Bạn uống $percentage% mục tiêu (${totalIntake.toInt()}ml / ${goal.toInt()}ml)\n$status\nChuỗi liên tiếp: $daysStreak ngày 🔥',
        payload: 'daily_summary',
      );
      print('✅ Đã gửi thống kê hàng ngày');
    } catch (e) {
      print('❌ Lỗi gửi thống kê: $e');
    }
  }

  /// Thông báo khuyến khích
  Future<void> sendMotivationNotification() async {
    final motivations = [
      '💪 Uống nước là yêu thương bản thân! Cộng vào mục tiêu hôm nay nào.',
      '🌟 Mỗi lượt uống nước là bước tiến để khỏe mạnh hơn!',
      '🎯 Chỉ cần một chút nỗ lực nữa để hoàn thành mục tiêu!',
      '✨ Cơ thể bạn sẽ cảm ơn bạn vì uống đủ nước!',
      '🏃 Uống nước giúp bạn có năng lượng suốt ngày!',
    ];

    final random = motivations[DateTime.now().millisecond % motivations.length];

    await _notificationService.showInstantNotification(
      title: '💬 Tin nhắn khuyến khích',
      body: random,
      payload: 'motivation',
    );
  }

  /// Hủy tất cả thông báo
  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllReminders();
  }

  /// Lấy danh sách thông báo đang chờ
  Future<void> getPendingNotifications() async {
    final pending = await _notificationService.getPendingNotifications();
    print('📋 Danh sách thông báo đang chờ:');
    for (var notification in pending) {
      print('  - ID: ${notification.id}, Title: ${notification.title}');
    }
  }
}
