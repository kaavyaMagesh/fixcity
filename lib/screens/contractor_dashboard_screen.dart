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

  // --- 📸 LOGIC: Capture and AI Verify ---
  Future<void> _handleFixUpload(String reportId, dynamic reportData) async {
    final picker = ImagePicker();

    // 1. Capture the new "Fixed" photo
    // Reduced quality slightly to prevent memory-related app exits on physical devices
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, 
    );

    if (photo == null) return;

    // Safety check: Ensure widget is still active
    if (!mounted) return;

    setState(() => _isVerifying = true);
    
    // Close the bottom sheet so user sees the loading overlay
    if (Navigator.canPop(context)) Navigator.pop(context);

    try {
      Uint8List imageBytes = await photo.readAsBytes();

      // 2. Extract Lat/Lng from the existing report data
      // This ensures we are verifying the correct location without needing a 'Before' image
      double lat = reportData['location']?['lat'] ?? 0.0;
      double lng = reportData['location']?['lng'] ?? 0.0;

      // 3. Call the simplified Service (Independent Quality Check)
      Map<String, dynamic> result = await ContractorAIService.verifyFix(
        imageBytes: imageBytes,
        latitude: lat,
        longitude: lng,
      );

      if (!mounted) return;

      bool isFixed = result['is_fixed'] ?? false;
      String reason = result['reason'] ?? "AI verification completed.";

      if (isFixed) {
        // 4. Update Firestore: Move to RESOLVED directly
        await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
          'status': 'RESOLVED',
          'aiAnalysis.status': 'VERIFIED BY AI',
          'afterImageVerified': true,
          'verificationReason': reason,
          'resolvedAt': FieldValue.serverTimestamp(),
        });

        _showSnackBar("✅ AI Approved! Task marked as Resolved.", Colors.green);
      } else {
        // AI rejected the fix based on image quality/location
        _showSnackBar("❌ AI Refused: $reason", Colors.redAccent);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error: AI verification failed. Check connection.", Colors.redAccent);
      }
      debugPrint("Verification Error: $e");
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showSnackBar(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Contractor Portal",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.orange),
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
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  "YOUR ACTIVE TASKS",
                  style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
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
                      return const Center(child: CircularProgressIndicator(color: Colors.orange));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
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
              color: Colors.black.withOpacity(0.85),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 25),
                    Text("Gemini AI is verifying repair...",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 10),
                    Text("Checking road safety and location coordinates",
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
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
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.orange,
            radius: 25,
            child: Icon(Icons.engineering, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Welcome back,", style: TextStyle(color: Colors.grey, fontSize: 12)),
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
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text("No active work orders.", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(data['imageUrl'],
              width: 60, height: 60, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey)),
        ),
        title: Text(data['aiAnalysis']?['issueType'] ?? "Infrastructure Task",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Dept: ${data['department'] ?? 'Municipal'}",
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        trailing: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
        ),
        onTap: () => _showUploadFixBottomSheet(context, doc),
      ),
    );
  }

  void _showUploadFixBottomSheet(BuildContext context, DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_enhance, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text("Verify Completion",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "Capture the repaired area. Gemini AI will analyze the road quality and location to close the task.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              // IMPORTANT: Passing 'data' here instead of just the URL
              onPressed: _isVerifying ? null : () => _handleFixUpload(doc.id, data),
              icon: const Icon(Icons.camera_alt),
              label: Text(_isVerifying ? "VERIFYING..." : "CAPTURE & FINISH"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}