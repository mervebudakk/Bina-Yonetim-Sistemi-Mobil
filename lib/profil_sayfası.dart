import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/app_config.dart';

const Color kPrimaryColor = Color(0xFF1ABC9C); 
const Color kAppBarColor = Color(0xFF34495E); 
const Color kBackgroundColor = Color(0xFFF8F9FA); 
const Color kCardColor = Colors.white; 
const Color kTextColor = Color(0xFF2C3E50); 
const Color kSecondaryTextColor = Color(0xFF7F8C8D); 

class ProfilePage extends StatefulWidget {
  final String token;

  const ProfilePage({super.key, required this.token});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _tcController = TextEditingController();
  final _emailController = TextEditingController();
  final _telController = TextEditingController();
  final _mevcutSifreController = TextEditingController();
  final _yeniSifreController = TextEditingController();
  final _yeniSifreTekrarController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUpdating = false;
  bool _showPasswordSection = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(decoded);

      return data['sub'] ??
          data[
              'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
    } catch (e) {
      debugPrint('Token parse hatası: $e');
      return null;
    }
  }

  final _daireNoController = TextEditingController();
  String? _insertDate;
  String? _daireNo;

  Future<void> _loadProfile() async {
    // ... BU FONKSİYONDA HİÇBİR DEĞİŞİKLİK YOK ...
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/KullaniciApi/ProfilGoruntule'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final daireId = data['daireId'];
        String? daireNo;

        if (daireId != null && daireId != 0) {
          try {
            final daireResponse = await http.get(
              Uri.parse('${AppConfig.baseUrl}/DaireApi/$daireId/detay'),
              headers: {
                'Authorization': 'Bearer ${widget.token}',
                'Content-Type': 'application/json',
              },
            );

            if (daireResponse.statusCode == 200) {
              final daireData = jsonDecode(daireResponse.body);
              daireNo = daireData['daireNo'];
            }
          } catch (e) {
            debugPrint('Daire bilgisi alınamadı: $e');
          }
        }

        if (mounted) {
          setState(() {
            _adController.text = data['ad'] ?? '';
            _soyadController.text = data['soyad'] ?? '';
            _tcController.text = data['tc'] ?? '';
            _emailController.text = data['email'] ?? '';
            _telController.text = data['telNo'] ?? '';
            _insertDate = data['insertDate'];
            _daireNo = daireNo;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Profil yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Bilinmiyor';

    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return 'Bilinmiyor';
    }
  }

  Future<void> _updateProfile() async {
    // ... BU FONKSİYONDA SADECE SNACKBAR RENKLERİ DEĞİŞTİ ...
    if (!_formKey.currentState!.validate()) return;

    if (_showPasswordSection) {
      if (_yeniSifreController.text != _yeniSifreTekrarController.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yeni şifreler eşleşmiyor!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final userId = _getUserIdFromToken(widget.token);
      if (userId == null) {
        throw Exception('Kullanıcı ID\'si alınamadı');
      }

      final updateData = {
        'ad': _adController.text.trim(),
        'soyad': _soyadController.text.trim(),
        'tc': _tcController.text.trim(),
        'email': _emailController.text.trim(),
        'telNo': _telController.text.trim(),
      };

      if (_showPasswordSection && _yeniSifreController.text.isNotEmpty) {
        updateData['mevcutSifre'] = _mevcutSifreController.text;
        updateData['yeniSifre'] = _yeniSifreController.text;
      }

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/KullaniciApi/ProfilGuncelle/$userId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _isEditing = false;
            _showPasswordSection = false;
            _mevcutSifreController.clear();
            _yeniSifreController.clear();
            _yeniSifreTekrarController.clear();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil başarıyla güncellendi!'),
              backgroundColor: kPrimaryColor, // DEĞİŞTİ
            ),
          );

          _loadProfile();
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Güncelleme başarısız');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Metin Alanları için ortak stil tanımı
    final inputDecorationTheme = InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        prefixIconColor: kSecondaryTextColor);


    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: kAppBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profil Avatar
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: kPrimaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kullanıcı Adı
                    Text(
                      '${_adController.text} ${_soyadController.text}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // TC Kimlik
                    Text(
                      'TC: ${_tcController.text}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: kSecondaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 4),
                    if (_daireNo != null)
                      Text(
                        'Daire: $_daireNo',
                        style: const TextStyle(
                          fontSize: 16,
                          color: kSecondaryTextColor,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Kayıt Tarihi: ${_formatDate(_insertDate)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Kişisel Bilgiler Kartı
                    Card(
                      elevation: 2,
                      color: kCardColor,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person_outline,
                                    color: kPrimaryColor),
                                SizedBox(width: 8),
                                Text(
                                  'Kişisel Bilgiler',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: kTextColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Ad
                            TextFormField(
                              controller: _adController,
                              enabled: _isEditing,
                              decoration: inputDecorationTheme.copyWith(
                                labelText: 'Ad',
                                prefixIcon: const Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ad giriniz';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Soyad
                            TextFormField(
                              controller: _soyadController,
                              enabled: _isEditing,
                              decoration: inputDecorationTheme.copyWith(
                                labelText: 'Soyad',
                                prefixIcon: const Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Soyad giriniz';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              enabled: _isEditing,
                              keyboardType: TextInputType.emailAddress,
                              decoration: inputDecorationTheme.copyWith(
                                labelText: 'E-posta',
                                prefixIcon: const Icon(Icons.email),
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!value.contains('@')) {
                                    return 'Geçerli e-posta adresi giriniz';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Telefon
                            TextFormField(
                              controller: _telController,
                              enabled: _isEditing,
                              keyboardType: TextInputType.phone,
                              decoration: inputDecorationTheme.copyWith(
                                labelText: 'Telefon',
                                prefixIcon: const Icon(Icons.phone),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Şifre Değiştirme Kartı (Düzenleme modunda)
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        color: kCardColor,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lock_outline,
                                      color: kPrimaryColor),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Şifre Değiştir',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: kTextColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _showPasswordSection,
                                    onChanged: (value) {
                                      setState(() {
                                        _showPasswordSection = value;
                                        if (!value) {
                                          _mevcutSifreController.clear();
                                          _yeniSifreController.clear();
                                          _yeniSifreTekrarController.clear();
                                        }
                                      });
                                    },
                                    activeColor: kPrimaryColor,
                                  ),
                                ],
                              ),
                              if (_showPasswordSection) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _mevcutSifreController,
                                  obscureText: true,
                                  decoration: inputDecorationTheme.copyWith(
                                    labelText: 'Mevcut Şifre',
                                    prefixIcon: const Icon(Icons.lock),
                                  ),
                                  validator: (value) {
                                    if (_showPasswordSection &&
                                        (value == null || value.isEmpty)) {
                                      return 'Mevcut şifre giriniz';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _yeniSifreController,
                                  obscureText: true,
                                  decoration: inputDecorationTheme.copyWith(
                                    labelText: 'Yeni Şifre',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                  ),
                                  validator: (value) {
                                    if (_showPasswordSection &&
                                        (value == null || value.length < 6)) {
                                      return 'Yeni şifre en az 6 karakter olmalıdır';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _yeniSifreTekrarController,
                                  obscureText: true,
                                  decoration: inputDecorationTheme.copyWith(
                                    labelText: 'Yeni Şifre Tekrar',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                  ),
                                  validator: (value) {
                                    if (_showPasswordSection &&
                                        value != _yeniSifreController.text) {
                                      return 'Şifreler eşleşmiyor';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Butonlar
                    if (_isEditing) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isUpdating
                                  ? null
                                  : () {
                                      setState(() {
                                        _isEditing = false;
                                        _showPasswordSection = false;
                                        _loadProfile();
                                      });
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kSecondaryTextColor,
                                side: const BorderSide(
                                    color: kSecondaryTextColor),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('İptal'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdating ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isUpdating
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Kaydet'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _tcController.dispose();
    _emailController.dispose();
    _telController.dispose();
    _mevcutSifreController.dispose();
    _yeniSifreController.dispose();
    _yeniSifreTekrarController.dispose();
    _daireNoController.dispose();
    super.dispose();
  }
}