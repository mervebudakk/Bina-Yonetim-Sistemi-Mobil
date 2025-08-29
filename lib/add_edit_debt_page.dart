// lib/add_edit_debt_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'config/app_config.dart';
import 'models/borc.dart';
import 'models/kullanici.dart';
import 'models/borc_tipi.dart';
import 'models/borc_turu.dart';

// --- TEMA RENKLERİ (main.dart dosyanızdan geldiği varsayılır) ---
const Color kPrimaryColor = Color(0xFF20C997);
const Color kSuccessColor = Color(0xFF28A745);
const Color kDangerColor = Color(0xFFDC3545);
const Color kInfoColor = Color(0xFF3498DB);
const Color kTextColor = Color(0xFF34495E);

class AddEditDebtPage extends StatefulWidget {
  final String token;
  final bool isAdmin;
  final Borc? debt;

  const AddEditDebtPage(
      {super.key, required this.token, required this.isAdmin, this.debt});

  @override
  State<AddEditDebtPage> createState() => _AddEditDebtPageState();
}

class _AddEditDebtPageState extends State<AddEditDebtPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _tutarController;
  late TextEditingController _tarihController;
  DateTime? _selectedDate;
  int? _selectedDaireId;
  int? _selectedBorcTipiId;
  String? _selectedBorcTipiAdi;
  int? _selectedBorcTuruId;

  List<Kullanici> _users = [];
  List<BorcTipi> _borcTipleri = [];
  List<BorcTuru> _borcTurleri = [];

  bool _isEditMode = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.debt != null;

    _tutarController = TextEditingController(
        text: _isEditMode ? widget.debt!.borcTutari.toStringAsFixed(2) : '');
    _tarihController = TextEditingController();
    if (_isEditMode && widget.debt!.sonOdemeTarihi != null) {
      _selectedDate = widget.debt!.sonOdemeTarihi;
      _tarihController.text = DateFormat('dd.MM.yyyy').format(_selectedDate!);
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _fetchUsers(),
      _fetchBorcTipleri(),
    ]);

    if (_isEditMode && widget.debt != null) {
      final debt = widget.debt!;
      _selectedDaireId = debt.daireId;

      List<BorcTuru> allTurler = [];
      for (var tip in _borcTipleri) {
        final turler = await _getBorcTurleriByTipId(tip.borcTipiId);
        allTurler.addAll(turler);
      }
      final borcTuru = allTurler.firstWhere((t) => t.turId == debt.turId,
          orElse: () => BorcTuru(turId: 0, turAd: '', borcTipiId: 0));

      if (borcTuru.turId != 0) {
        _selectedBorcTipiId = borcTuru.borcTipiId;
        _selectedBorcTipiAdi = _borcTipleri
            .firstWhere((t) => t.borcTipiId == _selectedBorcTipiId)
            .borcTipiAd;

        await _fetchBorcTurleriByTip(_selectedBorcTipiId!);

        _selectedBorcTuruId = debt.turId;
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/KullaniciApi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) _users = data.map((json) => Kullanici.fromJson(json)).toList();
      } else {
        throw Exception('Kullanıcılar yüklenemedi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Kullanıcılar yüklenirken hata: $e'),
            backgroundColor: kDangerColor));
      }
    }
  }

  Future<void> _fetchBorcTipleri() async {
    try {
      final response = await http.get(
          Uri.parse('${AppConfig.baseUrl}/BorclarApi/borc-tipleri'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted)
          _borcTipleri = data.map((json) => BorcTipi.fromJson(json)).toList();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchBorcTurleriByTip(int borcTipiId) async {
    setState(() {
      _borcTurleri = [];
      if (!_isEditMode) _selectedBorcTuruId = null;
    });
    final turler = await _getBorcTurleriByTipId(borcTipiId);
    if (mounted) setState(() => _borcTurleri = turler);
  }

  Future<List<BorcTuru>> _getBorcTurleriByTipId(int borcTipiId) async {
    try {
      final response = await http.get(
          Uri.parse('${AppConfig.baseUrl}/BorclarApi/borc-turleri/$borcTipiId'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BorcTuru.fromJson(json)).toList();
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      // --- DatePicker Renkleri Temaya Uyarlandı ---
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor, // Header background
              onPrimary: Colors.white, // Header text
              onSurface: kTextColor, // Body text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryColor, // Button text
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tarihController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;
    bool isGeneralDebt = _selectedBorcTipiAdi?.toLowerCase().contains('genel') ?? false;
    if (!isGeneralDebt && _selectedDaireId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lütfen bir kullanıcı seçin.'),
          backgroundColor: kDangerColor));
      return;
    }
    setState(() => _isSaving = true);
    try {
      String endpoint;
      Map<String, dynamic> body;
      if (isGeneralDebt) {
        endpoint = '/BorclarApi/genel-borc-ekle';
        body = {
          'toplamTutar': double.parse(_tutarController.text),
          'turId': _selectedBorcTuruId,
          'sonOdemeTarihi': _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null,
          'apartmanId': null,
        };
      } else {
        endpoint = '/BorclarApi/borc-ekle';
        body = {
          'daireId': _selectedDaireId,
          'turId': _selectedBorcTuruId,
          'borcTipiId': _selectedBorcTipiId,
          'borcTutari': double.parse(_tutarController.text),
          'sonOdemeTarihi': _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null,
        };
      }
      http.Response response;
      if (_isEditMode) {
        final body = {
          'turId': _selectedBorcTuruId,
          'borcTutari': double.parse(_tutarController.text),
          'sonOdemeTarihi': _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null,
        };
        response = await http.put(
          Uri.parse('${AppConfig.baseUrl}/BorclarApi/borc-guncelle/${widget.debt!.borcId}'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(body),
        );
      } else {
        response = await http.post(
          Uri.parse(AppConfig.baseUrl + endpoint),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(body),
        );
      }
      if (mounted) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final responseData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(responseData['message']),
              backgroundColor: kSuccessColor));
          Navigator.pop(context, true);
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'İşlem başarısız');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: kDangerColor));
      }
    }
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isGeneralDebt =
        _selectedBorcTipiAdi?.toLowerCase().contains('genel') ?? false;
        
    // Scaffold ve AppBar temadan otomatik stil alıyor
    return Scaffold(
      appBar:
          AppBar(title: Text(_isEditMode ? 'Borcu Düzenle' : 'Yeni Borç Ekle')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (!isGeneralDebt) ...[
                    DropdownButtonFormField<int>(
                      value: _selectedDaireId,
                      hint: const Text('Kullanıcı (Daire) Seçiniz'),
                      items: _users.map((user) => DropdownMenuItem(
                                value: user.daireId,
                                child: Text('${user.ad} ${user.soyad}')))
                          .toList(),
                      onChanged: _isEditMode ? null : (value) => setState(() => _selectedDaireId = value),
                      // Temaya uygun stil
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: _isEditMode,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      validator: isGeneralDebt ? null : (v) => v == null ? 'Lütfen bir kullanıcı seçin' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<int>(
                    value: _selectedBorcTipiId,
                    hint: const Text('Borç Tipi Seçiniz'),
                    items: _borcTipleri.map((tip) => DropdownMenuItem(
                              value: tip.borcTipiId, child: Text(tip.borcTipiAd)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedBorcTipiId = value;
                          _selectedBorcTipiAdi = _borcTipleri
                              .firstWhere((t) => t.borcTipiId == value)
                              .borcTipiAd;
                        });
                        _fetchBorcTurleriByTip(value);
                      }
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    validator: (v) => v == null ? 'Lütfen bir borç tipi seçin' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedBorcTuruId,
                    hint: const Text('Borç Türü Seçiniz'),
                    items: _borcTurleri.map((tur) => DropdownMenuItem(
                              value: tur.turId, child: Text(tur.turAd)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedBorcTuruId = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.article_outlined),
                    ),
                    validator: (v) => v == null ? 'Lütfen bir borç türü seçin' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tutarController,
                    decoration: InputDecoration(
                      labelText: isGeneralDebt ? 'Toplam Gider Tutarı' : 'Borç Tutarı',
                      prefixIcon: const Icon(Icons.attach_money)
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v == null || v.isEmpty ? 'Tutar giriniz' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tarihController,
                    decoration: const InputDecoration(
                      labelText: 'Son Ödeme Tarihi',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 24),
                  // Buton artık global temadan stil alıyor
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveDebt,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Kaydet'),
                  )
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _tutarController.dispose();
    _tarihController.dispose();
    super.dispose();
  }
}