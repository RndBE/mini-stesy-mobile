import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/auth_repository.dart';
import '../../../shared/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authRepo = AuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    _checkPendingSuspendMessage();
  }

  Future<void> _checkPendingSuspendMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final msg = prefs.getString('pending_suspend_message');
    if (msg != null && msg.isNotEmpty) {
      await prefs.remove('pending_suspend_message');
      if (mounted) {
        Future.microtask(() => _showSuspendDialog(msg));
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepo.login(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) {
        // --- FCM TOKEN REGISTRATION ---
        try {
          print("=== MINTA TOKEN KE FIREBASE ===");
          final fcmToken = await FirebaseMessaging.instance.getToken();
          print("=== DAPAT TOKEN FIREBASE: $fcmToken ===");
          if (fcmToken != null) {
            await _authRepo.registerFcmToken(fcmToken);
            print("=== SELESAI KIRIM TOKEN KE BACKEND ===");
          }
        } catch (e) {
          print("=== GAGAL DAPAT TOKEN FIREBASE: $e ===");
          debugPrint("Failed FCM: $e");
        }
        
        Navigator.of(context).pushReplacementNamed('/beranda');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final msg = e.response?.data?['message'] ??
          e.response?.data?['errors']?['username']?[0] ??
          'Terjadi kesalahan. Periksa koneksi internet.';
      
      final msgStr = msg.toString().toLowerCase();
      // Memunculkan Pop-Up jika status 403 atau pesan mengandung kata kunci suspend/nonaktif
      if (statusCode == 403 || msgStr.contains('suspend') || msgStr.contains('nonaktif') || msgStr.contains('tidak aktif') || msgStr.contains('diblokir')) {
        _showSuspendDialog(msg.toString());
      } else {
        setState(() => _errorMessage = msg.toString());
      }
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan tidak terduga.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuspendDialog(String message) {
    final bool isMaintenance = message.toLowerCase().contains('maintenance');
    final bool isSuspend = message.toLowerCase().contains('suspend');
    
    // Default to Non-Aktif (Merah)
    Color themeColor = Colors.red;
    Color bgColor = Colors.red.withOpacity(0.1);
    IconData iconData = Icons.block_flipped;
    String title = 'Akun Non-Aktif';

    if (isMaintenance) {
      themeColor = Colors.blue.shade700;
      bgColor = Colors.blue.withOpacity(0.1);
      iconData = Icons.build_circle;
      title = 'Sedang Perbaikan';
      message = message.replaceAll(RegExp(r'^maintenance:\s*', caseSensitive: false), '');
    } else if (isSuspend) {
      themeColor = Colors.amber.shade700;
      bgColor = Colors.amber.withOpacity(0.1);
      iconData = Icons.warning_rounded;
      title = 'Akun Ditangguhkan';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: themeColor, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message, // Pesan asli dari backend
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
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
    const colorTextPrimary = Color(0xFF2B3377);
    const colorTextSecondary = Color(0xFF4A55A2);
    const colorInputBg = Color(0xFFF2F4FD);
    const colorInputBorder = Color(0xFF909CE1);

    return Scaffold(
      backgroundColor: colorPrimaryDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
            child: Column(
              children: [
                    // ── Bagian Atas: Ilustrasi SVG ──
                    Expanded(
                      flex: 1,
                      child: SafeArea(
                        bottom: false,
                        child: SizedBox(
                          width: double.infinity,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // Background Wavy
                              Positioned(
                                bottom: -90, // <-- Dibuat minus agar turun ke bawah
                                left: 0,
                                right: 0,
                                child: Image.asset(
                                  'assets/images/bg-login.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Gambar Ilustrasi Utama
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                                child: Image.asset(
                                  'assets/images/login-page.png',
                                  fit: BoxFit.contain,
                                  height: 250, // <-- UBAH ANGKA INI UNTUK MENGATUR UKURANNYA
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Bagian Bawah: Card Form Login ──
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      padding: const EdgeInsets.fromLTRB(32, 30, 32, 32),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Title
                                const Text(
                                  'Masuk ke Akun.',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: colorTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Masuk ke akun Anda untuk melanjutkan.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Error message
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.danger.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppTheme.danger.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline,
                                            color: AppTheme.danger, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                                color: AppTheme.danger, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Username field
                                TextFormField(
                                  controller: _usernameCtrl,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(color: colorTextPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Nama Pengguna',
                                    hintStyle: const TextStyle(
                                        color: colorTextSecondary, fontSize: 14),
                                    filled: true,
                                    fillColor: colorInputBg,
                                    prefixIcon: const Icon(
                                      Icons.person,
                                      color: colorTextPrimary,
                                      size: 20,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: colorInputBorder, width: 1.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: colorInputBorder, width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: colorTextPrimary, width: 2),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Nama Pengguna tidak boleh kosong'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Password field
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _onLogin(),
                                  style: const TextStyle(color: colorTextPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Kata Sandi',
                                    hintStyle: TextStyle(
                                        color: colorTextSecondary.withValues(alpha: 0.6),
                                        fontSize: 14),
                                    filled: true,
                                    fillColor: colorInputBg,
                                    prefixIcon: const Icon(
                                      Icons.lock,
                                      color: colorTextPrimary,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: colorTextPrimary,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: colorTextPrimary, width: 1.5),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Kata Sandi tidak boleh kosong'
                                      : null,
                                ),
                                const SizedBox(height: 24),

                                // Login button
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _onLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorPrimaryDark,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: colorPrimaryDark,
                                      disabledForegroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Masuk',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 48),

                                // Footer Logos
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildNetworkLogo('/images/logo 1.png',
                                        height: 32),
                                    const SizedBox(width: 16),
                                    _buildNetworkLogo('/images/mini_stesy 1.png',
                                        height: 32),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkLogo(String path, {required double height}) {
    return Image.asset(
      'assets$path',
      height: height,
      errorBuilder: (context, error, stackTrace) => const SizedBox(),
    );
  }
}
