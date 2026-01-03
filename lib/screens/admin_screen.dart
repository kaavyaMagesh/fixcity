import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  // 🔒 SECURITY STATE
  bool _isAdmin = false;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  // 🔒 VERIFY ROLE
  Future<void> _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        IdTokenResult tokenResult = await user.getIdTokenResult();
        bool isClaimAdmin = tokenResult.claims?['role'] == 'admin';

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        bool isDbAdmin = false;
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (data['role'] == 'admin') isDbAdmin = true;
        }

        if (mounted) {
          setState(() {
            _isAdmin = isClaimAdmin || isDbAdmin;
            _isLoadingRole = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingRole = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // 🛠️ LOGIC: CONTRACTOR ASSIGNMENT
  void _showContractorSelector(String docId, String department) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text("Assign $department Contractor", 
          style: const TextStyle(color: Colors.white, fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'contractor')
                .where('department', isEqualTo: department)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) {
                return const Text("No contractors found for this department.", 
                  style: TextStyle(color: Colors.grey));
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var contractor = snapshot.data!.docs[index];
                  return ListTile(
                    leading: const Icon(Icons.engineering, color: Colors.orange),
                    title: Text(contractor['name'] ?? "No Name", style: const TextStyle(color: Colors.white)),
                    subtitle: Text(contractor['email'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    onTap: () {
                      _assignWork(docId, contractor.id, contractor['name'] ?? "Unknown");
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _assignWork(String docId, String contractorId, String contractorName) {
    FirebaseFirestore.instance.collection('reports').doc(docId).update({
      'status': 'IN PROGRESS', // For Contractor Query
      'aiAnalysis.status': 'IN PROGRESS', // For Admin UI
      'assignedContractorId': contractorId,
      'assignedContractorName': contractorName,
      'assignedAt': FieldValue.serverTimestamp(),
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Assigned to $contractorName"), backgroundColor: Colors.green),
    );
  }

  void _updateStatus(String docId, String newStatus) {
    FirebaseFirestore.instance.collection('reports').doc(docId).update({
      'status': newStatus,
      'aiAnalysis.status': newStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: _buildSearchBar(),
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoadingRole
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)))
            : StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('reports')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Error loading data", style: TextStyle(color: Colors.white)));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  var docs = snapshot.data!.docs;

                  // Stats Logic
                  int total = docs.length;
                  int resolved = 0;
                  int pending = 0;
                  int inProgress = 0;
                  Map<String, int> deptStats = {};

                  for (var doc in docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    var analysis = data['aiAnalysis'] as Map<String, dynamic>? ?? {};
                    String status = data['status'] ?? 'PENDING';
                    String dept = analysis['department'] ?? 'General';

                    // UPDATED: Logic to handle AI Resolved state
                    if (status == 'RESOLVED') resolved++;
                    else if (status == 'PENDING') pending++;
                    else inProgress++;

                    deptStats[dept] = (deptStats[dept] ?? 0) + 1;
                  }

                  // Filtering Logic
                  var filteredDocs = docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String status = data['status'] ?? 'PENDING';
                    String description = (data['description'] ?? "").toString().toLowerCase();

                    if (_selectedFilter == "Unresolved" && status == "RESOLVED") return false;
                    if (_selectedFilter == "Resolved" && status != "RESOLVED") return false;
                    if (_searchQuery.isNotEmpty && !description.contains(_searchQuery.toLowerCase())) return false;
                    return true;
                  }).toList();

                  return Column(
                    children: [
                      _buildStatsDashboard(total, resolved, pending, inProgress, deptStats),
                      if (filteredDocs.isNotEmpty)
                        SizedBox(height: 200, child: Padding(padding: const EdgeInsets.all(16.0), child: _buildLiveMap(filteredDocs))),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildFilterChip("All", Icons.list),
                            const SizedBox(width: 8),
                            _buildFilterChip("Unresolved", Icons.pending_actions, color: Colors.orangeAccent),
                            const SizedBox(width: 8),
                            _buildFilterChip("Resolved", Icons.check_circle_outline, color: Colors.greenAccent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            var doc = filteredDocs[index];
                            return _buildAdminCard(context, doc.data() as Map<String, dynamic>, doc['aiAnalysis'], doc.id);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  // 🃏 THE ADMIN CARD
  Widget _buildAdminCard(BuildContext context, Map<String, dynamic> data, Map? analysisRaw, String docId) {
    var analysis = analysisRaw ?? {};
    String status = data['status'] ?? 'PENDING';
    String urgency = analysis['urgency'] ?? 'Normal';
    String dept = analysis['department'] ?? 'General';
    String? assignedName = data['assignedContractorName'];
    
    // NEW: Check if Contractor AI verified this
    bool isAiVerified = data['afterImageVerified'] ?? false;
    String? aiReason = data['verificationReason'];

    Color statusColor = status == 'RESOLVED' ? Colors.green : Colors.orange;

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDeptBadge(dept),
                Text(urgency, style: TextStyle(color: urgency == 'Immediate' ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(analysis['issueType'] ?? "Issue", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(data['description'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade400)),

            // NEW: AI VERIFICATION NOTE
            if (isAiVerified)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: Colors.greenAccent),
                    const SizedBox(width: 6),
                    Expanded(child: Text("AI Verification: $aiReason", style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontStyle: FontStyle.italic))),
                  ],
                ),
              ),

            if (status == 'IN PROGRESS' && assignedName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text("Assigned to: $assignedName", style: const TextStyle(color: Colors.orange, fontSize: 12)),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _isAdmin
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: ['PENDING', 'IN PROGRESS', 'RESOLVED'].contains(status) ? status : 'PENDING',
                            dropdownColor: const Color(0xFF2C2C2C),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            items: ['PENDING', 'IN PROGRESS', 'RESOLVED']
                                .map((val) => DropdownMenuItem(
                                      value: val,
                                      child: Text(val, style: TextStyle(color: val == 'RESOLVED' ? Colors.green : Colors.orange)),
                                    )).toList(),
                            onChanged: (val) {
                              if (val == 'IN PROGRESS') {
                                _showContractorSelector(docId, dept);
                              } else if (val != null) {
                                _updateStatus(docId, val);
                              }
                            },
                          ),
                        ),
                      )
                    : _buildStatusBadge(status, statusColor),

                if (_isAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, docId),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildDeptBadge(String dept) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.blueGrey.shade900, borderRadius: BorderRadius.circular(4)),
      child: Text(dept.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildStatsDashboard(int total, int resolved, int pending, int inProgress, Map<String, int> deptStats) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("Total", total.toString(), Colors.blue),
              _buildStatItem("Resolved", resolved.toString(), Colors.green),
              _buildStatItem("Pending", pending.toString(), Colors.orange),
              _buildStatItem("Active", inProgress.toString(), Colors.yellow),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: OutlinedButton(
              onPressed: () => _showDeptDetails(deptStats),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text("View Department Breakdown ▼", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLiveMap(List<QueryDocumentSnapshot> docs) {
    List<Marker> markers = [];
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      var loc = data['location'];
      if (loc != null) {
        markers.add(Marker(
          point: LatLng(loc['lat'], loc['lng']),
          width: 40, height: 40,
          child: const Icon(Icons.location_on, color: Colors.redAccent, size: 30),
        ));
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        options: MapOptions(initialCenter: markers.isNotEmpty ? markers.first.point : const LatLng(0,0), initialZoom: 13.0),
        children: [
          TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png', subdomains: const ['a','b','c','d']),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(8)),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(hintText: "Search issues...", hintStyle: TextStyle(color: Colors.grey), prefixIcon: Icon(Icons.search, color: Colors.grey), border: InputBorder.none),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, {Color color = const Color(0xFFFF6D00)}) {
    bool isSel = _selectedFilter == label;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: isSel ? Colors.black : color),
      label: Text(label, style: TextStyle(color: isSel ? Colors.black : Colors.white)),
      backgroundColor: isSel ? color : const Color(0xFF2C2C2C),
      onPressed: () => setState(() => _selectedFilter = label),
    );
  }

  void _showDeptDetails(Map<String, int> stats) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: stats.entries.map((e) => ListTile(title: Text(e.key, style: const TextStyle(color: Colors.white)), trailing: Text(e.value.toString(), style: const TextStyle(color: Colors.orange)))).toList(),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Delete Report?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(child: const Text("CANCEL"), onPressed: () => Navigator.pop(ctx)),
          TextButton(child: const Text("DELETE", style: TextStyle(color: Colors.red)), onPressed: () {
            FirebaseFirestore.instance.collection('reports').doc(docId).delete();
            Navigator.pop(ctx);
          }),
        ],
      ),
    );
  }
}