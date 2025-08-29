import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profil_sayfası.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'kullanici_yonetimi.dart';
import 'config/app_config.dart';
import 'debt_management_page.dart';
import 'my_debts_page.dart';
import 'receipt_approval_page.dart';
import 'models/dashboard_data.dart';
import 'payment_history_page.dart';
import 'rol_yonetimi_page.dart';
import 'rol_yetki_yonetimi_page.dart';
import 'yetki_yonetimi_page.dart';
import 'kullanici_rol_yonetimi_page.dart';

const Color kPrimaryColor = Color(0xFF1ABC9C); 
const Color kAppBarColor = Color(0xFF34495E); 
const Color kBackgroundColor = Color(0xFFF8F9FA); 
const Color kCardColor = Colors.white; 
const Color kTextColor = Color(0xFF2C3E50); 
const Color kSecondaryTextColor = Color(0xFF7F8C8D); 

const Color kSuccessColor = Color(0xFF28C76F);
const Color kWarningColor = Color(0xFFFFA000);
const Color kDangerColor = Color(0xFFE74C3C);
const Color kInfoColor = Color(0xFF3498DB);

void main() {
  runApp(const BinaYonetimApp());
}

class BinaYonetimApp extends StatelessWidget {
  const BinaYonetimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bina Yönetim Sistemi',
      theme: ThemeData(
        // --- YENİ TEMA AYARLARI ---
        useMaterial3: true,
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        fontFamily: 'Roboto', // Örnek bir font ailesi

        // ColorScheme ayarları
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          background: kBackgroundColor,
          onBackground: kTextColor,
          surface: kCardColor,
          onSurface: kTextColor,
          error: kDangerColor,
        ),

        // AppBar Teması
        appBarTheme: const AppBarTheme(
          backgroundColor: kAppBarColor,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),

        // Kart Teması
        cardTheme: CardThemeData(
          color: kCardColor,
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // Buton Teması
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Metin Giriş Alanı Teması
        inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kSecondaryTextColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            labelStyle: const TextStyle(color: kSecondaryTextColor),
            prefixIconColor: kSecondaryTextColor,
        ),

        // Metin Temaları
         textTheme: const TextTheme(
           headlineMedium: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
           bodyMedium: TextStyle(color: kTextColor),
           labelLarge: TextStyle(color: Colors.white),
         ),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _tcController = TextEditingController();
  final _sifreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // API çağrısı
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tc': _tcController.text.trim(),
          'sifre': _sifreController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Başarılı giriş
        final data = jsonDecode(response.body);
        final token = data['token'];

