import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

// 👇 IMPORT YOUR SERVICES & WIDGETS
import '../services/ai_service.dart';
import '../services/translator.dart'; // Import Translator for multilingual support
import '../widgets/level_up_dialog.dart'; // 👈 Import the Gamification Dialog

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _imageFile;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  Position? _currentPosition;
  String _locationMessage = "Getting location...";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // 📍 1. Get Location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationMessage = "Location services disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationMessage = "Location permission denied.");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = position;
      _locationMessage =
          "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
    });
  }

  // 📸 2. Pick Image
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 🚀 3. ANALYZE & UPLOAD (GAMIFIED VERSION)
  Future<void> _analyzeAndUpload() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please take a photo first!")),
      );
      return;
    }
    // Note: We allow uploading without location if it fails, using default 0,0
    double lat = _currentPosition?.latitude ?? 0.0;
    double lng = _currentPosition?.longitude ?? 0.0;

    setState(() => _isLoading = true);

    try {
      // A. 🤖 AI ANALYSIS (Directly from File Bytes)
      final imageBytes = await _imageFile!.readAsBytes();

      final analysis = await AIService.analyzeIssue(
        imageBytes: imageBytes,
        userText: _descriptionController.text,
        latitude: lat,
        longitude: lng,
      );

      // B. 🎮 CALCULATE GAMIFICATION POINTS
      int points = 20; // Default Low
      if (analysis.severity.toUpperCase() == 'HIGH') points = 100;
      else if (analysis.severity.toUpperCase() == 'MEDIUM') points = 50;

      // C. Save to Firestore (Data ONLY, no Image URL)
      await FirebaseFirestore.instance.collection('reports').add({
        'imageUrl': "", // 👈 No Cloud Image
        'description': _descriptionController.text,
        'location': {'lat': lat, 'lng': lng},
        'timestamp': FieldValue.serverTimestamp(),
        'votes': 0,

        // AI RESULTS
        'aiAnalysis': {
          'issueType': analysis.issueType,
          'severity': analysis.severity,
          'urgency': analysis.urgency,
          'department': analysis.responsibleDepartment,
          'summary': analysis.summary,
          'confidence': analysis.confidence,
          'status': 'PENDING',
          'xpEarned': points, // 👈 Saving the points!
        },
      });

      if (mounted) {
        // D. ✨ SHOW LEVEL UP POPUP (Replaces SnackBar)
        showDialog(
          context: context,
          barrierDismissible: false, // Force them to click button
          builder: (context) => LevelUpDialog(
            points: points, 
            severity: analysis.severity
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Translator.t('report_issue'))), // Translated
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE PREVIEW
            GestureDetector(
              onTap: () => _showPickerOptions(),
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text(
                            Translator.t('camera'), // Translated
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // LOCATION STATUS
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFFFF6D00),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _locationMessage,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // DESCRIPTION INPUT
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: Translator.t('desc_hint'), // Translated
                labelText: "Description",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 30),

            // SUBMIT BUTTON
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6D00)),
                  )
                : ElevatedButton.icon(
                    onPressed: _analyzeAndUpload,
                    icon: const Icon(Icons.send),
                    label: Text(Translator.t('submit')), // Translated
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // 🛠️ FIXED: Bottom Sheet now lifts up safely
  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true, 
      useSafeArea: true, 
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 20.0), 
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: Text(
                Translator.t('camera'), // Translated
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: Text(
                Translator.t('gallery'), // Translated
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 40, width: double.infinity),
          ],
        ),
      ),
    );
  }
}