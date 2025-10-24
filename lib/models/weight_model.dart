class WeightModel {
  double currentWeight;
  double bmi;

  WeightModel({this.currentWeight = 0.0, this.bmi = 0.0});

  Map<String, dynamic> toJson() => {'currentWeight': currentWeight, 'bmi': bmi};

  factory WeightModel.fromJson(Map<String, dynamic> json) => WeightModel(
    currentWeight: json['currentWeight'] ?? 0.0,
    bmi: json['bmi'] ?? 0.0,
  );
}
