// steps_provider.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
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

  late StreamSubscription<StepCount> _stepCountSubscription;
  int _initialSteps = 0; // Số bước chân khi bắt đầu lắng nghe

  StepsProvider() {
    _initPedometer();
    loadData();
  }

  @override
  void dispose() {
    _stepCountSubscription.cancel();
    super.dispose();
  }

  String get uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference get _userCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('stepsData');

  // Khởi tạo Pedometer
  void _initPedometer() {
    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
      cancelOnError: true,
    );
  }

  // Xử lý khi có dữ liệu bước chân mới
  void _onStepCount(StepCount event) {
    if (_initialSteps == 0) {
      // Lần đầu nhận dữ liệu, lưu lại để tính chênh lệch
      _initialSteps = event.steps;
      return;
    }

    // Số bước chân mới kể từ khi app mở
    int newSteps = event.steps - _initialSteps;

    // Chỉ cập nhật nếu có bước chân mới
    if (newSteps > 0) {
      int totalStepsToday = _steps.steps + newSteps;
      _updateStepsData(totalStepsToday);
      _initialSteps = event.steps; // Reset lại để tính cho lần sau
    }
  }

  void _onStepCountError(error) {
    print("Pedometer Error: $error");
  }

  // Cập nhật dữ liệu và tính toán
  void _updateStepsData(int newTotalSteps) {
    _steps.steps = newTotalSteps;
    _steps.calories = newTotalSteps * 0.04; // Tính calo
    _steps.distance =
        newTotalSteps * 0.000762; // Ước tính quãng đường (1 bước ~ 0.762 mét)
    _steps.lastUpdated = Timestamp.now();

    // Thông báo cho UI cập nhật
    notifyListeners();

    // Lưu vào Firestore
    saveData();
  }

  // Load tất cả dữ liệu khi khởi tạo provider
  Future<void> loadData() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    // Load dữ liệu tổng quan trong ngày
    DocumentSnapshot todayDoc = await _userCollection.doc('today').get();
    if (todayDoc.exists) {
      _steps = StepsModel.fromJson(todayDoc.data() as Map<String, dynamic>);
    } else {
      // Nếu chưa có, tạo mới
      _steps = StepsModel(lastUpdated: Timestamp.now());
    }

    // Load dữ liệu cho biểu đồ
    await _loadChartData();

    notifyListeners();
  }

  // Lưu dữ liệu vào Firestore
  Future<void> saveData() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    // 1. Lưu dữ liệu tổng quan của ngày hôm nay
    await _userCollection.doc('today').set(_steps.toJson());

    // 2. Cập nhật dữ liệu cho biểu đồ giờ hiện tại
    DateTime now = DateTime.now();
    String hourDocId = "${now.year}-${now.month}-${now.day}-${now.hour}";
    await _userCollection.doc('today').collection('hourly').doc(hourDocId).set({
      'hour':
          Timestamp.fromDate(DateTime(now.year, now.month, now.day, now.hour)),
      'steps': _steps.steps
    });

    // 3. Cuối ngày, lưu tổng kết vào collection khác (cần một cơ chế trigger, ví dụ Cloud Function)
    // Tạm thời, chúng ta sẽ mô phỏng việc này khi người dùng mở app vào ngày mới
    _archiveYesterdayData();
  }

  // Lấy dữ liệu cho biểu đồ từ Firestore
  Future<void> _loadChartData() async {
    // Biểu đồ trong ngày
    var hourlySnapshot = await _userCollection
        .doc('today')
        .collection('hourly')
        .orderBy('hour')
        .get();
    _hourlySteps = hourlySnapshot.docs
        .map((doc) => HourlySteps.fromJson(doc.data()))
        .toList();

    // Biểu đồ 7 ngày
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

    notifyListeners();
  }

  // Hàm này nên được chạy bằng Cloud Function vào lúc nửa đêm
  // Hoặc kiểm tra khi người dùng mở app
  Future<void> _archiveYesterdayData() async {
    final lastUpdateDate = _steps.lastUpdated.toDate();
    final now = DateTime.now();

    // Nếu ngày cập nhật cuối cùng là ngày hôm qua
    if (now.difference(lastUpdateDate).inDays > 0) {
      // Lưu dữ liệu của ngày hôm qua vào history
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

      // Reset dữ liệu cho ngày hôm nay
      _steps = StepsModel(lastUpdated: Timestamp.now(), goal: _steps.goal);
      await _userCollection
          .doc('today')
          .collection('hourly')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
      saveData();
    }
  }
}
