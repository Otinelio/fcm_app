import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/reward_screen.dart';
import 'screens/promo_screen.dart';
import 'services/api_service.dart';
import 'services/fcm_services.dart';
import 'services/notification_router.dart';

// Fonction top-level obligatoire (pas dans une classe !)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Doit rester minimal : pas d'accès UI ici.
}

// Clé de navigation globale pour pouvoir naviguer depuis n'importe où
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await dotenv.load(fileName: ".env");

  // Initialisation des notifications locales (Foreground)
  final fcmService = FcmService();
  await fcmService.initLocalNotifications();
  fcmService.listenForegroundMessages();

  // Cas 1 : app en arrière-plan, l'utilisateur tape sur la notification système
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    handleNotificationTap(navigatorKey, message.data);
  });

  // Cas 2 : app totalement fermée, ouverte via tap sur la notification
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      handleNotificationTap(navigatorKey, message.data);
    }
  });

  final token = await ApiService.getToken();

  runApp(RestaurantLoyaltyApp(isLoggedIn: token != null));
}

class RestaurantLoyaltyApp extends StatelessWidget {
  final bool isLoggedIn;
  const RestaurantLoyaltyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Loyalty App',
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      home: isLoggedIn ? const MainLayout() : const LoginScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/notifications': (context) => const NotificationsScreen(),
        '/reward': (context) => const RewardScreen(),
        '/promo': (context) => const PromoScreen(),
      },
    );
  }
}
