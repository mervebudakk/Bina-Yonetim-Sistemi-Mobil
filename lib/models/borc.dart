import 'odeme_detay.dart';

class Borc {
  final int borcId;
  final double borcTutari;
  final DateTime? sonOdemeTarihi;
  final DateTime? insertDate;
  final int daireId;
  final int turId; 
  final String? daireNo;
  final String? kullaniciAdSoyad;
  final String? borcTuruAd;
  final String durum;
  final double odenenTutar;
  final double kalanTutar;
  final List<OdemeDetay> odemeler;

  Borc({
    required this.borcId,
    required this.borcTutari,
    this.sonOdemeTarihi,
    this.insertDate,
    required this.daireId,
    required this.turId, 
    this.daireNo,
    this.kullaniciAdSoyad,
    this.borcTuruAd,
    required this.durum,
    required this.odenenTutar, 
    required this.kalanTutar,
    required this.odemeler,
  });

  factory Borc.fromJson(Map<String, dynamic> json) {
    var odemelerList = json['odemeler'] as List?;
    List<OdemeDetay> odemeler = odemelerList?.map((i) => OdemeDetay.fromJson(i)).toList() ?? [];
    return Borc(
      borcId: json['borcId'],
      borcTutari: (json['borcTutari'] as num).toDouble(),
      sonOdemeTarihi: json['sonOdemeTarihi'] != null ? DateTime.parse(json['sonOdemeTarihi']) : null,
      insertDate: json['insertDate'] != null ? DateTime.parse(json['insertDate']) : null,
      daireId: json['daireId'],
      turId: json['turId'], 
      daireNo: json['daireNo'],
      kullaniciAdSoyad: json['kullaniciAdSoyad'],
      borcTuruAd: json['borcTuruAd'],
      durum: json['durum'],
      odenenTutar: (json['odenenTutar'] as num).toDouble(), 
      kalanTutar: (json['kalanTutar'] as num).toDouble(),
      odemeler: odemeler, 
    );
  }
}