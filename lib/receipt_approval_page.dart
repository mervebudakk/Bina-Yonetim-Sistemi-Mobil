// receipt_approval_page.dart - _fetchReceipts metodunu güncelle

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config/app_config.dart';
import 'models/makbuz.dart';

class ReceiptApprovalPage extends StatefulWidget {
  final String token;
  const ReceiptApprovalPage({super.key, required this.token});

  @override
  State<ReceiptApprovalPage> createState() => _ReceiptApprovalPageState();
}

class _ReceiptApprovalPageState extends State<ReceiptApprovalPage> {
  List<Makbuz> _pendingReceipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReceipts();
  }

  Future<void> _fetchReceipts() async {
    setState(() => _isLoading = true);
    try {
      // DEĞİŞİKLİK: Yeni endpoint kullan
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/MakbuzlarApi/onay-bekleyen-dekontlar'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        if (mounted) {
          setState(() {
            // Artık API'den direkt olarak onay bekleyen dekontlar geliyor
            _pendingReceipts = data.map((json) => Makbuz.fromJson(json)).toList();
          });
        }
      } else { 
        throw Exception('Dekontlar yüklenemedi'); 
      }
    } catch (e) {
      print(e);
      if (mounted) setState(() => _pendingReceipts = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processReceipt(int makbuzId, bool isApproved) async {
    final actionText = isApproved ? 'onaylamak' : 'reddetmek';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dekontu ${isApproved ? 'Onayla' : 'Reddet'}'),
        content: Text('Bu dekontu $actionText istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isApproved ? 'Onayla' : 'Reddet', style: TextStyle(color: isApproved ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      http.Response response;
      if (isApproved) {
        response = await http.put(
          Uri.parse('${AppConfig.baseUrl}/MakbuzlarApi/dekont-onayla/$makbuzId'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
      } else {
        response = await http.delete(
          Uri.parse('${AppConfig.baseUrl}/MakbuzlarApi/sakin-dekont-sil/$makbuzId'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
      }

      if (mounted) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İşlem başarılı.'), backgroundColor: Colors.green)
          );
          await _fetchReceipts(); 
        } else {
           final errorData = jsonDecode(response.body);
           throw Exception(errorData['error'] ?? 'İşlem başarısız');
        }
      }
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _launchReceiptUrl(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya yolu bulunamadı.'))
      );
      return;
    }
    
    final fullUrl = AppConfig.baseUrl.replaceAll('/api', '') + filePath;
    final uri = Uri.parse(fullUrl);
    
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dekont açılamadı: $uri'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onay Bekleyen Dekontlar'),
        // Yenileme butonu ekle
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchReceipts,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReceipts,
              child: _pendingReceipts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'Onay bekleyen dekont bulunmuyor.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _pendingReceipts.length,
                itemBuilder: (context, index) {
                  final receipt = _pendingReceipts[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            receipt.kullaniciAdSoyad ?? 'İsimsiz Kullanıcı', 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          subtitle: Text('Daire No: ${receipt.daireNo ?? '?'}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.image_search, color: Colors.blue),
                            tooltip: 'Dekontu Görüntüle',
                            onPressed: () => _launchReceiptUrl(receipt.dosyaYolu),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text(
                                 'Ödenen Tutar: ${receipt.odemeTutari.toStringAsFixed(2)} TL', 
                                 style: Theme.of(context).textTheme.bodyLarge
                               ),
                               const SizedBox(height: 4),
                               Text(
                                 'Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(receipt.insertDate)}', 
                                 style: Theme.of(context).textTheme.bodySmall
                               ),
                            ],
                          ),
                        ),
                        ButtonBar(
                          alignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _processReceipt(receipt.makbuzId, false),
                              icon: const Icon(Icons.close),
                              label: const Text('Reddet'),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _processReceipt(receipt.makbuzId, true),
                              icon: const Icon(Icons.check),
                              label: const Text('Onayla'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white
                              ),
                            ),
                          ],
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