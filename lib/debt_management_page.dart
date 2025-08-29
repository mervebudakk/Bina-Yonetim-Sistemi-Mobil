// lib/debt_management_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'config/app_config.dart';
import 'models/borc.dart';
import 'add_edit_debt_page.dart';
import 'models/odeme_detay.dart';

class DebtManagementPage extends StatefulWidget {
  final String token;
  final bool isAdmin;
  const DebtManagementPage({
    super.key,
    required this.token,
    required this.isAdmin,
  });

  @override
  State<DebtManagementPage> createState() => _DebtManagementPageState();
}

class _DebtManagementPageState extends State<DebtManagementPage> {
  List<Borc> _allDebts = [];
  List<Borc> _filteredDebts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  
  // Toplu silme için yeni değişkenler
  bool _isSelectionMode = false;
  Set<int> _selectedDebtIds = {};

  @override
  void initState() {
    super.initState();
    _loadDebts();
    _searchController.addListener(_filterDebts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDebts);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDebts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/BorclarApi/tum-borclar'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _allDebts = data.map((json) => Borc.fromJson(json)).toList();
            _filteredDebts = _allDebts;
          });
        }
      } else {
        throw Exception('Borçlar yüklenemedi');
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

  void _filterDebts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDebts = _allDebts.where((debt) {
        final userName = debt.kullaniciAdSoyad?.toLowerCase() ?? '';
        final daireNo = debt.daireNo?.toLowerCase() ?? '';

        return userName.contains(query) || daireNo.contains(query);
      }).toList();
    });
  }

  // Toplu silme modu toggle
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedDebtIds.clear();
      }
    });
  }

  // Tümünü seç/seçimi kaldır
  void _toggleSelectAll() {
    setState(() {
      if (_selectedDebtIds.length == _filteredDebts.length) {
        _selectedDebtIds.clear();
      } else {
        _selectedDebtIds = _filteredDebts.map((debt) => debt.borcId).toSet();
      }
    });
  }

  // Tek borç seçimi toggle
  void _toggleDebtSelection(int borcId) {
    setState(() {
      if (_selectedDebtIds.contains(borcId)) {
        _selectedDebtIds.remove(borcId);
      } else {
        _selectedDebtIds.add(borcId);
      }
    });
  }

  // Seçili borçları toplu silme
  Future<void> _bulkDeleteDebts() async {
    if (_selectedDebtIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Seçili Borçları Sil'),
          content: Text(
            '${_selectedDebtIds.length} adet borcu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      int successCount = 0;
      int failCount = 0;

      for (int borcId in _selectedDebtIds) {
        try {
          final response = await http.delete(
            Uri.parse('${AppConfig.baseUrl}/BorclarApi/borc-sil/$borcId'),
            headers: {'Authorization': 'Bearer ${widget.token}'},
          );

          if (response.statusCode == 200 || response.statusCode == 204) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
        }
      }

      if (mounted) {
        String message = '';
        Color backgroundColor = Colors.green;
        
        if (failCount == 0) {
          message = '$successCount borç başarıyla silindi.';
        } else if (successCount == 0) {
          message = 'Hiç borç silinemedi.';
          backgroundColor = Colors.red;
        } else {
          message = '$successCount borç silindi, $failCount borç silinemedi.';
          backgroundColor = Colors.orange;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
          ),
        );

        setState(() {
          _selectedDebtIds.clear();
          _isSelectionMode = false;
        });
        
        await _loadDebts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteDebt(int borcId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Borcu Sil'),
          content: const Text(
            'Bu borcu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/BorclarApi/borc-sil/$borcId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Borç başarıyla silindi.'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadDebts();
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Borç silinemedi');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToAddEditPage([Borc? debt]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditDebtPage(
          token: widget.token,
          isAdmin: widget.isAdmin,
          debt: debt,
        ),
      ),
    );
    if (result == true) {
      _loadDebts();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Ödendi':
        return Colors.green;
      case 'Onay Bekliyor':
        return Colors.orange;
      case 'Kısmi Ödendi':
        return Colors.blue;
      case 'Ödenmedi':
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text('${_selectedDebtIds.length} seçili')
            : const Text('Borç Yönetimi'),
        actions: [
          if (_isSelectionMode) ...[
            // Tümünü seç/seçimi kaldır butonu
            IconButton(
              icon: Icon(
                _selectedDebtIds.length == _filteredDebts.length
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              onPressed: _toggleSelectAll,
              tooltip: _selectedDebtIds.length == _filteredDebts.length
                  ? 'Seçimi Kaldır'
                  : 'Tümünü Seç',
            ),
            // Seçili borçları sil butonu
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _selectedDebtIds.isNotEmpty ? _bulkDeleteDebts : null,
              tooltip: 'Seçilenleri Sil',
            ),
            // Seçim modundan çık
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
              tooltip: 'İptal',
            ),
          ] else ...[
            // Seçim moduna geç butonu
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: 'Toplu Seç',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ARAMA ÇUBUĞU
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Kullanıcı Adı veya Daire No ile Ara',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                // SEÇIM MODU BİLGİ BARI (opsiyonel)
                if (_isSelectionMode && _selectedDebtIds.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedDebtIds.length} borç seçildi',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                // BORÇ LİSTESİ
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadDebts,
                    child: ListView.builder(
                      itemCount: _filteredDebts.length,
                      itemBuilder: (context, index) {
                        final debt = _filteredDebts[index];
                        final isSelected = _selectedDebtIds.contains(debt.borcId);

                        final formattedDate = debt.sonOdemeTarihi != null
                            ? DateFormat('dd.MM.yyyy').format(debt.sonOdemeTarihi!)
                            : 'Belirtilmemiş';
                        double progress = debt.borcTutari > 0
                            ? debt.odenenTutar / debt.borcTutari
                            : 0;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          elevation: 3,
                          color: isSelected 
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: isSelected 
                                ? BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                          child: ExpansionTile(
                            leading: _isSelectionMode
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      _toggleDebtSelection(debt.borcId);
                                    },
                                  )
                                : null,
                            title: Text(
                              '${debt.kullaniciAdSoyad ?? 'İsimsiz'} - Daire: ${debt.daireNo ?? '?'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              debt.borcTuruAd ?? 'Bilinmeyen Borç Türü',
                            ),
                            trailing: _isSelectionMode
                                ? null
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${debt.borcTutari.toStringAsFixed(2)} TL',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          debt.durum,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                        backgroundColor: _getStatusColor(debt.durum),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                            onExpansionChanged: _isSelectionMode
                                ? (bool expanded) {
                                    if (expanded) {
                                      _toggleDebtSelection(debt.borcId);
                                    }
                                  }
                                : null,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 10,
                                      backgroundColor: Colors.grey[300],
                                      color: _getStatusColor(debt.durum),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Ödenen: ${debt.odenenTutar.toStringAsFixed(2)} TL',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Kalan: ${debt.kalanTutar.toStringAsFixed(2)} TL',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (debt.odemeler.isNotEmpty) ...[
                                      const Divider(height: 24),
                                      Text(
                                        'Ödeme Geçmişi',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 8),
                                      for (var odeme in debt.odemeler)
                                        ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            odeme.odemeDurumu == 'ödendi'
                                                ? Icons.check_circle
                                                : odeme.odemeDurumu == 'beklemede'
                                                    ? Icons.hourglass_top
                                                    : Icons.cancel,
                                            size: 18,
                                            color: _getStatusColor(
                                              odeme.odemeDurumu ?? '',
                                            ),
                                          ),
                                          title: Text(
                                            '${odeme.odemeTutari.toStringAsFixed(2)} TL',
                                          ),
                                          subtitle: Text(
                                            odeme.insertDate != null
                                                ? DateFormat('dd.MM.yyyy HH:mm')
                                                    .format(odeme.insertDate!)
                                                : '',
                                          ),
                                          trailing: Text(
                                            odeme.odemeDurumu ?? '',
                                            style: TextStyle(
                                              color: _getStatusColor(
                                                odeme.odemeDurumu ?? '',
                                              ),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                    if (!_isSelectionMode) ...[
                                      const Divider(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blueGrey,
                                            ),
                                            onPressed: () =>
                                                _navigateToAddEditPage(debt),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () =>
                                                _deleteDebt(debt.borcId),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: _navigateToAddEditPage,
              child: const Icon(Icons.add),
            ),
    );
  }
}