import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config/app_config.dart';
import 'models/gecmis_odeme.dart';

class PaymentHistoryPage extends StatefulWidget {
  final String token;
  final bool isManagerView; // Bu sayfanın hangi modda çalışacağını belirler

  const PaymentHistoryPage({super.key, required this.token, required this.isManagerView});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<GecmisOdeme> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    // Role göre doğru endpoint'i seç
    final endpoint = widget.isManagerView
        ? '/MakbuzlarApi/tum-gecmis-dekontlar'
        : '/MakbuzlarApi/kendi-gecmis-dekontlar';
        
    try {
      final response = await http.get(
        Uri.parse(AppConfig.baseUrl + endpoint),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if(mounted) {
          setState(() {
            _payments = data.map((json) => GecmisOdeme.fromJson(json)).toList();
          });
        }
      } else { throw Exception('Ödemeler yüklenemedi'); }
    } catch (e) {
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
       }
    } finally {
       if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchReceiptUrl(String? filePath) async {
      // ... Bu metodu receipt_approval_page.dart'tan kopyalayabilirsiniz ...
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'ödendi': return Colors.green;
      case 'beklemede': return Colors.orange;
      case 'reddedildi': return Colors.grey[600]!;
      default: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isManagerView ? 'Tüm Geçmiş Ödemeler' : 'Ödemelerim'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPayments,
              child: ListView.builder(
                itemCount: _payments.length,
                itemBuilder: (context, index) {
                  final payment = _payments[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.receipt_long, color: _getStatusColor(payment.odemeDurumu)),
                      title: Text('${payment.odemeTutari.toStringAsFixed(2)} TL - ${payment.borcTuruAd ?? ''}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.isManagerView)
                            Text('${payment.kullaniciAdSoyad ?? ''} - Daire: ${payment.daireNo ?? '?'}'),
                          Text(payment.odemeTarihi != null ? DateFormat('dd.MM.yyyy HH:mm').format(payment.odemeTarihi!) : ''),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(payment.odemeDurumu ?? '', style: TextStyle(color: _getStatusColor(payment.odemeDurumu), fontStyle: FontStyle.italic)),
                          if(payment.dosyaYolu != null && payment.dosyaYolu!.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.image_search, color: Colors.blue),
                              onPressed: () => _launchReceiptUrl(payment.dosyaYolu),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}