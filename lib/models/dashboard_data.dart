// lib/models/dashboard_data.dart

class DashboardData {
  // Tüm roller için ortak
  final int onayBekleyenDekontSayisi;

  // Sadece Sakin için
  final double? aylikToplamBorc;
  final double? aylikOdenenTutar;
  final double? aylikKalanBorc;

  // Sadece Yönetici/Admin için
  final double? yonetimdekiToplamBorc;
  final double? yonetimdekiOdenenTutar;
  final double? yonetimdekiKalanTutar;
  final int? onaylanacakToplamDekont;
  final int? toplamAktifSakin;

  DashboardData({
    required this.onayBekleyenDekontSayisi,
    this.aylikToplamBorc,
    this.aylikOdenenTutar,
    this.aylikKalanBorc,
    this.yonetimdekiToplamBorc,
    this.yonetimdekiOdenenTutar,
    this.yonetimdekiKalanTutar,
    this.onaylanacakToplamDekont,
    this.toplamAktifSakin,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      onayBekleyenDekontSayisi: json['onayBekleyenDekontSayisi'] ?? 0,
      aylikToplamBorc: (json['aylikToplamBorc'] as num?)?.toDouble(),
      aylikOdenenTutar: (json['aylikOdenenTutar'] as num?)?.toDouble(),
      aylikKalanBorc: (json['aylikKalanBorc'] as num?)?.toDouble(),
      yonetimdekiToplamBorc: (json['yonetimdekiToplamBorc'] as num?)?.toDouble(),
      yonetimdekiOdenenTutar: (json['yonetimdekiOdenenTutar'] as num?)?.toDouble(),
      yonetimdekiKalanTutar: (json['yonetimdekiKalanTutar'] as num?)?.toDouble(),
      onaylanacakToplamDekont: json['onaylanacakToplamDekont'],
      toplamAktifSakin: json['toplamAktifSakin'],
    );
  }
}