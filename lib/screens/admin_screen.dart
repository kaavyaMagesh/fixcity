import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// We use this to format the date nicely
// If you don't have intl package, we use a simple manual helper below.

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. GET THE ROLE
    final String userRole =
        ModalRoute.of(context)!.settings.arguments as String? ?? 'Citizen';
    final bool isAdmin = userRole == 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? "ADMIN CONTROL PANEL" : "PUBLIC DASHBOARD"),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("Something went wrong"));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No reports yet. Good job! 🏙️"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data();
              var analysis = data['aiAnalysis'] as Map<String, dynamic>? ?? {};
              String status = analysis['status'] ?? 'PENDING';
              String docId = docs[index].id;

              return _buildAdminCard(
                context,
                data,
                analysis,
                status,
                docId,
                isAdmin,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    Map<String, dynamic> data,
    Map analysis,
    String status,
    String docId,
    bool isAdmin,
  ) {
    // Color Logic
    Color statusColor;
    if (status == 'RESOLVED')
      statusColor = Colors.greenAccent;
    else if (status == 'IN PROGRESS')
      statusColor = Colors.orangeAccent;
    else
      statusColor = Colors.redAccent;

    // 🕒 DATE PARSING
    String timeString = "Just Now";
    if (data['timestamp'] != null) {
      Timestamp t = data['timestamp'];
      DateTime dt = t.toDate();
      timeString =
          "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }

    // 📍 LOCATION PARSING
    String locString = "Unknown";
    if (data['location'] != null) {
      double lat = data['location']['lat'];
      double lng = data['location']['lng'];
      locString = "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
    }

    // ⚠️ SEVERITY PARSING
    String severity = analysis['severity'] ?? "Medium";

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER (Title + Delete) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    analysis['issueType'] ?? "Unknown Issue",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () => _confirmDelete(context, docId),
                  ),
              ],
            ),

            // --- INFO BADGES ROW (Updated!) ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Status Badge
                  _infoBadge(status, statusColor, Icons.info_outline),
                  const SizedBox(width: 8),

                  // Severity Badge (Red for High)
                  _infoBadge(
                    severity,
                    severity == 'High' ? Colors.red : Colors.orange,
                    Icons.warning_amber,
                  ),
                  const SizedBox(width: 8),

                  // Time Badge
                  _infoBadge(timeString, Colors.blueGrey, Icons.access_time),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- LOCATION ---
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(
                  locString,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --- DESCRIPTION ---
            Text(
              data['description'] ?? "No description provided.",
              style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
            ),

            // --- ADMIN BUTTONS ---
            if (isAdmin) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _updateStatus(docId, 'IN PROGRESS'),
                      icon: const Icon(
                        Icons.engineering,
                        color: Colors.orange,
                        size: 18,
                      ),
                      label: const Text(
                        "WORKING",
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _updateStatus(docId, 'RESOLVED'),
                      icon: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                      label: const Text(
                        "DONE",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper for little colored badges
  Widget _infoBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String docId, String newStatus) {
    FirebaseFirestore.instance.collection('reports').doc(docId).update({
      'aiAnalysis.status': newStatus,
    });
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          "Delete Report?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Cannot be undone.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('reports')
                  .doc(docId)
                  .delete();
              Navigator.pop(ctx);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
