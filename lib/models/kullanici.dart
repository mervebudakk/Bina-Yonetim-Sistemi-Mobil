// lib/models/kullanici.dart

class Kullanici {
  final int kullaniciId;
  String ad;
  String soyad;
  String tc;
  String? email;
  String? telNo;
  int daireId;
  String? sifre; // Sadece yeni kullanıcı eklerken kullanılacak

  Kullanici({
    required this.kullaniciId,
    required this.ad,
    required this.soyad,
    required this.tc,
    this.email,
    this.telNo,
    required this.daireId,
    this.sifre,
  });

  factory Kullanici.fromJson(Map<String, dynamic> json) {
    return Kullanici(
      kullaniciId: json['kullaniciId'],
      ad: json['ad'],
      soyad: json['soyad'],
      tc: json['tc'],
      email: json['email'],
      telNo: json['telNo'],
      daireId: json['daireId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'kullaniciId': kullaniciId,
      'ad': ad,
      'soyad': soyad,
      'tc': tc,
      'email': email,
      'telNo': telNo,
      'daireId': daireId,
    };
    if (sifre != null && sifre!.isNotEmpty) {
      data['sifre'] = sifre;
    }
    return data;
  }
}