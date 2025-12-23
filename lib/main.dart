import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

// Screen Imports
import 'screens/upload_screen.dart';
import 'screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load Environment variables (API Key)
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

      // 🎨 THEME: DARK MODE + NEON ORANGE
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Deep Black
        primaryColor: const Color(0xFFFF6D00), // Safety Orange

        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6D00),
          secondary: Color(0xFF00E5FF), // Cyan for AI accents
          surface: Color(0xFF1E1E1E), // Card Background
        ),

        useMaterial3: true,

        // Input Fields Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),

        // Buttons Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6D00),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // App Bar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),

      // 🚦 ROUTES
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/upload': (context) => const UploadScreen(),
        '/admin': (context) => const AdminScreen(),
      },
    );
  }
}

// 🏠 PROFESSIONAL HOME SCREEN
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Simulating a Role Switcher
  String _currentRole = "Citizen";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. TOP BAR with ROLE SWITCHER
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentRole,
                dropdownColor: const Color(0xFF2C2C2C),
                icon: const Icon(Icons.swap_horiz, color: Color(0xFFFF6D00)),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                items: ["Citizen", "Admin"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _currentRole = newValue!;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Switched to $newValue Mode 🔄")),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // 2. SCROLLABLE BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BRANDING SECTION ---
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  // Logo / Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6D00).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_city_rounded,
                      size: 80,
                      color: Color(0xFFFF6D00),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // App Name
                  const Text(
                    "FIXCITY",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "AI-POWERED INFRASTRUCTURE",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- ILLUSTRATION IMAGE ---
            // 🖼️ ENSURE 'assets/images/city_view.png' EXISTS!
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/city_view.png', // <--- Your Local Image
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(
                  height: 150,
                  color: Colors.grey.shade900,
                  child: const Center(
                    child: Text("Image Not Found (Check assets)"),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- ACTION BUTTONS (CARDS) ---

            // BUTTON 1: REPORT ISSUE
            _buildActionCard(
              context,
              title: "Report Complaint",
              description:
                  "Spot a pothole or broken light? Snap a photo and let AI analyze it.",
              icon: Icons.camera_alt_outlined,
              color: const Color(0xFFFF6D00),
              onTap: () => Navigator.pushNamed(context, '/upload'),
            ),

            const SizedBox(height: 20),

            // BUTTON 2: CITY DASHBOARD
            _buildActionCard(
              context,
              title: "City Dashboard",
              description:
                  "View live status of complaints (Admin controls hidden for Citizens).",
              icon: Icons.dashboard_outlined,
              color: const Color(0xFF00E5FF),
              onTap: () {
                // 👇 KEY CHANGE IS HERE: Passing arguments
                Navigator.pushNamed(
                  context,
                  '/admin',
                  arguments: _currentRole, // <--- Sending "Citizen" or "Admin"
                );
              },
            ),

            const SizedBox(height: 40), // Bottom padding for scrolling
          ],
        ),
      ),
    );
  }

  // Helper Widget to make the buttons look like cool cards
  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade700,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
