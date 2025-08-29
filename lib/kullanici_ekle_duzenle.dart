import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/app_config.dart';
import 'models/kullanici.dart';
import 'models/daire.dart';
import 'models/rol.dart';

class AddEditUserPage extends StatefulWidget {
  final String token;
  final Kullanici? user;
  final bool isAdmin;

  const AddEditUserPage({
    super.key,
    required this.token,
    this.user,
    required this.isAdmin,
  });

  @override
  State<AddEditUserPage> createState() => _AddEditUserPageState();
}

class _AddEditUserPageState extends State<AddEditUserPage> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  late TextEditingController _adController;
  late TextEditingController _soyadController;
  late TextEditingController _tcController;
  late TextEditingController _emailController;
  late TextEditingController _telController;
  late TextEditingController _sifreController;

  // State Variables
  List<Daire> _availableDaires = [];
  List<Rol> _availableRoles = [];
  final Map<int, bool> _selectedRoles = {};
  int? _selectedDaireId;
  bool _isEditMode = false;
  bool _isLoading = false;
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.user != null;

    _adController = TextEditingController(
      text: _isEditMode ? widget.user!.ad : '',
    );
    _soyadController = TextEditingController(
      text: _isEditMode ? widget.user!.soyad : '',
    );
    _tcController = TextEditingController(
      text: _isEditMode ? widget.user!.tc : '',
    );
    _emailController = TextEditingController(
      text: _isEditMode ? widget.user!.email : '',
    );
    _telController = TextEditingController(
      text: _isEditMode ? widget.user!.telNo : '',
    );
    _sifreController = TextEditingController();

    _selectedDaireId = _isEditMode ? widget.user!.daireId : null;

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isDataLoading = true);
    await _fetchDaires();
    if (widget.isAdmin && !_isEditMode) {
      await _fetchRoles();
    }
    setState(() => _isDataLoading = false);
  }

  Future<void> _fetchDaires() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/DaireApi/tum-daireler'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Gelen tüm daireleri önce bir listeye alalım
        List<Daire> allDaires = data
            .map((json) => Daire.fromJson(json))
            .toList();

        setState(() {
          // Dropdown için gösterilecek listeyi oluşturalım:
          // 1. Sadece boş olan daireleri al.
          _availableDaires = allDaires
              .where((d) => d.dolulukDurumu == false)
              .toList();

          // 2. EĞER DÜZENLEME MODUNDAYSAK:
          // Kullanıcının mevcut dairesi bu listede yoksa (yani doluysa), onu da listeye ekle.
          if (_isEditMode && _selectedDaireId != null) {
            final isCurrentUserDaireInList = _availableDaires.any(
              (d) => d.daireId == _selectedDaireId,
            );
            if (!isCurrentUserDaireInList) {
              // Kullanıcının dairesini tüm daireler listesinden bul ve ekle
              final currentUserDaire = allDaires.firstWhere(
                (d) => d.daireId == _selectedDaireId,
                // BU SATIRI AŞAĞIDAKİ GİBİ GÜNCELLE
                orElse: () => Daire(
                  daireId: -1,
                  apartmanId:
                      -1, // HATA 1 İÇİN EKLENDİ: Eksik olan zorunlu parametre
                  daireNo: '-1', // HATA 2 İÇİN DÜZELTİLDİ: Tipi String yapıldı
                  apartmanNo: 'Bulunamadı',
                  dolulukDurumu: true,
                ),
              );
              if (currentUserDaire.daireId != -1) {
                _availableDaires.add(currentUserDaire);
                // İsteğe bağlı: Daireleri numarasına göre sırala
                _availableDaires.sort((a, b) => a.daireNo.compareTo(b.daireNo));
              }
            }
          }
        });
      } else {
        throw Exception('Daireler yüklenemedi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daireler yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchRoles() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/RollerApi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _availableRoles = data.map((json) => Rol.fromJson(json)).toList();
          for (var role in _availableRoles) {
            _selectedRoles[role.rolId] = false;
          }
        });
      } else {
        throw Exception('Roller yüklenemedi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Roller yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Admin ise en az bir rol seçildi mi kontrol et
    if (widget.isAdmin && !_isEditMode) {
      if (!_selectedRoles.containsValue(true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen en az bir rol seçin.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> body;
      // API'deki yeni DTO'ya uygun body oluştur
      body = {
        'tc': _tcController.text,
        'ad': _adController.text,
        'soyad': _soyadController.text,
        'email': _emailController.text,
        'telNo': _telController.text,
        'sifre': _sifreController.text,
        'daireId': _selectedDaireId,
      };

      if (widget.isAdmin && !_isEditMode) {
        body['rolIds'] = _selectedRoles.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();
      }

      http.Response response;
      if (_isEditMode) {
        // Düzenleme modunda Kullanici nesnesi (rolsüz) gönderiyoruz
        response = await http.put(
          Uri.parse(
            '${AppConfig.baseUrl}/KullaniciApi/KullaniciGuncelle/${widget.user!.kullaniciId}',
          ),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            // ...Kullanici modeli toJson() ile de yapılabilir
            'kullaniciId': widget.user!.kullaniciId,
            'tc': _tcController.text,
            'ad': _adController.text,
            'soyad': _soyadController.text,
            'email': _emailController.text,
            'telNo': _telController.text,
            'daireId': _selectedDaireId,
          }),
        );
      } else {
        // Ekleme modunda yeni DTO'yu gönderiyoruz
        response = await http.post(
          Uri.parse('${AppConfig.baseUrl}/KullaniciApi/KullaniciEkle'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );
      }

      if (mounted) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kullanıcı başarıyla kaydedildi.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'İşlem başarısız');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _tcController.dispose();
    _emailController.dispose();
    _telController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Kullanıcıyı Düzenle' : 'Yeni Kullanıcı Ekle',
        ),
      ),
      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _adController,
                      decoration: const InputDecoration(labelText: 'Ad'),
                      validator: (v) => v!.isEmpty ? 'Ad boş olamaz' : null,
                    ),
                    TextFormField(
                      controller: _soyadController,
                      decoration: const InputDecoration(labelText: 'Soyad'),
                      validator: (v) => v!.isEmpty ? 'Soyad boş olamaz' : null,
                    ),
                    TextFormField(
                      controller: _tcController,
                      decoration: const InputDecoration(
                        labelText: 'TC Kimlik No',
                        counterText: "",
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      validator: (v) =>
                          v!.length != 11 ? 'TC 11 haneli olmalıdır' : null,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'E-posta'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextFormField(
                      controller: _telController,
                      decoration: const InputDecoration(labelText: 'Telefon'),
                      keyboardType: TextInputType.phone,
                    ),

                    if (!_isEditMode)
                      TextFormField(
                        controller: _sifreController,
                        decoration: const InputDecoration(labelText: 'Şifre'),
                        obscureText: true,
                        validator: (v) =>
                            v!.isEmpty ? 'Şifre boş olamaz' : null,
                      ),

                    const SizedBox(height: 16),

                    // Daire seçimi
                    DropdownButtonFormField<int>(
                      value: _selectedDaireId,
                      hint: const Text('Boş Daire Seçiniz'),
                      items: _availableDaires.map((daire) {
                        return DropdownMenuItem<int>(
                          value: daire.daireId,
                          child: Text(
                            'Daire ${daire.daireNo} ${widget.isAdmin ? "(${daire.apartmanNo})" : ""}',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedDaireId = value),
                      validator: (v) =>
                          v == null ? 'Daire seçimi zorunludur' : null,
                    ),

                    // Admin için Rol seçimi
                    if (widget.isAdmin && !_isEditMode) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Roller',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(),
                      ..._availableRoles.map((role) {
                        return CheckboxListTile(
                          title: Text(role.rolTuru),
                          value: _selectedRoles[role.rolId],
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedRoles[role.rolId] = value!;
                            });
                          },
                        );
                      }).toList(),
                    ],

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveUser,
                      child: _isLoading
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
                  ],
                ),
              ),
            ),
    );
  }
}
