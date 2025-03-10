class User {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen']) 
          : null,
    );
  }
} 