import 'dart:io';
import 'dart:math' as Math; // 👈 Required for Distance Calculation
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/ai_service.dart';
import '../services/translator.dart';
import '../widgets/level_up_dialog.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _imageFile;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  // 📍 Location State
  Position? _currentPosition;
  LatLng? _manualLocation;
  String _locationMessage = "Getting GPS location...";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // 📍 1. Get GPS Location
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
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
      _locationMessage =
          "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
    });
  }

  // 🗺️ 2. Open Map to Pick Location
  Future<void> _pickLocationOnMap() async {
    final initial = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(51.5, -0.09);

    final LatLng? picked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(initialCenter: initial),
      ),
    );

    if (picked != null) {
      setState(() {
        _manualLocation = picked;
        _locationMessage =
            "📍 Selected: ${picked.latitude.toStringAsFixed(4)}, ${picked.longitude.toStringAsFixed(4)}";
      });
    }
  }

  // 📸 3. Pick Image
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 🚀 4. ANALYZE & UPLOAD (With Verification)
  // 🚀 4. ANALYZE & UPLOAD (With Crowd-Sourced Severity)
  Future<void> _analyzeAndUpload() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please take a photo first!")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("You must be logged in!")));
      return;
    }

    // Determine final location
    double lat = _manualLocation?.latitude ?? _currentPosition?.latitude ?? 0.0;
    double lng =
        _manualLocation?.longitude ?? _currentPosition?.longitude ?? 0.0;

    setState(() => _isLoading = true);

    try {
      // A. 🤖 AI ANALYSIS
      final imageBytes = await _imageFile!.readAsBytes();
      final analysis = await AIService.analyzeIssue(
        imageBytes: imageBytes,
        userText: _descriptionController.text,
        latitude: lat,
        longitude: lng,
      );

      // B. 🛡️ CHECK FOR DUPLICATES
      DocumentSnapshot? existingDuplicate = await _findNearbyDuplicate(
        lat,
        lng,
        analysis.issueType,
      );

      // 🔥 NEW FEATURE: CROWD-SOURCED SEVERITY INCREASE
      if (existingDuplicate != null) {
        // 1. Get current data
        var data = existingDuplicate.data() as Map<String, dynamic>;
        int currentVotes = (data['votes'] ?? 0) + 1; // Increment vote
        var currentAnalysis = data['aiAnalysis'] ?? {};
        String currentSeverity = currentAnalysis['severity'] ?? 'Low';

        // 2. Determine New Severity based on votes
        String newSeverity = currentSeverity;
        if (currentVotes >= 5 && currentSeverity == 'Low')
          newSeverity = 'Medium';
        if (currentVotes >= 10 && currentSeverity == 'Medium')
          newSeverity = 'High';
        if (currentVotes >= 20) newSeverity = 'Critical';

        // 3. Update the EXISTING report instead of creating a new one
        await FirebaseFirestore.instance
            .collection('reports')
            .doc(existingDuplicate.id)
            .update({
              'votes': currentVotes,
              'aiAnalysis.severity': newSeverity, // 👈 AUTO-ESCALATION
              'lastReported': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          setState(() => _isLoading = false);
          // 4. Show "Upvoted" Dialog instead of "Blocked" Dialog
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                "Issue Upvoted! ⬆️",
                style: TextStyle(color: Colors.greenAccent),
              ),
              content: Text(
                "This issue was already reported. You have added a vote to it.\n\n"
                "Current Votes: $currentVotes\n"
                "Severity Status: $newSeverity",
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "OK",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
        return; // ✅ Stop here (don't create a new doc)
      }

      // ... [The rest of your code for creating a NEW report stays the same] ...

      // C. CALCULATE POINTS (Standard Logic)
      int points = 20;
      if (analysis.severity.toUpperCase() == 'HIGH')
        points = 100;
      else if (analysis.severity.toUpperCase() == 'MEDIUM')
        points = 50;
      if (analysis.isHumanitarian) points = 150;

      // D. SAVE REPORT
      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user.uid,
        'imageUrl': "",
        'description': _descriptionController.text,
        'location': {'lat': lat, 'lng': lng},
        'timestamp': FieldValue.serverTimestamp(),
        'votes': 1, // Start with 1 vote
        'issueType': analysis.issueType,
        'aiAnalysis': {
          'issueType': analysis.issueType,
          'severity': analysis.severity,
          'urgency': analysis.urgency,
          'department': analysis.responsibleDepartment,
          'summary': analysis.summary,
          'confidence': analysis.confidence,
          'status': 'PENDING',
          'xpEarned': points,
          'estimatedCost': analysis.estimatedCost,
          'materialsRequired': analysis.materialsRequired,
          'manpower': analysis.manpower,
          'isHumanitarian': analysis.isHumanitarian,
        },
      });

      // E. UPDATE USER STATS
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'totalXP': FieldValue.increment(points),
        'reportCount': FieldValue.increment(1),
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              LevelUpDialog(points: points, severity: analysis.severity),
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

  // 🔍 HELPER: Find nearby duplicate reports
  Future<DocumentSnapshot?> _findNearbyDuplicate(
    double lat,
    double lng,
    String type,
  ) async {
    // Optimization: In a real app, use GeoFlutterFire queries.
    // Here we fetch all reports and filter in memory (OK for Hackathon scale).
    final reports = await FirebaseFirestore.instance
        .collection('reports')
        .get();

    for (var doc in reports.docs) {
      final data = doc.data();

      // Check if Issue Type Matches (Case insensitive check is safer)
      String dbType =
          (data['issueType'] ?? data['aiAnalysis']['issueType'] ?? "")
              .toString();

      // Simple string match - in production, check synonyms too
      if (dbType.toLowerCase().contains(type.toLowerCase()) ||
          type.toLowerCase().contains(dbType.toLowerCase())) {
        Map<String, dynamic> loc = data['location'];
        double d = _calculateDistance(lat, lng, loc['lat'], loc['lng']);

        // If same type AND within 20 meters -> DUPLICATE
        if (d < 20) {
          return doc;
        }
      }
    }
    return null;
  }

  // 📏 HELPER: Haversine Distance Calculation (Returns meters)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295; // Math.pi / 180
    var c = Math.cos;
    var a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * Math.asin(Math.sqrt(a)) * 1000; // 2 * R; R = 6371 km
  }

  // ⚠️ HELPER: Show Duplicate Alert
  void _showDuplicateAlert(Map<String, dynamic> data) {
    String status = data['aiAnalysis']['status'] ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Issue Already Reported",
          style: TextStyle(color: Color(0xFFFF6D00)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 60, color: Color(0xFFFF6D00)),
            const SizedBox(height: 20),
            const Text(
              "This issue has already been reported in your area.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                "Current Status: $status",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Translator.t('report_issue'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                          const Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            Translator.t('camera'),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Row(
                children: [
                  Icon(
                    _manualLocation != null
                        ? Icons.edit_location_alt
                        : Icons.my_location,
                    color: const Color(0xFFFF6D00),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _locationMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickLocationOnMap,
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text("CHANGE"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: Translator.t('desc_hint'),
                labelText: "Description",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6D00)),
                  )
                : ElevatedButton.icon(
                    onPressed: _analyzeAndUpload,
                    icon: const Icon(Icons.send),
                    label: Text(Translator.t('submit')),
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
                Translator.t('camera'),
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
                Translator.t('gallery'),
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

// 🗺️ LOCATION PICKER SUB-SCREEN
class LocationPickerScreen extends StatefulWidget {
  final LatLng initialCenter;
  const LocationPickerScreen({super.key, required this.initialCenter});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _pickedLocation;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, _pickedLocation),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 15,
              onTap: (tapPosition, point) =>
                  setState(() => _pickedLocation = point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _pickedLocation),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "CONFIRM LOCATION",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
