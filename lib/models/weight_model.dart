import 'dart:ui';

class WeightModel {
  double currentWeight;
  double bmi;
  DateTime dateTime;

  WeightModel({
    this.currentWeight = 0.0,
    this.bmi = 0.0,
    DateTime? dateTime,
  }) : dateTime = dateTime ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'currentWeight': currentWeight,
        'bmi': bmi,
        'dateTime': dateTime.toIso8601String(),
      };

  factory WeightModel.fromJson(Map<String, dynamic> json) => WeightModel(
        currentWeight: (json['currentWeight'] ?? 0.0).toDouble(),
        bmi: (json['bmi'] ?? 0.0).toDouble(),
        dateTime: DateTime.parse(
            json['dateTime'] ?? DateTime.now().toIso8601String()),
      );
}
