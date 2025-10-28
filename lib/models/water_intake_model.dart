class WaterIntakeModel {
  int cupsDrunk = 0;
  double mlGoal = 2500;
  int totalCups = 10;
  Map<String, int> hourlyIntake = {};
  Map<String, int> dailyIntake = {}; // Tổng lượng nước mỗi ngày
  Map<String, int> dailyIntakeMax = {}; // ✅ NEW: Giá trị MAX mỗi ngày
  DateTime lastResetDate = DateTime.now();

  WaterIntakeModel({
    this.cupsDrunk = 0,
    this.mlGoal = 2500,
    this.totalCups = 10,
  });

  Map<String, dynamic> toJson() {
    return {
      'cupsDrunk': cupsDrunk,
      'mlGoal': mlGoal,
      'totalCups': totalCups,
      'hourlyIntake': hourlyIntake,
      'dailyIntake': dailyIntake,
      'dailyIntakeMax': dailyIntakeMax, // ✅ NEW
      'lastResetDate': lastResetDate.toIso8601String(),
    };
  }

  factory WaterIntakeModel.fromJson(Map<String, dynamic> json) {
    return WaterIntakeModel(
      cupsDrunk: json['cupsDrunk'] ?? 0,
      mlGoal: (json['mlGoal'] ?? 2500).toDouble(),
      totalCups: json['totalCups'] ?? 10,
    )
      ..hourlyIntake = Map<String, int>.from(json['hourlyIntake'] ?? {})
      ..dailyIntake = Map<String, int>.from(json['dailyIntake'] ?? {})
      ..dailyIntakeMax =
          Map<String, int>.from(json['dailyIntakeMax'] ?? {}) // ✅ NEW
      ..lastResetDate = DateTime.parse(
          json['lastResetDate'] ?? DateTime.now().toIso8601String());
  }
}
