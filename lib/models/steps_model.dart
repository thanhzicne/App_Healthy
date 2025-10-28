import 'package:cloud_firestore/cloud_firestore.dart';

class StepsModel {
  int steps;
  int goal;
  double distance; // ✅ Xóa thuộc tính trùng lặp
  double calories;
  Timestamp lastUpdated;

  StepsModel({
    this.steps = 0,
    this.goal = 10000,
    this.distance = 0.0,
    this.calories = 0.0,
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
        lastUpdated: json['lastUpdated'] ?? Timestamp.now(),
      );
}

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

  Map<String, dynamic> toJson() => {
        'hour': Timestamp.fromDate(hour),
        'steps': steps,
      };
}

class DailySteps {
  final DateTime date;
  final int steps;
  final double calories;
  final double distance; // ✅ Thêm thuộc tính distance

  DailySteps({
    required this.date,
    required this.steps,
    required this.calories,
    required this.distance, // ✅ Thêm vào constructor
  });

  factory DailySteps.fromJson(Map<String, dynamic> json) {
    return DailySteps(
      date: (json['date'] as Timestamp).toDate(),
      steps: json['steps'] ?? 0,
      calories: (json['calories'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 0.0).toDouble(), // ✅ Ánh xạ distance
    );
  }

  Map<String, dynamic> toJson() => {
        'date': Timestamp.fromDate(date),
        'steps': steps,
        'calories': calories,
        'distance': distance, // ✅ Lưu distance vào JSON
      };
}
