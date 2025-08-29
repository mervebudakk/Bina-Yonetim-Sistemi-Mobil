// lib/models/rol.dart
class Rol {
  final int rolId;
  final String rolTuru;

  Rol({required this.rolId, required this.rolTuru});

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(
      rolId: json['rolId'],
      rolTuru: json['rolTuru'],
    );
  }
}