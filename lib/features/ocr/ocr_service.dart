import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:visionaid/core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// OCR Service Provider
final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// OCR Service - uses Nemotron API for text recognition on web
/// Falls back to API-based OCR since ML Kit doesn't work on web
class OcrService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isProcessing = false;
  String? _cachedApiKey;

  /// Get API key from storage (uses SharedPreferences on web)
  Future<String?> _getApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey;
    
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        _cachedApiKey = prefs.getString(AppConstants.apiKeyStorageKey);
      } else {
        _cachedApiKey = await _secureStorage.read(key: AppConstants.apiKeyStorageKey);
      }
    } catch (e) {
      print('[VisionAid OCR] Error reading API key: $e');
    }
    return _cachedApiKey;
  }

  /// Recognize text from image bytes using Nemotron Vision API
  /// Target: < 2 seconds from capture to first word (PRD requirement)
  Future<String?> recognizeText(Uint8List imageBytes) async {
    if (_isProcessing) {
      print('[VisionAid OCR] Already processing, skipping');
      return null;
    }

    _isProcessing = true;

    try {
      final apiKey = await _getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        print('[VisionAid OCR] No API key configured');
        return null;
      }

      // Convert image to base64
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('${AppConstants.nimBaseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConstants.nemotronVisionModel,
          'messages': [
            {
              'role': 'system',
              'content': _getOcrSystemPrompt(),
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': _getOcrPrompt(),
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': 300,
          'temperature': 0.1,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null && content.trim().isNotEmpty) {
          // Check if no text was found
          if (content.toLowerCase().contains('no text') ||
              content.toLowerCase().contains('no visible text') ||
              content.toLowerCase().contains('cannot detect')) {
            return null;
          }
          return content.trim();
        }
      } else {
        print('[VisionAid OCR] API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[VisionAid OCR] Recognition error: $e');
    } finally {
      _isProcessing = false;
    }

    return null;
  }

  /// Check if text fills significant portion of frame
  /// Auto-detect when text fills > 30% of frame (PRD requirement)
  Future<bool> hasSignificantText(Uint8List imageBytes) async {
    // For web, we'll use a simple heuristic based on OCR result length
    final text = await recognizeText(imageBytes);
    return text != null && text.length > 50; // Significant if >50 chars
  }

  /// Get text blocks with position information (simplified for API-based OCR)
  Future<List<TextBlockInfo>> getTextBlocks(Uint8List imageBytes) async {
    final text = await recognizeText(imageBytes);
    if (text == null || text.isEmpty) return [];

    // Return single block for API-based OCR (no position info available)
    return [
      TextBlockInfo(
        text: text,
        position: 'center',
        confidence: 0.9,
      ),
    ];
  }

  String _getOcrSystemPrompt() => '''
You are a text recognition assistant for blind users.
Your task is to read ALL visible text in images accurately.

Rules:
1. Read text exactly as written (preserve capitalization, punctuation)
2. Read text in logical order (top to bottom, left to right)
3. If there are multiple text areas, separate them with line breaks
4. If no text is visible, say "No text detected"
5. Include signs, labels, screens, documents - any visible text
6. Do NOT describe the image, only read the text
''';

  String _getOcrPrompt() => '''
Read all visible text in this image. 
Return only the text content, nothing else.
If multiple text blocks exist, separate them with line breaks.
If no text is visible, say "No text detected".
''';

  void dispose() {
    // No cleanup needed for API-based service
  }
}

/// Information about a recognized text block
class TextBlockInfo {
  final String text;
  final String position;
  final double confidence;

  const TextBlockInfo({
    required this.text,
    required this.position,
    required this.confidence,
  });

  /// Format for TTS output
  String toSpokenFormat() {
    return 'Text at $position: $text';
  }
}
