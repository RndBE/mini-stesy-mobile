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

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

// Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Config local notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
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

  void _setupFCM() {
    FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
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
