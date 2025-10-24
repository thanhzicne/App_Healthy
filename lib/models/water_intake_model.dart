class WaterIntakeModel {
  int cupsDrunk;
  int totalCups;
  double mlGoal;
  Map<String, int> hourlyIntake;
  Map<String, int> dailyIntake; // 'YYYY-MM-DD': total ml for the day
  DateTime lastResetDate;

  WaterIntakeModel({
    this.cupsDrunk = 0,
    this.totalCups = 8,
    this.mlGoal = 2000,
    Map<String, int>? hourlyIntake,
    Map<String, int>? dailyIntake,
    DateTime? lastResetDate,
  })  : hourlyIntake = hourlyIntake ?? {},
        dailyIntake = dailyIntake ?? {},
        lastResetDate = lastResetDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'cupsDrunk': cupsDrunk,
        'totalCups': totalCups,
        'mlGoal': mlGoal,
        'hourlyIntake': hourlyIntake,
        'dailyIntake': dailyIntake,
        'lastResetDate': lastResetDate.toIso8601String(),
      };

  factory WaterIntakeModel.fromJson(Map<String, dynamic> json) =>
      WaterIntakeModel(
        cupsDrunk: json['cupsDrunk'] ?? 0,
        totalCups: json['totalCups'] ?? 8,
        mlGoal: json['mlGoal'] ?? 2000,
        hourlyIntake: Map<String, int>.from(json['hourlyIntake'] ?? {}),
        dailyIntake: Map<String, int>.from(json['dailyIntake'] ?? {}),
        lastResetDate: json['lastResetDate'] != null
            ? DateTime.parse(json['lastResetDate'])
            : DateTime.now(),
      );
}
