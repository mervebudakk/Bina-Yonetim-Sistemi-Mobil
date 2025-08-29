import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'models/borc_detay.dart';
import 'config/app_config.dart';
import 'dart:convert';

class UploadReceiptPage extends StatefulWidget {
  final String token;
  final BorcDetay borc;

  const UploadReceiptPage({super.key, required this.token, required this.borc});

  @override
  State<UploadReceiptPage> createState() => _UploadReceiptPageState();
}

class _UploadReceiptPageState extends State<UploadReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  final _tutarController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;
  bool _isPickingImage = false;

  Future<void> _pickImage() async {
    // Eğer zaten bir resim seçme işlemi aktifse, tekrar çalıştırma.
    if (_isPickingImage) return;

    try {
      if (mounted) {
        setState(() {
          _isPickingImage = true; // İşlemi başlat ve butonu kilitle
        });
      }

      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

      if (mounted && pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } finally {
      // İşlem bitince (başarılı veya başarısız), kilidi kaldır.
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _uploadReceipt() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir dekont dosyası seçin.'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/MakbuzlarApi/kendi-dekont-ekle'),
      );
      
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      
      // Form alanlarını ekle
      request.fields['BorcId'] = widget.borc.borcId.toString();
      request.fields['OdemeTutari'] = _tutarController.text;
      
      // Dosyayı ekle
      request.files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dekont başarıyla yüklendi. Onay bekleniyor.'), backgroundColor: Colors.green));
            Navigator.pop(context, true); // Bir önceki sayfaya 'true' değeriyle dön (liste yenilensin)
        }
      } else {
        final responseBody = await response.stream.bytesToString();
        final errorData = jsonDecode(responseBody);
        throw Exception(errorData['error'] ?? 'Yükleme başarısız');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }

    if (mounted) {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.borc.borcTuruAd} Ödemesi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Toplam Borç: ${widget.borc.borcTutari.toStringAsFixed(2)} TL', style: Theme.of(context).textTheme.titleMedium),
              Text('Kalan Borç: ${widget.borc.kalanTutar.toStringAsFixed(2)} TL', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _tutarController,
                decoration: const InputDecoration(labelText: 'Ödeme Miktarı', prefixText: '₺ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Lütfen bir tutar girin.';
                  final tutar = double.tryParse(value);
                  if (tutar == null) return 'Geçersiz tutar.';
                  if (tutar <= 0) return 'Tutar 0\'dan büyük olmalı.';
                  if (tutar > widget.borc.kalanTutar) return 'Tutar kalan borçtan fazla olamaz.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Dosya Seçim Alanı
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: _pickImage,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _selectedImage == null
                        ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image), SizedBox(width: 8), Text('Dekont Seç')])
                        : Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text(_selectedImage!.path.split('/').last, overflow: TextOverflow.ellipsis))]),
                  ),
                ),
              ),

              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Image.file(_selectedImage!, height: 200, fit: BoxFit.contain),
                ),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadReceipt,
                icon: _isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload),
                label: Text(_isUploading ? 'Yükleniyor...' : 'Yükle ve Onaya Gönder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}