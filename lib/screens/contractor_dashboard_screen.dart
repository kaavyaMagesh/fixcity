import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/contractor_ai_service.dart';

class ContractorDashboardScreen extends StatefulWidget {
  const ContractorDashboardScreen({super.key});

  @override
  State<ContractorDashboardScreen> createState() => _ContractorDashboardScreenState();
}

class _ContractorDashboardScreenState extends State<ContractorDashboardScreen> {
  bool _isVerifying = false;

  // --- 📸 LOGIC: UNTOUCHED ---
  Future<void> _handleFixUpload(String reportId, dynamic reportData) async {
    final picker = ImagePicker();

    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, 
    );

    if (photo == null) return;
    if (!mounted) return;

    setState(() => _isVerifying = true);
    
    if (Navigator.canPop(context)) Navigator.pop(context);

    try {
      Uint8List imageBytes = await photo.readAsBytes();

      double lat = reportData['location']?['lat'] ?? 0.0;
      double lng = reportData['location']?['lng'] ?? 0.0;

      Map<String, dynamic> result = await ContractorAIService.verifyFix(
        imageBytes: imageBytes,
        latitude: lat,
        longitude: lng,
      );

      if (!mounted) return;

      bool isFixed = result['is_fixed'] ?? false;
      String reason = result['reason'] ?? "AI verification completed.";

      if (isFixed) {
        await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
          'status': 'RESOLVED',
          'aiAnalysis.status': 'VERIFIED BY AI',
          'afterImageVerified': true,
          'verificationReason': reason,
          'resolvedAt': FieldValue.serverTimestamp(),
        });

        _showSnackBar("✅ AI Approved! Task marked as Resolved.", Colors.green);
      } else {
        _showSnackBar("❌ AI Refused: $reason", const Color(0xFFF44336)); // Spec Red
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error: AI verification failed. Check connection.", const Color(0xFFF44336));
      }
      debugPrint("Verification Error: $e");
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showSnackBar(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Spec: App Background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E), // Spec: Surface Grey
        title: const Text("Contractor Portal",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF6D00)), // Spec: Primary Orange
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user?.email ?? "Contractor"),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
                child: Text(
                  "YOUR ACTIVE TASKS",
                  style: TextStyle(
                      color: Color(0xFFB3B3B3), // Spec: Body Light Grey
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 12),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .where('assignedContractorId', isEqualTo: user?.uid)
                      .where('status', isEqualTo: 'IN PROGRESS')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        return _buildTaskCard(context, snapshot.data!.docs[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // --- 🤖 AI PROCESSING OVERLAY ---
          if (_isVerifying)
            Container(
              color: Colors.black.withOpacity(0.9),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00E5FF)), // Spec: AI Cyan
                    SizedBox(height: 25),
                    Text("AI IS VERIFYING FIX",
                        style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
                    SizedBox(height: 10),
                    Text("Analyzing road safety & GPS metrics",
                        style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(String email) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Spec Surface
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFF6D00), // Spec Orange
            radius: 28,
            child: Icon(Icons.engineering, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Welcome back,", style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13)),
                const SizedBox(height: 4),
                Text(email,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: const Color(0xFF2C2C2C)),
          const SizedBox(height: 16),
          const Text("No active work orders.", style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return Card(
      color: const Color(0xFF1E1E1E), // Spec Surface
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF333333), width: 1), // Spec thin border
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(data['imageUrl'],
              width: 65, height: 65, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF2C2C2C), child: const Icon(Icons.broken_image, color: Colors.grey))),
        ),
        title: Text(data['aiAnalysis']?['issueType'] ?? "Infrastructure Task",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text("Dept: ${data['department'] ?? 'Municipal'}",
              style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.w600)), // Spec Cyan
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.camera_alt, color: Color(0xFFFF6D00), size: 20),
        ),
        onTap: () => _showUploadFixBottomSheet(context, doc),
      ),
    );
  }

  void _showUploadFixBottomSheet(BuildContext context, DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E), // Spec Surface
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_enhance, size: 48, color: Color(0xFFFF6D00)),
            const SizedBox(height: 20),
            const Text("Verify Completion",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "Capture the repaired area. Gemini AI will analyze the road quality and location to close the task.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isVerifying ? null : () => _handleFixUpload(doc.id, data),
              icon: const Icon(Icons.camera_alt),
              label: const Text("CAPTURE & FINISH"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00), // Spec Orange
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Spec Radius 8
                textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}