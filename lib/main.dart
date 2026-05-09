import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/beranda/screens/beranda_screen.dart';
import 'features/peta/screens/peta_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'shared/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage/secure_storage.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");

  if (message.data['type'] == 'force_logout') {
    print("Silent push received in background. Forcing logout.");
    await SecureStorage.clearAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_suspend_message', message.data['reason'] ?? 'Akun Anda telah dinonaktifkan.');
  } else if (message.data['type'] == 'password_changed') {
    print("Silent push received in background (Password changed). Clean logout.");
    await SecureStorage.clearAll();
  }
}

// Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  importance: Importance.high,
);

// ==== GLOBAL NAVIGATOR KEY ====
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Config local notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highImportanceChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
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
        '/login':   (_) => const LoginScreen(),
        '/beranda': (_) => const BerandaScreen(),
        '/peta':    (_) => const PetaScreen(),
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    
    _setupFCM();
    _checkAuth();
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

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("=== TERIMA PESAN FCM DI FOREGROUND! ===");
      print("Title: ${message.notification?.title}");
      print("Body: ${message.notification?.body}");
      print("Data: ${message.data}");
      
      if (message.data['type'] == 'force_logout') {
        print("Silent push received in foreground. Forcing logout.");
        await SecureStorage.clearAll();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_suspend_message', message.data['reason'] ?? 'Akun Anda telah dinonaktifkan.');
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil('/login', (route) => false);
        }
        return; // Jangan tampilkan notifikasi lokal untuk silent push
      } else if (message.data['type'] == 'password_changed') {
        print("Silent push received in foreground (Password changed). Clean logout.");
        await SecureStorage.clearAll();
        // Tendang ke login tanpa pesan peringatan merah
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil('/login', (route) => false);
        }
        return;
      }

      RemoteNotification? notification = message.notification;
      final title = notification?.title ?? message.data['title'] ?? message.data['judul'];
      final body = notification?.body ?? message.data['body'] ?? message.data['message'] ?? message.data['pesan'];

      if (title != null || body != null) {
        flutterLocalNotificationsPlugin.show(
          id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
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
        );
      }
    });
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Check Internet Connection
    bool hasInternet = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                style: TextStyle(color: Color(0xFF2E3B84), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return; // Stop the flow until they retry
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
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
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
      body: ScaleTransition(
        scale: _scaleAnim,
        child: Stack(
          children: [
            // Konten Tengah (Ilustrasi & Loading)
            Center(
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

            // Logo Bawah (Dipaku di paling bawah layar)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100.0), // Jarak dari ujung bawah layar diperbesar agar posisinya lebih naik
                child: Row(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
