// lib/models/borc_tipi.dart
class BorcTipi {
  final int borcTipiId;
  final String borcTipiAd;

  BorcTipi({required this.borcTipiId, required this.borcTipiAd});

  factory BorcTipi.fromJson(Map<String, dynamic> json) {
    return BorcTipi(
      borcTipiId: json['borcTipiId'],
      borcTipiAd: json['borcTipiAd'],
    );
  }
}