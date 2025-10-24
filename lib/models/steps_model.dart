// steps_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StepsModel {
  int steps;
  int goal;
  double distance;
  double calories; // Thêm trường calories
  Timestamp lastUpdated; // Thêm trường thời gian cập nhật

  StepsModel({
    this.steps = 0,
    this.goal = 10000,
    this.distance = 0.0,
    this.calories = 0.0, // Khởi tạo giá trị
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'steps': steps,
        'goal': goal,
        'distance': distance,
        'calories': calories,
        'lastUpdated': lastUpdated,
      };

  factory StepsModel.fromJson(Map<String, dynamic> json) => StepsModel(
        steps: json['steps'] ?? 0,
        goal: json['goal'] ?? 10000,
        distance: (json['distance'] ?? 0.0).toDouble(),
        calories: (json['calories'] ?? 0.0).toDouble(),
        // Xử lý cả Timestamp và dữ liệu cũ
        lastUpdated: json['lastUpdated'] ?? Timestamp.now(),
      );
}

// Model cho dữ liệu bước chân hàng giờ (cho biểu đồ trong ngày)
class HourlySteps {
  final DateTime hour;
  final int steps;

  HourlySteps({required this.hour, required this.steps});

  factory HourlySteps.fromJson(Map<String, dynamic> json) {
    return HourlySteps(
      hour: (json['hour'] as Timestamp).toDate(),
      steps: json['steps'] ?? 0,
    );
  }
}

// Model cho dữ liệu bước chân hàng ngày (cho biểu đồ 7 ngày)
class DailySteps {
  final DateTime date;
  final int steps;
  final double calories;

  DailySteps({required this.date, required this.steps, required this.calories});

  factory DailySteps.fromJson(Map<String, dynamic> json) {
    return DailySteps(
      date: (json['date'] as Timestamp).toDate(),
      steps: json['steps'] ?? 0,
      calories: (json['calories'] ?? 0.0).toDouble(),
    );
  }
}
