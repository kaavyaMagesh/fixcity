import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ContractorAIService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static Future<Map<String, dynamic>> verifyFix({
    required Uint8List imageBytes,
    required double latitude,
    required double longitude,
  }) async {
    if (_apiKey.isEmpty) throw Exception('GEMINI_API_KEY missing');

    final imageBase64 = base64Encode(imageBytes);

    final prompt = '''
      You are a Civil Engineering Inspector. 
      Analyze this image of a completed road repair at coordinates: $latitude, $longitude.
      
      Task:
      1. Does the road/infrastructure in this specific image look properly fixed and safe?
      2. Ensure there are no remaining hazards (like open potholes or debris).
      
      Return ONLY a JSON object:
      {
        "is_fixed": boolean,
        "confidence": 0.0 to 1.0,
        "reason": "Short explanation of the repair quality"
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
      final fullUri = Uri.parse('$_baseUrl?key=$_apiKey');
      final response = await http.post(
        fullUri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) throw Exception('API Error');

      final data = jsonDecode(response.body);
      String text = data['candidates'][0]['content']['parts'][0]['text'];
      
      // Use the same Regex logic that works in your User service
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) throw Exception('No JSON found');
      
      return jsonDecode(jsonMatch.group(0)!);
    } catch (e) {
      print("Contractor AI Error: $e");
      return {"is_fixed": false, "reason": "AI connection failed."};
    }
  }
}