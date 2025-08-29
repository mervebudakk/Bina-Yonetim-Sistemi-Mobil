class OdemeDetay {
  final double odemeTutari;
  final String? odemeDurumu;
  final DateTime? insertDate;
  OdemeDetay({required this.odemeTutari, this.odemeDurumu, this.insertDate});
  factory OdemeDetay.fromJson(Map<String, dynamic> json) {
    return OdemeDetay(
      odemeTutari: (json['odemeTutari'] as num).toDouble(),
      odemeDurumu: json['odemeDurumu'],
      insertDate: json['insertDate'] != null ? DateTime.parse(json['insertDate']) : null,
    );
  }
}