class StepsModel {
  int steps;
  int goal;
  double distance;

  StepsModel({this.steps = 0, this.goal = 10000, this.distance = 0.0});

  Map<String, dynamic> toJson() => {
    'steps': steps,
    'goal': goal,
    'distance': distance,
  };

  factory StepsModel.fromJson(Map<String, dynamic> json) => StepsModel(
    steps: json['steps'] ?? 0,
    goal: json['goal'] ?? 10000,
    distance: json['distance'] ?? 0.0,
  );
}
