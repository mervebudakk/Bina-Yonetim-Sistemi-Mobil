import 'odeme_detay.dart';

class BorcDetay {
  final int borcId;
  final double borcTutari;
  final String borcTuruAd;
  final DateTime? sonOdemeTarihi;
  final double odenenTutar;
  final double kalanTutar;
  final String durum;
  final List<OdemeDetay> odemeler;

  BorcDetay({
    required this.borcId,
    required this.borcTutari,
    required this.borcTuruAd,
    this.sonOdemeTarihi,
    required this.odenenTutar,
    required this.kalanTutar,
    required this.durum,
    required this.odemeler,
  });

  factory BorcDetay.fromJson(Map<String, dynamic> json) {
    var odemelerList = json['odemeler'] as List;
    List<OdemeDetay> odemeler =
        odemelerList.map((i) => OdemeDetay.fromJson(i)).toList();
        
    return BorcDetay(
      borcId: json['borcId'],
      borcTutari: (json['borcTutari'] as num).toDouble(),
      borcTuruAd: json['borcTuruAd'],
      sonOdemeTarihi: json['sonOdemeTarihi'] != null
          ? DateTime.parse(json['sonOdemeTarihi'])
          : null,
      odenenTutar: (json['odenenTutar'] as num).toDouble(),
      kalanTutar: (json['kalanTutar'] as num).toDouble(),
      durum: json['durum'],
      odemeler: odemeler,
    );
  }
}