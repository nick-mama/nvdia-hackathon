import 'package:camera/camera.dart' as camera;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visionaid/core/constants/app_constants.dart';
import 'package:visionaid/core/providers/app_state_provider.dart';
import 'package:visionaid/core/theme/app_theme.dart';
import 'package:visionaid/features/camera/camera_service.dart';
import 'package:visionaid/features/tts/tts_service.dart';
import 'package:visionaid/features/scene/nemotron_service.dart';
import 'package:visionaid/features/ocr/ocr_service.dart';
import 'package:visionaid/features/modes/mode_selector.dart';
import 'package:visionaid/ui/widgets/spoken_output_display.dart';
import 'package:visionaid/ui/widgets/status_indicator.dart';

/// Main Camera Screen - F-04 Accessible Navigation UI
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    // Initialize TTS first for audio feedback
    await ref.read(ttsServiceProvider).initialize();
    
    // Announce app ready
    await ref.read(ttsServiceProvider).speak(
      'VisionAid ready. Double tap to describe scene. Single tap to read text.',
      priority: AlertPriority.info,
    );
    
    setState(() => _isInitialized = true);
    
    // Start continuous capture if in scene mode
    final currentMode = ref.read(currentModeProvider);
    if (currentMode == AppMode.scene) {
      _startContinuousDescription();
    }
  }
  
  void _startContinuousDescription() {
    final cameraNotifier = ref.read(cameraControllerProvider.notifier);
    cameraNotifier.startContinuousCapture();
    
    // Set up frame processing
    cameraNotifier.onFrameCaptured = (imageBytes) async {
      final mode = ref.read(currentModeProvider);
      final isProcessing = ref.read(isProcessingProvider);
      final continuousEnabled = ref.read(continuousDescriptionProvider);
      
      if (!continuousEnabled || isProcessing) return;
      
      if (mode == AppMode.scene || mode == AppMode.explore) {
        await _processSceneDescription(imageBytes);
      }
    };
  }
  
  Future<void> _processSceneDescription(dynamic imageBytes) async {
    ref.read(isProcessingProvider.notifier).state = true;
    
    try {
      final nemotronService = ref.read(nemotronServiceProvider);
      final mode = ref.read(currentModeProvider);
      
      final description = await nemotronService.describeScene(
        imageBytes,
        detailed: mode == AppMode.explore,
      );
      
      if (description != null && description.isNotEmpty) {
        await ref.read(ttsServiceProvider).speak(description);
      }
    } catch (e) {
      print('[VisionAid] Scene description error: $e');
    } finally {
      ref.read(isProcessingProvider.notifier).state = false;
    }
  }
  
  Future<void> _handleDoubleTap() async {
    // F-01: Describe scene immediately on double tap
    HapticFeedback.mediumImpact();
    
    final cameraNotifier = ref.read(cameraControllerProvider.notifier);
    final imageBytes = await cameraNotifier.captureFrame();
    
    if (imageBytes != null) {
      await _processSceneDescription(imageBytes);
    }
  }
  
  Future<void> _handleSingleTap() async {
    // F-03: Read text on single tap
    HapticFeedback.lightImpact();
    
    final cameraNotifier = ref.read(cameraControllerProvider.notifier);
    final imageBytes = await cameraNotifier.captureFrame();
    
    if (imageBytes != null) {
      ref.read(isProcessingProvider.notifier).state = true;
      
      try {
        final ocrService = ref.read(ocrServiceProvider);
        final text = await ocrService.recognizeText(imageBytes);
        
        if (text != null && text.isNotEmpty) {
          await ref.read(ttsServiceProvider).speak(text);
        } else {
          await ref.read(ttsServiceProvider).speak('No text detected.');
        }
      } catch (e) {
        print('[VisionAid] OCR error: $e');
        await ref.read(ttsServiceProvider).announceError(
          'Unable to read text',
          recovery: 'Try adjusting camera position',
        );
      } finally {
        ref.read(isProcessingProvider.notifier).state = false;
      }
    }
  }
  
  void _handleLongPress() {
    // Open mode selector
    HapticFeedback.heavyImpact();
    _showModeSelector();
  }
  
  void _handleSwipeUp() {
    // Cycle through modes
    HapticFeedback.selectionClick();
    final modeNotifier = ref.read(currentModeProvider.notifier);
    modeNotifier.cycleMode();
    
    final newMode = ref.read(currentModeProvider);
    ref.read(ttsServiceProvider).announceMode(newMode);
    
    // Update continuous capture based on mode
    final cameraNotifier = ref.read(cameraControllerProvider.notifier);
    if (newMode == AppMode.scene || newMode == AppMode.explore) {
      cameraNotifier.startContinuousCapture();
    } else {
      cameraNotifier.stopContinuousCapture();
    }
  }
  
  void _handleSwipeDown() {
    // Repeat last spoken output
    HapticFeedback.selectionClick();
    ref.read(ttsServiceProvider).repeatLast();
  }
  
  void _handleTwoFingerTap() {
    // Pause/resume continuous description
    HapticFeedback.mediumImpact();
    final current = ref.read(continuousDescriptionProvider);
    ref.read(continuousDescriptionProvider.notifier).state = !current;
    
    final status = current ? 'Continuous description paused' : 'Continuous description resumed';
    ref.read(ttsServiceProvider).speak(status, priority: AlertPriority.warning);
  }
  
  void _showModeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ModeSelector(),
    );
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraState = ref.read(cameraControllerProvider);
    
    cameraState.whenData((controller) {
      if (state == AppLifecycleState.inactive) {
        ref.read(cameraControllerProvider.notifier).stopContinuousCapture();
      } else if (state == AppLifecycleState.resumed) {
        final currentMode = ref.read(currentModeProvider);
        if (currentMode == AppMode.scene || currentMode == AppMode.explore) {
          _startContinuousDescription();
        }
      }
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraControllerProvider);
    final currentMode = ref.watch(currentModeProvider);
    final isProcessing = ref.watch(isProcessingProvider);
    
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: GestureDetector(
        onDoubleTap: _handleDoubleTap,
        onTap: _handleSingleTap,
        onLongPress: _handleLongPress,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -500) {
              _handleSwipeUp();
            } else if (details.primaryVelocity! > 500) {
              _handleSwipeDown();
            }
          }
        },
        child: Semantics(
          label: 'Camera view. ${currentMode.displayName} active. '
              'Double tap to describe scene. Single tap to read text. '
              'Swipe up to change mode. Swipe down to repeat last output. '
              'Long press for settings.',
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera Preview
              cameraState.when(
                data: (controller) => controller.value.isInitialized
                    ? CameraPreviewWidget(controller: controller)
                    : const _LoadingView(),
                loading: () => const _LoadingView(),
                error: (error, _) => _ErrorView(error: error.toString()),
              ),
              
              // Status Overlay
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: StatusIndicator(
                  mode: currentMode,
                  isProcessing: isProcessing,
                ),
              ),
              
              // Spoken Output Display
              const Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: SpokenOutputDisplay(),
              ),
              
              // Mode indicator at bottom
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 0,
                right: 0,
                child: _ModeIndicator(mode: currentMode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CameraPreviewWidget extends StatelessWidget {
  final camera.CameraController controller;
  
  const CameraPreviewWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = 1 / (controller.value.aspectRatio * size.aspectRatio);
    
    return ClipRect(
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: Center(
          child: camera.CameraPreview(controller),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.deepNavy,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.accessibilityTeal,
              semanticsLabel: 'Loading camera',
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing camera...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.deepNavy,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.warmAmber,
              semanticLabel: 'Error',
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Error',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeIndicator extends StatelessWidget {
  final AppMode mode;
  
  const _ModeIndicator({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Current mode: ${mode.displayName}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.deepNavy.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.accessibilityTeal,
            width: 2,
          ),
        ),
        child: Text(
          mode.displayName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.accessibilityTeal,
          ),
        ),
      ),
    );
  }
}