        // Ana sayfaya git
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(token: token)),
        );
      } else {
        // Hatalı giriş
        final errorData = jsonDecode(response.body);
        String errorMessage = errorData['error'] ?? 'Giriş başarısız!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // Bağlantı hatası
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bağlantı hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Login hata: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8.0,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Başlık
                      const Icon(
                        Icons.apartment,
                        size: 60,
                        color: kInfoColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bina Yönetim',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sisteme Giriş Yapın',
                        style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
                      ),
                      const SizedBox(height: 40),

                      // TC Kimlik No
                      TextFormField(
                        controller: _tcController,
                        keyboardType: TextInputType.number,
                        maxLength: 11,
                        decoration: const InputDecoration(
                          labelText: 'TC Kimlik No',
                          prefixIcon: Icon(Icons.person_outline),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'TC Kimlik No giriniz';
                          }
                          if (value.length != 11) {
                            return 'TC Kimlik No 11 haneli olmalıdır';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Şifre
                      TextFormField(
                        controller: _sifreController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre giriniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Giriş Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Giriş Yap'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tcController.dispose();
    _sifreController.dispose();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  final String token;
  const HomePage({super.key, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> userPermissions = [];
  String _appBarTitle = 'Ana Sayfa';
  bool _isAdmin = false;
  bool _isManager = false;

  DashboardData? _dashboardData;
  bool _isDashboardLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _loadPermissions(); 
    await _loadDashboardData(); 
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isDashboardLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/DashboardApi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _dashboardData = DashboardData.fromJson(jsonDecode(response.body));
          });
        }
      } else {
        throw Exception('Kontrol paneli verileri yüklenemedi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isDashboardLoading = false);
    }
  }

  void _loadPermissions() {
    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(widget.token);

      // 'perm' claim'ini al. API'den bu claim bazen tek bir string, bazen de liste olarak gelebilir.
      // Her iki durumu da kontrol altına alıyoruz.
      final permissions = decodedToken['perm'];

      if (permissions is List) {
        setState(() {
          userPermissions = List<String>.from(permissions);
        });
      } else if (permissions is String) {
        setState(() {
          userPermissions = [permissions];
        });
      }
      _updateTitleBasedOnRole();
    } catch (e) {
      print('Token decode hatası: $e');
      // Token hatalıysa veya 'perm' claim'i yoksa kullanıcıyı güvenli bir şekilde login ekranına at
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  // _loadPermissions metodunun bittiği yerin altına ekleyin
  void _updateTitleBasedOnRole() {
    // Öncelik sırasına göre kontrol yapıyoruz

    // Admin yetkileri var mı? (Rol/Yetki yönetimi gibi sadece admine özel yetkiler)
    if (userPermissions.contains("Rol Ekleme") ||
        userPermissions.contains("Apartman Ekleme")) {
      setState(() {
        _appBarTitle = 'Admin Paneli';
        _isAdmin = true;
        _isManager = true;
      });
      return; // Admin ise daha fazla kontrol etmeye gerek yok
    }

    // Yönetici yetkileri var mı? (Kullanıcı ekleme, dekont onaylama gibi)
    if (userPermissions.contains("Yeni Kullanıcı Ekleme") ||
        userPermissions.contains("Dekont Onaylama")) {
      setState(() {
        _appBarTitle = 'Yönetici Paneli';
        _isManager = true;
      });
      return; // Yönetici ise daha fazla kontrol etmeye gerek yok
    }

    // Hiçbiri değilse, standart sakindir
    if (userPermissions.contains("Kendi Borç Bilgilerini Görüntüleme")) {
      setState(() {
        _appBarTitle = 'Sakin Paneli';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(token: widget.token),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: kAppBarColor),
              child: Text(
                'Menü',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),

            if (_isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Admin Paneli'),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(),

              // === KULLANICI YÖNETİMİ ===
              ExpansionTile(
                leading: const Icon(Icons.people),
                title: const Text('Kullanıcı Yönetimi'),
                children: [
                  if (userPermissions.contains("Yeni Kullanıcı Ekleme"))
                    ListTile(
                      leading: const Icon(Icons.person_add),
                      title: const Text('Kullanıcı İşlemleri'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserManagementPage(
                              token: widget.token,
                              isAdmin: _isAdmin,
                            ),
                          ),
                        );
                      },
                    ),

                  if (userPermissions.contains("Kullanıcıya Rol Atama"))
                    ListTile(
                      leading: const Icon(Icons.person_pin),
                      title: const Text('Kullanıcı Rolleri'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserRoleManagementPage(token: widget.token),
                          ),
                        );
                      },
                    ),
                ],
              ),

              // === ROL YÖNETİMİ ===
              ExpansionTile(
                leading: const Icon(Icons.security),
                title: const Text('Rol Yönetimi'),
                children: [
                  if (userPermissions.contains("Rol Ekleme"))
                    ListTile(
                      leading: const Icon(Icons.add_moderator),
                      title: const Text('Rol İşlemleri'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RoleManagementPage(token: widget.token),
                          ),
                        );
                      },
                    ),

                  if (userPermissions.contains("Rol-Yetki Atama"))
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: const Text('Rol-Yetki Bağlantıları'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RolePermissionManagementPage(
                              token: widget.token,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),

              // === YETKİ YÖNETİMİ ===
              ExpansionTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Yetki Yönetimi'),
                children: [
                  if (userPermissions.contains("Yetki Ekleme"))
                    ListTile(
                      leading: const Icon(Icons.key),
                      title: const Text('Yetki İşlemleri'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PermissionManagementPage(token: widget.token),
                          ),
                        );
                      },
                    ),
                ],
              ),

              const Divider(),

              // === BORÇ YÖNETİMİ ===
              ExpansionTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Borç Yönetimi'),
                children: [
                  if (userPermissions.contains("Borç Ekleme"))
                    ListTile(
                      leading: const Icon(Icons.post_add),
                      title: const Text('Borç İşlemleri'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DebtManagementPage(
                              token: widget.token,
                              isAdmin: _isAdmin,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),

              // === DEKONT YÖNETİMİ ===
              ExpansionTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Dekont Yönetimi'),
                children: [
                  if (userPermissions.contains("Dekont Onaylama"))
                    ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: const Text('Dekont Onayları'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ReceiptApprovalPage(token: widget.token),
                          ),
                        );
                      },
                    ),

                  if (userPermissions.contains(
                    "Tüm Kullanıcıların Geçmiş Ödeme Dekontunu Görüntüleme",
                  ))
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Tüm Geçmiş Ödemeler'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentHistoryPage(
                              token: widget.token,
                              isManagerView: true,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),

              // === SİSTEM YÖNETİMİ ===
              ExpansionTile(
                leading: const Icon(Icons.settings),
                title: const Text('Sistem Yönetimi'),
                children: [
                  if (userPermissions.contains("Apartman Ekleme"))
                    ListTile(
                      leading: const Icon(Icons.apartment),
                      title: const Text('Apartman Yönetimi'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: ApartmentManagementPage navigate
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Apartman Yönetimi sayfası yapılacak.',
                            ),
                          ),
                        );
                      },
                    ),

                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Sistem Bilgileri'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: SystemInfoPage navigate
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sistem Bilgileri sayfası yapılacak.'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ] else ...[
              // ADMIN DEĞİLSE (Yönetici veya Sakin için normal menü)

              // Standart Kullanıcı Menüleri (Admin hariç)
              if (userPermissions.contains(
                "Kendi Borç Bilgilerini Görüntüleme",
              ))
                ListTile(
                  leading: const Icon(Icons.credit_card),
                  title: const Text('Borçlarım'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyDebtsPage(token: widget.token),
                      ),
                    );
                  },
                ),

              if (userPermissions.contains(
                "Kendi Geçmiş Ödeme Dekontunu Görüntüleme",
              ))
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Dekontlarım'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentHistoryPage(
                          token: widget.token,
                          isManagerView: false,
                        ),
                      ),
                    );
                  },
                ),

              // Yönetici için özel menüler
              if (userPermissions.contains(
                "Tüm Kullanıcıların Geçmiş Ödeme Dekontunu Görüntüleme",
              ))
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Tüm Geçmiş Ödemeler'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentHistoryPage(
                          token: widget.token,
                          isManagerView: true,
                        ),
                      ),
                    );
                  },
                ),

              // Yönetici/Admin yetkilerinden herhangi birine sahipse bir ayraç göster
              if (userPermissions.contains(
                    "Tüm Kullanıcıların Borç Bilgilerini Görüntüleme",
                  ) ||
                  userPermissions.contains("Dekont Onaylama") ||
                  userPermissions.contains("Yeni Kullanıcı Ekleme"))
                const Divider(),

              // Yönetici / Admin Menüleri
              if (userPermissions.contains("Yeni Kullanıcı Ekleme"))
                ListTile(
                  leading: const Icon(Icons.group_add),
                  title: const Text('Kullanıcı Yönetimi'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserManagementPage(
                          token: widget.token,
                          isAdmin: _isAdmin,
                        ),
                      ),
                    );
                  },
                ),

              if (userPermissions.contains("Borç Ekleme"))
                ListTile(
                  leading: const Icon(Icons.post_add),
                  title: const Text('Borç Yönetimi'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DebtManagementPage(
                          token: widget.token,
                          isAdmin: _isAdmin,
                        ),
                      ),
                    );
                  },
                ),

              if (userPermissions.contains("Dekont Onaylama"))
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Dekont Onayları'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReceiptApprovalPage(token: widget.token),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: kPrimaryColor,
        child: _isDashboardLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (_dashboardData != null) ...[
                    if (_isAdmin)
                      _buildAdminDashboard(_dashboardData!)
                    else if (_isManager)
                      _buildYoneticiDashboard(_dashboardData!)
                    else
                      _buildSakinDashboard(_dashboardData!),
                    const Divider(height: 40),
                  ],

                  const Icon(Icons.apartment, size: 100, color: kInfoColor),
                  const SizedBox(height: 20),
                  Text(
                    _isAdmin ? 'Admin Paneline Hoş Geldiniz!' : 'Hoş Geldiniz!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isAdmin) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Sistem yönetim işlemlerinizi sol menüden gerçekleştirebilirsiniz.',
                      style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  // Yeni Admin Dashboard Widget'ı
  Widget _buildAdminDashboard(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sistem Genel Durumu',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),

        // Sadece sistem geneli istatistikler
        _DashboardCard(
          icon: Icons.groups,
          title: 'Toplam Aktif Kullanıcı',
          value: data.toplamAktifSakin?.toString() ?? '0',
          color: kInfoColor,
        ),
        const SizedBox(height: 12),

        _DashboardCard(
          icon: Icons.pending_actions,
          title: 'Onay Bekleyen Dekont',
          value: data.onaylanacakToplamDekont?.toString() ?? '0',
          color: kWarningColor,
          isUrgent: (data.onaylanacakToplamDekont ?? 0) > 0,
        ),
        const SizedBox(height: 12),

        // Sistem geneli mali durum (Admin için sadece bilgilendirme)
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics, size: 40, color: Colors.green),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sistem Mali Durumu',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Toplam: ${data.yonetimdekiToplamBorc?.toStringAsFixed(2) ?? '0.00'} TL',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tahsil Edilen:',
                      style: TextStyle(
                        color: kSuccessColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${data.yonetimdekiOdenenTutar?.toStringAsFixed(2) ?? '0.00'} TL',
                      style: TextStyle(
                        color: kSuccessColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bekleyen:',
                      style: TextStyle(
                        color: kWarningColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${data.yonetimdekiKalanTutar?.toStringAsFixed(2) ?? '0.00'} TL',
                      style: TextStyle(
                        color: kWarningColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYoneticiDashboard(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yönetici Paneli',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        _DashboardCard(
          icon: Icons.groups,
          title: 'Toplam Aktif Sakin',
          value: data.toplamAktifSakin?.toString() ?? '0',
          color: kInfoColor,
        ),
        const SizedBox(height: 12),

        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 40,
                      color: kDangerColor,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bu Ayki Toplam Borç',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          '${data.yonetimdekiToplamBorc?.toStringAsFixed(2) ?? '0.00'} TL',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ödenen:',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${data.yonetimdekiOdenenTutar?.toStringAsFixed(2) ?? '0.00'} TL',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kalan:',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${data.yonetimdekiKalanTutar?.toStringAsFixed(2) ?? '0.00'} TL',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // --- DEĞİŞEN KART SONU ---
        const SizedBox(height: 12),
        _DashboardCard(
          icon: Icons.pending_actions,
          title: 'Onay Bekleyen Dekont',
          value: data.onaylanacakToplamDekont?.toString() ?? '0',
          color: Colors.orange,
          isUrgent: (data.onaylanacakToplamDekont ?? 0) > 0,
        ),
      ],
    );
  }

  Widget _buildSakinDashboard(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardCard(
          icon: Icons.payment,
          title: 'Bu Ayki Toplam Borcunuz',
          value: '${data.aylikToplamBorc?.toStringAsFixed(2) ?? '0.00'} TL',
          color: kDangerColor,
        ),
        const SizedBox(height: 12),
        _DashboardCard(
          icon: Icons.check_circle,
          title: 'Bu Ay Ödediğiniz Tutar',
          value: '${data.aylikOdenenTutar?.toStringAsFixed(2) ?? '0.00'} TL',
          color: kSuccessColor,
        ),
        const SizedBox(height: 12),
        _DashboardCard(
          icon: Icons.account_balance_wallet,
          title: 'Bu Ayki Kalan Borcunuz',
          value: '${data.aylikKalanBorc?.toStringAsFixed(2) ?? '0.00'} TL',
          color: kDangerColor,
          isUrgent: (data.aylikKalanBorc ?? 0) > 0,
        ),
        const SizedBox(height: 12),
        _DashboardCard(
          icon: Icons.hourglass_top,
          title: 'Onay Bekleyen Dekont',
          value: data.onayBekleyenDekontSayisi.toString(),
          color: Colors.orange,
          isUrgent: data.onayBekleyenDekontSayisi > 0,
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isUrgent;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isUrgent ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey[600])),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
