import 'package:flutter/material.dart';
import 'dart:io';
import '../services/fcm_services.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initFcm();
  }

  Future<void> _initFcm() async {
    // Si la session était valide (auto-login), on rafraîchit le token FCM
    final fcmService = FcmService();
    await fcmService.initAfterLogin(
      onTokenReady: (token) async {
        debugPrint('====================================');
        debugPrint('FCM TOKEN READY (Auto-login): $token');
        debugPrint('====================================');
        
        // Envoi au backend Laravel via ApiService
        final platform = Platform.isAndroid ? 'android' : 'ios';
        await ApiService.registerDeviceToken(token, platform);
      },
    );
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const NotificationsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
