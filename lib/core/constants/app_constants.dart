/// VisionAid App Constants
class AppConstants {
  // App Info
  static const String appName = 'VisionAid';
  static const String tagline = 'See the world. Navigate freely. Live independently.';
  static const String shortTagline = 'Your AI Eyes';
  
  // API Endpoints - NVIDIA NIM
  static const String nimBaseUrl = 'https://integrate.api.nvidia.com/v1';
  
  // Nemotron Models from PRD
  static const String nemotronVisionModel = 'nvidia/nemotron-nano-12b-v2-vl';
  static const String nemotronOrchestratorModel = 'nvidia/nemotron-nano-30b-a3b';
  static const String nemotronReasoningModel = 'nvidia/nemotron-super-120b-a12b';
  
  // Timing Constants (from PRD)
  static const int sceneDescriptionIntervalMs = 4000; // 4 seconds
  static const int maxLatencyMs = 3000; // Target < 3 seconds
  static const int coldStartMaxMs = 4000; // < 4 seconds to camera-ready
  static const int ocrMaxLatencyMs = 2000; // < 2 seconds from tap to first word
  
  // Detection Constants
  static const double proximityWarningFeet = 5.0;
  static const double proximityCriticalFeet = 2.0;
  static const double yoloConfidenceThreshold = 0.7;
  
  // Object Classes for Detection
  static const List<String> detectionClasses = [
    'stairs',
    'door',
    'chair',
    'person',
    'vehicle',
    'curb',
    'wall',
  ];
  
  // TTS Settings
  static const double defaultTtsRate = 0.5; // 0.0 to 1.0
  static const double defaultTtsPitch = 1.0;
  static const double defaultTtsVolume = 1.0;
  
  // Accessibility
  static const double minTouchTargetSize = 44.0; // WCAG requirement
  static const double minContrastRatio = 4.5; // WCAG 2.1 AA
  static const int maxDescriptionWords = 20; // From PRD
  
  // Storage Keys
  static const String apiKeyStorageKey = 'nvidia_api_key';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String ttsRateKey = 'tts_rate';
  static const String ttsPitchKey = 'tts_pitch';
  static const String selectedModeKey = 'selected_mode';
  static const String hapticEnabledKey = 'haptic_enabled';
}

/// App Modes as defined in PRD
enum AppMode {
  scene('Scene Mode', 'Continuous scene description every 4 seconds'),
  read('Read Mode', 'Optimized for text detection'),
  navigate('Navigate Mode', 'Obstacle detection prioritized'),
  explore('Explore Mode', 'Full AI description with detailed labeling');
  
  final String displayName;
  final String description;
  
  const AppMode(this.displayName, this.description);
}

/// Alert Priority Levels
enum AlertPriority {
  critical, // Immediate danger - haptic + audio, preempts everything
  warning,  // Potential hazard - audio alert
  info,     // General information - queued TTS
}

/// Detection Result
class DetectionResult {
  final String className;
  final double confidence;
  final double distanceFeet;
  final String spatialPosition; // left, right, center, ahead
  final AlertPriority priority;
  
  const DetectionResult({
    required this.className,
    required this.confidence,
    required this.distanceFeet,
    required this.spatialPosition,
    required this.priority,
  });
  
  String toSpokenAlert() {
    if (priority == AlertPriority.critical) {
      return '$className ${distanceFeet.toStringAsFixed(0)} feet $spatialPosition. Caution.';
    }
    return '$className $spatialPosition.';
  }
}
