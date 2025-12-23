import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isAdmin;

  const ReportDetailScreen({
    super.key,
    required this.doc,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    var data = doc.data() as Map<String, dynamic>;
    var analysis = data['aiAnalysis'] as Map<String, dynamic>? ?? {};

    // Check if we actually have a valid URL (longer than just "http")
    String imageUrl = data['imageUrl'] ?? '';
    bool hasImage = imageUrl.length > 10;

    String status = analysis['status'] ?? 'PENDING';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Report Details"),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ 1. HEADER SECTION (Image or Gradient)
            SizedBox(
              height: 250,
              width: double.infinity,
              child: hasImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => _buildStylishPlaceholder(),
                    )
                  : _buildStylishPlaceholder(), // 👈 Now shows a cool design instead of error text
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏷️ 2. HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          analysis['issueType'] ?? "Issue Report",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      _statusChip(status),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🤖 3. AI ANALYSIS
                  _sectionTitle("AI Assessment"),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _detailRow(
                          Icons.business,
                          "Department",
                          analysis['department'] ?? "General",
                        ),
                        const Divider(color: Colors.white10),
                        _detailRow(
                          Icons.timer_outlined,
                          "Urgency",
                          analysis['urgency'] ?? "Normal",
                        ),
                        const Divider(color: Colors.white10),
                        _detailRow(
                          Icons.warning_amber,
                          "Severity",
                          analysis['severity'] ?? "Medium",
                        ),
                        const Divider(color: Colors.white10),
                        _detailRow(
                          Icons.summarize,
                          "Summary",
                          analysis['summary'] ?? "No summary provided.",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 📝 4. DESCRIPTION
                  _sectionTitle("Citizen Description"),
                  Text(
                    data['description'] ?? "No description provided.",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),

                  // 👮 5. ADMIN ACTIONS
                  if (isAdmin) ...[
                    const SizedBox(height: 30),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),
                    const Text(
                      "Admin Actions",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                            ),
                            icon: const Icon(Icons.engineering),
                            label: const Text("WORK STARTED"),
                            onPressed: () =>
                                _updateStatus(context, doc.id, 'IN PROGRESS'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.check_circle),
                            label: const Text("RESOLVE"),
                            onPressed: () =>
                                _updateStatus(context, doc.id, 'RESOLVED'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 NEW: A Stylish Gradient Header (Instead of "Missing Image")
  Widget _buildStylishPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Icon(
          Icons
              .location_city_rounded, // Looks intentional, like a category icon
          size: 80,
          color: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00E5FF),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    Color textColor = (label == "Urgency" && value == "Immediate")
        ? Colors.redAccent
        : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = status == 'RESOLVED'
        ? Colors.green
        : (status == 'IN PROGRESS' ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _updateStatus(BuildContext context, String docId, String newStatus) {
    FirebaseFirestore.instance.collection('reports').doc(docId).update({
      'aiAnalysis.status': newStatus,
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Status updated to $newStatus")));
    Navigator.pop(context);
  }
}
