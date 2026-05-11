import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/beranda/screens/beranda_screen.dart';
import 'features/peta/screens/peta_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/notifications/screens/warning_notification_detail_screen.dart';
import 'shared/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage/secure_storage.dart';
import 'core/constants/api_constants.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");

  if (message.data['type'] == 'force_logout') {
    print("Silent push received in background. Forcing logout.");
    await _showAccountStatusNotification(message.data['reason']);
    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      await SecureStorage.clearAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'pending_suspend_message',
        message.data['reason'] ?? 'Akun Anda telah dinonaktifkan.',
      );
    }
  } else if (message.data['type'] == 'password_changed') {
    print(
      "Silent push received in background (Password changed). Clean logout.",
    );
    await SecureStorage.clearAll();
  }
}

// Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Map<String, dynamic>? _pendingWarningNotificationData;
Map<String, dynamic>? _pendingUpdateNotificationData;

const AndroidNotificationChannel highImportanceChannel =
    AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
    );

Future<void> _showAccountStatusNotification(String? reason) async {
  const initializationSettingsAndroid = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(highImportanceChannel);

  await flutterLocalNotificationsPlugin.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: 'Status Akun Berubah',
    body: reason?.isNotEmpty == true
        ? reason
        : 'Akun Anda telah dinonaktifkan. Silakan hubungi Administrator.',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}

Future<void> _openWarningNotificationDetail(Map<String, dynamic> data) async {
  final navigator = navigatorKey.currentState;
  if (navigator == null) {
    _pendingWarningNotificationData = data;
    return;
  }

  await navigator.push(
    MaterialPageRoute(
      builder: (_) => WarningNotificationDetailScreen(data: data),
    ),
  );
}

Future<void> _openPendingWarningNotificationIfAny() async {
  final data = _pendingWarningNotificationData;
  if (data == null) return;

  _pendingWarningNotificationData = null;
  await Future.delayed(const Duration(milliseconds: 250));
  await _openWarningNotificationDetail(data);
}

Future<void> _showPendingUpdateNotificationIfAny() async {
  final data = _pendingUpdateNotificationData;
  if (data == null) return;

  _pendingUpdateNotificationData = null;
  await Future.delayed(const Duration(milliseconds: 250));
  await _showUpdateNotificationDialog(data);
}

Future<void> _handleNotificationData(
  Map<String, dynamic> data, {
  bool deferWarningNavigation = false,
}) async {
  final notificationType = data['type']?.toString();
  if (notificationType == 'warning_alert' ||
      notificationType == 'logger_warning') {
    if (deferWarningNavigation) {
      _pendingWarningNotificationData = data;
      return;
    }

    await _openWarningNotificationDetail(data);
    return;
  }

  if (data['type'] != 'app_update') {
    return;
  }

  await _showUpdateNotificationDialog(data);
}

Future<bool> _launchUpdateUrl(String updateUrl) async {
  final uri = Uri.tryParse(updateUrl);
  if (uri == null || !uri.hasScheme) {
    return false;
  }

  if (!await canLaunchUrl(uri)) {
    return false;
  }

  await launchUrl(uri, mode: LaunchMode.externalApplication);
  return true;
}

Future<void> _launchConfiguredUpdateUrl() async {
  try {
    final response = await Dio().get(
      '$kBaseUrl/api/v1/mobile/auth/config',
      options: Options(receiveTimeout: const Duration(seconds: 5)),
    );

    if (response.data == null || response.data['success'] != true) {
      return;
    }

    final config = response.data['data'];
    final updateUrl = config?['update_url']?.toString() ?? '';
    if (updateUrl.isEmpty) {
      return;
    }

    await _launchUpdateUrl(updateUrl);
  } catch (e) {
    print('Failed to open configured update URL: $e');
  }
}

