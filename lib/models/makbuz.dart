class Makbuz {
  final int makbuzId;
  final double odemeTutari;
  final DateTime insertDate;
  final String? kullaniciAdSoyad;
  final String? daireNo;
  final String? dosyaYolu;
  final bool dogrulamaDurumu;

  Makbuz({
    required this.makbuzId,
    required this.odemeTutari,
    required this.insertDate,
    this.kullaniciAdSoyad,
    this.daireNo,
    this.dosyaYolu,
    required this.dogrulamaDurumu,
  });

  factory Makbuz.fromJson(Map<String, dynamic> json) {
    return Makbuz(
      makbuzId: json['makbuzId'],
      odemeTutari: (json['odemeTutari'] as num).toDouble(),
      insertDate: DateTime.parse(json['insertDate']),
      kullaniciAdSoyad: json['kullaniciAdSoyad'],
      daireNo: json['daireNo'],
      dosyaYolu: json['dosyaYolu'],
      dogrulamaDurumu: json['dogrulamaDurumu'] ?? false,
    );
  }
}