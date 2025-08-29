// lib/models/borc_turu.dart
class BorcTuru {
  final int turId;
  final String turAd;
  final int borcTipiId;

  BorcTuru({required this.turId, required this.turAd, required this.borcTipiId});

  factory BorcTuru.fromJson(Map<String, dynamic> json) {
    return BorcTuru(
      turId: json['turId'],
      turAd: json['turAd'],
      borcTipiId: json['borcTipiId'],
    );
  }
}