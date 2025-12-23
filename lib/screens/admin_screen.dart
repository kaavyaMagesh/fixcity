import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart'; // 👈 Map Package
import 'package:latlong2/latlong.dart'; // 👈 For Coordinates
import '../widgets/app_drawer.dart';
import 'report_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _selectedFilter = "All";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final String userRole =
        ModalRoute.of(context)!.settings.arguments as String? ?? 'Citizen';
    final bool isAdmin = userRole == 'Admin';

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: _buildSearchBar(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;

          // 1. FILTERING LOGIC
          var filteredDocs = docs.where((doc) {
            var data = doc.data();
            var analysis = data['aiAnalysis'] as Map<String, dynamic>? ?? {};

            String status = analysis['status'] ?? 'PENDING';
            String urgency = analysis['urgency'] ?? 'Normal';
            String description = (data['description'] ?? "")
                .toString()
                .toLowerCase();
            String type = (analysis['issueType'] ?? "")
                .toString()
                .toLowerCase();

            if (_selectedFilter == "Critical" && urgency != "Immediate")
              return false;
            if (_selectedFilter == "Unresolved" && status == "RESOLVED")
              return false;
            if (_selectedFilter == "Resolved" && status != "RESOLVED")
              return false;

            if (_searchQuery.isNotEmpty) {
              if (!description.contains(_searchQuery.toLowerCase()) &&
                  !type.contains(_searchQuery.toLowerCase())) {
                return false;
              }
            }
            return true;
          }).toList();

          return Column(
            children: [
              // ------------------------------------
              // 🗺️ THE LIVE INCIDENT MAP
              // ------------------------------------
              // We pass ALL docs to the map (so you see everything), or filteredDocs if you prefer.
              SizedBox(
                height: 250, // Height of the map section
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildLiveMap(
                    filteredDocs,
                  ), // 👈 Passing real data to map
                ),
              ),

              // ------------------------------------
              // 🏷️ FILTERS
              // ------------------------------------
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip("All", Icons.list),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      "Critical",
                      Icons.gpp_maybe,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      "Unresolved",
                      Icons.pending_actions,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      "Resolved",
                      Icons.check_circle_outline,
                      color: Colors.greenAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ------------------------------------
              // 📋 REPORT LIST
              // ------------------------------------
              Expanded(
                child: filteredDocs.isEmpty
                    ? const Center(
                        child: Text(
                          "No reports match.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          var doc = filteredDocs[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReportDetailScreen(
                                    doc: doc,
                                    isAdmin: isAdmin,
                                  ),
                                ),
                              );
                            },
                            child: _buildAdminCard(
                              context,
                              doc.data(),
                              doc['aiAnalysis'],
                              doc.id,
                              isAdmin,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🗺️ MAP WIDGET BUILDER
  Widget _buildLiveMap(List<QueryDocumentSnapshot> docs) {
    // 1. Convert Firestore Docs to Markers
    List<Marker> markers = docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      var location = data['location'];
      var analysis = data['aiAnalysis'] ?? {};
      String severity = analysis['severity'] ?? 'Medium';

      // Default to 0,0 if location is missing
      double lat = location != null ? location['lat'] : 0.0;
      double lng = location != null ? location['lng'] : 0.0;

      // Color coding
      Color pinColor = Colors.orangeAccent;
      if (severity == 'High') pinColor = Colors.redAccent;
      if (severity == 'Low') pinColor = Colors.cyanAccent;

      return Marker(
        point: LatLng(lat, lng),
        width: 40,
        height: 40,
        child: Icon(Icons.location_on, color: pinColor, size: 40),
      );
    }).toList();

    // Default center (e.g., your city). Ideally, calculate center of all points.
    LatLng initialCenter = markers.isNotEmpty
        ? markers.first.point
        : const LatLng(51.5, -0.09); // Default to London or your preference

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blueAccent.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: FlutterMap(
          options: MapOptions(initialCenter: initialCenter, initialZoom: 13.0),
          children: [
            TileLayer(
              // Dark Mode Tiles
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search issues...",
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData icon, {
    Color color = const Color(0xFFFF6D00),
  }) {
    bool isSelected = _selectedFilter == label;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.black : color),
      label: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.black : Colors.white),
      ),
      backgroundColor: isSelected ? color : const Color(0xFF2C2C2C),
      onPressed: () => setState(() => _selectedFilter = label),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    Map<String, dynamic> data,
    Map? analysisRaw,
    String docId,
    bool isAdmin,
  ) {
    var analysis = analysisRaw ?? {};
    String urgency = analysis['urgency'] ?? 'Normal';
    String dept = analysis['department'] ?? 'General';
    Color urgencyColor = urgency == 'Immediate'
        ? Colors.red
        : (urgency == '24hrs' ? Colors.orange : Colors.green);

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: urgency == 'Immediate'
              ? Colors.red.withOpacity(0.6)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade900,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    dept.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _infoBadge(urgency, urgencyColor, Icons.access_time_filled),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              analysis['issueType'] ?? "Issue",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              data['description'] ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade400),
            ),

            if (isAdmin) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _updateStatus(docId, 'IN PROGRESS'),
                      child: const Text(
                        "WORKING",
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _updateStatus(docId, 'RESOLVED'),
                      child: const Text(
                        "DONE",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, docId),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String docId, String newStatus) => FirebaseFirestore
      .instance
      .collection('reports')
      .doc(docId)
      .update({'aiAnalysis.status': newStatus});
  void _confirmDelete(BuildContext context, String docId) =>
      FirebaseFirestore.instance.collection('reports').doc(docId).delete();
}
