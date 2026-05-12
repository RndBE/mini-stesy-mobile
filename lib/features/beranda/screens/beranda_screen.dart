import 'package:flutter/material.dart';
import '../../chatbot/screens/chatbot_screen.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/models/user_model.dart';
import '../data/beranda_repository.dart';
import '../../analisa/screens/kategori_pos_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final AuthRepository _authRepo = AuthRepository();
  UserModel? _currentUser;
  
  // State untuk instansi
  bool _isLoadingInstansi = true;
  String _namaInstansi = "Memuat data...";
  String _alamatInstansi = "Mengambil detail alamat instansi...";
  String? _logoInstansiUrl; // Nullable jika nanti pakai URL gambar logo
  List<dynamic> _kategoriList = []; // Menyimpan kategori logger untuk menu dinamis

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _authRepo.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
    
    _fetchDataInstansi();
  }

  final BerandaRepository _berandaRepo = BerandaRepository();

  Future<void> _fetchDataInstansi() async {
    // 1. Coba load dari cache dulu biar UI langsung muncul tanpa nunggu internet
    try {
      final cachedData = await _berandaRepo.getCachedBerandaInfo();
      if (cachedData != null && mounted) {
        _updateInstansiState(cachedData);
      }
    } catch (_) {}

    // 2. Fetch data terbaru dari server secara background
    try {
      final data = await _berandaRepo.getBerandaInfo();
      
      if (mounted) {
        _updateInstansiState(data);
      }
    } catch (e) {
      if (mounted && _kategoriList.isEmpty) {
        // Hanya tampilkan error kalau cache sebelumnya kosong
        setState(() {
          _isLoadingInstansi = false;
          _namaInstansi = "Gagal memuat data";
          _alamatInstansi = "Periksa koneksi internet atau server";
        });
      }
    }
  }

  void _updateInstansiState(Map<String, dynamic> data) {
    setState(() {
      _isLoadingInstansi = false;
      // Asumsi respons JSON memiliki key 'instansi'
      if (data['instansi'] != null) {
        final instansi = data['instansi'];
        _namaInstansi = instansi['nama'] ?? "Nama Instansi Belum Diatur";
        _alamatInstansi = instansi['alamat'] ?? "Alamat belum diatur";
        
        // Prioritaskan logo_mobile, fallback ke logo jika tidak ada
        final rawLogo = (instansi['logo_mobile'] != null && instansi['logo_mobile'].toString().isNotEmpty)
            ? instansi['logo_mobile']
            : instansi['logo'];

        if (rawLogo != null && rawLogo.toString().isNotEmpty) {
          _logoInstansiUrl = rawLogo.toString().startsWith('http')
              ? rawLogo.toString()
              : '$kBaseUrl/storage/$rawLogo';
        }
      } else {
        _namaInstansi = "Data Instansi Tidak Ditemukan";
        _alamatInstansi = "Silakan hubungi administrator";
      }
      
      if (data['kategori_list'] != null) {
        _kategoriList = data['kategori_list'] as List<dynamic>;
      }
    });
  }

  void _onLogout() {
    const colorPrimaryDark = Color(0xFF2B3377);
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ikon Formal
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorPrimaryDark.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.exit_to_app_rounded, color: colorPrimaryDark, size: 40),
                ),
                const SizedBox(height: 20),
                // Judul
                const Text(
                  'Akhiri Sesi Pemantauan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorPrimaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                // Deskripsi Formal
                const Text(
                  'Anda akan keluar dari sistem STESY. Pastikan seluruh pengecekan data telah selesai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Tombol Aksi
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop(); // Tutup dialog
                          await _authRepo.logout();
                          if (mounted) {
                            Navigator.of(context).pushReplacementNamed('/login');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F), // Merah formal (Material Red 700)
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimaryDark = Color(0xFF2B3377);
    const colorBackground = Color(0xFFF8F9FA);

    // Format tanggal: Sabtu, 24 Januari 2026
    final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: colorPrimaryDark, // Status bar akan berwarna biru
      floatingActionButton: _buildChatbotFab(colorPrimaryDark),
      body: SafeArea(
        bottom: false,
        child: Container(
          color: colorBackground, // Background untuk sisa halaman
          child: Stack(
            children: [
          // 1. Background Biru Atas Lurus (Tanpa ClipPath Melengkung)
          Container(
            height: 185, // Tinggi disesuaikan agar pas di tengah card instansi
            width: double.infinity,
            color: colorPrimaryDark,
            child: ClipRect( // Agar gambar ombak yang digeser tidak bocor ke bawah
              child: Stack(
                children: [
                  // Wavy Background (Ombak Putih Transparan)
                  Positioned(
                    top: 30, // Menggeser posisi gelombang putih ke bawah
                    left: 0,
                    right: 0,
                    bottom: -40,
                    child: Opacity(
                      opacity: 0.35, 
                      child: Image.asset(
                        'assets/images/bg-login.png',
                        fit: BoxFit.cover, 
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Main Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Telemetri & User
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Telemetri BBWS C3',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser?.nama.toUpperCase() ?? 'USER',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      
                      // Logout Button
                      InkWell(
                        onTap: _onLogout,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                // --- Live Monitoring & Date ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge Live Monitoring
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Live Monitoring',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tanggal
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- CARD INSTANSI (Overlap) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF1), // Warna abu-abu kebiruan terang sesuai UI
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        // Logo Box
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _isLoadingInstansi 
                              ? Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )
                              : _logoInstansiUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: _logoInstansiUrl!, 
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => const Center(
                                        child: SizedBox(
                                          width: 20, height: 20, 
                                          child: CircularProgressIndicator(strokeWidth: 2)
                                        )
                                      ),
                                      errorWidget: (context, url, error) => const Icon(
                                        Icons.broken_image_rounded, 
                                        color: Colors.grey, 
                                        size: 32,
                                      ),
                                    )
                                  : const Icon(Icons.apartment_rounded, color: colorPrimaryDark, size: 32), // Placeholder Logo
                        ),
                        const SizedBox(width: 16),
                        
                        // Text Detail Instansi
                        Expanded(
                          child: _isLoadingInstansi
                              ? Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(height: 14, width: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                                      const SizedBox(height: 8),
                                      Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                                      const SizedBox(height: 4),
                                      Container(height: 10, width: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                                    ],
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _namaInstansi,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _alamatInstansi,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 11,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- MENU SECTION ---
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Grid Menu
                        Expanded(
                          child: _isLoadingInstansi
                              ? GridView.count(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                  children: List.generate(6, (index) => Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  )),
                                )
                              : GridView.count(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                  children: [
                              // 1. Menu dinamis dari kategori logger (Pos)
                              ..._kategoriList.map((kat) {
                                final namaKat = kat['nama_kategori'] ?? 'Unknown';
                                final kodeKat = (kat['kode'] ?? '').toString().toUpperCase();
                                
                                // Gabungkan nama dan kode untuk mendeteksi kata kunci dengan lebih kuat
                                final searchStr = '${namaKat.toLowerCase()} ${kodeKat.toLowerCase()}';
                                
                                // Daftar gambar icon yang sudah ada di folder assets/images/
                                const availableIcons = ['afmr', 'arr', 'awlr', 'awqr', 'awr'];
                                
                                // Mencari apakah ada kata kunci yang cocok di nama/kode kategori
                                String? matchedIcon;
                                for (final icon in availableIcons) {
                                  if (searchStr.contains(icon)) {
                                    matchedIcon = icon;
                                    break;
                                  }
                                }
                                
                                if (matchedIcon != null) {
                                  // Menggunakan gambar dari assets (sesuai nama file yang kamu sebutkan)
                                  return _buildMenuCard(
                                    'Pos\n$namaKat', 
                                    assetPath: 'assets/images/$matchedIcon.png',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => KategoriPosScreen(kategori: namaKat),
                                        ),
                                      );
                                    },
                                  );
                                } else {
                                  // Fallback ke Material Icon jika gambar belum ada
                                  IconData icon = Icons.waves_rounded;
                                  Color color = Colors.blue;
                                  
                                  if (kodeKat.contains('ARR') || namaKat.toUpperCase().contains('ARR')) {
                                    icon = Icons.cloudy_snowing;
                                    color = Colors.lightBlue;
                                  } else if (kodeKat.contains('KLIMAT') || namaKat.toUpperCase().contains('KLIMAT')) {
                                    icon = Icons.thermostat;
                                    color = Colors.deepOrange;
                                  }
                                  
                                  return _buildMenuCard(
                                    'Pos\n$namaKat', 
                                    icon: icon, 
                                    iconColor: color,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => KategoriPosScreen(kategori: namaKat),
                                        ),
                                      );
                                    },
                                  );
                                }
                              }),
                              
                              // 2. Menu statis lainnya
                              _buildMenuCard(
                                'Peta\nLokasi', 
                                assetPath: 'assets/images/peta_lokasi.png',
                                onTap: () {
                                  Navigator.pushNamed(context, '/peta');
                                },
                              ),
                              // _buildMenuCard('Realtime\nMonitoring', icon: Icons.cell_tower_rounded, iconColor: Colors.red),
                              // _buildMenuCard('Data\nPerangkat', icon: Icons.description_outlined, iconColor: Colors.blueAccent),
                              // _buildMenuCard('Pengaturan\nDevice', icon: Icons.settings_outlined, iconColor: Colors.grey.shade700),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    String title, {
    IconData? icon,
    String? assetPath,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (assetPath != null)
                Image.asset(
                  assetPath,
                  height: 42,
                  width: 42,
                  fit: BoxFit.contain,
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 38,
                  color: iconColor,
                ),
              const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildChatbotFab(Color primaryColor) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ChatbotScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 350),
              ),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 26,
              ),
              // Notification dot
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
