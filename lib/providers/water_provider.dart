import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/water_intake_model.dart';

class WaterProvider with ChangeNotifier {
  WaterIntakeModel _water = WaterIntakeModel();
  UserModel? _user;

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
      // Check if reset is needed
      if (_isNewDay(_water.lastResetDate)) {
        await _savePreviousDayTotal();
        await resetDailyIntake();
      }
      _pruneDailyIntake(); // Keep only last 30 days
      notifyListeners();
    }
  }

  Future<void> addWater(int ml) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    String hourKey = DateTime.now().toString().substring(11, 13) + ":00";
    _water.cupsDrunk += (ml / 250).floor();
    _water.hourlyIntake[hourKey] = (_water.hourlyIntake[hourKey] ?? 0) + ml;
    await _updateFirestore();
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
      return now.difference(date).inDays > 30;
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
    // Basic formula: 30-35 ml/kg body weight (assuming height-based estimation)
    double baseWeight = user.height * 0.5; // Rough estimate
    double mlPerKg = user.gender == 'Nam' ? 35 : 30;
    if (user.age > 50) mlPerKg -= 5; // Adjust for older age
    return baseWeight * mlPerKg;
  }

  // Get daily statistics
  Map<String, dynamic> getDailyStats(DateTime date) {
    final dateStr = date.toString().substring(0, 10);
    final intake = _water.dailyIntake[dateStr] ?? 0;
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
    _water.dailyIntake.forEach((dateStr, ml) {
      final date = DateTime.parse(dateStr);
      if (date.year == year && date.month == month) {
        totalIntake += ml;
        daysTracked++;
      }
    });
    return {
      'totalIntake': totalIntake,
      'averageDaily': daysTracked > 0 ? totalIntake / daysTracked : 0,
      'daysTracked': daysTracked,
      'goalAchievement': (totalIntake / (_water.mlGoal * daysTracked)) * 100,
    };
  }
}
