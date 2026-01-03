import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'translator.dart'; // 👈 Import Translator

class IssueAnalysisResult {
  final String issueType;
  final String severity;
  final String urgency;
  final String summary;
  final double confidence;
  final String responsibleDepartment;
  final String estimatedCost;
  final List<String> materialsRequired;
  final String manpower;
  final bool isHumanitarian;

  IssueAnalysisResult({
    required this.issueType,
    required this.severity,
    required this.urgency,
    required this.summary,
    required this.confidence,
    required this.responsibleDepartment,
    required this.estimatedCost,
    required this.materialsRequired,
    required this.manpower,
    required this.isHumanitarian,
  });

  factory IssueAnalysisResult.fromGemini(Map<String, dynamic> geminiJson) {
    // Helper to calculate urgency based on severity
    String calculateUrgency(String sev) {
      if (sev.contains('HIGH')) return 'Immediate';
      if (sev.contains('MEDIUM')) return '24hrs';
      return 'Non-Urgent';
    }

    // Ensure severity is safe string
    final severityStr = (geminiJson['severity'] ?? 'LOW').toUpperCase();

    return IssueAnalysisResult(
      issueType: geminiJson['issue_type'] ?? 'Issue',
      severity: severityStr,
      urgency: calculateUrgency(severityStr),
      summary: geminiJson['summary'] ?? 'No summary provided',
      confidence: (geminiJson['base_confidence'] ?? 0.5).toDouble(),
      responsibleDepartment:
          geminiJson['responsible_department'] ?? 'Municipal',
      estimatedCost: geminiJson['estimatedCost'] ?? "Pending",
      materialsRequired: List<String>.from(
        geminiJson['materialsRequired'] ?? [],
      ),
      manpower: geminiJson['manpower'] ?? "Pending",
      isHumanitarian: geminiJson['isHumanitarian'] ?? false,
    );
  }
}

class AIService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static Future<IssueAnalysisResult> analyzeIssue({
    required Uint8List imageBytes,
    required String userText,
    required double latitude,
    required double longitude,
  }) async {
    if (_apiKey.isEmpty) throw Exception('GEMINI_API_KEY missing');

    final imageBase64 = base64Encode(imageBytes);

    // 👇 GET CURRENT LANGUAGE NAME FOR AI
    String langName = "English";
    if (Translator.currentLang == 'ta') langName = "Tamil";
    if (Translator.currentLang == 'hi') langName = "Hindi";

    final prompt =
        '''
      You are a Civil Engineer AI. Analyze this image.
      User description: "$userText"
      Location: $latitude, $longitude
      
      IMPORTANT: Provide the response fields in $langName language (except keys).
      
      Return ONLY a JSON object:
      {
        "issue_type": "Short title in $langName",
        "severity": "HIGH", "MEDIUM", or "LOW" (Keep this in English for logic),
        "base_confidence": 0.9,
        "responsible_department": "Department Name in $langName",
        "summary": "1 sentence explanation in $langName",
        "isHumanitarian": boolean,
        "estimatedCost": "Cost in INR (e.g. ₹5000) in $langName",
        "materialsRequired": ["Material 1 in $langName", "Material 2 in $langName"],
        "manpower": "Labor estimate in $langName"
      }
    ''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': imageBase64},
            },
          ],
        },
      ],
    });

    try {
      final response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200)
        throw Exception('API Error: ${response.body}');

      final data = jsonDecode(response.body);
      if (data['candidates'] == null || data['candidates'].isEmpty) {
        throw Exception('No analysis returned.');
      }

      final text = data['candidates'][0]['content']['parts'][0]['text'];
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) throw Exception('No JSON found');

      final cleanJson = jsonDecode(jsonMatch.group(0)!);
      return IssueAnalysisResult.fromGemini(cleanJson);
    } catch (e) {
      print("AI Error: $e");
      throw e;
    }
  }
}
