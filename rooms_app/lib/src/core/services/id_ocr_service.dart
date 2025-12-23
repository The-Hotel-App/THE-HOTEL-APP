import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rooms/src/core/logging/app_logger.dart';

/// Service for extracting ID numbers from government ID card images using OCR
/// Supports: Aadhaar, PAN, Passport, Driving License, Voter ID
class IdOcrService {
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  // ID number patterns
  static final RegExp _aadhaarPattern = RegExp(
    r'\b\d{4}\s?\d{4}\s?\d{4}\b',
    multiLine: true,
  );

  static final RegExp _panPattern = RegExp(
    r'\b[A-Z]{5}\d{4}[A-Z]\b',
    multiLine: true,
  );

  static final RegExp _passportPattern = RegExp(
    r'\b[A-Z]\d{7}\b',
    multiLine: true,
  );

  static final RegExp _drivingLicensePattern = RegExp(
    r'\b[A-Z]{2}\d{2}\s?\d{11}\b|\b[A-Z]{2}-\d{2}\d{11}\b',
    multiLine: true,
  );

  static final RegExp _voterIdPattern = RegExp(
    r'\b[A-Z]{3}\d{7}\b',
    multiLine: true,
  );

  /// Pick image from camera or gallery and extract ID number
  Future<IdOcrResult> pickAndExtract({required ImageSource source}) async {
    try {
      AppLogger.info('Picking image from ${source.name}', tag: 'OCR');

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        return IdOcrResult(success: false, message: 'No image selected');
      }

      return await extractFromFile(File(image.path));
    } catch (e) {
      AppLogger.error('Error picking image', tag: 'OCR', error: e);
      return IdOcrResult(success: false, message: 'Failed to pick image: $e');
    }
  }

  /// Extract ID number from a file - tries all ID patterns
  Future<IdOcrResult> extractFromFile(File imageFile) async {
    try {
      AppLogger.debug('Extracting text from image', tag: 'OCR');

      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      AppLogger.debug('Text recognized, searching for ID patterns', tag: 'OCR');

      // Try all patterns in order of likelihood
      String? idNumber;
      String? idType;

      // Try Aadhaar (most common in India)
      final aadhaarMatch = _aadhaarPattern.firstMatch(recognizedText.text);
      if (aadhaarMatch != null) {
        idNumber = aadhaarMatch.group(0)!.replaceAll(' ', '');
        idType = 'Aadhaar';
        AppLogger.success('Found Aadhaar number', tag: 'OCR');
      }

      // Try PAN
      if (idNumber == null) {
        final panMatch = _panPattern.firstMatch(recognizedText.text);
        if (panMatch != null) {
          idNumber = panMatch.group(0)!;
          idType = 'PAN';
          AppLogger.success('Found PAN number', tag: 'OCR');
        }
      }

      // Try Passport
      if (idNumber == null) {
        final passportMatch = _passportPattern.firstMatch(recognizedText.text);
        if (passportMatch != null) {
          idNumber = passportMatch.group(0)!;
          idType = 'Passport';
          AppLogger.success('Found Passport number', tag: 'OCR');
        }
      }

      // Try Driving License
      if (idNumber == null) {
        final dlMatch = _drivingLicensePattern.firstMatch(recognizedText.text);
        if (dlMatch != null) {
          idNumber = dlMatch.group(0)!.replaceAll(' ', '').replaceAll('-', '');
          idType = 'Driving License';
          AppLogger.success('Found Driving License number', tag: 'OCR');
        }
      }

      // Try Voter ID
      if (idNumber == null) {
        final voterMatch = _voterIdPattern.firstMatch(recognizedText.text);
        if (voterMatch != null) {
          idNumber = voterMatch.group(0)!;
          idType = 'Voter ID';
          AppLogger.success('Found Voter ID number', tag: 'OCR');
        }
      }

      if (idNumber != null) {
        return IdOcrResult(
          success: true,
          idNumber: idNumber,
          idType: idType,
          imagePath: imageFile.path,
          rawText: recognizedText.text,
          message: '$idType number extracted successfully',
        );
      } else {
        AppLogger.warning('No ID number found in text', tag: 'OCR');

        return IdOcrResult(
          success: false,
          imagePath: imageFile.path,
          rawText: recognizedText.text,
          message: 'No ID number found. Please enter manually.',
        );
      }
    } catch (e) {
      AppLogger.error('Error extracting text', tag: 'OCR', error: e);
      return IdOcrResult(
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

/// Result of ID OCR extraction
class IdOcrResult {
  final bool success;
  final String? idNumber;
  final String? idType;
  final String? imagePath;
  final String? rawText;
  final String message;

  IdOcrResult({
    required this.success,
    this.idNumber,
    this.idType,
    this.imagePath,
    this.rawText,
    required this.message,
  });
}