Future<void> _showUpdateNotificationDialog(Map<String, dynamic> data) async {
  final context = navigatorKey.currentContext;
  if (context == null) {
    _pendingUpdateNotificationData = data;
    return;
  }

  final latestVersion = data['latest_app_version']?.toString() ?? '';
  final forceUpdate = data['force_update']?.toString() == '1' ||
      data['force_update'] == true;
  var updateUrl = data['update_url']?.toString() ?? '';

  if (updateUrl.isEmpty) {
    updateUrl = await _getConfiguredUpdateUrl();
  }

  await showDialog(
    context: context,
    barrierDismissible: !forceUpdate,
    builder: (dialogContext) => PopScope(
      canPop: !forceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: forceUpdate ? Colors.red : const Color(0xFF2E3B84),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Pembaruan Tersedia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          forceUpdate
              ? 'Versi aplikasi ${latestVersion.isEmpty ? 'terbaru' : latestVersion} wajib dipasang untuk dapat melanjutkan.'
              : 'Versi aplikasi ${latestVersion.isEmpty ? 'terbaru' : latestVersion} telah tersedia. Perbarui sekarang untuk mendapatkan fitur terbaru dan perbaikan sistem.',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Nanti Saja',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          TextButton(
            onPressed: updateUrl.isEmpty
                ? null
                : () async {
                    await _launchUpdateUrl(updateUrl);
                    if (!forceUpdate && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
            child: Text(
              'Update Sekarang',
              style: TextStyle(
                color: forceUpdate ? Colors.red : const Color(0xFF2E3B84),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<String> _getConfiguredUpdateUrl() async {
  try {
    final response = await Dio().get(
      '$kBaseUrl/api/v1/mobile/auth/config',
      options: Options(receiveTimeout: const Duration(seconds: 5)),
    );

    if (response.data == null || response.data['success'] != true) {
      return '';
    }

    return response.data['data']?['update_url']?.toString() ?? '';
  } catch (e) {
    print('Failed to get configured update URL: $e');
    return '';
  }
}

Future<void> _handleLocalNotificationTap(NotificationResponse response) async {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) {
    return;
  }

  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      await _handleNotificationData(decoded);
    }
  } catch (e) {
    print('Failed to parse notification payload: $e');
  }
}

// ==== GLOBAL NAVIGATOR KEY ====
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Config local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(highImportanceChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  } catch (e) {
    print("Firebase init failed: $e");
    // Ignore error so app can still run if google-services.json is missing
  }

  runApp(const StesyApp());
}

class StesyApp extends StatelessWidget {
  const StesyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'STESY Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: const SplashRouter(),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/beranda': (_) => const BerandaScreen(),
        '/peta': (_) => const PetaScreen(),
      },
    );
  }
}

