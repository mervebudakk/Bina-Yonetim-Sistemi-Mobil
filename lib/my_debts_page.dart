import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'config/app_config.dart';
import 'models/borc_detay.dart';
import 'upload_receipt_page.dart';

// --- TEMA RENKLERİ (main.dart dosyanızdan geldiği varsayılır) ---
// Bu sabitleri merkezi bir dosyada (örneğin theme.dart) tutup buradan import edebilirsiniz.
const Color kPrimaryColor = Color(0xFF20C997);
const Color kAppBarColor = Color(0xFF34495E);
const Color kBackgroundColor = Color(0xFFF8F9FA);
const Color kCardColor = Colors.white;
const Color kTextColor = Color(0xFF34495E);
const Color kSecondaryTextColor = Color(0xFF7F8C8D);
const Color kSuccessColor = Color(0xFF28A745);
const Color kWarningColor = Color(0xFFFFC107);
const Color kDangerColor = Color(0xFFDC3545);
const Color kInfoColor = Color(0xFF3498DB);


class MyDebtsPage extends StatefulWidget {
  final String token;
  const MyDebtsPage({super.key, required this.token});

  @override
  State<MyDebtsPage> createState() => _MyDebtsPageState();
}

class _MyDebtsPageState extends State<MyDebtsPage> {
  List<BorcDetay> _borclar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyDebts();
  }

  Future<void> _loadMyDebts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/BorclarApi/kendi-borclarini-goruntuleme'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _borclar = data.map((json) => BorcDetay.fromJson(json)).toList();
          });
        }
      } else {
        throw Exception('Borçlar yüklenemedi. Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Hata mesajı rengi temadan alındı
          SnackBar(content: Text('Hata: $e'), backgroundColor: kDangerColor),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // --- RENK METODU TEMA SABİTLERİYLE GÜNCELLENDİ ---
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) { // Gelen veriyi küçük harfe çevirerek kontrol et
      case 'ödendi':
        return kSuccessColor;
      case 'onay bekliyor':
        return kWarningColor;
      case 'kısmi ödendi':
        return kInfoColor;
      case 'reddedildi':
        return kSecondaryTextColor;
      case 'ödenmedi':
      default:
        return kDangerColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold ve AppBar temadan otomatik olarak renk alacak
    return Scaffold(
      appBar: AppBar(title: const Text('Borçlarım')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : RefreshIndicator(
              // Refresh indicator rengi temadan alındı
              color: kPrimaryColor,
              onRefresh: _loadMyDebts,
              child: _borclar.isEmpty
              ? const Center(
                  child: Text(
                    'Görüntülenecek borcunuz bulunmamaktadır.',
                    style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _borclar.length,
                  itemBuilder: (context, index) {
                    final borc = _borclar[index];
                    double progress = borc.borcTutari > 0
                        ? borc.odenenTutar / borc.borcTutari
                        : 0;
                    final formattedDate = borc.sonOdemeTarihi != null
                        ? DateFormat('dd.MM.yyyy').format(borc.sonOdemeTarihi!)
                        : 'Belirtilmemiş';

                    // Kartlar artık global temadan stil alıyor ama lokal margin korunuyor
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          borc.borcTuruAd,
                          // Metin rengi global temadan geliyor
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Toplam Tutar: ${borc.borcTutari.toStringAsFixed(2)} TL\nSon Ödeme: $formattedDate',
                            // Alt başlık rengi temadan alındı
                            style: const TextStyle(
                              color: kSecondaryTextColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                        trailing: Chip(
                          label: Text(
                            borc.durum,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          backgroundColor: _getStatusColor(borc.durum),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ödenen: ${borc.odenenTutar.toStringAsFixed(2)} TL',
                                      style: const TextStyle(
                                        color: kSuccessColor, // Renk temadan alındı
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Kalan: ${borc.kalanTutar.toStringAsFixed(2)} TL',
                                      style: const TextStyle(
                                        color: kDangerColor, // Renk temadan alındı
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 12,
                                  backgroundColor: Colors.grey[300],
                                  color: _getStatusColor(borc.durum),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                if (borc.odemeler.isNotEmpty) ...[
                                  const Divider(height: 24),
                                  Text(
                                    'Ödeme Geçmişi',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: kTextColor
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...borc.odemeler.map((odeme) {
                                    final odemeDurum = odeme.odemeDurumu?.toLowerCase() ?? '';
                                    return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(
                                            odemeDurum == 'ödendi' ? Icons.check_circle :
                                            odemeDurum == 'beklemede' ? Icons.hourglass_top :
                                            Icons.cancel,
                                            size: 18,
                                            color: _getStatusColor(odemeDurum)),
                                        title: Text(
                                            '${odeme.odemeTutari.toStringAsFixed(2)} TL',
                                            style: TextStyle(
                                                decoration: odemeDurum == 'reddedildi'
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none)),
                                        subtitle: Text(odeme.insertDate != null
                                            ? DateFormat('dd.MM.yyyy HH:mm').format(odeme.insertDate!)
                                            : ''),
                                        trailing: Text(
                                            odeme.odemeDurumu ?? '',
                                            style: TextStyle(
                                                color: _getStatusColor(odemeDurum),
                                                fontStyle: FontStyle.italic)));
                                  }).toList(),
                                ],
                                const SizedBox(height: 16),
                                // Buton artık global temadan otomatik stil alıyor
                                if (borc.kalanTutar > 0)
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => UploadReceiptPage(
                                            token: widget.token,
                                            borc: borc,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadMyDebts();
                                      }
                                    },
                                    icon: const Icon(Icons.upload_file, size: 20),
                                    label: const Text('Dekont Yükle'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ),
    );
  }
}