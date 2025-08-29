class GecmisOdeme {
  final int makbuzId;
  final double odemeTutari;
  final String? odemeDurumu;
  final DateTime? odemeTarihi;
  final String? borcTuruAd;
  final String? dosyaYolu;
  final String? kullaniciAdSoyad;
  final String? daireNo;

  GecmisOdeme({
    required this.makbuzId,
    required this.odemeTutari,
    this.odemeDurumu,
    this.odemeTarihi,
    this.borcTuruAd,
    this.dosyaYolu,
    this.kullaniciAdSoyad,
    this.daireNo,
  });

  factory GecmisOdeme.fromJson(Map<String, dynamic> json) {
    return GecmisOdeme(
      makbuzId: json['makbuzId'],
      odemeTutari: (json['odemeTutari'] as num).toDouble(),
      odemeDurumu: json['odemeDurumu'],
      odemeTarihi: json['odemeTarihi'] != null ? DateTime.parse(json['odemeTarihi']) : null,
      borcTuruAd: json['borcTuruAd'],
      dosyaYolu: json['dosyaYolu'],
      kullaniciAdSoyad: json['kullaniciAdSoyad'],
      daireNo: json['daireNo'],
    );
  }
}