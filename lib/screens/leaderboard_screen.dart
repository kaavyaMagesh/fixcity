import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("City Leaderboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query users collection ordered by totalXP descending
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('totalXP', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading data", style: TextStyle(color: Colors.white)));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              var userData = users[index].data() as Map<String, dynamic>;
              int rank = index + 1;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: rank <= 3 
                    ? Border.all(color: const Color(0xFFFF6D00).withOpacity(0.5), width: 1)
                    : null,
                ),
                child: ListTile(
                  leading: _buildRankCircle(rank),
                  title: Text(
                    userData['name'] ?? 'Anonymous',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${userData['role'] ?? 'Citizen'}",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  trailing: Text(
                    "${userData['totalXP'] ?? 0} XP",
                    style: const TextStyle(
                      color: Color(0xFFFF6D00),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRankCircle(int rank) {
    Color circleColor = Colors.grey.shade800;
    Widget content = Text("$rank", style: const TextStyle(color: Colors.white));

    if (rank == 1) {
      circleColor = const Color(0xFFFFD700); // Gold
      content = const Icon(Icons.emoji_events, color: Colors.black, size: 20);
    } else if (rank == 2) {
      circleColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      circleColor = const Color(0xFFCD7F32); // Bronze
    }

    return CircleAvatar(
      backgroundColor: circleColor,
      radius: 18,
      child: content,
    );
  }
}