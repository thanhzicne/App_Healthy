import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/water_intake_model.dart';

// Import NotificationService
// import '../services/notification_service.dart';
import '../services/notification_service.dart';
import '../services/water_notification_handler.dart';

class WaterProvider with ChangeNotifier {
  WaterIntakeModel _water = WaterIntakeModel();
  UserModel? _user;
  // final _notificationService = NotificationService();
  final _notificationService = NotificationService();
  final _notificationHandler = WaterNotificationHandler();

  WaterIntakeModel get water => _water;
  UserModel? get user => _user;

  Future<void> loadWater() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Load user data
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      _user = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
      _water.mlGoal = _calculateWaterGoal(_user!);
      _water.totalCups = (_water.mlGoal / 250).ceil();
    }

    // Load water intake data
    DocumentSnapshot waterDoc = await FirebaseFirestore.instance
        .collection('water_intakes')
        .doc(uid)
        .get();
    if (waterDoc.exists) {
      _water =
          WaterIntakeModel.fromJson(waterDoc.data() as Map<String, dynamic>);
      if (_isNewDay(_water.lastResetDate)) {
        await _savePreviousDayTotal();
        await resetDailyIntake();
      }
      _pruneDailyIntake();
      await _updateFirestore();
    }

    // Lên lịch thông báo nhắc nhở
    // await _setupDailyReminders();

    notifyListeners();
  }

  Future<void> addWater(int ml) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    String hourKey = DateTime.now().toString().substring(11, 13) + ":00";
    _water.cupsDrunk += (ml / 250).floor();
    _water.hourlyIntake[hourKey] = (_water.hourlyIntake[hourKey] ?? 0) + ml;

    await _updateFirestore();

    // Kiểm tra và thông báo nếu cần
    await _checkProgressAndNotify();

    notifyListeners();
  }

  /// ✅ THÊM: Thêm nước VÀ tự động gửi thông báo
  Future<void> addWaterWithNotification(int ml) async {
    if (FirebaseAuth.instance.currentUser == null) return;

    String hourKey = DateTime.now().toString().substring(11, 13) + ":00";
    _water.cupsDrunk += (ml / 250).floor();
    _water.hourlyIntake[hourKey] = (_water.hourlyIntake[hourKey] ?? 0) + ml;

    await _updateFirestore();

    // Lấy thông tin hiện tại
    final currentIntake = getCurrentDailyIntake();
    final goal = _water.mlGoal;

    // Gửi thông báo dựa trên lượng nước hiện tại
    await _notificationHandler.handleWaterIntakeNotification(
      currentIntake: currentIntake,
      goal: goal,
      timestamp: DateTime.now(),
    );

    print('📱 Đã cập nhật lượng nước và gửi thông báo');

    notifyListeners();
  }

  Future<void> resetDailyIntake() async {
    _water.cupsDrunk = 0;
    _water.hourlyIntake.clear();
    _water.lastResetDate = DateTime.now();
    await _updateFirestore();
  }

  Future<void> _savePreviousDayTotal() async {
    final previousDay = _water.lastResetDate.toString().substring(0, 10);
    final dailyTotal =
    _water.hourlyIntake.values.fold(0, (sum, ml) => sum + ml);
    _water.dailyIntake[previousDay] = dailyTotal;
    await _updateFirestore();
  }

  void _pruneDailyIntake() {
    final now = DateTime.now();
    final keysToRemove = _water.dailyIntake.keys.where((dateStr) {
      final date = DateTime.parse(dateStr);
      return now.difference(date).inDays >= 7;
    }).toList();
    for (var key in keysToRemove) {
      _water.dailyIntake.remove(key);
    }
  }

  Future<void> _updateFirestore() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('water_intakes')
        .doc(uid)
        .set(_water.toJson());
  }

  bool _isNewDay(DateTime lastReset) {
    final now = DateTime.now();
    return now.day != lastReset.day ||
        now.month != lastReset.month ||
        now.year != lastReset.year;
  }

  double _calculateWaterGoal(UserModel user) {
    double baseWeight = user.height * 0.5;
    double mlPerKg = user.gender == 'Nam' ? 35 : 30;
    if (user.age > 50) mlPerKg -= 5;
    return baseWeight * mlPerKg;
  }

  // Thiết lập thông báo nhắc nhở hàng ngày
  Future<void> _setupDailyReminders() async {
    // Uncomment để kích hoạt
    // await _notificationService.scheduleDailyReminders(
    //   hours: [9, 12, 15, 18, 21], // Nhắc vào 9h, 12h, 15h, 18h, 21h
    // );
  }

  /// ✅ THÊM: Khởi tạo nhắc nhở hàng ngày
  Future<void> initializeDailyReminders() async {
    try {
      final reminderHours = [8, 12, 15, 18, 21];

      await _notificationHandler.scheduleWaterReminders(
        reminderHours: reminderHours,
        goal: _water.mlGoal,
      );

      print('✅ Đã khởi tạo nhắc nhở hàng ngày');
    } catch (e) {
      print('❌ Lỗi khởi tạo nhắc nhở: $e');
    }
  }

  /// ✅ THÊM: Gửi thông báo thống kê cuối ngày
  Future<void> sendEndOfDaySummary() async {
    try {
      final dailyStats = getDailyStats(DateTime.now());
      final totalIntake = dailyStats['intake'] ?? 0.0;
      final goal = dailyStats['goal'] ?? _water.mlGoal;

      final daysStreak = _calculateStreakDays();

      await _notificationHandler.sendDailySummary(
        totalIntake: totalIntake,
        goal: goal,
        daysStreak: daysStreak,
      );

      print('✅ Đã gửi tóm tắt cuối ngày');
    } catch (e) {
      print('❌ Lỗi gửi tóm tắt: $e');
    }
  }

  /// ✅ THÊM: Gửi thông báo khuyến khích
  Future<void> sendMotivation() async {
    await _notificationHandler.sendMotivationNotification();
  }

  /// ✅ THÊM: Tính toán chuỗi liên tiếp
  int _calculateStreakDays() {
    int streak = 0;
    final now = DateTime.now();

    for (int i = 0; i < 100; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toString().substring(0, 10);
      final dailyStats = getDailyStats(date);
      final intake = dailyStats['intake'] ?? 0.0;
      final goal = dailyStats['goal'] ?? _water.mlGoal;

      if (intake >= goal) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// ✅ THÊM: Hủy tất cả thông báo
  Future<void> cancelAllNotifications() async {
    await _notificationHandler.cancelAllNotifications();
  }

  // Kiểm tra tiến độ và gửi thông báo
  Future<void> _checkProgressAndNotify() async {
    final currentIntake = getCurrentDailyIntake();
    final hour = DateTime.now().hour;

    // Chỉ thông báo vào các mốc giờ nhất định (10h, 14h, 18h, 20h)
    if ([10, 14, 18, 20].contains(hour)) {
      final expectedIntake = _getExpectedIntakeByTime(hour);

      if (currentIntake < expectedIntake) {
        // Uncomment để kích hoạt
        // await _notificationService.checkAndNotify(
        //   currentIntake: currentIntake.toDouble(),
        //   goal: _water.mlGoal,
        // );
      }
    }
  }

  // Tính lượng nước dự kiến uống được theo giờ
  double _getExpectedIntakeByTime(int hour) {
    // Phân bổ mục tiêu theo thời gian trong ngày
    // 6h-12h: 30%, 12h-18h: 40%, 18h-22h: 30%
    if (hour < 12) {
      return _water.mlGoal * 0.3 * (hour - 6) / 6;
    } else if (hour < 18) {
      return _water.mlGoal * 0.3 + _water.mlGoal * 0.4 * (hour - 12) / 6;
    } else {
      return _water.mlGoal * 0.7 + _water.mlGoal * 0.3 * (hour - 18) / 4;
    }
  }

  // Lấy lượng nước đã uống trong ngày
  double getCurrentDailyIntake() {
    return _water.hourlyIntake.values.fold(0, (sum, ml) => sum + ml).toDouble();
  }

  // Get daily statistics
  Map<String, dynamic> getDailyStats(DateTime date) {
    final now = DateTime.now();
    int intake = 0;

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      intake = _water.hourlyIntake.values.fold(0, (sum, ml) => sum + ml);
    } else {
      final dateStr = date.toString().substring(0, 10);
      intake = _water.dailyIntake[dateStr] ?? 0;
    }

    return {
      'intake': intake,
      'goal': _water.mlGoal,
      'status': intake >= _water.mlGoal
          ? 'Đạt'
          : (intake > _water.mlGoal * 0.8 ? 'Gần đạt' : 'Chưa đạt'),
    };
  }

  // Get monthly statistics
  Map<String, dynamic> getMonthlyStats(int year, int month) {
    double totalIntake = 0;
    int daysTracked = 0;

    final todayIntake =
    _water.hourlyIntake.values.fold(0, (sum, ml) => sum + ml);

    Map<String, int> monthData = Map.from(_water.dailyIntake);
    final todayStr = DateTime.now().toString().substring(0, 10);
    monthData[todayStr] = todayIntake;

    monthData.forEach((dateStr, ml) {
      final date = DateTime.parse(dateStr);
      if (date.year == year && date.month == month) {
        totalIntake += ml;
        if (ml > 0) {
          daysTracked++;
        }
      }
    });

    double averageDaily = daysTracked > 0 ? totalIntake / daysTracked : 0;
    double goalAchievement = daysTracked > 0
        ? (totalIntake / (_water.mlGoal * daysTracked)) * 100
        : 0;

    return {
      'totalIntake': totalIntake,
      'averageDaily': averageDaily,
      'daysTracked': daysTracked,
      'goalAchievement': goalAchievement,
    };
  }

  // Phương thức để người dùng test thông báo
  Future<void> testNotification() async {
    final currentIntake = getCurrentDailyIntake();
    // Uncomment để kích hoạt
    // await _notificationService.checkAndNotify(
    //   currentIntake: currentIntake,
    //   goal: _water.mlGoal,
    // );
  }
}