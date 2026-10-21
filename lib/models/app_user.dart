
class AppUser {
  final String id;
  String name;
  String username;
  String role;
  bool isActive;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'role': role,
      'isActive': isActive,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
