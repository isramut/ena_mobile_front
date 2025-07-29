import 'package:ena_mobile_front/common/ena_main_layout.dart';
import 'package:ena_mobile_front/features/apply/ena_apply_content.dart';
import 'package:ena_mobile_front/features/auth/forgot_password_screen.dart';
import 'package:ena_mobile_front/features/auth/login_screen.dart';
import 'package:ena_mobile_front/features/auth/register_screen.dart';
import 'package:ena_mobile_front/features/contact/contact_page.dart';
import 'package:ena_mobile_front/features/home/ena_home_content.dart';
import 'package:ena_mobile_front/features/news/ena_news_content.dart';
import 'package:ena_mobile_front/features/parametres/parametre_screen.dart';
import 'package:ena_mobile_front/features/prepa/prepa_ena_content.dart';
import 'package:ena_mobile_front/features/profile/profile_screen.dart';
import 'package:ena_mobile_front/features/recours/recours_screen.dart';
import 'package:ena_mobile_front/common/theme_provider.dart';
import 'package:ena_mobile_front/common/app_themes.dart';
import 'package:ena_mobile_front/common/mobile_platform_config.dart';
import 'package:ena_mobile_front/services/biometric_service.dart';
import 'package:ena_mobile_front/services/firebase_analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'common/splash_screen.dart';

// Configuration spécifique Android/iOS pour ENA Mobile

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp();

  // Charger les variables d'environnement
  await dotenv.load(fileName: ".env");

  // Configuration optimisée pour Android et iOS
  MobilePlatformConfig.configurePlatform();

  // Tracker l'ouverture de l'application
  await FirebaseAnalyticsService.trackAppOpened();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'ENA RDC',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.themeMode,
          navigatorObservers: [
            FirebaseAnalyticsService.observer,
          ],
          supportedLocales: const [
            Locale('fr', ''), // Français
            Locale('en', ''), // Anglais
            Locale('sw', ''), // Swahili
            Locale('ln', ''), // Lingala
            Locale('kg', ''), // Kikongo
            Locale('ts', ''), // Tshiluba
            // Ajoute d'autres locales si nécessaire
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            // Ajoute ici les délégués de localisation si nécessaire
          ],
          home: const SplashScreen(),
          // Pour garder la cohérence de navigation
          routes: {
            '/register': (_) => const RegisterScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/recours': (_) => const RecoursScreen(),
            // Ajoute d'autres routes auth-only si nécessaire
          },
        );
      },
    );
  }
}

class MainRouter extends StatefulWidget {
  const MainRouter({super.key});

  @override
  State<MainRouter> createState() => _MainRouterState();
}

class _MainRouterState extends State<MainRouter> {
  int selectedIndex = 0;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (mounted) {
      setState(() {
        isLoggedIn = loggedIn;
      });
    }
  }

  void handleLoginSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    if (mounted) {
      setState(() {
        isLoggedIn = true;
        selectedIndex = 0;
      });
    }
  }

  void handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Gérer le logout biométrique correctement
    await BiometricAuthService.handleUserLogout();
    
    // Ne pas effacer TOUTES les données - préserver les paramètres biométriques
    await prefs.remove('isLoggedIn');
    await prefs.remove('auth_token');
    // Préserver 'user_email' et les paramètres biométriques pour permettre la reconnexion
    
    setState(() => isLoggedIn = false);
  }

  void handleMenuChanged(int idx) {
    setState(() => selectedIndex = idx);
  }

  // Le tableau des pages (index : menu/layout)
  List<Widget> get _mainPages => [
    AccueilScreen(onMenuChanged: handleMenuChanged),
    const ActualitesScreen(),
    const PostulerContent(),
    PrepaEnaContent(onMenuChanged: handleMenuChanged),
    const ContactPage(),
    const ProfileScreen(),
    const ParametreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return LoginScreen(onLoginSuccess: handleLoginSuccess);
    } else {
      // 2. Une fois connecté, tout passe dans le layout global
      return EnaMainLayout(
        selectedIndex: selectedIndex,
        onMenuChanged: handleMenuChanged,
        pageBuilder: (ctx) => _mainPages[selectedIndex],
        onAvatarTap: handleLogout,
      );
    }
  }
}
