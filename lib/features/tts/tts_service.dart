import 'dart:async';
import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:visionaid/core/constants/app_constants.dart';
import 'package:visionaid/core/providers/app_state_provider.dart';

/// TTS Service Provider
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Priority-based Text-to-Speech Service
/// Implements priority queue for safety alerts as per PRD
class TtsService {
  final Ref _ref;
  final FlutterTts _flutterTts = FlutterTts();
  
  // Priority queues for different alert levels
  final Queue<String> _criticalQueue = Queue<String>();
  final Queue<String> _warningQueue = Queue<String>();
  final Queue<String> _infoQueue = Queue<String>();
  
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _currentText = '';
  
  TtsService(this._ref);
  
  /// Initialize TTS engine with iOS-optimized settings
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // iOS-specific configuration
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
      
      // Set default language
      await _flutterTts.setLanguage('en-US');
      
      // Apply initial settings
      final settings = _ref.read(ttsSettingsProvider);
      await _applySettings(settings);
      
      // Set up completion handler
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _processNextInQueue();
      });
      
      _flutterTts.setErrorHandler((message) {
        print('[VisionAid TTS] Error: $message');
        _isSpeaking = false;
        _processNextInQueue();
      });
      
      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
      });
      
      _isInitialized = true;
      print('[VisionAid TTS] Initialized successfully');
    } catch (e) {
      print('[VisionAid TTS] Initialization error: $e');
    }
  }
  
  Future<void> _applySettings(TtsSettings settings) async {
    await _flutterTts.setSpeechRate(settings.rate);
    await _flutterTts.setPitch(settings.pitch);
    await _flutterTts.setVolume(settings.volume);
  }
  
  /// Speak with priority level
  /// Critical alerts preempt all other speech
  Future<void> speak(String text, {AlertPriority priority = AlertPriority.info}) async {
    if (!_isInitialized) await initialize();
    
    final settings = _ref.read(ttsSettingsProvider);
    if (!settings.isEnabled) return;
    
    // Update last spoken text for repeat functionality
    _ref.read(lastSpokenTextProvider.notifier).state = text;
    
    switch (priority) {
      case AlertPriority.critical:
        // Critical alerts interrupt immediately
        await stop();
        _criticalQueue.addFirst(text);
        await _processNextInQueue();
        break;
      case AlertPriority.warning:
        _warningQueue.add(text);
        if (!_isSpeaking) await _processNextInQueue();
        break;
      case AlertPriority.info:
        _infoQueue.add(text);
        if (!_isSpeaking) await _processNextInQueue();
        break;
    }
  }
  
  /// Process next item in priority queue
  Future<void> _processNextInQueue() async {
    if (_isSpeaking) return;
    
    String? textToSpeak;
    
    // Priority order: critical > warning > info
    if (_criticalQueue.isNotEmpty) {
      textToSpeak = _criticalQueue.removeFirst();
    } else if (_warningQueue.isNotEmpty) {
      textToSpeak = _warningQueue.removeFirst();
    } else if (_infoQueue.isNotEmpty) {
      textToSpeak = _infoQueue.removeFirst();
    }
    
    if (textToSpeak != null) {
      _isSpeaking = true;
      _currentText = textToSpeak;
      
      // Apply current settings before speaking
      final settings = _ref.read(ttsSettingsProvider);
      await _applySettings(settings);
      
      await _flutterTts.speak(textToSpeak);
    }
  }
  
  /// Stop current speech
  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }
  
  /// Clear all queues and stop
  Future<void> clearAndStop() async {
    _criticalQueue.clear();
    _warningQueue.clear();
    _infoQueue.clear();
    await stop();
  }
  
  /// Repeat last spoken text
  Future<void> repeatLast() async {
    final lastText = _ref.read(lastSpokenTextProvider);
    if (lastText.isNotEmpty) {
      await speak(lastText, priority: AlertPriority.info);
    }
  }
  
  /// Announce mode change
  Future<void> announceMode(AppMode mode) async {
    await speak('${mode.displayName} activated. ${mode.description}', 
        priority: AlertPriority.warning);
  }
  
  /// Announce error with recovery instructions
  Future<void> announceError(String error, {String? recovery}) async {
    final message = recovery != null 
        ? '$error. $recovery' 
        : error;
    await speak(message, priority: AlertPriority.warning);
  }
  
  bool get isSpeaking => _isSpeaking;
  String get currentText => _currentText;
  
  void dispose() {
    _flutterTts.stop();
  }
}
