import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../main.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Get Current User Data
    final User? user = AuthService().currentUser;

    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          // 1. HEADER
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6D00), Color(0xFFFF9E40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              user?.displayName ?? "FixCity User",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(user?.email ?? "No Email"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Icon(Icons.person, size: 40, color: Colors.grey.shade800)
                  : null,
            ),
          ),

          // 2. MENU ITEMS
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(context, Icons.home, "Home", () {
                  // Go to root (StreamBuilder handles the rest)
                  Navigator.pop(context); // Close drawer
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }),

                _buildDrawerItem(
                  context,
                  Icons.dashboard,
                  "City Dashboard",
                  () async {
                    Navigator.pop(context);
                    String role = await AuthService().getUserRole();
                    if (context.mounted) {
                      Navigator.pushNamed(context, '/admin', arguments: role);
                    }
                  },
                ),

                _buildDrawerItem(context, Icons.person, "My Profile", () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                }),

                const Divider(color: Colors.grey),

                _buildDrawerItem(context, Icons.info_outline, "About", () {
                  showAboutDialog(
                    context: context,
                    applicationName: "FixCity",
                    applicationVersion: "1.0.0",
                    applicationIcon: const Icon(
                      Icons.location_city,
                      color: Colors.orange,
                      size: 50,
                    ),
                    children: [
                      const Text("Built for the City Hackathon 2025."),
                    ],
                  );
                }),
              ],
            ),
          ),

          // 3. LOGOUT BUTTON (FIXED)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildDrawerItem(context, Icons.logout, "Log Out", () async {
              // 1. Close the drawer first
              Navigator.pop(context);

              // 2. Sign out from Firebase
              await AuthService().signOut();

              // 3. 🚨 CRITICAL FIX: Pop everything until we hit the 'Root' (main.dart)
              // This forces the StreamBuilder in main.dart to see "User is null" and show AuthScreen.
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
