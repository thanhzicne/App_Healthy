import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/water_intake_model.dart';

// Import NotificationService
// import '../services/notification_service.dart';

class WaterProvider with ChangeNotifier {
  WaterIntakeModel _water = WaterIntakeModel();
  UserModel? _user;
  // final _notificationService = NotificationService();

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
