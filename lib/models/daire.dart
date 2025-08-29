// lib/models/daire.dart

class Daire {
  final int daireId;
  final String daireNo;
  final int apartmanId;
  final String? apartmanNo;      // <-- Hata veren eksik alanlardan biri
  final bool dolulukDurumu;     // <-- Hata veren diğer eksik alan
  final String? aktifKullanici;

  Daire({
    required this.daireId,
    required this.daireNo,
    required this.apartmanId,
    this.apartmanNo,
    required this.dolulukDurumu,
    this.aktifKullanici,
  });

  factory Daire.fromJson(Map<String, dynamic> json) {
    return Daire(
      daireId: json['daireId'],
      daireNo: json['daireNo'],
      apartmanId: json['apartmanId'] ?? 0,
      apartmanNo: json['apartmanNo'],
      dolulukDurumu: json['dolulukDurumu'] ?? false,
      aktifKullanici: json['aktifKullanici'],
    );
  }
}