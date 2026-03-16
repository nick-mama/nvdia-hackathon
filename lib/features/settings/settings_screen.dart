import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visionaid/core/constants/app_constants.dart';
import 'package:visionaid/core/providers/app_state_provider.dart';
import 'package:visionaid/core/theme/app_theme.dart';
import 'package:visionaid/features/scene/nemotron_service.dart';
import 'package:visionaid/features/tts/tts_service.dart';

/// Settings Screen - Accessible settings for TTS, detection, and privacy
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _apiKeyVisible = false;
  
  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _announceScreen();
  }
  
  Future<void> _loadApiKey() async {
    final nemotron = ref.read(nemotronServiceProvider);
    final hasKey = await nemotron.hasApiKey();
    if (hasKey) {
      _apiKeyController.text = '••••••••••••••••';
    }
  }
  
  void _announceScreen() {
    ref.read(ttsServiceProvider).speak(
      'Settings screen. Swipe to navigate options.',
      priority: AlertPriority.info,
    );
  }
  
  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ttsSettings = ref.watch(ttsSettingsProvider);
    final hapticEnabled = ref.watch(hapticEnabledProvider);
    
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('Settings'),
        ),
        backgroundColor: AppColors.deepNavy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop();
          },
          tooltip: 'Go back',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TTS Section
          _SectionHeader(title: 'Voice Settings'),
          const SizedBox(height: 12),
          
          // Speech Rate
          _SettingsTile(
            title: 'Speech Rate',
            subtitle: '${(ttsSettings.rate * 100).toInt()}%',
            icon: Icons.speed,
            child: Slider(
              value: ttsSettings.rate,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: '${(ttsSettings.rate * 100).toInt()}%',
              activeColor: AppColors.accessibilityTeal,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref.read(ttsSettingsProvider.notifier).setRate(value);
              },
            ),
          ),
          
          // Speech Pitch
          _SettingsTile(
            title: 'Speech Pitch',
            subtitle: '${(ttsSettings.pitch * 100).toInt()}%',
            icon: Icons.tune,
            child: Slider(
              value: ttsSettings.pitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: '${(ttsSettings.pitch * 100).toInt()}%',
              activeColor: AppColors.accessibilityTeal,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref.read(ttsSettingsProvider.notifier).setPitch(value);
              },
            ),
          ),
          
          // TTS Enabled Toggle
          _SettingsTile(
            title: 'Voice Output',
            subtitle: ttsSettings.isEnabled ? 'Enabled' : 'Disabled',
            icon: ttsSettings.isEnabled ? Icons.volume_up : Icons.volume_off,
            trailing: Switch(
              value: ttsSettings.isEnabled,
              activeColor: AppColors.accessibilityTeal,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref.read(ttsSettingsProvider.notifier).toggleEnabled();
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Feedback Section
          _SectionHeader(title: 'Feedback'),
          const SizedBox(height: 12),
          
          _SettingsTile(
            title: 'Haptic Feedback',
            subtitle: hapticEnabled ? 'Enabled' : 'Disabled',
            icon: Icons.vibration,
            trailing: Switch(
              value: hapticEnabled,
              activeColor: AppColors.accessibilityTeal,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref.read(hapticEnabledProvider.notifier).state = value;
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // API Configuration
          _SectionHeader(title: 'AI Configuration'),
          const SizedBox(height: 12),
          
          _SettingsTile(
            title: 'NVIDIA API Key',
            subtitle: 'Required for AI features',
            icon: Icons.key,
            child: Column(
              children: [
                TextField(
                  controller: _apiKeyController,
                  obscureText: !_apiKeyVisible,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter your API key',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: AppColors.deepNavy,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accessibilityTeal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accessibilityTeal.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accessibilityTeal, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _apiKeyVisible ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.accessibilityTeal,
                      ),
                      onPressed: () {
                        setState(() => _apiKeyVisible = !_apiKeyVisible);
                      },
                      tooltip: _apiKeyVisible ? 'Hide API key' : 'Show API key',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveApiKey,
                    child: const Text('Save API Key'),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          _SectionHeader(title: 'About'),
          const SizedBox(height: 12),
          
          _SettingsTile(
            title: 'VisionAid',
            subtitle: 'Version 1.0.0 MVP',
            icon: Icons.info,
          ),
          
          _SettingsTile(
            title: 'Powered by',
            subtitle: 'NVIDIA Nemotron AI',
            icon: Icons.auto_awesome,
          ),
          
          const SizedBox(height: 32),
          
          // Test TTS Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _testTts,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Test Voice Output'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accessibilityTeal,
                side: const BorderSide(color: AppColors.accessibilityTeal),
                minimumSize: const Size(44, 56),
              ),
            ),
          ),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }
  
  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty || apiKey.startsWith('•')) {
      ref.read(ttsServiceProvider).speak(
        'Please enter a valid API key',
        priority: AlertPriority.warning,
      );
      return;
    }
    
    final nemotron = ref.read(nemotronServiceProvider);
    await nemotron.saveApiKey(apiKey);
    
    HapticFeedback.mediumImpact();
    
    ref.read(ttsServiceProvider).speak(
      'API key saved successfully',
      priority: AlertPriority.info,
    );
    
    // Mask the key after saving
    setState(() {
      _apiKeyController.text = '••••••••••••••••';
      _apiKeyVisible = false;
    });
  }
  
  void _testTts() {
    HapticFeedback.selectionClick();
    ref.read(ttsServiceProvider).speak(
      'This is a test of VisionAid voice output. Your current speech rate and pitch settings are being used.',
      priority: AlertPriority.info,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.accessibilityTeal,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final Widget? child;
  
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $subtitle',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.deepNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accessibilityTeal.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accessibilityTeal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.accessibilityTeal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: 16),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}
