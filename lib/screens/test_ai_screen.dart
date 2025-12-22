import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../services/ai_service.dart';

class TestAIScreen extends StatefulWidget {
  @override
  _TestAIScreenState createState() => _TestAIScreenState();
}

class _TestAIScreenState extends State<TestAIScreen> {
  bool _isLoading = false;
  String _result = '';
  IssueAnalysisResult? _lastResult;
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Test Screen')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Citizen description',
                hintText: 'Eg: Big pothole near school bus stop',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAI,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: _isLoading 
                ? CircularProgressIndicator(color: Colors.white)
                : Text('🖼️ Test AI (Pick Image)', style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
            if (_result.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ RESULT:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[800])),
                    SizedBox(height: 15),
                      _buildResultRow('Issue', _lastResult?.issueType ?? ''),
                      _buildResultRow('Severity', _lastResult?.severity ?? ''),
                      _buildResultRow('Urgency', _lastResult?.urgency ?? ''),
                      _buildResultRow('Confidence', '${(_lastResult?.confidence ?? 0).toStringAsFixed(2)}'),
                      _buildResultRow('Dept', _lastResult?.responsibleDepartment ?? ''),  // NEW
                      _buildResultRow('Summary', _lastResult?.summary ?? ''),

                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _testAI() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final imageBytes = await _pickImageFromGallery();
      
      if (imageBytes == null) {
        setState(() { 
          _result = '❌ No image selected';
          _isLoading = false; 
        });
        return;
      }

      print('📸 Image picked: ${imageBytes.length} bytes');
      
      final result = await AIService.analyzeIssue(
        imageBytes: imageBytes,
        userText: _textController.text,  // use user text
        latitude: 12.9716,
        longitude: 80.2707,
      );


      setState(() {
        _lastResult = result;
        _result = '✅ Success!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testWithText(String text) async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final imageBytes = Uint8List.fromList(List.generate(10000, (i) => i % 256));
      
      final result = await AIService.analyzeIssue(
        imageBytes: imageBytes,
        userText: _textController.text.isNotEmpty ? _textController.text : text,
        latitude: 12.9716,
        longitude: 80.2707,
      );


      setState(() {
        _lastResult = result;
        _result = '✅ Success!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<Uint8List?> _pickImageFromGallery() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    
    if (result != null && result.files.single.bytes != null) {
      return result.files.single.bytes!;
    }
    return null;
  }
}

