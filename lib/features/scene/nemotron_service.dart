import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:visionaid/core/constants/app_constants.dart';

/// Nemotron Service Provider
final nemotronServiceProvider = Provider<NemotronService>((ref) {
  return NemotronService();
});

/// API Key Provider
final apiKeyProvider = FutureProvider<String?>((ref) async {
  final nemotron = ref.read(nemotronServiceProvider);
  return await nemotron._getApiKey();
});

/// Nemotron AI Service
/// Implements hybrid architecture with:
/// - nemotron-nano-12b-v2-vl for vision processing
/// - nemotron-nano-30b-a3b for agentic orchestration  
/// - nemotron-super-120b-a12b for complex reasoning
class NemotronService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _cachedApiKey;
  
  /// Get API key from storage (uses SharedPreferences on web, SecureStorage on mobile)
  Future<String?> _getApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey;
    
    try {
      if (kIsWeb) {
        // Use SharedPreferences on web (secure storage has issues)
        final prefs = await SharedPreferences.getInstance();
        _cachedApiKey = prefs.getString(AppConstants.apiKeyStorageKey);
      } else {
        _cachedApiKey = await _secureStorage.read(key: AppConstants.apiKeyStorageKey);
      }
    } catch (e) {
      print('[VisionAid Nemotron] Error reading API key: $e');
    }
    return _cachedApiKey;
  }
  
  /// Save API key to storage
  Future<void> saveApiKey(String apiKey) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.apiKeyStorageKey, apiKey);
      } else {
        await _secureStorage.write(key: AppConstants.apiKeyStorageKey, value: apiKey);
      }
      _cachedApiKey = apiKey;
      print('[VisionAid Nemotron] API key saved successfully');
    } catch (e) {
      print('[VisionAid Nemotron] Error saving API key: $e');
    }
  }
  
  /// Check if API key is configured
  Future<bool> hasApiKey() async {
    final key = await _getApiKey();
    return key != null && key.isNotEmpty;
  }
  
  /// Describe scene using Nemotron Vision-Language model
  /// nvidia/nemotron-nano-12b-v2-vl for image understanding
  Future<String?> describeScene(Uint8List imageBytes, {bool detailed = false}) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      print('[VisionAid Nemotron] No API key configured');
      return null;
    }
    
    try {
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);
      
      // Build prompt based on mode
      final prompt = detailed
          ? _buildDetailedScenePrompt()
          : _buildScenePrompt();
      
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
              'content': _getVisionSystemPrompt(),
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt,
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
          'max_tokens': 150,
          'temperature': 0.3,
          'stream': false,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;
        
        if (content != null) {
          // Self-validate output through orchestrator
          return await _validateAndRefine(content);
        }
      } else {
        print('[VisionAid Nemotron] Vision API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[VisionAid Nemotron] Scene description error: $e');
    }
    
    return null;
  }
  
  /// Use orchestrator model for tool calling and refinement
  /// nvidia/nemotron-nano-30b-a3b for agentic orchestration
  Future<String?> orchestrate({
    required String task,
    Map<String, dynamic>? context,
  }) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) return null;
    
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.nimBaseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConstants.nemotronOrchestratorModel,
          'messages': [
            {
              'role': 'system',
              'content': _getOrchestratorSystemPrompt(),
            },
            {
              'role': 'user',
              'content': task,
            },
          ],
          'max_tokens': 200,
          'temperature': 0.2,
          'stream': false,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices']?[0]?['message']?['content'] as String?;
      }
    } catch (e) {
      print('[VisionAid Nemotron] Orchestration error: $e');
    }
    
    return null;
  }
  
  /// Use complex reasoning model for difficult tasks
  /// nvidia/nemotron-super-120b-a12b for complex multi-step reasoning
  Future<String?> complexReasoning({
    required String task,
    String? additionalContext,
  }) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) return null;
    
    try {
      final messages = <Map<String, dynamic>>[
        {
          'role': 'system',
          'content': _getReasoningSystemPrompt(),
        },
        {
          'role': 'user',
          'content': additionalContext != null 
              ? '$task\n\nContext: $additionalContext' 
              : task,
        },
      ];
      
      final response = await http.post(
        Uri.parse('${AppConstants.nimBaseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConstants.nemotronReasoningModel,
          'messages': messages,
          'max_tokens': 500,
          'temperature': 0.3,
          'stream': false,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices']?[0]?['message']?['content'] as String?;
      }
    } catch (e) {
      print('[VisionAid Nemotron] Complex reasoning error: $e');
    }
    
    return null;
  }
  
  /// Self-validation using orchestrator
  /// Ensures output follows safety rubric from PRD
  Future<String> _validateAndRefine(String originalDescription) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) return _sanitizeDescription(originalDescription);
    
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.nimBaseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConstants.nemotronOrchestratorModel,
          'messages': [
            {
              'role': 'system',
              'content': _getValidationSystemPrompt(),
            },
            {
              'role': 'user',
              'content': 'Validate and refine this scene description for a blind user: "$originalDescription"',
            },
          ],
          'max_tokens': 100,
          'temperature': 0.1,
          'stream': false,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final refined = data['choices']?[0]?['message']?['content'] as String?;
        return refined ?? _sanitizeDescription(originalDescription);
      }
    } catch (e) {
      print('[VisionAid Nemotron] Validation error: $e');
    }
    
    return _sanitizeDescription(originalDescription);
  }
  
  /// Fallback sanitization when API is unavailable
  String _sanitizeDescription(String text) {
    // Ensure under 20 words as per PRD
    final words = text.split(' ');
    if (words.length > AppConstants.maxDescriptionWords) {
      return '${words.take(AppConstants.maxDescriptionWords).join(' ')}...';
    }
    return text;
  }
  
  // System Prompts
  
  String _getVisionSystemPrompt() => '''
You are VisionAid, an AI assistant helping blind and low vision users understand their surroundings.

Rules:
1. Describe scenes concisely in under 20 words
2. Prioritize safety-relevant information (obstacles, stairs, people, vehicles)
3. Use spatial language (left, right, ahead, behind)
4. Never describe people by race, ethnicity, or appearance judgments
5. State facts, not assumptions about what people are doing or feeling
6. If you see potential hazards, mention them first
7. Use simple, clear language suitable for audio output

Example good outputs:
- "Kitchen with counter ahead. Person on your left. Table and chairs to the right."
- "Outdoor sidewalk. Stairs going down 10 feet ahead. Railing on the right."
- "Office space. Door ahead is open. Desk with computer on the left."
''';

  String _getOrchestratorSystemPrompt() => '''
You are the VisionAid orchestrator, managing tool calls and responses for a blind user assistant.

Your role:
1. Route tasks to appropriate tools (vision, OCR, navigation, RAG)
2. Combine information from multiple sources coherently
3. Validate outputs for safety and accuracy
4. Maintain context across interactions
5. Prioritize user safety in all responses

Always be concise and actionable.
''';

  String _getReasoningSystemPrompt() => '''
You are VisionAid's complex reasoning engine for challenging accessibility tasks.

Handle:
1. Multi-step navigation planning
2. Complex document analysis
3. Spatial reasoning for unfamiliar environments
4. Route optimization with obstacle avoidance

Provide clear, step-by-step guidance suitable for audio output to blind users.
''';

  String _getValidationSystemPrompt() => '''
You validate scene descriptions for blind users.

Safety rubric:
1. No hallucinated hazards (don't invent dangers)
2. No racial or ethnic profiling of people
3. Sentences under 20 words
4. Actionable and specific (include distances, positions)
5. Safety hazards mentioned first

If the description passes, return it unchanged.
If it needs refinement, return the improved version only.
''';

  String _buildScenePrompt() => '''
Describe what you see for a blind person. Focus on:
1. Any obstacles or hazards
2. People and their general positions
3. Key objects and furniture
4. Doorways, stairs, or paths

Keep it under 20 words.
''';

  String _buildDetailedScenePrompt() => '''
Provide a detailed scene description for a blind person exploring this space.
Include:
1. Overall environment type
2. All visible obstacles and their positions
3. People present and their general locations
4. Furniture and objects with spatial relationships
5. Any text or signs visible
6. Lighting conditions
7. Potential paths for navigation

Be thorough but organized. Use spatial language consistently.
''';
}
