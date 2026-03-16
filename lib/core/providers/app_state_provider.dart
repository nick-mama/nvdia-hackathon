import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visionaid/core/constants/app_constants.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider to check if onboarding is complete
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
});

/// Provider for current app mode
final currentModeProvider = StateNotifierProvider<CurrentModeNotifier, AppMode>((ref) {
  return CurrentModeNotifier();
});

class CurrentModeNotifier extends StateNotifier<AppMode> {
  CurrentModeNotifier() : super(AppMode.scene);
  
  void setMode(AppMode mode) {
    state = mode;
  }
  
  void cycleMode() {
    final modes = AppMode.values;
    final currentIndex = modes.indexOf(state);
    final nextIndex = (currentIndex + 1) % modes.length;
    state = modes[nextIndex];
  }
}

/// Provider for TTS settings
final ttsSettingsProvider = StateNotifierProvider<TtsSettingsNotifier, TtsSettings>((ref) {
  return TtsSettingsNotifier();
});

class TtsSettings {
  final double rate;
  final double pitch;
  final double volume;
  final bool isEnabled;
  
  const TtsSettings({
    this.rate = AppConstants.defaultTtsRate,
    this.pitch = AppConstants.defaultTtsPitch,
    this.volume = AppConstants.defaultTtsVolume,
    this.isEnabled = true,
  });
  
  TtsSettings copyWith({
    double? rate,
    double? pitch,
    double? volume,
    bool? isEnabled,
  }) {
    return TtsSettings(
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class TtsSettingsNotifier extends StateNotifier<TtsSettings> {
  TtsSettingsNotifier() : super(const TtsSettings());
  
  void setRate(double rate) {
    state = state.copyWith(rate: rate.clamp(0.0, 1.0));
  }
  
  void setPitch(double pitch) {
    state = state.copyWith(pitch: pitch.clamp(0.5, 2.0));
  }
  
  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }
  
  void toggleEnabled() {
    state = state.copyWith(isEnabled: !state.isEnabled);
  }
  
  void increaseRate() {
    setRate(state.rate + 0.1);
  }
  
  void decreaseRate() {
    setRate(state.rate - 0.1);
  }
}

/// Provider for haptic feedback settings
final hapticEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider for tracking if camera is ready
final cameraReadyProvider = StateProvider<bool>((ref) => false);

/// Provider for tracking continuous description state
final continuousDescriptionProvider = StateProvider<bool>((ref) => true);

/// Provider for last spoken text (for repeat functionality)
final lastSpokenTextProvider = StateProvider<String>((ref) => '');

/// Provider for AI processing state
final isProcessingProvider = StateProvider<bool>((ref) => false);

/// Provider for error messages
final errorMessageProvider = StateProvider<String?>((ref) => null);
