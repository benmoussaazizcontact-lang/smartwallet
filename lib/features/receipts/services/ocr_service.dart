import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_errors.dart';

class OcrService {
  /// On-device recognition uses the Latin ML Kit model only.
  /// Arabic script is not recognized here. See docs/ARABIC_OCR_PLAN.md.
  ///
  /// Android 10+ (and especially API 35/36) can return null from
  /// `ContentResolver.openInputStream(file://...)`, which makes ML Kit's
  /// `InputImage.fromFilePath` throw NPE (`null.getClass()`). Decode the
  /// JPEG/PNG in Dart and pass a bitmap instead.
  Future<String> recognize({String? imagePath, Uint8List? bytes}) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Google ML Kit text recognition is not available on web. Use Android or iOS.',
      );
    }
    final data = await _loadBytes(imagePath, bytes);
    final input = await _toInputImage(data);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(input);
      return result.text;
    } on PlatformException {
      throw const OcrFailure(OcrFailureKind.engine);
    } on MissingPluginException {
      throw const OcrFailure(OcrFailureKind.engine);
    } catch (error) {
      if (error is OcrFailure) rethrow;
      throw const OcrFailure(OcrFailureKind.engine);
    } finally {
      await recognizer.close();
    }
  }

  Future<Uint8List> _loadBytes(String? imagePath, Uint8List? bytes) async {
    if (bytes != null && bytes.isNotEmpty) return bytes;
    if (imagePath == null || imagePath.isEmpty || imagePath.startsWith('content:')) {
      throw const OcrFailure(OcrFailureKind.unreadable);
    }
    final file = File(imagePath);
    if (!await file.exists()) {
      throw const OcrFailure(OcrFailureKind.unreadable);
    }
    final data = await file.readAsBytes();
    if (data.isEmpty) {
      throw const OcrFailure(OcrFailureKind.unreadable);
    }
    return data;
  }

  Future<InputImage> _toInputImage(Uint8List data) async {
    try {
      final codec = await ui.instantiateImageCodec(
        data,
        targetWidth: 1600,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (rgba == null) {
          throw const OcrFailure(OcrFailureKind.unreadable);
        }
        return InputImage.fromBitmap(
          bitmap: rgba.buffer.asUint8List(),
          width: image.width,
          height: image.height,
        );
      } finally {
        image.dispose();
      }
    } on OcrFailure {
      rethrow;
    } catch (_) {
      throw const OcrFailure(OcrFailureKind.unreadable);
    }
  }
}
