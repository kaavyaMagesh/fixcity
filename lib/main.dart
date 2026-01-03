import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// Screen Imports
import 'screens/upload_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/contractor_login_screen.dart'; // 👈 NEW
import 'screens/contractor_dashboard_screen.dart'; // 👈 NEW (Create this file next)
import 'screens/home_screen.dart'; 

// Service Imports
import 'services/translator.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  runApp(const FixCityApp());
}

class FixCityApp extends StatelessWidget {
  const FixCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixCity',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFFF6D00),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6D00),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),

      // UPDATED AUTH GATEWAY
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          
          if (snapshot.hasData) {
            // Use a FutureBuilder to check the role claim before deciding the home screen
            return FutureBuilder<IdTokenResult>(
              future: snapshot.data!.getIdTokenResult(),
              builder: (context, tokenSnapshot) {
                if (tokenSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }

                final role = tokenSnapshot.data?.claims?['role'];

                if (role == 'admin') {
                  return const AdminScreen();
                } else if (role == 'contractor') {
                  return const ContractorDashboardScreen(); // 👈 New View
                } else {
                  return const HomeScreen(); // Default for Citizens
                }
              },
            );
          }
          return const AuthScreen();
        },
      ),

      routes: {
        '/upload': (context) => const UploadScreen(),
        '/admin': (context) => const AdminScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/auth': (context) => const AuthScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/admin_login': (context) => const AdminLoginScreen(),
        '/contractor_login': (context) => const ContractorLoginScreen(), // 👈 NEW
        '/admin_dashboard': (context) => const AdminScreen(),
        '/contractor_dashboard': (context) => const ContractorDashboardScreen(), // 👈 NEW
      },
    );
  }
}