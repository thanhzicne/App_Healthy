// steps_provider.dart
import 'dart:async';
import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import '../models/steps_model.dart';
import '../services/notification_service.dart';

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
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  Timer? _pedometerTimeoutTimer;
  Timer? _accelHeartbeatTimer;
  bool _isInitSensorInProgress = false;
  bool _isLoadingData = false;
  bool _hasReceivedPedometerEvent = false;
  DateTime _lastAccelEventAt = DateTime.fromMillisecondsSinceEpoch(0);

  int _lastSensorSteps =
      0; // Giá trị cảm biến cuối cùng nhận được (tổng từ boot)
  int _lastSavedSteps = 0;
  DateTime _lastHourlyUpdateTime = DateTime.now();

  // Biến cho thuật toán Accelerometer
  double _lastMag = 0;
  double _magAvg = 0; // EMA để làm mượt tín hiệu
  DateTime _lastStepTime = DateTime.now();

  // ---------------------------
  // Step detection tuning (Accelerometer fallback)
  // Mục tiêu: giống nhịp bước "bình thường", tránh đếm rung/lắc liên tục.
  // ---------------------------
  // Lấy tín hiệu high-pass (|mag - baseline|), rồi dùng ngưỡng động theo cửa sổ mẫu.
  static const int _signalWindowSize =
      25; // phản ứng nhanh hơn khi lắc/di chuyển nhẹ
  final ListQueue<double> _signalWindow = ListQueue<double>(_signalWindowSize);
  bool _wasAboveThreshold = false;
  int _accelDetectedSteps = 0;
  Timer? _accelCalibrationTimer;

  // Nếu thuật toán "bước chân" không bắt được trên thiết bị,
  // chuyển sang chế độ "shake" để đảm bảo lắc cũng tăng theo yêu cầu.
  bool _forceShakeMode = false;
  double _prevMag = 0;

  // Nhịp bước người bình thường thường ~0.4s - 1.2s (50 - 150 bước/phút).
  // Cho phép rộng hơn để không bỏ sót.
  // Yêu cầu mới: "lắc cũng tăng" -> nới min interval để bắt rung/lắc,
  // nhưng vẫn giới hạn để tránh nhảy quá nhanh.
  static const int _minStepIntervalMs = 2400;
  static const int _maxStepIntervalMs = 3000;

  // Ngưỡng tối thiểu để tránh noise.
  // Hạ xuống để J8 lắc/di chuyển nhẹ cũng lên, nhưng vẫn có ngưỡng sàn.
  double _minThreshold = 0.12;
  bool _isUsingAccelerometer = false;
  bool get isUsingAccelerometer => _isUsingAccelerometer;

  // Trạng thái cho debug/UI
  String _sensorStatus = "Đang khởi tạo...";
  String get sensorStatus => _sensorStatus;

  // Trạng thái quyền và cảm biến
  bool _hasPermission = true;
  bool _isSensorAvailable = true;

  bool get hasPermission => _hasPermission;
  bool get isSensorAvailable => _isSensorAvailable;

  // Lưu ngày hiện tại để kiểm tra reset
  DateTime _savedDate = DateTime.now();

  StepsProvider() {
    _loadFromLocalStorage();
    loadData();
  }

  @override
  void dispose() {
    // Lưu dữ liệu vào SharedPreferences trước khi thoát app
    _saveToLocalStorage();
    _stepCountSubscription?.cancel();
    _accelSubscription?.cancel();
    _pedometerTimeoutTimer?.cancel();
    _accelHeartbeatTimer?.cancel();
    _accelCalibrationTimer?.cancel();
    super.dispose();
  }

  // ✅ Lưu dữ liệu vào SharedPreferences
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('steps_today', _steps.steps);
      await prefs.setDouble('calories_today', _steps.calories);
      await prefs.setDouble('distance_today', _steps.distance);
      await prefs.setString('last_save_date', DateTime.now().toString());
      print('✅ Saved to local storage: ${_steps.steps} steps');
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }

  // ✅ Load dữ liệu từ SharedPreferences
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSteps = prefs.getInt('steps_today') ?? 0;
      final savedCalories = prefs.getDouble('calories_today') ?? 0.0;
      final savedDistance = prefs.getDouble('distance_today') ?? 0.0;
      final lastSaveDateStr = prefs.getString('last_save_date');

      if (lastSaveDateStr != null) {
        _savedDate = DateTime.parse(lastSaveDateStr);
      }

      // ✅ Kiểm tra nếu sang ngày mới -> reset số bước
      DateTime now = DateTime.now();
      DateTime savedDay =
          DateTime(_savedDate.year, _savedDate.month, _savedDate.day);
      DateTime today = DateTime(now.year, now.month, now.day);

      if (today.isAfter(savedDay)) {
        // Sang ngày mới -> reset
        _steps.steps = 0;
        _steps.calories = 0.0;
        _steps.distance = 0.0;
        print('🔄 Ngày mới! Reset số bước về 0');
        // Xóa dữ liệu cũ
        await prefs.remove('steps_today');
        await prefs.remove('calories_today');
        await prefs.remove('distance_today');
      } else {
        // Cùng ngày -> load dữ liệu cũ
        _steps.steps = savedSteps;
        _steps.calories = savedCalories;
        _steps.distance = savedDistance;
        print('✅ Loaded from local storage: $savedSteps steps');
      }
    } catch (e) {
      print('Error loading from local storage: $e');
    }
  }

  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  CollectionReference get _userCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('stepsData');

  // Khởi tạo Pedometer
  Future<void> _initPedometer() async {
    if (uid == null) return;
    if (_isInitSensorInProgress) return;

    // Nếu đã có subscription rồi thì không reset lại (tránh bị kẹt "đang kết nối...")
    if (_stepCountSubscription != null || _accelSubscription != null) {
      return;
    }

    _isInitSensorInProgress = true;
    _hasReceivedPedometerEvent = false;

    _hasPermission = await _requestActivityRecognitionPermission();
    if (!_hasPermission) {
      _sensorStatus = "Thiếu quyền truy cập";
      _isInitSensorInProgress = false;
      notifyListeners();
      return;
    }

    _stepCountSubscription?.cancel();
    _accelSubscription?.cancel();
    _pedometerTimeoutTimer?.cancel();

    _sensorStatus = "Đang kết nối cảm biến...";

    // Thử dùng Pedometer trước
    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (e) {
        print("Pedometer error, falling back to Accelerometer: $e");
        _isInitSensorInProgress = false;
        _startAccelerometerCounting();
      },
      cancelOnError: false,
    );

    // Timeout: Nếu sau 3 giây không có phản hồi từ Pedometer, thử dùng Accelerometer
    _pedometerTimeoutTimer = Timer(const Duration(seconds: 3), () {
      if (!_hasReceivedPedometerEvent) {
        print("Pedometer timeout, falling back to Accelerometer");
        _isInitSensorInProgress = false;
        _startAccelerometerCounting();
      }
    });

    _isSensorAvailable = true;
    notifyListeners();
  }

  void _startAccelerometerCounting() {
    if (_isUsingAccelerometer) return;

    _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
    _pedometerTimeoutTimer?.cancel();
    _isUsingAccelerometer = true;
    _isInitSensorInProgress = false;
    _sensorStatus = "Đang dùng cảm biến gia tốc...";
    _lastMag = 0;
    _magAvg = 0;
    _lastAccelEventAt = DateTime.fromMillisecondsSinceEpoch(0);
    _accelHeartbeatTimer?.cancel();
    _signalWindow.clear();
    _wasAboveThreshold = false;
    _accelDetectedSteps = 0;
    _forceShakeMode = false;
    _prevMag = 0;
    _minThreshold = 0.12;
    _accelCalibrationTimer?.cancel();

    // Dùng accelerometer (có cả trọng lực) vì ổn định hơn trên nhiều máy.
    _accelSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      _lastAccelEventAt = DateTime.now();

      // Magnitude có cả trọng lực ~ 9.81. Dùng EMA làm baseline rồi high-pass.
      final mag =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      // alpha lớn hơn để baseline bám nhanh hơn khi lắc (đỡ trễ)
      const alpha = 0.2;
      _magAvg = (_magAvg == 0) ? mag : (_magAvg * (1 - alpha) + mag * alpha);
      final signal = (mag - _magAvg).abs();

      // Chế độ "shake": dùng jerk (độ thay đổi magnitude) để bắt lắc chắc chắn hơn
      // so với ngưỡng động (vì có máy baseline bám quá nhanh làm signal nhỏ).
      if (_forceShakeMode) {
        final jerk = (_prevMag == 0) ? 0.0 : (mag - _prevMag).abs();
        _prevMag = mag;

        final now = DateTime.now();
        final dt = now.difference(_lastStepTime).inMilliseconds;
        // Ngưỡng jerk tương đối, đủ để lắc nhẹ/mạnh đều vượt.
        if (jerk > 0.35 && dt >= _minStepIntervalMs) {
          _updateStepsData(_steps.steps + 1, 1);
          _accelDetectedSteps++;
          _lastStepTime = now;
        }
        return;
      }

      // Cập nhật cửa sổ tín hiệu để tính ngưỡng động
      if (_signalWindow.length == _signalWindowSize) {
        _signalWindow.removeFirst();
      }
      _signalWindow.addLast(signal);

      // Tính mean/std nhanh (window nhỏ nên O(n) vẫn ổn)
      double mean = 0;
      for (final v in _signalWindow) {
        mean += v;
      }
      mean = _signalWindow.isEmpty ? 0 : mean / _signalWindow.length;

      double variance = 0;
      for (final v in _signalWindow) {
        final d = v - mean;
        variance += d * d;
      }
      variance = _signalWindow.isEmpty ? 0 : variance / _signalWindow.length;
      final std = sqrt(variance);

      // Ngưỡng động: mean + k*std, nhưng không thấp hơn _minThreshold
      // k nhỏ hơn để dễ vượt ngưỡng hơn (đặc biệt khi lắc)
      final dynamicThreshold = max(_minThreshold, mean + 0.8 * std);

      // Đếm theo peak đơn giản (rising edge). Với yêu cầu "lắc cũng tăng",
      // rising edge ổn định hơn falling edge trên nhiều thiết bị.
      final isAbove = signal > dynamicThreshold;
      final now = DateTime.now();
      final dt = now.difference(_lastStepTime).inMilliseconds;

      if (isAbove && !_wasAboveThreshold) {
        _wasAboveThreshold = true;
        if (dt >= _minStepIntervalMs && dt <= _maxStepIntervalMs) {
          _updateStepsData(_steps.steps + 1, 1);
          _accelDetectedSteps++;
          _lastStepTime = now;
        }
      } else if (!isAbove) {
        _wasAboveThreshold = false;
      }

      _lastMag = signal;
    }, onError: (e) {
      _sensorStatus = "Không đọc được cảm biến gia tốc: $e";
      notifyListeners();
    });

    // Auto-calibration: nếu có dữ liệu nhưng 3s vẫn không đếm được bước,
    // tự hạ ngưỡng và cuối cùng chuyển sang shake-mode để đảm bảo "lắc cũng tăng".
    _accelCalibrationTimer = Timer(const Duration(seconds: 3), () {
      if (_accelDetectedSteps == 0) {
        // hạ ngưỡng thêm một lần
        _minThreshold = 0.06;
        _sensorStatus = "Đang dùng gia tốc (tăng nhạy)...";
        notifyListeners();

        // nếu thêm 2s nữa vẫn không có bước -> force shake mode
        _accelCalibrationTimer = Timer(const Duration(seconds: 2), () {
          if (_accelDetectedSteps == 0) {
            _forceShakeMode = true;
            _sensorStatus = "Đang dùng chế độ lắc (shake mode)";
            notifyListeners();
          }
        });
      }
    });

    // Heartbeat: sau 2s mà vẫn chưa nhận event -> báo rõ để người dùng biết do thiết bị/cấu hình.
    _accelHeartbeatTimer = Timer(const Duration(seconds: 2), () {
      if (_lastAccelEventAt.millisecondsSinceEpoch == 0) {
        _sensorStatus =
            "Không nhận được dữ liệu cảm biến. Hãy tắt tiết kiệm pin và thử lại.";
        notifyListeners();
      } else {
        _sensorStatus = "Đang dùng cảm biến gia tốc (đang nhận dữ liệu)";
        notifyListeners();
      }
    });

    notifyListeners();
  }

  // Yêu cầu quyền ACTIVITY_RECOGNITION
  Future<bool> _requestActivityRecognitionPermission() async {
    try {
      final status = await Permission.activityRecognition.status;

      if (status.isDenied) {
        final result = await Permission.activityRecognition.request();
        _hasPermission = result.isGranted;
        notifyListeners();
        return result.isGranted;
      }

      _hasPermission = status.isGranted;
      notifyListeners();
      return status.isGranted;
    } catch (e) {
      print("Error requesting permission: $e");
      _hasPermission = false;
      notifyListeners();
      return false;
    }
  }

  // Hàm để người dùng thử cấp quyền lại từ UI
  Future<void> retryPermission() async {
    await _initPedometer();
  }

  // Xử lý khi có dữ liệu bước chân mới
  void _onStepCount(StepCount event) async {
    print("👣 Pedometer event: ${event.steps} steps since boot");
    _hasReceivedPedometerEvent = true;
    _isUsingAccelerometer = false;
    _isInitSensorInProgress = false;
    _pedometerTimeoutTimer?.cancel();
    _sensorStatus = "Cảm biến đang hoạt động: ${event.steps}";
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String lastSensorKey = 'last_sensor_steps_$uid';
    final int previousSensorValue = prefs.getInt(lastSensorKey) ?? 0;

    if (previousSensorValue == 0) {
      // Lần đầu tiên nhận sự kiện: Thiết lập mốc ban đầu
      print("🚀 Lần đầu nhận dữ liệu cảm biến: ${event.steps}");
      await prefs.setInt(lastSensorKey, event.steps);
      _lastSensorSteps = event.steps;

      // Cập nhật trạng thái để người dùng biết đã kết nối thành công
      _sensorStatus = "Đã kết nối! Hãy bắt đầu di chuyển.";
      notifyListeners();
      // Không return sớm theo kiểu "đợi event thứ 2" nữa.
      // UI vẫn hiển thị realtime theo _steps.steps hiện tại (thường là 0 hoặc đã load từ Firestore).
    }

    final int baseline =
        (previousSensorValue == 0) ? event.steps : previousSensorValue;
    int delta = event.steps - baseline;

    if (delta > 0) {
      print("✅ Phát hiện $delta bước chân mới!");
      int totalStepsToday = _steps.steps + delta;

      _updateStepsData(totalStepsToday, delta);

      // Lưu lại giá trị cảm biến mới nhất
      await prefs.setInt(lastSensorKey, event.steps);
      _lastSensorSteps = event.steps;

      // ✅ Cập nhật notification barrier
      _updateStepsNotification(totalStepsToday);
    } else if (delta < 0) {
      // Trường hợp điện thoại khởi động lại (sensor reset về 0)
      print("🔄 Cảm biến bị reset (có thể do khởi động lại máy)");
      await prefs.setInt(lastSensorKey, event.steps);
      _lastSensorSteps = event.steps;
    }
  }

  void _onStepCountError(error) {
    print("❌ Pedometer Error: $error");
    _startAccelerometerCounting();
  }

  // Cập nhật dữ liệu và tính toán
  void _updateStepsData(int newTotalSteps, int newStepsAdded) {
    _steps.steps = newTotalSteps;
    _steps.calories = newTotalSteps * 0.04;
    _steps.distance = newTotalSteps * 0.000762;
    _steps.lastUpdated = Timestamp.now();

    print(
        "Updated steps: ${_steps.steps}, Calories: ${_steps.calories}, Distance: ${_steps.distance}");

    // Cập nhật biểu đồ hourly
    _updateHourlyChart();

    notifyListeners();
    saveData();
    // ✅ Lưu vào local storage khi cập nhật
    _saveToLocalStorage();
  }

  // ✅ Cập nhật notification với số bước hiện tại
  Future<void> _updateStepsNotification(int currentSteps) async {
    try {
      final notificationService = NotificationService();
      await notificationService.showOrUpdateLiveStepsNotification(
        stepsToday: currentSteps,
        goal: _steps.goal,
      );
    } catch (e) {
      print('Error updating notification: $e');
    }
  }

  // Cập nhật biểu đồ hourly tự động
  void _updateHourlyChart() {
    DateTime now = DateTime.now();

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
    if (_isLoadingData) return;
    if (uid == null) {
      print("Waiting for user to login...");
      _sensorStatus = "Đang chờ đăng nhập...";
      notifyListeners();
      FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((user) => user != null)
          .then((_) {
        loadData();
      });
      return;
    }

    print("StepsProvider: Loading data for user $uid");
    _sensorStatus = "Đang tải dữ liệu...";
    notifyListeners();
    _isLoadingData = true;

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
    } catch (e) {
      // ✅ Quan trọng: Dù Firestore lỗi vẫn phải init cảm biến để đếm realtime.
      print(
          "Error loading steps data (Firestore). Continue init sensor. Error: $e");
    } finally {
      // Luôn khởi động cảm biến để realtime steps hoạt động kể cả khi load Firestore fail.
      _sensorStatus = "Đang khởi động cảm biến...";
      notifyListeners();
      // Chỉ init cảm biến nếu chưa chạy (tránh reset liên tục do loadData bị gọi nhiều lần)
      if (_stepCountSubscription == null && _accelSubscription == null) {
        await _initPedometer();
      }
      _isLoadingData = false;
      notifyListeners();
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
          .set(
        {
          'hour': Timestamp.fromDate(
              DateTime(now.year, now.month, now.day, now.hour)),
          'steps': _steps.steps
        },
        SetOptions(merge: true),
      );

      _lastSavedSteps = _steps.steps;
      print("Data saved to Firestore: ${_steps.steps} steps");
    } catch (e) {
      print("Error saving data: $e");
    }
  }

  // ✅ FIXED: Lưu số bước cao nhất của hôm qua
  // ✅ Sửa hàm _archiveYesterdayDataIfNeeded để lưu cả hourly data
  Future<void> _archiveYesterdayDataIfNeeded() async {
    final lastUpdateDate = _steps.lastUpdated.toDate();
    final now = DateTime.now();
    final lastUpdateDay =
        DateTime(lastUpdateDate.year, lastUpdateDate.month, lastUpdateDate.day);
    final today = DateTime(now.year, now.month, now.day);

    print(
        "📄 Kiểm tra lưu lịch sử - LastUpdate: $lastUpdateDay, Today: $today");

    if (lastUpdateDay.isBefore(today)) {
      print("📄 Phát hiện ngày mới - Lưu dữ liệu bước chân hôm qua");
      try {
        String yesterdayDocId =
            "${lastUpdateDate.year}-${lastUpdateDate.month}-${lastUpdateDate.day}";
        int maxStepsYesterday = _steps.steps;

        // ✅ Lấy tất cả hourly data
        var hourlySnapshot =
            await _userCollection.doc('today').collection('hourly').get();

        // Tìm max steps
        for (var doc in hourlySnapshot.docs) {
          final stepsValue = doc.data()['steps'] ?? 0;
          if (stepsValue > maxStepsYesterday) {
            maxStepsYesterday = stepsValue;
          }
        }

        final caloriesYesterday = maxStepsYesterday * 0.04;
        final distanceYesterday = maxStepsYesterday * 0.000762;

        print('💾 Lưu dữ liệu hôm qua - Max steps: $maxStepsYesterday');

        // ✅ Lưu daily summary
        await _userCollection
            .doc('history')
            .collection('daily')
            .doc(yesterdayDocId)
            .set({
          'date': Timestamp.fromDate(lastUpdateDate),
          'steps': maxStepsYesterday,
          'calories': caloriesYesterday,
          'distance': distanceYesterday,
        });

        // ✅ Lưu hourly data vào history
        for (var doc in hourlySnapshot.docs) {
          final hourData = doc.data();
          await _userCollection
              .doc('history')
              .collection('daily')
              .doc(yesterdayDocId)
              .collection('hourly')
              .doc(doc.id)
              .set(hourData);
        }

        // Reset dữ liệu hôm nay
        _steps = StepsModel(lastUpdated: Timestamp.now(), goal: _steps.goal);
        _lastSavedSteps = 0;
        _hourlySteps.clear();

        // Xóa hourly data cũ
        for (var doc in hourlySnapshot.docs) {
          await doc.reference.delete();
        }

        await _userCollection.doc('today').set(_steps.toJson());
        print("✅ Reset bước chân cho hôm nay thành công");

        await _loadChartData();
      } catch (e) {
        print("Error archiving yesterday's data: $e");
      }
    }
  }

  // ✅ FIXED: Lấy đúng 7 ngày (không tự thêm cho đủ) + hôm nay
  Future<void> _loadChartData() async {
    if (uid == null) return;

    try {
      // ✅ Lấy dữ liệu hourly hôm nay (24 cột)
      var hourlySnapshot = await _userCollection
          .doc('today')
          .collection('hourly')
          .orderBy('hour')
          .get();
      _hourlySteps = hourlySnapshot.docs
          .map((doc) => HourlySteps.fromJson(doc.data()))
          .toList();
      print("📊 Hourly data loaded: ${_hourlySteps.length} records");

      // ✅ Lấy tối đa 7 ngày từ history (chỉ các ngày đã có, không tự thêm)
      var dailySnapshot = await _userCollection
          .doc('history')
          .collection('daily')
          .orderBy('date', descending: true)
          .limit(6) // Lấy 6 ngày quá khứ
          .get();
      print("📅 Firestore history data: ${dailySnapshot.docs.length} records");

      var dailyStepsFromHistory = dailySnapshot.docs
          .map((doc) {
            print("   - Doc: ${doc.id}, Data: ${doc.data()}");
            return DailySteps.fromJson(doc.data());
          })
          .toList()
          .reversed
          .toList();

      // ✅ Thêm dữ liệu hôm nay vào đầu list
      _dailySteps = [
        DailySteps(
          date: DateTime.now(),
          steps: _steps.steps,
          calories: _steps.calories,
          distance: _steps.distance,
        ),
        ...dailyStepsFromHistory,
      ];

      print(
          "✅ Loaded chart data - Hourly steps: ${_hourlySteps.length} giờ, Daily steps: ${_dailySteps.length} ngày (including today)");
      notifyListeners(); // ✅ Cập nhật UI khi load dữ liệu
    } catch (e) {
      print("❌ Error loading chart data: $e");
    }
  }

  //thêm dữ liệu từ nút cài đặt trong profile
  Future<void> updateGoal(int newGoal) async {
    if (uid == null || newGoal <= 0) return;

    _steps.goal = newGoal;

    await saveData(); // Lưu dữ liệu (bao gồm cả goal mới)
    notifyListeners();
  }

  //xoá dữ liệu từ nút cài ặt trong profile
  Future<void> clearAllData() async {
    if (uid == null) return;
    print("--- 🗑️ Bắt đầu xóa tất cả dữ liệu bước chân ---");

    try {
      // 1. Xóa hourly data của hôm nay
      var hourlySnapshot =
          await _userCollection.doc('today').collection('hourly').get();
      for (var doc in hourlySnapshot.docs) {
        await doc.reference.delete();
      }

      // 2. Xóa doc 'today'
      await _userCollection.doc('today').delete();

      // 3. Xóa data lịch sử (history)
      var historySnapshot =
          await _userCollection.doc('history').collection('daily').get();
      for (var doc in historySnapshot.docs) {
        // Xóa sub-collection 'hourly' trong từng ngày lịch sử (nếu có)
        var histHourlySnapshot = await doc.reference.collection('hourly').get();
        for (var hDoc in histHourlySnapshot.docs) {
          await hDoc.reference.delete();
        }
        // Xóa doc của ngày đó
        await doc.reference.delete();
      }

      // 4. Reset state local
      _steps = StepsModel(
          lastUpdated: Timestamp.now(), goal: _steps.goal); // Giữ lại goal
      _hourlySteps.clear();
      _dailySteps.clear();
      _lastSensorSteps = 0;
      _lastSavedSteps = 0;

      // 5. Xóa SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_sensor_steps_$uid');

      print("--- ✅ Đã xóa tất cả dữ liệu bước chân ---");
    } catch (e) {
      print("❌ Lỗi khi xóa dữ liệu bước chân: $e");
    }
    notifyListeners();
  }

  void resetStateOnLogout() {
    // 1. Reset state local
    // (Chúng ta giữ lại goal của người dùng cũ, nó sẽ được load lại)
    _steps = StepsModel(lastUpdated: Timestamp.now(), goal: _steps.goal);
    _hourlySteps.clear();
    _dailySteps.clear();
    _lastSensorSteps = 0;
    _lastSavedSteps = 0;

    // 2. Hủy subscription của Pedometer
    _stepCountSubscription?.cancel();
    _stepCountSubscription = null;

    // 3. Xóa cache cảm biến
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('last_sensor_steps_$uid');
    });

    // KHÔNG GỌI BẤT KỲ HÀM .delete() NÀO
    notifyListeners();
    print('StepsProvider state reset (local only for logout).');
  }
}
