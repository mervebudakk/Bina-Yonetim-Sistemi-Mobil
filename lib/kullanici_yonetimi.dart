// lib/user_management_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/kullanici.dart';
import 'kullanici_ekle_duzenle.dart';
import 'config/app_config.dart';
import 'models/daire.dart';

class UserManagementPage extends StatefulWidget {
  final String token;
  final bool isAdmin;
  const UserManagementPage({
    super.key,
    required this.token,
    required this.isAdmin,
  });

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Kullanici> _users = [];
  List<Daire> _allDaires = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // Sayfa açıldığında tüm verileri yükle
  }

  // Hem kullanıcıları hem de daireleri aynı anda çeken birleşik metot
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // İki API isteğini aynı anda başlatıp bitmelerini bekle (daha performanslı)
    await Future.wait([_fetchUsers(), _fetchDaires()]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Kullanıcıları çeken metot (sadeleştirildi)
  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/KullaniciApi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _users = data.map((json) => Kullanici.fromJson(json)).toList();
      } else {
        throw Exception('Kullanıcılar yüklenemedi');
      }
    } catch (e) {
      _users = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcılar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Daireleri çeken metot
  Future<void> _fetchDaires() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/DaireApi/tum-daireler'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _allDaires = data.map((json) => Daire.fromJson(json)).toList();
      } else {
        throw Exception('Daireler yüklenemedi');
      }
    } catch (e) {
      _allDaires = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daire bilgileri çekilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Silme ve yönlendirme metotları aynı kalıyor...
  Future<void> _deleteUser(int userId) async {
    // ... Bu metodun içeriği doğru, değişiklik yok ...
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: const Text(
          'Bu kullanıcıyı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/KullaniciApi/KullaniciSil/$userId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı başarıyla silindi.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Listeyi yenilemek için _loadData'yı çağır
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Kullanıcı silinemedi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // UserManagementPage'in State sınıfının bittiği yerin altına bu fonksiyonları ekleyin.

  // ESKİ _showUserDetailsDialog FONKSİYONUNU SİL, YERİNE BUNU YAPIŞTIR
  void _showUserDetailsDialog(
    BuildContext context,
    Kullanici user,
    Daire daire,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // SÜSLÜ DIALOG YERİNE STANDART AlertDialog KULLANIYORUZ
        return AlertDialog(
          // Başlık ve kapatma butonu
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${user.ad} ${user.soyad}',
              ), // Başlığı kullanıcının adı yapalım
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          // İçeriği AlertDialog'un content kısmına taşıyoruz
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kullanıcı bilgi kartı
                // Not: Artık bu yardımcı fonksiyonları da sadeleştireceğiz
                _buildInfoCard(
                  title:
                      'Kullanıcı Bilgileri', // Başlığı daha açıklayıcı yapalım
                  children: [
                    _buildDetailRow('T.C.:', user.tc),
                    _buildDetailRow('E-posta:', user.email ?? 'Girilmemiş'),
                    _buildDetailRow('Telefon:', user.telNo ?? 'Girilmemiş'),
                    _buildDetailRow('Daire:', daire.daireNo),
                  ],
                ),
                const SizedBox(height: 20),
                // Borçlar Kartı
                _buildSectionCard(
                  icon: Icons.monetization_on,
                  title: 'Borçlar',
                  child: _buildPlaceholderTable(),
                ),
                const SizedBox(height: 20),
                // Dekontlar Kartı
                _buildSectionCard(
                  icon: Icons.receipt_long,
                  title: 'Dekontlar',
                  child: _buildPlaceholderTable(),
                ),
              ],
            ),
          ),
          // Kapat butonunu actions kısmına alabiliriz ama yukarıda ikonla çözdük
          // İstersen buraya da ekleyebilirsin:
          // actions: [
          //   TextButton(
          //     onPressed: () => Navigator.of(context).pop(),
          //     child: const Text('Kapat'),
          //   ),
          // ],
        );
      },
    );
  }

  // Aşağıdaki yardımcı widget'ları da aynı dosyanın en sonuna ekleyin.

  // _buildDetailRow FONKSİYONUNU BUNUNLA DEĞİŞTİR
  Widget _buildDetailRow(String label, String value) {
    // Sadece renkleri siliyoruz, yapi aynı kalıyor
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text.rich(
        TextSpan(
          // ANA STİLİ SİLİYORUZ, ARTIK TEMADAN ALACAK
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ), // Sadece kalın yapalım
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // _buildInfoCard FONKSİYONUNU BUNUNLA DEĞİŞTİR
  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    // Süslü Container yerine basit bir Column kullanıyoruz
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(
              context,
            ).primaryColor, // Temanın ana rengini kullanalım
          ),
        ),
        const Divider(), // Başlığın altına bir çizgi çekelim
        ...children,
      ],
    );
  }

  // _buildSectionCard FONKSİYONUNU BUNUNLA DEĞİŞTİR
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    // Burada da süslü Container yerine basit bir yapı
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey[700], size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Divider(),
        // Placeholder'daki yazıları da görünür yapalım
        DefaultTextStyle(
          style: TextStyle(color: Colors.black54), // Yazı rengini değiştir
          child: child,
        ),
      ],
    );
  }

  // _buildPlaceholderTable içindeki renkleri de temizleyelim
  Widget _buildPlaceholderTable() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text('TUTAR'), Text('DURUM'), Text('TARİH')],
    );
  }

  void _navigateToAddEditPage([Kullanici? user]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditUserPage(
          token: widget.token,
          user: user,
          isAdmin: widget.isAdmin,
        ),
      ),
    );
    if (result == true) {
      _loadData(); // Listeyi yenilemek için _loadData'yı çağır
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Yönetimi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData, // Yenileme işlemi için _loadData'yı kullan
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  // Daire ID'sine göre ilgili daire nesnesini bul
                  final daire = _allDaires.firstWhere(
                    (d) => d.daireId == user.daireId,
                    orElse: () => Daire(
                      daireId: 0,
                      daireNo: '?',
                      apartmanId: 0,
                      dolulukDurumu: false,
                      apartmanNo: '',
                    ),
                  );
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(user.ad[0])),
                      title: Text('${user.ad} ${user.soyad}'),
                      // DAİRE NO GÖSTERİMİ
                      subtitle: Text(
                        'TC: ${user.tc} - Daire: ${daire.daireNo}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.visibility,
                              color: Colors.blueGrey,
                            ),
                            tooltip: 'Detayları Görüntüle',
                            onPressed: () {
                              // Birazdan oluşturacağımız dialog'u burada çağırıyoruz
                              _showUserDetailsDialog(context, user, daire);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _navigateToAddEditPage(user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(user.kullaniciId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditPage(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
