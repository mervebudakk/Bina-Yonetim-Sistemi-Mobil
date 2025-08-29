// rol_yetki_yonetimi_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/app_config.dart';

class RolePermissionManagementPage extends StatefulWidget {
  final String token;
  const RolePermissionManagementPage({super.key, required this.token});

  @override
  State<RolePermissionManagementPage> createState() => _RolePermissionManagementPageState();
}

class _RolePermissionManagementPageState extends State<RolePermissionManagementPage> {
  List<RoleWithPermissions> _roles = [];
  List<Permission> _allPermissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadRoles(), _loadPermissions()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadRoles() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/RollerApi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<RoleWithPermissions> roles = [];
        
        for (var roleData in data) {
          // Her rol için yetkilerini çek
          final rolePermissions = await _getRolePermissions(roleData['rolId']);
          roles.add(RoleWithPermissions.fromJson(roleData, rolePermissions));
        }
        
        setState(() {
          _roles = roles;
        });
      } else {
        throw Exception('Roller yüklenemedi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Roller yüklenirken hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<List<Permission>> _getRolePermissions(int rolId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/RolYetkileriApi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final rolePermissions = data.where((item) => 
            item['rolId'] == rolId && 
            (item['aktiflikDurumu'] ?? true) == true
        ).toList();
        
        List<Permission> permissions = [];
        for (var rolePermData in rolePermissions) {
          final permission = _allPermissions.firstWhere(
            (p) => p.yetkiId == rolePermData['yetkiId'],
            orElse: () => Permission(
              yetkiId: rolePermData['yetkiId'],
              ad: 'Bilinmeyen Yetki',
              aciklama: null,
              sistemId: 0,
              aktiflikDurumu: true,
            ),
          );
          if (permission.ad != 'Bilinmeyen Yetki') {
            permissions.add(permission);
          }
        }
        return permissions;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
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
          _allPermissions = data.map((json) => Permission.fromJson(json)).toList();
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

  Future<void> _showRolePermissionsDialog(RoleWithPermissions role) async {
    final Map<int, bool> selectedPermissions = {};
    
    // Mevcut yetkileri işaretle
    for (var permission in _allPermissions) {
      selectedPermissions[permission.yetkiId] = role.permissions.any(
        (rolePermission) => rolePermission.yetkiId == permission.yetkiId
      );
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${role.rolTuru} - Yetkileri'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                if (role.aciklama != null && role.aciklama!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      role.aciklama!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allPermissions.length,
                    itemBuilder: (context, index) {
                      final permission = _allPermissions[index];
                      return CheckboxListTile(
                        title: Text(permission.ad),
                        subtitle: permission.aciklama != null && permission.aciklama!.isNotEmpty
                            ? Text(permission.aciklama!)
                            : null,
                        value: selectedPermissions[permission.yetkiId] ?? false,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            selectedPermissions[permission.yetkiId] = value ?? false;
                          });
                        },
                      );
                    },
                  ),
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
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final selectedPermissionIds = selectedPermissions.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      
      await _updateRolePermissions(role.rolId, selectedPermissionIds);
    }
  }

  Future<void> _updateRolePermissions(int rolId, List<int> permissionIds) async {
    try {
      // Önce mevcut tüm yetkileri kaldır
      await _removeAllRolePermissions(rolId);
      
      // Sonra yeni yetkileri ekle
      for (int permissionId in permissionIds) {
        await _addPermissionToRole(rolId, permissionId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rol yetkileri güncellendi.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removeAllRolePermissions(int rolId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/RolYetkileriApi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final rolePermissions = data.where((item) => 
            item['rolId'] == rolId && 
            (item['aktiflikDurumu'] ?? true) == true
        ).toList();
        
        for (var rolePermission in rolePermissions) {
          // Her birini pasif yap
          await _removeSpecificRolePermission(
            rolePermission['yetkiId'], 
            rolePermission['rolId']
          );
        }
      }
    } catch (e) {
      // Hata loglanabilir ama işlemi durdurmaz
      print('Rol yetkileri kaldırılırken hata: $e');
    }
  }

  // Özel yetki silme metodu - Pasif yapma için
  Future<void> _removeSpecificRolePermission(int yetkiId, int rolId) async {
    try {
      // RolYetkileri tablosundan ilgili kaydı bul ve pasif yap
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/RolYetkileriApi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        final rolePermission = data.firstWhere(
          (item) => item['yetkiId'] == yetkiId && 
                   item['rolId'] == rolId && 
                   (item['aktiflikDurumu'] ?? true) == true, // Sadece aktif olanları bul
          orElse: () => null,
        );
        
        if (rolePermission != null) {
          // Kaydı pasif yap (silme yerine)
          final updateBody = {
            'yetkiId': yetkiId,
            'rolId': rolId,
            'aktiflikDurumu': false, // Pasif yap
          };

          final updateResponse = await http.put(
            Uri.parse('${AppConfig.baseUrl}/RolYetkileriApi/$yetkiId/$rolId'),
            headers: {
              'Authorization': 'Bearer ${widget.token}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(updateBody),
          );
          
          if (updateResponse.statusCode == 200) {
            final responseData = jsonDecode(updateResponse.body);
            print('Pasif yapma başarılı: ${responseData['message']}');
          } else {
            // PUT başarısız olursa, eski DELETE yöntemini dene
            await _fallbackDeleteMethod(yetkiId, rolId, rolePermission);
          }
        } else {
          throw Exception('Aktif rol-yetki bağlantısı bulunamadı');
        }
      } else {
        throw Exception('RolYetkileri verileri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      print('Pasif yapma hatası: $e');
      throw Exception('Yetki kaldırma hatası: $e');
    }
  }

  // Yedek silme metodu (eski yöntem)
  Future<void> _fallbackDeleteMethod(int yetkiId, int rolId, Map<String, dynamic> rolePermission) async {
    try {
      // Farklı primary key isimlerini dene
      dynamic primaryKey;
      if (rolePermission.containsKey('id')) {
        primaryKey = rolePermission['id'];
      } else if (rolePermission.containsKey('rolYetkiId')) {
        primaryKey = rolePermission['rolYetkiId'];
      } else if (rolePermission.containsKey('rolYetkileriId')) {
        primaryKey = rolePermission['rolYetkileriId'];
      } else {
        primaryKey = yetkiId; // Son çare
      }
      
      final deleteResponse = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/RolYetkileriApi/$primaryKey'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (deleteResponse.statusCode != 204 && deleteResponse.statusCode != 200) {
        throw Exception('Silme işlemi başarısız: ${deleteResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Yedek silme metodu hatası: $e');
    }
  }

  Future<void> _addPermissionToRole(int rolId, int permissionId) async {
    final body = {
      'rolId': rolId,
      'yetkiId': permissionId,
      'aktiflikDurumu': true,
    };

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/RolYetkileriApi'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Yetki ekleme başarısız');
    }
  }

  Future<void> _showAddPermissionDialog(RoleWithPermissions role) async {
    final availablePermissions = _allPermissions.where((permission) => 
        !role.permissions.any((rolePermission) => rolePermission.yetkiId == permission.yetkiId)
    ).toList();

    if (availablePermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu role eklenebilecek yetki bulunmuyor.')),
      );
      return;
    }

    Permission? selectedPermission;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${role.rolTuru} - Yetki Ekle'),
          content: DropdownButtonFormField<Permission>(
            decoration: const InputDecoration(
              labelText: 'Eklenecek Yetki',
              border: OutlineInputBorder(),
            ),
            items: availablePermissions.map((permission) => DropdownMenuItem(
              value: permission,
              child: Text(permission.ad),
            )).toList(),
            onChanged: (Permission? value) {
              setDialogState(() {
                selectedPermission = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: selectedPermission != null 
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedPermission != null) {
      try {
        await _addPermissionToRole(role.rolId, selectedPermission!.yetkiId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yetki eklendi.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removePermissionFromRole(RoleWithPermissions role, Permission permission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yetki Kaldır'),
        content: Text('${role.rolTuru} rolünden "${permission.ad}" yetkisini kaldırmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaldır', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _removeSpecificRolePermission(permission.yetkiId, role.rolId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yetki kaldırıldı.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rol-Yetki Yönetimi'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _roles.isEmpty
                  ? const Center(
                      child: Text(
                        'Rol bulunamadı.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _roles.length,
                      itemBuilder: (context, index) {
                        final role = _roles[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo,
                              child: Text(
                                role.rolTuru.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              role.rolTuru,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: role.aciklama != null && role.aciklama!.isNotEmpty
                                ? Text(role.aciklama!)
                                : const Text('Açıklama yok'),
                            trailing: Text(
                              '${role.permissions.length} yetki',
                              style: TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Mevcut Yetkiler:',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.add, color: Colors.green),
                                              onPressed: () => _showAddPermissionDialog(role),
                                              tooltip: 'Yetki Ekle',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              onPressed: () => _showRolePermissionsDialog(role),
                                              tooltip: 'Yetkileri Düzenle',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (role.permissions.isEmpty)
                                      const Text(
                                        'Bu role henüz yetki atanmamış.',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    else
                                      Column(
                                        children: role.permissions.map((permission) => Card(
                                          color: Colors.indigo.shade50,
                                          child: ListTile(
                                            dense: true,
                                            leading: const Icon(
                                              Icons.key,
                                              color: Colors.indigo,
                                              size: 20,
                                            ),
                                            title: Text(
                                              permission.ad,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            subtitle: permission.aciklama != null && permission.aciklama!.isNotEmpty
                                                ? Text(
                                                    permission.aciklama!,
                                                    style: const TextStyle(fontSize: 12),
                                                  )
                                                : null,
                                            trailing: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.red,
                                                size: 16,
                                              ),
                                              onPressed: () => _removePermissionFromRole(role, permission),
                                              tooltip: 'Yetki Kaldır',
                                            ),
                                          ),
                                        )).toList(),
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

// RoleWithPermissions model sınıfı
class RoleWithPermissions {
  final int rolId;
  final String rolTuru;
  final String? aciklama;
  final bool aktiflikDurumu;
  final List<Permission> permissions;

  RoleWithPermissions({
    required this.rolId,
    required this.rolTuru,
    this.aciklama,
    required this.aktiflikDurumu,
    required this.permissions,
  });

  factory RoleWithPermissions.fromJson(Map<String, dynamic> json, List<Permission> permissions) {
    return RoleWithPermissions(
      rolId: json['rolId'],
      rolTuru: json['rolTuru'],
      aciklama: json['aciklama'],
      aktiflikDurumu: json['aktiflikDurumu'] ?? true,
      permissions: permissions,
    );
  }
}

// Permission model sınıfı (önceden tanımlanmışsa import edilebilir)
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