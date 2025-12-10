import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Service for extracting Aadhaar number from ID card images using OCR
class AadhaarOcrService {
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Aadhaar number regex pattern (12 digits, may be space-separated as 4-4-4)
  static final RegExp _aadhaarPattern = RegExp(
    r'\b\d{4}\s?\d{4}\s?\d{4}\b',
    multiLine: true,
  );

  /// Pick image from camera or gallery and extract Aadhaar number
  Future<AadhaarOcrResult> pickAndExtract({required ImageSource source}) async {
    try {
      debugPrint('📷 Picking image from ${source.name}');

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        return AadhaarOcrResult(success: false, message: 'No image selected');
      }

      return await extractFromFile(File(image.path));
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return AadhaarOcrResult(
        success: false,
        message: 'Failed to pick image: $e',
      );
    }
  }

  /// Extract Aadhaar number from a file
  Future<AadhaarOcrResult> extractFromFile(File imageFile) async {
    try {
      debugPrint('🔍 Extracting text from image: ${imageFile.path}');

      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      debugPrint('📝 Recognized text: ${recognizedText.text}');

      // Search for Aadhaar pattern in recognized text
      final match = _aadhaarPattern.firstMatch(recognizedText.text);

      if (match != null) {
        // Clean up the Aadhaar number (remove spaces)
        final aadhaarNumber = match.group(0)!.replaceAll(' ', '');

        debugPrint('✅ Found Aadhaar number: $aadhaarNumber');

        return AadhaarOcrResult(
          success: true,
          aadhaarNumber: aadhaarNumber,
          imagePath: imageFile.path,
          rawText: recognizedText.text,
          message: 'Aadhaar number extracted successfully',
        );
      } else {
        debugPrint('⚠️ No Aadhaar number found in text');

        return AadhaarOcrResult(
          success: false,
          imagePath: imageFile.path,
          rawText: recognizedText.text,
          message:
              'No Aadhaar number found in the image. Please try again with a clearer image.',
        );
      }
    } catch (e) {
      debugPrint('❌ Error extracting text: $e');
      return AadhaarOcrResult(
        success: false,
        message: 'Failed to process image: $e',
      );
    }
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}

/// Result of Aadhaar OCR extraction
class AadhaarOcrResult {
  final bool success;
  final String? aadhaarNumber;
  final String? imagePath;
  final String? rawText;
  final String message;

  AadhaarOcrResult({
    required this.success,
    this.aadhaarNumber,
    this.imagePath,
    this.rawText,
    required this.message,
  });

  /// Format Aadhaar number as xxxx xxxx xxxx
  String? get formattedAadhaarNumber {
    if (aadhaarNumber == null || aadhaarNumber!.length != 12) return null;
    return '${aadhaarNumber!.substring(0, 4)} ${aadhaarNumber!.substring(4, 8)} ${aadhaarNumber!.substring(8, 12)}';
  }
}
