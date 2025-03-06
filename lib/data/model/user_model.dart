class User {
  final String id;
  final String? fullName;
  final String? email;

  User({
    required this.id,
    this.fullName,
    this.email,
  });

  // Chuyển đổi từ JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
    };
  }
}
