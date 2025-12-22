import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class IssueAnalysisResult {
  final String issueType;
  final String severity;
  final String urgency;
  final String summary;
  final double confidence;
  final String responsibleDepartment;  // NEW

  IssueAnalysisResult({
    required this.issueType,
    required this.severity,
    required this.urgency,
    required this.summary,
    required this.confidence,
    required this.responsibleDepartment,
  });

  factory IssueAnalysisResult.fromGemini(
    Map<String, dynamic> geminiJson, {
    required double popScore,
  }) {
    final severityStr =
        (geminiJson['severity'] ?? geminiJson['Severity'] ?? 'LOW') as String;

    final severityScore = _severityToScore(severityStr);
    final riskScore = 0.6 * severityScore + 0.4 * popScore;
    final urgency = _riskToUrgency(riskScore);

    final baseConfNum =
        (geminiJson['base_confidence'] ?? geminiJson['baseConfidence'] ?? 0.5)
            as num;

    return IssueAnalysisResult(
      issueType: (geminiJson['issue_type'] ??
              geminiJson['issueType'] ??
              'other_infrastructure') as String,
      severity: severityStr,
      urgency: urgency,
      summary: (geminiJson['summary'] ?? '') as String,
      confidence: baseConfNum.toDouble().clamp(0.0, 1.0),
      responsibleDepartment:
          (geminiJson['responsible_department'] ??
           geminiJson['department'] ??
           'Other/Unclear') as String,   // NEW
    );
  }

  static double _severityToScore(String severity) {
    switch (severity) {
      case 'LOW':
        return 1.0;
      case 'MEDIUM':
        return 2.0;
      case 'HIGH':
        return 3.0;
      default:
        return 1.0;
    }
  }

  static String _riskToUrgency(double riskScore) {
    if (riskScore <= 2.0) return 'LOW';
    if (riskScore <= 3.5) return 'MEDIUM';
    return 'HIGH';
  }
}

class AIService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get _endpoint =>
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey';
// or:
//// 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$_apiKey';

  static Future<IssueAnalysisResult> analyzeIssue({
    required Uint8List imageBytes,
    required String userText,
    required double latitude,
    required double longitude,
  }) async {
    print('🔹 analyzeIssue CALLED');

    final popScore = await _getPopulationScore(latitude, longitude);
    final geminiResponse = await _callGemini(imageBytes, userText);

    print('🔹 GEMINI TEXT RAW: $geminiResponse');

    // Extract JSON object from the text
    final jsonMatch = RegExp(r'\{[\s\S]*\}')
        .firstMatch(geminiResponse);
    if (jsonMatch == null) {
      throw Exception('No JSON object found in Gemini response');
    }

    final jsonString = jsonMatch.group(0)!;
    print('🔹 PARSED JSON STRING: $jsonString');

    final geminiJson =
        jsonDecode(jsonString) as Map<String, dynamic>;

    return IssueAnalysisResult.fromGemini(
      geminiJson,
      popScore: popScore,
    );
  }

  static Future<double> _getPopulationScore(
      double lat, double lon) async {
    final roughZone = (lat * lon).abs() % 3 + 1;
    return roughZone.toDouble();
  }

  static Future<String> _callGemini(
      Uint8List imageBytes, String userText) async {
    if (_apiKey.isEmpty) {
      throw Exception(
          'GEMINI_API_KEY is empty. Check your .env and dotenv.load.');
    }

    final imageBase64 = base64Encode(imageBytes);

    final prompt = '''
    You are an infrastructure issue classifier for Indian cities.

    You will receive:
    1) A citizen-provided description of the issue.
    2) A photo of the location.

    Use BOTH the description and the image to decide:
    - issue_type: [pothole, crack, garbage_dump, footpath_damage, other_infrastructure]
    - severity: [LOW, MEDIUM, HIGH]
    - base_confidence: 0.0 to 1.0
    - responsible_department: one of ["Municipal Corporation", "PWD", "NHAI", "Water Supply & Sewerage Board", "Electricity Board", "Other/Unclear"]
    - summary: short description.

    IMPORTANT:
    - If the text mentions schools, hospitals, bus stops or highways, use that to refine severity/department.
    - Respond with ONLY a JSON object. No explanations, no markdown, no backticks.

    Example:
    {
      "issue_type": "pothole",
      "severity": "HIGH",
      "base_confidence": 0.92,
      "summary": "Large pothole near school bus stop",
      "responsible_department": "Municipal Corporation"
    }
    ''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},                 // instructions
            {'text': 'Citizen description: $userText'}, // user text as input
            {
              'inline_data': {                // image as input
                'mime_type': 'image/jpeg',
                'data': imageBase64,
              }
            },
          ]
        }
      ]
    });


    print('🔹 SENDING REQUEST TO GEMINI...');
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print(
        '🔹 RESPONSE STATUS: ${response.statusCode}');

    if (response.statusCode != 200) {
      print(
          '🔹 RESPONSE BODY (ERROR): ${response.body}');
      throw Exception(
          'Gemini API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data['candidates'] == null ||
        data['candidates'].isEmpty) {
      throw Exception(
          'No candidates returned from Gemini: ${response.body}');
    }

    final text =
        data['candidates'][0]['content']['parts'][0]['text']
            as String;
    print('🔹 GEMINI TEXT (FIRST PART): $text');
    return text;
  }
}


