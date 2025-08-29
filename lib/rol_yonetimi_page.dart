// rol_yonetimi_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/app_config.dart';

class RoleManagementPage extends StatefulWidget {
  final String token;
  const RoleManagementPage({super.key, required this.token});

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage> {
  List<Role> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/RollerApi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _roles = data.map((json) => Role.fromJson(json)).toList();
        });
      } else {
        throw Exception('Roller yüklenemedi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _showAddEditRoleDialog([Role? role]) async {
    final isEdit = role != null;
    final nameController = TextEditingController(text: role?.rolTuru ?? '');
    final descController = TextEditingController(text: role?.aciklama ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Rol Düzenle' : 'Yeni Rol Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Rol Adı',
                hintText: 'Örn: Güvenlik Görevlisi',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'Rolün açıklaması...',
              ),
              maxLines: 3,
            ),
          ],
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
                  const SnackBar(content: Text('Rol adı boş olamaz!')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text(isEdit ? 'Güncelle' : 'Ekle'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveRole(
        nameController.text.trim(),
        descController.text.trim(),
        role?.rolId,
      );
    }
  }

  Future<void> _saveRole(
    String roleName,
    String description,
    int? roleId,
  ) async {
    try {
      http.Response response;

      if (roleId != null) {
        // GÜNCELLEME - Sadece gerekli alanları gönder
        final body = {
          'rolId': roleId,
          'rolTuru': roleName,
          'aciklama': description,
          'aktiflikDurumu': true,
        };

        response = await http.put(
          Uri.parse('${AppConfig.baseUrl}/RollerApi/$roleId'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );
      } else {
        // EKLEME - Sadece gerekli alanları gönder
        final body = {
          'rolTuru': roleName,
          'aciklama': description,
          // aktiflikDurumu, insertDate, insertUser API'de otomatik atanacak
        };

        response = await http.post(
          Uri.parse('${AppConfig.baseUrl}/RollerApi'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol ${roleId != null ? 'güncellendi' : 'eklendi'}.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRoles();
      } else {
        // HATA DETAYINI GÖSTER
        String errorMessage = 'İşlem başarısız';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['error'] ?? errorData['message'] ?? 'Bilinmeyen hata';
        } catch (e) {
          errorMessage =
              'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bağlantı hatası: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Rol durumu değiştirmeden önce kullanıcıya onay sorar
  Future<void> _confirmAndToggleRoleStatus(Role role) async {
    // Eğer rol aktiften pasife alınacaksa, uyarı göster
    if (role.aktiflikDurumu) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rol Durumu Değiştir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${role.rolTuru} rolünü pasif yapmak istediğinizden emin misiniz?'),
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
                        'Bu role sahip kullanıcılar varsa işlem başarısız olacaktır.',
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

    await _toggleRoleStatus(role);
  }

  Future<void> _toggleRoleStatus(Role role) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${AppConfig.baseUrl}/RollerApi/durum-guncelle/${role.rolId}',
        ),
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
        _loadRoles(); // Liste durumunu güncellemek için rolleri yeniden yükle
      } else if (response.statusCode == 400) {
        // BadRequest - Kullanıcı kontrolü hatası
        final errorData = jsonDecode(response.body);
        if (!mounted) return;

        // Detaylı hata mesajı göster
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
                Text(errorData['error'] ?? 'Rol durumu değiştirilemedi'),
                if (errorData['userCount'] != null) ...[
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
                        const Icon(Icons.people, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bu role sahip ${errorData['userCount']} aktif kullanıcı bulunuyor.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rol Yönetimi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRoles,
              child: _roles.isEmpty
                  ? const Center(
                      child: Text(
                        'Henüz rol bulunmuyor.',
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
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: role.aktiflikDurumu 
                                  ? Colors.blue 
                                  : Colors.grey,
                              child: Text(
                                role.rolTuru.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              role.rolTuru,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                // Rol pasif ise yazının üstünü çiz
                                decoration: !role.aktiflikDurumu
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: !role.aktiflikDurumu
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (role.aciklama != null &&
                                    role.aciklama!.isNotEmpty)
                                  Text(role.aciklama!)
                                else
                                  const Text('Açıklama yok'),
                                const SizedBox(height: 4),
                                // Durum göstergesi
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: role.aktiflikDurumu
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: role.aktiflikDurumu
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    role.aktiflikDurumu ? 'Aktif' : 'Pasif',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: role.aktiflikDurumu
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
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showAddEditRoleDialog(role),
                                  tooltip: 'Düzenle',
                                ),
                                // Toggle butonu - onay ile
                                IconButton(
                                  icon: Icon(
                                    role.aktiflikDurumu 
                                        ? Icons.toggle_on 
                                        : Icons.toggle_off,
                                    color: role.aktiflikDurumu
                                        ? Colors.green
                                        : Colors.red,
                                    size: 28,
                                  ),
                                  onPressed: () => _confirmAndToggleRoleStatus(role),
                                  tooltip: role.aktiflikDurumu 
                                      ? 'Pasif Yap' 
                                      : 'Aktif Yap',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditRoleDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Role model sınıfı
class Role {
  final int rolId;
  final String rolTuru;
  final String? aciklama;
  final bool aktiflikDurumu;

  Role({
    required this.rolId,
    required this.rolTuru,
    this.aciklama,
    required this.aktiflikDurumu,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      rolId: json['rolId'],
      rolTuru: json['rolTuru'],
      aciklama: json['aciklama'],
      aktiflikDurumu: json['aktiflikDurumu'] ?? true,
    );
  }
}