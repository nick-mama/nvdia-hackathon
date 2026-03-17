import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visionaid/core/constants/app_constants.dart';
import 'package:visionaid/core/providers/app_state_provider.dart';
import 'package:visionaid/features/scene/nemotron_service.dart';
import 'package:visionaid/features/ocr/ocr_service.dart';
import 'package:visionaid/features/tts/tts_service.dart';

/// Agent Orchestrator Provider
final agentOrchestratorProvider = Provider<AgentOrchestrator>((ref) {
  return AgentOrchestrator(ref);
});

/// Tool definitions for Nemotron agent
enum AgentTool {
  describeScene(
      'describe_scene', 'Analyze camera frame and describe the environment'),
  readText('read_text', 'Extract and read text from the camera view'),
  flagHazard('flag_hazard', 'Alert user to immediate danger'),
  queryRag(
      'query_rag', 'Query knowledge base for location-specific information'),
  estimateRoute('estimate_route', 'Provide navigation guidance'),
  analyzeDocument(
      'analyze_document', 'Deep analysis of documents or complex text');

  final String id;
  final String description;

  const AgentTool(this.id, this.description);
}

/// Context packet for agent processing
class AgentContext {
  final Uint8List? imageBytes;
  final List<DetectionResult> detections;
  final AppMode currentMode;
  final List<String> recentOutputs;
  final String? userQuery;

  const AgentContext({
    this.imageBytes,
    this.detections = const [],
    required this.currentMode,
    this.recentOutputs = const [],
    this.userQuery,
  });
}

/// Agentic Orchestrator implementing PRD's agentic loop
/// Perceive -> Reason -> Retrieve -> Act -> Verify
class AgentOrchestrator {
  final Ref _ref;

  // Rolling context window (last 10 turns as per PRD)
  final List<Map<String, dynamic>> _contextWindow = [];
  static const int _maxContextTurns = 10;

  AgentOrchestrator(this._ref);

  /// Main agentic loop entry point
  Future<void> processFrame(AgentContext context) async {
    // 1. PERCEIVE: Gather sensor data
    final perceptionData = _buildPerceptionPacket(context);

    // 2. Check for critical hazards first (bypass AI for speed)
    final criticalHazard = _checkCriticalHazards(context.detections);
    if (criticalHazard != null) {
      await _handleCriticalAlert(criticalHazard);
      return; // Critical alerts preempt everything
    }

    // 3. REASON: Determine appropriate action based on mode
    final action = await _determineAction(context, perceptionData);

    // 4. ACT: Execute the determined action
    await _executeAction(action, context);

    // 5. Update context window for continuity
    _updateContextWindow(action, context);
  }

  Map<String, dynamic> _buildPerceptionPacket(AgentContext context) {
    return {
      'mode': context.currentMode.name,
      'detections': context.detections
          .map((d) => {
                'class': d.className,
                'distance': d.distanceFeet,
                'position': d.spatialPosition,
                'confidence': d.confidence,
              })
          .toList(),
      'hasImage': context.imageBytes != null,
      'recentOutputCount': context.recentOutputs.length,
      'userQuery': context.userQuery,
    };
  }

  DetectionResult? _checkCriticalHazards(List<DetectionResult> detections) {
    for (final detection in detections) {
      if (detection.priority == AlertPriority.critical) {
        return detection;
      }
    }
    return null;
  }

  Future<void> _handleCriticalAlert(DetectionResult hazard) async {
    final tts = _ref.read(ttsServiceProvider);
    await tts.speak(hazard.toSpokenAlert(), priority: AlertPriority.critical);
  }

  Future<AgentAction> _determineAction(
    AgentContext context,
    Map<String, dynamic> perceptionData,
  ) async {
    // Mode-based routing as per PRD
    switch (context.currentMode) {
      case AppMode.scene:
        return AgentAction(
          tool: AgentTool.describeScene,
          priority: AlertPriority.info,
          detailed: false,
        );

      case AppMode.read:
        return AgentAction(
          tool: AgentTool.readText,
          priority: AlertPriority.info,
        );

      case AppMode.navigate:
        // Prioritize obstacle alerts in navigate mode
        if (context.detections.isNotEmpty) {
          return AgentAction(
            tool: AgentTool.flagHazard,
            priority: AlertPriority.warning,
            data: context.detections,
          );
        }
        return AgentAction(
          tool: AgentTool.estimateRoute,
          priority: AlertPriority.info,
        );

      case AppMode.explore:
        return AgentAction(
          tool: AgentTool.describeScene,
          priority: AlertPriority.info,
          detailed: true,
        );
    }
  }

