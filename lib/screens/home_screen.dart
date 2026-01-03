import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 Added
import 'package:firebase_auth/firebase_auth.dart'; // 👈 Added

import '../services/translator.dart';
import '../services/auth_service.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentRole = "Citizen";
  String _userName = "Hero";

  final List<String> _heroImages = [
    'assets/images/img1.png',
    'assets/images/img2.png',
    'assets/images/img3.png',
    'assets/images/img4.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // 1. Load Role
    String role = await AuthService().getUserRole();

    // 2. Load Display Name
    final user = FirebaseAuth.instance.currentUser;
    String name = user?.displayName ?? "Citizen";

    if (mounted) {
      setState(() {
        _currentRole = role;
        _userName = name;
      });
    }
  }

  void _changeLanguage(String langCode) {
    setState(() {
      Translator.currentLang = langCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          // --- HERO HEADER (Dynamic) ---
          SliverAppBar(
            expandedHeight: 280.0,
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroHeader(), // Now creates the StreamBuilder
            ),
          ),

          // --- BODY CONTENT ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLanguageSelector(),
                  const SizedBox(height: 30),

                  // 📸 SLIDESHOW
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 150.0,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 4),
                      autoPlayAnimationDuration: const Duration(
                        milliseconds: 800,
                      ),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enlargeCenterPage: false,
                      viewportFraction: 1.0,
                    ),
                    items: _heroImages.map((imagePath) {
                      return Builder(
                        builder: (BuildContext context) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (c, o, s) => Container(
                                color: Colors.grey.shade900,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),

                  // --- ACTION CARDS ---
                  _buildActionCard(
                    context,
                    title: Translator.t('report_issue'),
                    description:
                        "Spot a pothole or broken light? Snap a photo and let AI analyze it.",
                    icon: Icons.camera_alt_outlined,
                    color: const Color(0xFFFF6D00),
                    onTap: () => Navigator.pushNamed(context, '/upload'),
                  ),
                  const SizedBox(height: 20),
                  _buildActionCard(
                    context,
                    title: Translator.t('dashboard'),
                    description:
                        "View live status of complaints (Admin controls hidden for Citizens).",
                    icon: Icons.dashboard_outlined,
                    color: const Color(0xFF00E5FF),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/admin',
                        arguments: _currentRole,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildActionCard(
                    context,
                    title: Translator.t('leaderboard'),
                    description: Translator.t(
                      'Earn XP by reporting issues. Climb the ranks to become a City Legend!',
                    ),
                    icon: Icons.emoji_events_outlined,
                    color: const Color(0xFFFFD700),
                    onTap: () => Navigator.pushNamed(context, '/leaderboard'),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✨ THE DYNAMIC HERO HEADER
  Widget _buildHeroHeader() {
    final user = FirebaseAuth.instance.currentUser;

    // If no user logged in, show default static header
    if (user == null) return _buildStaticHeaderContent(0);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int xp = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          xp = data['totalXP'] ?? 0;
        }
        return _buildStaticHeaderContent(xp);
      },
    );
  }

  Widget _buildStaticHeaderContent(int currentXP) {
    // 🧠 LOGIC: Calculate Rank & Progress
    String rankTitle = "ROOKIE";
    int nextLevelTarget = 100;

    if (currentXP >= 1000) {
      rankTitle = "LEGEND";
      nextLevelTarget = 5000; // Harder to level up at top
    } else if (currentXP >= 500) {
      rankTitle = "EXPERT";
      nextLevelTarget = 1000;
    } else if (currentXP >= 100) {
      rankTitle = "SCOUT";
      nextLevelTarget = 500;
    }

    // Calculate Percentage (0.0 to 1.0)
    // Avoid division by zero
    double progress = (currentXP / nextLevelTarget).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Icon(
              Icons.location_city,
              size: 250,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6D00).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    "RANK • $rankTitle", // 👈 Now Dynamic!
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Welcome, $_userName!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  Translator.t('app_title'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 25),

                // XP Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "XP Progress",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      "$currentXP / $nextLevelTarget XP", // 👈 Now Dynamic!
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress, // 👈 Now Dynamic!
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00E5FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... (Language Selector & Action Cards remain identical) ...

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
