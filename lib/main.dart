import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // Uncomment after Firebase setup
// import 'firebase_options.dart'; // Uncomment after Firebase setup

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FixCityApp());
}

class FixCityApp extends StatelessWidget {
  const FixCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixCity MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        '/upload': (context) => const UploadScreen(),
        '/admin': (context) => const AdminScreen(),
      },
    );
  }
}

// ==================== 1. HOME SCREEN ====================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FixCity 🚧')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_city, size: 100, color: Colors.orange),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/upload'),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Report Issue (Citizen)"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/admin'),
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text("Admin Dashboard"),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 2. UPLOAD SCREEN ====================
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Report')),
      body: const Center(child: Text("TODO: Add Camera & Input Form")),
    );
  }
}

// ==================== 3. ADMIN SCREEN ====================
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('City Admin Dashboard')),
      body: const Center(child: Text("TODO: Add Firestore List")),
    );
  }
}
