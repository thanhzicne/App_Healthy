// lib/services/weight_notification_handler.dart
import 'notification_service.dart'; // Import service chính

class WeightNotificationHandler {
  final _notificationService = NotificationService();

  // Hàm này tạo nội dung thông báo động như bạn yêu cầu
  Future<void> scheduleWeeklyReminder({
    required double currentWeight,
    required double targetWeight,
  }) async {
    String title = 'Đã đến lúc kiểm tra cân nặng!';
    String body = '';

    if (currentWeight <= 0 || targetWeight <= 0) {
      body = 'Hãy cập nhật cân nặng của bạn để theo dõi tiến độ nhé.';
    } else {
      double diff = targetWeight - currentWeight;
      if (diff.abs() < 0.1) {
        body =
        'Hiện tại: ${currentWeight.toStringAsFixed(1)} kg. Bạn đã đạt được mục tiêu! 🎉';
      } else if (diff > 0) {
        // Cần tăng cân
        body =
        'Hiện tại: ${currentWeight.toStringAsFixed(1)} kg. Cố gắng tăng ${diff.toStringAsFixed(1)} kg nữa để đạt mục tiêu nhé!';
      } else {
        // Cần giảm cân
        body =
        'Hiện tại: ${currentWeight.toStringAsFixed(1)} kg. Cố gắng giảm ${diff.abs().toStringAsFixed(1)} kg nữa để đạt mục tiêu nhé!';
      }
    }

    // Hẹn lịch thông báo này lặp lại hàng tuần
    // (Ví dụ: 9:00 sáng Chủ Nhật hàng tuần)
    await _notificationService.scheduleWeeklyReminder(
      id: 300, // ID 300 cho Cân nặng
      title: title,
      body: body,
      weekday: 7, // 7 = Chủ Nhật (1 = Thứ 2, 7 = Chủ Nhật)
      hour: 9,
      minute: 0,
    );
  }

  // Hủy thông báo
  Future<void> cancelWeeklyReminder() async {
    await _notificationService.cancelWeightReminders();
    print('Đã hủy nhắc nhở cân nặng');
  }
}