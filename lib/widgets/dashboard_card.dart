import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String status; // "ASSIGNED", "ANALYZED", "PENDING"
  final String severity; // "Critical", "Moderate", "Low"

  const DashboardCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.status,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    // 1. SAFE COLOR LOGIC (Prevents crashes if status is weird)
    Color badgeColor;
    if (status == "ASSIGNED") {
      badgeColor = Colors.green;
    } else if (status == "ANALYZED") {
      badgeColor = Colors.blue;
    } else {
      badgeColor = Colors.orange; // Default for "PENDING"
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark card bg
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === IMAGE AREA ===
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // 👇 ANTI-CRASH PROTECTION: Shows icon if image fails
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 50,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: Colors.grey[900],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),

              // Status Badge (Top Right)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Severity Overlay (Bottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        // Red for critical, Orange for others
                        color: severity == "Critical"
                            ? Colors.redAccent
                            : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Severity: $severity",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // === TEXT CONTENT ===
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title.toUpperCase(), // e.g., "POTHOLE"
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "#R-${DateTime.now().minute}", // Fake Ticket ID
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                Divider(color: Colors.grey[800], height: 1),
                const SizedBox(height: 10),

                // Footer Row
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "Chennai, IN", // Hardcoded for MVP
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "Just now",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
