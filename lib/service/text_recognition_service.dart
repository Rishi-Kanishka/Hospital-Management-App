import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'prescription_parser_service.dart';

class TextRecognitionService {
  final PrescriptionParserService _prescriptionParserService =
      PrescriptionParserService();

  /// Recognizes text from an image and returns the raw text
  Future<String> recognizeTextFromImage({required String imgPath}) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final image = InputImage.fromFile(File(imgPath));
    final recognizedText = await textRecognizer.processImage(image);
    return recognizedText.text;
  }

  /// Recognizes text from an image and attempts to parse it as a prescription
  Future<Map<String, dynamic>> recognizePrescriptionFromImage(
      {required String imgPath}) async {
    final rawText = await recognizeTextFromImage(imgPath: imgPath);
    return _prescriptionParserService.parsePrescriptionText(rawText);
  }
}
