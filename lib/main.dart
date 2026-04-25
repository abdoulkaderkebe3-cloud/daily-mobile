import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_app_screen.dart';
import 'components/notification_bubble.dart';
import 'components/image_zoom.dart';

import 'package:google_fonts/google_fonts.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialiser();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const TheDailyMuseApp(),
    ),
  );
}

class TheDailyMuseApp extends StatelessWidget {
  const TheDailyMuseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.select<AppProvider, String>((p) => p.theme);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Daily Muse',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        primaryColor: const Color(0xFF111111),
        cardColor: const Color(0xFFFFFFFF),
        dividerColor: const Color(0xFFE2E2E5),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme.apply(bodyColor: const Color(0xFF1F1F1F)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF09090B),
        primaryColor: const Color(0xFFFFFFFF),
        cardColor: const Color(0xFF18181B),
        dividerColor: const Color(0xFF27272A),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme.apply(bodyColor: const Color(0xFFEDEDED)),
        ),
      ),
      themeMode: theme == 'dark' ? ThemeMode.dark : ThemeMode.light,
      home: const AppContent(),
    );
  }
}

class AppContent extends StatefulWidget {
  const AppContent({super.key});

  @override
  AppContentState createState() => AppContentState();
}

class AppContentState extends State<AppContent> {
  bool _afficherBienvenue = false;

  void onLoginOrRegisterSuccess() {
    setState(() {
      _afficherBienvenue = true;
    });
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) {
        setState(() {
          _afficherBienvenue = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final isLoadingUtilisateur = context.select<AppProvider, bool>((p) => p.isLoadingUtilisateur);
    final user = context.select<AppProvider, Map<String, dynamic>?>((p) => p.donneesUtilisateur);
    final imageZoomee = context.select<AppProvider, String?>((p) => p.imageZoomee);
    final notification = context.select<AppProvider, NotificationData>((p) => p.notification);

    return Scaffold(
      body: Stack(
        children: [
          // Main content logic
          if (isLoadingUtilisateur)
            const LoadingScreen()
          else if (user == null && !_afficherBienvenue)
            AuthScreen(onSuccess: onLoginOrRegisterSuccess)
          else if (_afficherBienvenue)
            WelcomeScreen(
              onTermine: () {
                setState(() {
                  _afficherBienvenue = false;
                });
              },
            )
          else if (user != null)
            const MainAppScreen(),

          // Image Zoom Layer
          if (imageZoomee != null)
            ImageZoom(
              imageUrl: imageZoomee,
              onFermer: () => provider.setImageZoomee(null),
            ),
            
          // Notification Layer
          if (notification.visible)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: NotificationBubble(
                message: notification.message,
                type: notification.type,
              ),
            ),
        ],
      ),
    );
  }
}
