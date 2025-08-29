// kullanici_rol_yonetimi_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/app_config.dart';

class UserRoleManagementPage extends StatefulWidget {
  final String token;
  const UserRoleManagementPage({super.key, required this.token});

  @override
  State<UserRoleManagementPage> createState() => _UserRoleManagementPageState();
}

class _UserRoleManagementPageState extends State<UserRoleManagementPage> {
  List<UserWithRoles> _users = [];
  List<Role> _allRoles = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<UserWithRoles> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadUsers(), _loadRoles()]);
    _filterUsers();
    setState(() => _isLoading = false);
  }

  Future<void> _loadUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/KullaniciApi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<UserWithRoles> users = [];
        
        for (var userData in data) {
          // Her kullanıcı için rollerini çek
          final userRoles = await _getUserRoles(userData['kullaniciId']);
          users.add(UserWithRoles.fromJson(userData, userRoles));
        }
        
        setState(() {
          _users = users;
        });
      } else {
        throw Exception('Kullanıcılar yüklenemedi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcılar yüklenirken hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<List<Role>> _getUserRoles(int kullaniciId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/KullaniciRolleriApi/kullanici/$kullaniciId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Role(
          rolId: json['rolId'],
          rolTuru: json['rol'],
          aciklama: null,
          aktiflikDurumu: true,
        )).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> _loadRoles() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/RollerApi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allRoles = data.map((json) => Role.fromJson(json)).toList();
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

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final fullName = '${user.ad} ${user.soyad}'.toLowerCase();
        final tc = user.tc.toLowerCase();
        return fullName.contains(query) || tc.contains(query);
      }).toList();
    });
  }

  Future<void> _showUserRolesDialog(UserWithRoles user) async {
    final Map<int, bool> selectedRoles = {};
    
    // Mevcut rolleri işaretle
    for (var role in _allRoles) {
      selectedRoles[role.rolId] = user.roles.any((userRole) => userRole.rolId == role.rolId);
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${user.ad} ${user.soyad} - Rolleri'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TC: ${user.tc}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _allRoles.length,
                    itemBuilder: (context, index) {
                      final role = _allRoles[index];
                      return CheckboxListTile(
                        title: Text(role.rolTuru),
                        subtitle: role.aciklama != null && role.aciklama!.isNotEmpty
                            ? Text(role.aciklama!)
                            : null,
                        value: selectedRoles[role.rolId] ?? false,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            selectedRoles[role.rolId] = value ?? false;
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
      final selectedRoleIds = selectedRoles.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      
      await _updateUserRoles(user.kullaniciId, selectedRoleIds);
    }
  }

  Future<void> _updateUserRoles(int kullaniciId, List<int> roleIds) async {
    try {
      final body = {
        'kullaniciId': kullaniciId,
        'rolIds': roleIds,
      };

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/KullaniciRolleriApi/rolleri-guncelle'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı rolleri güncellendi.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Rolleri güncelleme başarısız');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showAddRoleDialog(UserWithRoles user) async {
    final availableRoles = _allRoles.where((role) => 
        !user.roles.any((userRole) => userRole.rolId == role.rolId)
    ).toList();

    if (availableRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kullanıcıya eklenebilecek rol bulunmuyor.')),
      );
      return;
    }

    Role? selectedRole;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${user.ad} ${user.soyad} - Rol Ekle'),
          content: DropdownButtonFormField<Role>(
            decoration: const InputDecoration(
              labelText: 'Eklenecek Rol',
              border: OutlineInputBorder(),
            ),
            items: availableRoles.map((role) => DropdownMenuItem(
              value: role,
              child: Text(role.rolTuru),
            )).toList(),
            onChanged: (Role? value) {
              setDialogState(() {
                selectedRole = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: selectedRole != null 
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedRole != null) {
      await _assignRoleToUser(user.kullaniciId, selectedRole!.rolTuru);
    }
  }

  Future<void> _assignRoleToUser(int kullaniciId, String rolTuru) async {
    try {
      final body = {
        'kullaniciId': kullaniciId,
        'rolTuru': rolTuru,
      };

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/KullaniciRolleriApi/rol-ata'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rol atandı.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Rol atama başarısız');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removeRoleFromUser(UserWithRoles user, Role role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rol Kaldır'),
        content: Text('${user.ad} ${user.soyad} kullanıcısından "${role.rolTuru}" rolünü kaldırmak istediğinizden emin misiniz?'),
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
        final body = {
          'kullaniciId': user.kullaniciId,
          'rolTuru': role.rolTuru,
        };

        final response = await http.delete(
          Uri.parse('${AppConfig.baseUrl}/KullaniciRolleriApi/rol-sil'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rol kaldırıldı.'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Rol kaldırma başarısız');
        }
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
        title: const Text('Kullanıcı Rol Yönetimi'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Arama çubuğu
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Kullanıcı adı veya TC ile ara...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
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
                // Kullanıcı listesi
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: _filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                              'Kullanıcı bulunamadı.',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.purple,
                                    child: Text(
                                      user.ad.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    '${user.ad} ${user.soyad}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('TC: ${user.tc}'),
                                  trailing: Text(
                                    '${user.roles.length} rol',
                                    style: TextStyle(
                                      color: Colors.purple,
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
                                                'Mevcut Roller:',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.add, color: Colors.green),
                                                    onPressed: () => _showAddRoleDialog(user),
                                                    tooltip: 'Rol Ekle',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                                    onPressed: () => _showUserRolesDialog(user),
                                                    tooltip: 'Rolleri Düzenle',
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          if (user.roles.isEmpty)
                                            const Text(
                                              'Bu kullanıcıya henüz rol atanmamış.',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            )
                                          else
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: user.roles.map((role) => Chip(
                                                label: Text(
                                                  role.rolTuru,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                backgroundColor: Colors.purple,
                                                deleteIcon: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                onDeleted: () => _removeRoleFromUser(user, role),
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
                ),
              ],
            ),
    );
  }
}

// UserWithRoles model sınıfı
class UserWithRoles {
  final int kullaniciId;
  final String ad;
  final String soyad;
  final String tc;
  final String? email;
  final List<Role> roles;

  UserWithRoles({
    required this.kullaniciId,
    required this.ad,
    required this.soyad,
    required this.tc,
    this.email,
    required this.roles,
  });

  factory UserWithRoles.fromJson(Map<String, dynamic> json, List<Role> roles) {
    return UserWithRoles(
      kullaniciId: json['kullaniciId'],
      ad: json['ad'],
      soyad: json['soyad'],
      tc: json['tc'],
      email: json['email'],
      roles: roles,
    );
  }
}

// Role model sınıfı (önceden tanımlanmışsa import edilebilir)
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