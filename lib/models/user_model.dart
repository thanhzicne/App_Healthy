class UserModel {
  String name;
  String email;
  String gender;
  int age;
  double height;

  UserModel({
    required this.name,
    required this.email,
    required this.gender,
    required this.age,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'gender': gender,
    'age': age,
    'height': height,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    name: json['name'],
    email: json['email'],
    gender: json['gender'],
    age: json['age'],
    height: json['height'],
  );
}
