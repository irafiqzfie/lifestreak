import 'dart:convert';

class Session {
  final String token;
  final String userId;
  final String username;
  final DateTime expiresAt;

  const Session({
    required this.token,
    required this.userId,
    required this.username,
    required this.expiresAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      token: json['token'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userId': userId,
      'username': username,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  String toStorageValue() => jsonEncode(toJson());

  static Session fromStorageValue(String value) {
    return Session.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }
}
