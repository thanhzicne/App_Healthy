// file: models/user_model.dart

class UserModel {
  final String name;
  final String email;
  final String gender;
  final int age;
  final double height;
  final String? avatarUrl;

  UserModel({
    required this.name,
    required this.email,
    required this.gender,
    required this.age,
    required this.height,
    this.avatarUrl,
  });

  // Chuyển đổi từ JSON (dữ liệu từ Firestore) sang UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] ?? 'Tên người dùng',
      email: json['email'] ?? '',
      gender: json['gender'] ?? 'Chưa cập nhật',
      age: (json['age'] ?? 0).toInt(),
      height: (json['height'] ?? 0.0).toDouble(),
      avatarUrl: json['avatarUrl'],
    );
  }

  // Chuyển đổi từ UserModel sang JSON (để lưu vào Firestore)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'gender': gender,
      'age': age,
      'height': height,
      'avatarUrl': avatarUrl,
    };
  }

  // Tạo ra một bản sao của UserModel nhưng với các giá trị được cập nhật
  UserModel copyWith({
    String? name,
    String? email,
    String? gender,
    int? age,
    double? height,
    String? avatarUrl,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