/// Splash router: cek apakah sudah login atau belum.
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();

    _startSplashFlow();
  }

  Future<void> _startSplashFlow() async {
    // Jalankan initPackageInfo & tunggu animasi selesai secara paralel
    await Future.wait([
      _initPackageInfo(),
      Future.delayed(const Duration(milliseconds: 700)), // tunggu animasi 600ms + buffer
    ]);
    _setupFCM(); // Fire & forget — tidak perlu menunggu FCM untuk navigasi
    _checkAuth();
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = 'v${info.version}';
        });
      }
    } catch (e) {
      print('Error getting package info: $e');
    }
  }

  bool _isUpdateRequired(String current, String latest) {
    if (current.isEmpty || latest.isEmpty) return false;
    List<int> c = current
        .replaceAll('v', '')
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    List<int> l = latest
        .replaceAll('v', '')
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    for (int i = 0; i < 3; i++) {
      int cVal = i < c.length ? c[i] : 0;
      int lVal = i < l.length ? l[i] : 0;
      if (lVal > cVal) return true;
      if (lVal < cVal) return false;
    }
    return false;
  }

  Future<void> _setupFCM() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print("FCM permission status: ${settings.authorizationStatus}");

    final fcmToken = await FirebaseMessaging.instance.getToken();
    print("FCM current token: $fcmToken");
    if (fcmToken != null) {
      await AuthRepository().registerFcmToken(fcmToken);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      print("FCM refreshed token: $token");
      await AuthRepository().registerFcmToken(token);
    });

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print("=== NOTIFIKASI FCM DIKLIK ===");
      print("Data: ${message.data}");
      await _handleNotificationData(message.data);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print("=== APP DIBUKA DARI NOTIFIKASI FCM ===");
      print("Data: ${initialMessage.data}");
      final shouldDefer = initialMessage.data['type']?.toString() == 'warning_alert' ||
          initialMessage.data['type']?.toString() == 'logger_warning';
      await _handleNotificationData(
        initialMessage.data,
        deferWarningNavigation: shouldDefer,
      );
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("=== TERIMA PESAN FCM DI FOREGROUND! ===");
      print("Title: ${message.notification?.title}");
      print("Body: ${message.notification?.body}");
      print("Data: ${message.data}");

      if (message.data['type'] == 'force_logout') {
        print("Silent push received in foreground. Forcing logout.");
        await _showAccountStatusNotification(message.data['reason']);
        final token = await SecureStorage.getToken();
        if (token != null && token.isNotEmpty) {
          await SecureStorage.clearAll();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'pending_suspend_message',
            message.data['reason'] ?? 'Akun Anda telah dinonaktifkan.',
          );
          if (navigatorKey.currentContext != null) {
            Navigator.of(
              navigatorKey.currentContext!,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
        return; // Hindari notifikasi ganda dari handler umum di bawah.
      } else if (message.data['type'] == 'password_changed') {
        print(
          "Silent push received in foreground (Password changed). Clean logout.",
        );
        final token = await SecureStorage.getToken();
        if (token != null && token.isNotEmpty) {
          await SecureStorage.clearAll();
          // Tendang ke login tanpa pesan peringatan merah
          if (navigatorKey.currentContext != null) {
            Navigator.of(
              navigatorKey.currentContext!,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
        return;
      }

      RemoteNotification? notification = message.notification;
      final title =
          notification?.title ?? message.data['title'] ?? message.data['judul'];
      final body =
          notification?.body ??
          message.data['body'] ??
          message.data['message'] ??
          message.data['pesan'];

      if (title != null || body != null) {
        flutterLocalNotificationsPlugin.show(
          id:
              message.messageId?.hashCode ??
              DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // id
              'High Importance Notifications', // title
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    // Check Internet Connection
    bool hasInternet = false;
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        hasInternet = true;
      }
    } catch (_) {
      hasInternet = false;
    }

    if (!hasInternet) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Tidak Ada Koneksi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Mohon maaf, aplikasi STESY Mobile memerlukan koneksi internet untuk menarik data terbaru. '
            'Silakan periksa pengaturan jaringan Anda dan pastikan perangkat terhubung ke internet, lalu coba kembali.',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retry checking
                _checkAuth();
              },
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  color: Color(0xFF2E3B84),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return; // Stop the flow until they retry
    }

    // ── Check App Config for Version Update ──
    try {
      final dio = Dio();
      final response = await dio.get(
        '$kBaseUrl/api/v1/mobile/auth/config',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );

      if (response.data != null && response.data['success'] == true) {
        final config = response.data['data'];
        final latestVersion = config['latest_app_version'] ?? '1.0.0';
        final forceUpdate = config['force_update'] ?? false;
        final updateUrl = config['update_url'] ?? '';

        if (_isUpdateRequired(_version, latestVersion)) {
          if (!mounted) return;

          await showDialog(
            context: context,
            barrierDismissible: !forceUpdate,
            builder: (context) => PopScope(
              canPop: !forceUpdate,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.system_update,
                      color: forceUpdate ? Colors.red : const Color(0xFF2E3B84),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pembaruan Tersedia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  forceUpdate
                      ? 'Versi aplikasi Anda sudah usang. Anda wajib memperbarui aplikasi ke versi $latestVersion untuk dapat melanjutkan.'
                      : 'Versi terbaru ($latestVersion) telah tersedia. Perbarui sekarang untuk mendapatkan fitur terbaru dan perbaikan sistem.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                actions: [
                  if (!forceUpdate)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Nanti Saja',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () async {
                      if (updateUrl.isNotEmpty) {
                        final uri = Uri.parse(updateUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                      if (!forceUpdate) Navigator.of(context).pop();
                    },
                    child: Text(
                      'Update Sekarang',
                      style: TextStyle(
                        color: forceUpdate
                            ? Colors.red
                            : const Color(0xFF2E3B84),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          if (forceUpdate) return; // Stop Splash flow if forced update
        }
      }
    } catch (e) {
      print('Config check failed: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/onboarding');
      return;
    }

    final isLoggedIn = await AuthRepository().isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/beranda');
      _openPendingWarningNotificationIfAny();
      _showPendingUpdateNotificationIfAny();
    } else {
      _pendingWarningNotificationData = null;
      Navigator.of(context).pushReplacementNamed('/login');
      _showPendingUpdateNotificationIfAny();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Konten Tengah (Ilustrasi & Loading) — ScaleTransition hanya di sini
          Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Transform.translate(
                offset: const Offset(0, -80), // Ilustrasi & loading dinaikkan ke atas
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/login-page.png',
                      width: 320,
                      height: 320,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 48),
                    const CircularProgressIndicator(
                      color: Color(0xFF2B3377),
                      strokeWidth: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Logo Bawah (Dipaku di paling bawah layar)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 60.0,
              ), // Disesuaikan agar ada ruang untuk teks versi
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo 1.png',
                        height: 28, // Ukuran logo dikecilkan
                      ),
                      const SizedBox(width: 24), // Jarak antara kedua logo
                      Image.asset(
                        'assets/images/mini_stesy 1.png',
                        height: 28, // Ukuran logo dikecilkan
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_version.isNotEmpty)
                    Text(
                      _version,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
