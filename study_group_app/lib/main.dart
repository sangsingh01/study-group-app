// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/profile_provider.dart';
import 'theme.dart';
import 'services/database_service.dart';

// Imported your splash screen as the startup point
import 'screens/splash_screen.dart';

// 🌟 FIX 3: Declared the global key to manage background context navigation routing
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(DatabaseService()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Group App',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // 🌟 FIX 3: Registered global key with MaterialApp
      theme: AppTheme.lightTheme(),
      // The app boots up into the splash screen animation, which then forwards to AuthWrapper
      home: const SplashScreen(), 
    );
  }
}