  Future<void> _executeAction(AgentAction action, AgentContext context) async {
    final nemotron = _ref.read(nemotronServiceProvider);
    final ocr = _ref.read(ocrServiceProvider);
    final tts = _ref.read(ttsServiceProvider);

    String? output;

    switch (action.tool) {
      case AgentTool.describeScene:
        if (context.imageBytes != null) {
          output = await nemotron.describeScene(
            context.imageBytes!,
            detailed: action.detailed,
          );
        }
        break;

      case AgentTool.readText:
        if (context.imageBytes != null) {
          output = await ocr.recognizeText(context.imageBytes!);
          if (output == null || output.isEmpty) {
            output = 'No text detected in view.';
          }
        }
        break;

      case AgentTool.flagHazard:
        final detections = action.data as List<DetectionResult>?;
        if (detections != null && detections.isNotEmpty) {
          // Speak each detection
          for (final detection in detections) {
            await tts.speak(
              detection.toSpokenAlert(),
              priority: detection.priority,
            );
          }
          return; // Already handled TTS
        }
        break;

      case AgentTool.estimateRoute:
        // For MVP, provide basic guidance based on detections
        output = _buildNavigationGuidance(context.detections);
        break;

      case AgentTool.queryRag:
        // RAG would be implemented with vector store
        output = 'Knowledge base query not available in MVP.';
        break;

      case AgentTool.analyzeDocument:
        if (context.imageBytes != null) {
          final text = await ocr.recognizeText(context.imageBytes!);
          if (text != null && text.length > 200) {
            // Use complex reasoning for long documents
            output = await nemotron.complexReasoning(
              task: 'Summarize this document for a blind user',
              additionalContext: text,
            );
          } else {
            output = text;
          }
        }
        break;
    }

    // Speak the output if we have one
    if (output != null && output.isNotEmpty) {
      // Check for repetition to avoid fatigue
      if (!_isRepetitive(output, context.recentOutputs)) {
        await tts.speak(output, priority: action.priority);
      }
    }
  }

  String _buildNavigationGuidance(List<DetectionResult> detections) {
    if (detections.isEmpty) {
      return 'Path appears clear ahead.';
    }

    final buffer = StringBuffer();

    // Group by position
    final ahead =
        detections.where((d) => d.spatialPosition == 'ahead').toList();
    final left = detections.where((d) => d.spatialPosition == 'left').toList();
    final right =
        detections.where((d) => d.spatialPosition == 'right').toList();

    if (ahead.isNotEmpty) {
      buffer.write(
          '${ahead.first.className} ${ahead.first.distanceFeet.toStringAsFixed(0)} feet ahead. ');
    }

    if (left.isNotEmpty) {
      buffer.write('${left.first.className} on left. ');
    }

    if (right.isNotEmpty) {
      buffer.write('${right.first.className} on right. ');
    }

    return buffer.toString().trim();
  }

  bool _isRepetitive(String newOutput, List<String> recentOutputs) {
    if (recentOutputs.isEmpty) return false;

    // Simple deduplication - check if very similar to last output
    final lastOutput = recentOutputs.last;
    final similarity = _calculateSimilarity(newOutput, lastOutput);

    return similarity > 0.8; // 80% similarity threshold
  }

  double _calculateSimilarity(String a, String b) {
    final wordsA = a.toLowerCase().split(' ').toSet();
    final wordsB = b.toLowerCase().split(' ').toSet();

    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;

    return union > 0 ? intersection / union : 0;
  }

  void _updateContextWindow(AgentAction action, AgentContext context) {
    _contextWindow.add({
      'timestamp': DateTime.now().toIso8601String(),
      'tool': action.tool.id,
      'mode': context.currentMode.name,
      'detectionsCount': context.detections.length,
    });

    // Keep only last N turns
    while (_contextWindow.length > _maxContextTurns) {
      _contextWindow.removeAt(0);
    }
  }

  /// Clear context window (e.g., when user changes location)
  void clearContext() {
    _contextWindow.clear();
  }
}

/// Action determined by agent reasoning
class AgentAction {
  final AgentTool tool;
  final AlertPriority priority;
  final bool detailed;
  final dynamic data;

  const AgentAction({
    required this.tool,
    this.priority = AlertPriority.info,
    this.detailed = false,
    this.data,
  });
}
