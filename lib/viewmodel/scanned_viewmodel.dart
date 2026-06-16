import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:readit/services/firebase_service.dart';
import 'package:logger/logger.dart';
import 'package:readit/utils/snackbar_utils.dart';

class ScannedTextViewModel {
  final FirebaseService _firebaseService = FirebaseService();
  final Logger _logger = Logger();
  void copyTextToClipboard(
      {required BuildContext context, required String text}) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      SnackBarUtils.showSuccessSnackBar(context, "Text copied successfully!");
    });
  }

  Future<void> saveToFirebase(String text, String source) async {
    try {
      await _firebaseService.saveExtractedText(text, source);
      _logger.i('Text saved to Firebase successfully');
      return Future.value();
    } catch (e) {
      _logger.e('Error saving text to Firebase: $e');
      return Future.error(e);
    }
  }
}
