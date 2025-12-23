import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          // 1. BIG HEADER with User Info
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6D00), Color(0xFFFF9E40)],
              ),
            ),
            accountName: const Text(
              "Citizen User",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: const Text("citizen@fixcity.app"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.grey.shade800),
            ),
          ),

          // 2. MENU ITEMS
          _buildDrawerItem(context, Icons.home, "Home", () {
            Navigator.pop(context); // Close drawer
            Navigator.pushNamed(context, '/'); // Go Home
          }),

          _buildDrawerItem(context, Icons.dashboard, "City Dashboard", () {
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              '/admin',
              arguments: 'Citizen',
            ); // Default to Citizen
          }),

          _buildDrawerItem(context, Icons.person, "My Profile", () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/profile'); // We will make this next!
          }),

          const Spacer(), // Pushes everything down
          const Divider(color: Colors.grey),

          _buildDrawerItem(context, Icons.info_outline, "About & Version", () {
            showAboutDialog(
              context: context,
              applicationName: "FixCity",
              applicationVersion: "1.0.0",
              applicationIcon: const Icon(
                Icons.location_city,
                color: Colors.orange,
              ),
              children: [const Text("Built for the City Hackathon 2025.")],
            );
          }),

          _buildDrawerItem(context, Icons.logout, "Log Out", () {
            // Simulate Logout
            Navigator.pushReplacementNamed(context, '/');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Logged out successfully.")),
            );
          }),

          const SizedBox(height: 20),
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
