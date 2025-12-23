import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

// Screen Imports
import 'screens/upload_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/app_drawer.dart';

// 👇 1. IMPORT THE TRANSLATOR HELPER
import 'services/translator.dart';

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
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFFF6D00),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6D00),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
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
        '/profile': (context) => const ProfileScreen(),
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
  String _currentRole = "Citizen";

  // 👇 2. FUNCTION TO SWITCH LANGUAGE
  void _changeLanguage(String langCode) {
    setState(() {
      Translator.currentLang = langCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
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

                  // 👇 3. TRANSLATED APP TITLE
                  Text(
                    Translator.t('app_title'), // "FIXCITY"
                    style: const TextStyle(
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

                  const SizedBox(height: 20),

                  // 👇 4. LANGUAGE SELECTOR WIDGET
                  _buildLanguageSelector(),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- ILLUSTRATION ---
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/city_view.png',
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

            // --- CARDS ---
            // Report Button
            _buildActionCard(
              context,
              title: Translator.t('report_issue'), // 👈 Translated
              description:
                  "Spot a pothole or broken light? Snap a photo and let AI analyze it.",
              icon: Icons.camera_alt_outlined,
              color: const Color(0xFFFF6D00),
              onTap: () => Navigator.pushNamed(context, '/upload'),
            ),

            const SizedBox(height: 20),

            // Dashboard Button
            _buildActionCard(
              context,
              title: Translator.t('dashboard'), // 👈 Translated
              description:
                  "View live status of complaints (Admin controls hidden for Citizens).",
              icon: Icons.dashboard_outlined,
              color: const Color(0xFF00E5FF),
              onTap: () {
                Navigator.pushNamed(context, '/admin', arguments: _currentRole);
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 👇 5. LANGUAGE BUTTON BUILDER
  Widget _buildLanguageSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _langButton("ENG", "en"),
        const SizedBox(width: 10),
        _langButton("தமிழ்", "ta"),
        const SizedBox(width: 10),
        _langButton("हिंदी", "hi"),
      ],
    );
  }

  Widget _langButton(String label, String code) {
    bool isActive = Translator.currentLang == code;
    return GestureDetector(
      onTap: () => _changeLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF6D00) : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey.shade700,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

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
