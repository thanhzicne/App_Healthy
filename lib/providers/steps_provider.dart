// steps_provider.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/steps_model.dart';

class StepsProvider with ChangeNotifier {
  // Dữ liệu tổng quan
  StepsModel _steps = StepsModel(lastUpdated: Timestamp.now());
  StepsModel get steps => _steps;

  // Dữ liệu cho biểu đồ
  List<HourlySteps> _hourlySteps = [];
  List<DailySteps> _dailySteps = [];
  List<HourlySteps> get hourlySteps => _hourlySteps;
  List<DailySteps> get dailySteps => _dailySteps;

  StreamSubscription<StepCount>? _stepCountSubscription;
  int _initialSteps = 0;
  int _lastSavedSteps = 0;
  DateTime _lastHourlyUpdateTime = DateTime.now();

  StepsProvider() {
    loadData();
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    super.dispose();
  }

  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  CollectionReference get _userCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('stepsData');

  // Khởi tạo Pedometer
  Future<void> _initPedometer() async {
    if (uid == null) return;

    bool hasPermission = await _requestActivityRecognitionPermission();
    if (!hasPermission) {
      print("Activity Recognition permission not granted!");
      return;
    }

    _stepCountSubscription?.cancel();

    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
      cancelOnError: false,
    );
  }

  // Yêu cầu quyền ACTIVITY_RECOGNITION
  Future<bool> _requestActivityRecognitionPermission() async {
    try {
      final status = await Permission.activityRecognition.status;

      if (status.isDenied) {
        final result = await Permission.activityRecognition.request();
        return result.isGranted;
      }

      return status.isGranted;
    } catch (e) {
      print("Error requesting permission: $e");
      return false;
    }
  }

  // Xử lý khi có dữ liệu bước chân mới
  void _onStepCount(StepCount event) {
    print("Pedometer event received: ${event.steps}");

    if (_initialSteps == 0) {
      _initialSteps = event.steps;
      print("Initial steps set: $_initialSteps");
      return;
    }

    int currentSystemSteps = event.steps;
    int newStepsFromSensor = currentSystemSteps - _initialSteps;

    print("Current system steps: $currentSystemSteps, Initial: $_initialSteps, New steps: $newStepsFromSensor");

    if (newStepsFromSensor > 0) {
      int totalStepsToday = _steps.steps + newStepsFromSensor;
      print("Total steps today: $totalStepsToday");

      _updateStepsData(totalStepsToday, newStepsFromSensor);

      _initialSteps = currentSystemSteps;
    }
  }

  void _onStepCountError(error) {
    print("Pedometer Error: $error");
  }

  // Cập nhật dữ liệu và tính toán
  void _updateStepsData(int newTotalSteps, int newStepsAdded) {
    _steps.steps = newTotalSteps;
    _steps.calories = newTotalSteps * 0.04;
    _steps.distance = newTotalSteps * 0.000762;
    _steps.lastUpdated = Timestamp.now();

    print("Updated steps: ${_steps.steps}, Calories: ${_steps.calories}, Distance: ${_steps.distance}");

    // Cập nhật biểu đồ hourly
    _updateHourlyChart();

    notifyListeners();
    saveData();
  }

  // Cập nhật biểu đồ hourly tự động
  void _updateHourlyChart() {
    DateTime now = DateTime.now();
    String hourDocId = "${now.year}-${now.month}-${now.day}-${now.hour}";

    // Tìm xem giờ hiện tại có trong danh sách hourlySteps chưa
    int existingIndex = _hourlySteps.indexWhere((h) => h.hour.hour == now.hour);

    if (existingIndex >= 0) {
      // Cập nhật dữ liệu giờ hiện tại
      _hourlySteps[existingIndex] = HourlySteps(hour: now, steps: _steps.steps);
    } else {
      // Thêm giờ mới nếu chưa có
      _hourlySteps.add(HourlySteps(hour: now, steps: _steps.steps));
      _hourlySteps.sort((a, b) => a.hour.hour.compareTo(b.hour.hour));
    }

    _lastHourlyUpdateTime = now;
    print("Hourly chart updated. Total entries: ${_hourlySteps.length}");
  }

  // Load tất cả dữ liệu khi khởi tạo provider
  Future<void> loadData() async {
    if (uid == null) {
      print("Waiting for user to login...");
      FirebaseAuth.instance.authStateChanges().firstWhere((user) => user != null).then((_) {
        loadData();
      });
      return;
    }

    print("StepsProvider: Loading data for user $uid");

    try {
      DocumentSnapshot todayDoc = await _userCollection.doc('today').get();
      if (todayDoc.exists) {
        _steps = StepsModel.fromJson(todayDoc.data() as Map<String, dynamic>);
        _lastSavedSteps = _steps.steps;
      } else {
        _steps = StepsModel(lastUpdated: Timestamp.now());
        _lastSavedSteps = 0;
      }

      await _archiveYesterdayDataIfNeeded();
      await _loadChartData();
      await _initPedometer();

      notifyListeners();
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  // Lưu dữ liệu vào Firestore
  Future<void> saveData() async {
    if (uid == null) return;

    try {
      await _userCollection.doc('today').set(_steps.toJson());

      DateTime now = DateTime.now();
      String hourDocId = "${now.year}-${now.month}-${now.day}-${now.hour}";

      await _userCollection
          .doc('today')
          .collection('hourly')
          .doc(hourDocId)
          .set({
        'hour': Timestamp.fromDate(DateTime(now.year, now.month, now.day, now.hour)),
        'steps': _steps.steps
      }, SetOptions(merge: true));

      _lastSavedSteps = _steps.steps;
      print("Data saved to Firestore: ${_steps.steps} steps");
    } catch (e) {
      print("Error saving data: $e");
    }
  }

  // Hàm kiểm tra xem dữ liệu _steps có phải của hôm qua không
  Future<void> _archiveYesterdayDataIfNeeded() async {
    final lastUpdateDate = _steps.lastUpdated.toDate();
    final now = DateTime.now();

    final lastUpdateDay = DateTime(lastUpdateDate.year, lastUpdateDate.month, lastUpdateDate.day);
    final today = DateTime(now.year, now.month, now.day);

    if (lastUpdateDay.isBefore(today)) {
      print("Archiving yesterday's data...");

      try {
        String yesterdayDocId =
            "${lastUpdateDate.year}-${lastUpdateDate.month}-${lastUpdateDate.day}";

        await _userCollection
            .doc('history')
            .collection('daily')
            .doc(yesterdayDocId)
            .set({
          'date': Timestamp.fromDate(lastUpdateDate),
          'steps': _steps.steps,
          'calories': _steps.calories,
        });

        _steps = StepsModel(lastUpdated: Timestamp.now(), goal: _steps.goal);
        _lastSavedSteps = 0;
        _hourlySteps.clear(); // Xóa dữ liệu hourly cũ

        var snapshot = await _userCollection
            .doc('today')
            .collection('hourly')
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }

        await _userCollection.doc('today').set(_steps.toJson());
        print("Reset steps for today.");
      } catch (e) {
        print("Error archiving yesterday's data: $e");
      }
    }
  }

  // Lấy dữ liệu cho biểu đồ từ Firestore
  Future<void> _loadChartData() async {
    if (uid == null) return;

    try {
      var hourlySnapshot = await _userCollection
          .doc('today')
          .collection('hourly')
          .orderBy('hour')
          .get();
      _hourlySteps = hourlySnapshot.docs
          .map((doc) => HourlySteps.fromJson(doc.data()))
          .toList();

      var dailySnapshot = await _userCollection
          .doc('history')
          .collection('daily')
          .orderBy('date', descending: true)
          .limit(7)
          .get();
      _dailySteps = dailySnapshot.docs
          .map((doc) => DailySteps.fromJson(doc.data()))
          .toList()
          .reversed
          .toList();

      print("Loaded hourly steps: ${_hourlySteps.length}, Daily steps: ${_dailySteps.length}");
    } catch (e) {
      print("Error loading chart data: $e");
    }
  }
}