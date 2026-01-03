import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 Import Firestore
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = AuthService().currentUser;

    final String displayName = user?.displayName ?? "Citizen User";
    final String email = user?.email ?? "citizen@fixcity.app";
    final String? photoUrl = user?.photoURL;

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 📸 AVATAR SECTION
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF6D00),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6D00).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white70,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 📊 LIVE STATS ROW (STREAM BUILDER)
            // This listens to the 'users' collection for changes
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                // Default values if loading or no data
                String reports = "0";
                String xp = "0";
                String rank = "Rookie";

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  int xpVal = data['totalXP'] ?? 0;
                  int reportVal = data['reportCount'] ?? 0;

                  reports = reportVal.toString();
                  xp = xpVal.toString();

                  // Simple Rank Logic
                  if (xpVal > 1000)
                    rank = "Legend";
                  else if (xpVal > 500)
                    rank = "Expert";
                  else if (xpVal > 100)
                    rank = "Scout";
                }

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat(reports, "Reports"),
                      _buildContainerDivider(),
                      _buildStat(xp, "Total XP"), // 👈 Shows real XP
                      _buildContainerDivider(),
                      _buildStat(rank, "Rank"),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // ⚙️ SETTINGS LIST
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Settings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),

            _buildSettingTile(Icons.notifications, "Notifications", true),
            _buildSettingTile(Icons.dark_mode, "Dark Mode", true),

            const Divider(color: Colors.grey, height: 40),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                "Log Out",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6D00),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildContainerDivider() {
    return Container(height: 30, width: 1, color: Colors.white10);
  }

  Widget _buildSettingTile(IconData icon, String title, bool isSwitched) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: const Color(0xFF1E1E1E),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Switch(
          value: isSwitched,
          activeColor: const Color(0xFFFF6D00),
          onChanged: (val) {},
        ),
      ),
    );
  }
}
