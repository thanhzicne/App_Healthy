class WaterIntakeModel {
  int cupsDrunk;
  int totalCups;
  double mlGoal;

  WaterIntakeModel({
    this.cupsDrunk = 0,
    this.totalCups = 8,
    this.mlGoal = 2000,
  });

  Map<String, dynamic> toJson() => {
    'cupsDrunk': cupsDrunk,
    'totalCups': totalCups,
    'mlGoal': mlGoal,
  };

  factory WaterIntakeModel.fromJson(Map<String, dynamic> json) =>
      WaterIntakeModel(
        cupsDrunk: json['cupsDrunk'] ?? 0,
        totalCups: json['totalCups'] ?? 8,
        mlGoal: json['mlGoal'] ?? 2000,
      );
}
