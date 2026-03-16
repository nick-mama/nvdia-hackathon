import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visionaid/core/constants/app_constants.dart';
import 'package:visionaid/core/providers/app_state_provider.dart';

/// Provider for available cameras
final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});

/// Provider for camera controller
final cameraControllerProvider = StateNotifierProvider<CameraControllerNotifier, AsyncValue<CameraController>>((ref) {
  return CameraControllerNotifier(ref);
});

/// Camera Controller State Notifier
class CameraControllerNotifier extends StateNotifier<AsyncValue<CameraController>> {
  final Ref _ref;
  CameraController? _controller;
  Timer? _frameTimer;
  bool _isCapturing = false;
  
  // Callback for frame processing
  void Function(Uint8List imageBytes)? onFrameCaptured;
  
  CameraControllerNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        state = AsyncValue.error('No cameras available', StackTrace.current);
        return;
      }
      
      // Use rear camera for scene capture (as per PRD)
      final rearCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      
      _controller = CameraController(
        rearCamera,
        ResolutionPreset.medium, // 720p as per PRD
        enableAudio: false, // No audio recording as per PRD
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _controller!.initialize();
      
      // Set flash off by default
      await _controller!.setFlashMode(FlashMode.off);
      
      state = AsyncValue.data(_controller!);
      _ref.read(cameraReadyProvider.notifier).state = true;
      
      print('[VisionAid Camera] Initialized successfully');
    } catch (e, stack) {
      print('[VisionAid Camera] Initialization error: $e');
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// Start continuous frame capture for AI processing
  void startContinuousCapture() {
    if (_isCapturing || _controller == null || !_controller!.value.isInitialized) {
      return;
    }
    
    _isCapturing = true;
    
    // Capture frames at interval defined in PRD (4 seconds)
    _frameTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.sceneDescriptionIntervalMs),
      (_) => _captureFrame(),
    );
    
    print('[VisionAid Camera] Started continuous capture');
  }
  
  /// Stop continuous frame capture
  void stopContinuousCapture() {
    _frameTimer?.cancel();
    _frameTimer = null;
    _isCapturing = false;
    print('[VisionAid Camera] Stopped continuous capture');
  }
  
  /// Capture single frame on demand
  Future<Uint8List?> captureFrame() async {
    return await _captureFrame();
  }
  
  Future<Uint8List?> _captureFrame() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    
    try {
      final XFile imageFile = await _controller!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Notify listeners
      onFrameCaptured?.call(imageBytes);
      
      return imageBytes;
    } catch (e) {
      print('[VisionAid Camera] Frame capture error: $e');
      return null;
    }
  }
  
  /// Toggle flash for low-light OCR
  Future<void> toggleFlash() async {
    if (_controller == null) return;
    
    final currentMode = _controller!.value.flashMode;
    final newMode = currentMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    
    await _controller!.setFlashMode(newMode);
  }
  
  /// Check if flash is on
  bool get isFlashOn => _controller?.value.flashMode == FlashMode.torch;
  
  /// Get current camera controller
  CameraController? get controller => _controller;
  
  @override
  void dispose() {
    stopContinuousCapture();
    _controller?.dispose();
    super.dispose();
  }
}

/// Provider for frame capture stream
final frameCaptureStreamProvider = StreamProvider<Uint8List>((ref) {
  final controller = StreamController<Uint8List>();
  
  final cameraNotifier = ref.watch(cameraControllerProvider.notifier);
  cameraNotifier.onFrameCaptured = (bytes) {
    controller.add(bytes);
  };
  
  ref.onDispose(() {
    controller.close();
  });
  
  return controller.stream;
});
