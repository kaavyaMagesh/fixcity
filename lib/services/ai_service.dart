import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 1. DATA MODEL
class IssueAnalysisResult {
  final String issueType;
  final String severity;
  final String urgency;
  final String summary;
  final double confidence;
  final String responsibleDepartment;

  IssueAnalysisResult({
    required this.issueType,
    required this.severity,
    required this.urgency,
    required this.summary,
    required this.confidence,
    required this.responsibleDepartment,
  });

  factory IssueAnalysisResult.fromGemini(Map<String, dynamic> geminiJson) {
    String calculateUrgency(String sev) {
      if (sev == 'HIGH') return 'Immediate';
      if (sev == 'MEDIUM') return '24hrs';
      return 'Non-Urgent';
    }

    final severityStr = (geminiJson['severity'] ?? 'LOW').toUpperCase();

    return IssueAnalysisResult(
      issueType: geminiJson['issue_type'] ?? 'other',
      severity: severityStr,
      urgency: calculateUrgency(severityStr),
      summary: geminiJson['summary'] ?? 'No summary provided',
      confidence: (geminiJson['base_confidence'] ?? 0.5).toDouble(),
      responsibleDepartment:
          geminiJson['responsible_department'] ?? 'Municipal Corp',
    );
  }
}

// 2. SERVICE CLASS
class AIService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _endpoint =
      // 👇 USE THIS EXACT STRING (No "pro", no "latest")
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static Future<IssueAnalysisResult> analyzeIssue({
    required Uint8List imageBytes,
    required String userText,
    // 👇 THESE WERE MISSING! I ADDED THEM BACK.
    required double latitude,
    required double longitude,
  }) async {
    if (_apiKey.isEmpty)
      throw Exception('GEMINI_API_KEY is missing in .env file');

    // Convert image to Base64
    final imageBase64 = base64Encode(imageBytes);

    // The Prompt
    final prompt =
        '''
      You are an infrastructure classifier. Analyze this image and text.
      User description: "$userText"
      Location Context: Lat $latitude, Lng $longitude (Use if relevant for identifying highway vs city road)
      
      Return ONLY a JSON object with these fields:
      - issue_type: [pothole, garbage, streetlight, drainage, other]
      - severity: [LOW, MEDIUM, HIGH]
      - base_confidence: 0.0 to 1.0
      - responsible_department: [Roads, Sanitation, Electrical, Water, Other]
      - summary: Short 10-word description.
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

      if (response.statusCode != 200) {
        throw Exception('Gemini API Error: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) throw Exception('No JSON found in response');

      final cleanJson = jsonDecode(jsonMatch.group(0)!);
      return IssueAnalysisResult.fromGemini(cleanJson);
    } catch (e) {
      print("AI Error: $e");
      throw e;
    }
  }
}
