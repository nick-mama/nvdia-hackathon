import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// OCR Service Provider
final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// OCR Service using Google ML Kit
/// Implements F-03: Text Reading feature from PRD
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  
  bool _isProcessing = false;
  
  /// Recognize text from image bytes
  /// Target: < 2 seconds from capture to first word (PRD requirement)
  Future<String?> recognizeText(Uint8List imageBytes) async {
    if (_isProcessing) {
      print('[VisionAid OCR] Already processing, skipping');
      return null;
    }
    
    _isProcessing = true;
    
    try {
      // Decode image to get dimensions
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        print('[VisionAid OCR] Failed to decode image');
        return null;
      }
      
      // Create InputImage from bytes
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: ui.Size(
            decodedImage.width.toDouble(),
            decodedImage.height.toDouble(),
          ),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: decodedImage.width,
        ),
      );
      
      // Process image
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        return null;
      }
      
      // Build readable output
      return _formatRecognizedText(recognizedText);
    } catch (e) {
      print('[VisionAid OCR] Recognition error: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Format recognized text for TTS output
  String _formatRecognizedText(RecognizedText recognizedText) {
    final buffer = StringBuffer();
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        buffer.writeln(line.text);
      }
      buffer.writeln(); // Paragraph break between blocks
    }
    
    return buffer.toString().trim();
  }
  
  /// Check if text fills significant portion of frame
  /// Auto-detect when text fills > 30% of frame (PRD requirement)
  Future<bool> hasSignificantText(Uint8List imageBytes) async {
    try {
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return false;
      
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: ui.Size(
            decodedImage.width.toDouble(),
            decodedImage.height.toDouble(),
          ),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: decodedImage.width,
        ),
      );
      
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.blocks.isEmpty) return false;
      
      // Calculate text coverage
      final imageArea = decodedImage.width * decodedImage.height;
      double textArea = 0;
      
      for (final block in recognizedText.blocks) {
        final boundingBox = block.boundingBox;
        textArea += boundingBox.width * boundingBox.height;
      }
      
      final coverage = textArea / imageArea;
      return coverage > 0.3; // 30% threshold from PRD
    } catch (e) {
      print('[VisionAid OCR] Coverage check error: $e');
      return false;
    }
  }
  
  /// Get text blocks with position information
  /// Useful for spatial description of text layout
  Future<List<TextBlockInfo>> getTextBlocks(Uint8List imageBytes) async {
    try {
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return [];
      
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: ui.Size(
            decodedImage.width.toDouble(),
            decodedImage.height.toDouble(),
          ),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: decodedImage.width,
        ),
      );
      
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.blocks.map((block) {
        final position = _determinePosition(
          block.boundingBox,
          decodedImage.width.toDouble(),
          decodedImage.height.toDouble(),
        );
        
        return TextBlockInfo(
          text: block.text,
          position: position,
          confidence: block.lines.isNotEmpty 
              ? block.lines.first.confidence ?? 0.0 
              : 0.0,
        );
      }).toList();
    } catch (e) {
      print('[VisionAid OCR] Block extraction error: $e');
      return [];
    }
  }
  
  /// Determine spatial position of text block
  String _determinePosition(
    ui.Rect boundingBox,
    double imageWidth,
    double imageHeight,
  ) {
    final centerX = boundingBox.center.dx;
    final centerY = boundingBox.center.dy;
    
    final horizontalThird = imageWidth / 3;
    final verticalThird = imageHeight / 3;
    
    String horizontal;
    if (centerX < horizontalThird) {
      horizontal = 'left';
    } else if (centerX > horizontalThird * 2) {
      horizontal = 'right';
    } else {
      horizontal = 'center';
    }
    
    String vertical;
    if (centerY < verticalThird) {
      vertical = 'top';
    } else if (centerY > verticalThird * 2) {
      vertical = 'bottom';
    } else {
      vertical = 'middle';
    }
    
    if (horizontal == 'center' && vertical == 'middle') {
      return 'center';
    }
    
    return '$vertical $horizontal';
  }
  
  void dispose() {
    _textRecognizer.close();
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
