import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_service.dart';

class DataService {
  // We don't need Uuid or FirebaseStorage anymore!

  Future<void> submitReport({
    required File imageFile,
    required String description,
    required double lat,
    required double lng,
  }) async {
    try {
      print("🚀 STARTED: Processing without saving image...");

      // 1. CONVERT IMAGE TO BYTES (For AI)
      Uint8List imageBytes = await imageFile.readAsBytes();
      print("✅ Image loaded: ${imageBytes.length} bytes");

      // 2. SEND DIRECTLY TO GEMINI AI
      // We skip the upload and go straight to analysis
      print("🤖 Sending to Gemini...");
      IssueAnalysisResult aiResult = await AIService.analyzeIssue(
        imageBytes: imageBytes,
        userText: description,
        latitude: lat,
        longitude: lng,
      );
      print("✅ AI Analysis Complete: ${aiResult.issueType}");

      // 3. SAVE ONLY DATA TO FIRESTORE
      // We save "No Image" for the imageUrl field so the app doesn't break
      print("💾 Saving text data to Firestore...");
      await FirebaseFirestore.instance.collection('reports').add({
        'imageUrl':
            'https://placehold.co/600x400?text=No+Image+Saved', // Placeholder
        'description': description,
        'aiAnalysis': {
          'issueType': aiResult.issueType,
          'severity': aiResult.severity,
          'urgency': aiResult.urgency,
          'confidence': aiResult.confidence,
          'department': aiResult.responsibleDepartment,
          'summary': aiResult.summary,
          'status': 'ANALYZED',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'location': {'lat': lat, 'lng': lng},
      });

      print("🎉 SUCCESS: Report Saved (Text Only)!");
    } catch (e) {
      print("❌ ERROR: $e");
      throw Exception("Failed to process report: $e");
    }
  }

  Stream<QuerySnapshot> getReportsStream() {
    return FirebaseFirestore.instance
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
