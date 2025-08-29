// yetki_yonetimi_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/app_config.dart';

class PermissionManagementPage extends StatefulWidget {
  final String token;
  const PermissionManagementPage({super.key, required this.token});

  @override
  State<PermissionManagementPage> createState() => _PermissionManagementPageState();
}

class _PermissionManagementPageState extends State<PermissionManagementPage> {
  List<Permission> _permissions = [];
  List<System> _systems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadPermissions(), _loadSystems()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadPermissions() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/YetkilerApi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _permissions = data.map((json) => Permission.fromJson(json)).toList();
        });
      } else {
        throw Exception('Yetkiler yüklenemedi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yetkiler yüklenirken hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadSystems() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/SistemApi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _systems = data.map((json) => System.fromJson(json)).toList();
        });
      } else {
        throw Exception('Sistemler yüklenemedi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sistemler yüklenirken hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showAddEditPermissionDialog([Permission? permission]) async {
    final isEdit = permission != null;
    final nameController = TextEditingController(text: permission?.ad ?? '');
    final descController = TextEditingController(text: permission?.aciklama ?? '');
    int? selectedSystemId = permission?.sistemId ?? (_systems.isNotEmpty ? _systems.first.sistemId : null);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Yetki Düzenle' : 'Yeni Yetki Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Yetki Adı',
                    hintText: 'Örn: Rapor Görüntüleme',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Yetki açıklaması...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedSystemId,
                  decoration: const InputDecoration(
                    labelText: 'Sistem',
                    border: OutlineInputBorder(),
                  ),
                  items: _systems.map((system) => DropdownMenuItem(
                    value: system.sistemId,
                    child: Text(system.ad),
                  )).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedSystemId = value;
                    });
                  },
                  validator: (value) => value == null ? 'Sistem seçiniz' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yetki adı boş olamaz!')),
                  );
                  return;
                }
                if (selectedSystemId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sistem seçiniz!')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(isEdit ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _savePermission(
        nameController.text.trim(),
        descController.text.trim(),
        selectedSystemId!,
        permission?.yetkiId,
      );
    }
  }

  Future<void> _savePermission(String permissionName, String description, int systemId, int? permissionId) async {
    try {
      http.Response response;

      if (permissionId != null) {
        // GÜNCELLEME - API'nin beklediği formatta Yetkiler nesnesini gönder
        final body = {
          'yetkiId': permissionId,
          'ad': permissionName,
          'aciklama': description,
          'sistemId': systemId,
          'aktiflikDurumu': true,
          'insertDate': DateTime.now().toIso8601String(),
        };
        
        response = await http.put(
          Uri.parse('${AppConfig.baseUrl}/YetkilerApi/$permissionId'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );
      } else {
        // EKLEME - DTO formatında gönder
        final body = {
          'ad': permissionName,
          'aciklama': description,
          'sistemId': systemId,
        };
        
        response = await http.post(
          Uri.parse('${AppConfig.baseUrl}/YetkilerApi'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Yetki ${permissionId != null ? 'güncellendi' : 'eklendi'}.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadPermissions();
      } else {
        String errorMessage = 'İşlem başarısız';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? 
                        errorData['message'] ?? 
                        errorData['title'] ??
                        'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Bilinmeyen hata'}';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Yetki durumu değiştirme onay dialogu
  Future<void> _confirmAndTogglePermissionStatus(Permission permission) async {
    // Eğer yetki aktiften pasife alınacaksa, uyarı göster
    if (permission.aktiflikDurumu) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Yetki Durumu Değiştir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${permission.ad} yetkisini pasif yapmak istediğinizden emin misiniz?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu yetkiye sahip roller varsa işlem başarısız olacaktır.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pasif Yap'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    await _togglePermissionStatus(permission);
  }

  Future<void> _togglePermissionStatus(Permission permission) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/YetkilerApi/durum-guncelle/${permission.yetkiId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message']),
            backgroundColor: Colors.green,
          ),
        );
        _loadPermissions();
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('İşlem Başarısız'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorData['error'] ?? 'Yetki durumu değiştirilemedi'),
                if (errorData['roleCount'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.group, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bu yetkiye sahip ${errorData['roleCount']} aktif rol bulunuyor.',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Durum değiştirilemedi');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _confirmAndDeletePermission(Permission permission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yetki Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${permission.ad} yetkisini kalıcı olarak silmek istediğinizden emin misiniz?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu yetkiye sahip roller varsa işlem başarısız olacaktır. Bu işlem geri alınamaz!',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kalıcı Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePermission(permission);
    }
  }

  Future<void> _deletePermission(Permission permission) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/YetkilerApi/${permission.yetkiId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadPermissions();
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Silme İşlemi Başarısız'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorData['error'] ?? 'Yetki silinemedi'),
                if (errorData['roleCount'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.group, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bu yetkiye sahip ${errorData['roleCount']} rol bulunuyor.',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      } else {
        String errorMessage = 'Yetki silinemedi';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? 'HTTP ${response.statusCode}';
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Bilinmeyen hata'}';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _getSystemName(int sistemId) {
    final system = _systems.firstWhere(
      (s) => s.sistemId == sistemId,
      orElse: () => System(sistemId: 0, ad: 'Bilinmeyen Sistem', aciklama: null, aktiflikDurumu: true),
    );
    return system.ad;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yetki Yönetimi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _permissions.isEmpty
                  ? const Center(
                      child: Text(
                        'Henüz yetki bulunmuyor.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _permissions.length,
                      itemBuilder: (context, index) {
                        final permission = _permissions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: permission.aktiflikDurumu 
                                  ? Colors.green 
                                  : Colors.grey,
                              child: const Icon(
                                Icons.key,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              permission.ad,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: !permission.aktiflikDurumu
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: !permission.aktiflikDurumu
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (permission.aciklama != null && permission.aciklama!.isNotEmpty)
                                  Text(
                                    permission.aciklama!,
                                    style: TextStyle(
                                      color: !permission.aktiflikDurumu
                                          ? Colors.grey
                                          : null,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sistem: ${_getSystemName(permission.sistemId)}',
                                  style: TextStyle(
                                    color: permission.aktiflikDurumu 
                                        ? Colors.blue 
                                        : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: permission.aktiflikDurumu
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: permission.aktiflikDurumu
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    permission.aktiflikDurumu ? 'Aktif' : 'Pasif',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: permission.aktiflikDurumu
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Düzenleme butonu
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showAddEditPermissionDialog(permission),
                                  tooltip: 'Düzenle',
                                ),
                                // Aktiflik durumu switch butonu
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: permission.aktiflikDurumu,
                                    onChanged: (value) => _confirmAndTogglePermissionStatus(permission),
                                    activeColor: Colors.green,
                                    inactiveThumbColor: Colors.red,
                                    inactiveTrackColor: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                // Silme butonu
                                IconButton(
                                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                                  onPressed: () => _confirmAndDeletePermission(permission),
                                  tooltip: 'Kalıcı Sil',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditPermissionDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Permission model sınıfı
class Permission {
  final int yetkiId;
  final String ad;
  final String? aciklama;
  final int sistemId;
  final bool aktiflikDurumu;

  Permission({
    required this.yetkiId,
    required this.ad,
    this.aciklama,
    required this.sistemId,
    required this.aktiflikDurumu,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      yetkiId: json['yetkiId'],
      ad: json['ad'],
      aciklama: json['aciklama'],
      sistemId: json['sistemId'],
      aktiflikDurumu: json['aktiflikDurumu'] ?? true,
    );
  }
}

// System model sınıfı
class System {
  final int sistemId;
  final String ad;
  final String? aciklama;
  final bool aktiflikDurumu;

  System({
    required this.sistemId,
    required this.ad,
    this.aciklama,
    required this.aktiflikDurumu,
  });

  factory System.fromJson(Map<String, dynamic> json) {
    return System(
      sistemId: json['sistemId'],
      ad: json['ad'],
      aciklama: json['aciklama'],
      aktiflikDurumu: json['aktiflikDurumu'] ?? true,
    );
  }
}