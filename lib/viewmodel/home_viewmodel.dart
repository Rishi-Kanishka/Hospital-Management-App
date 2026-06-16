import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:readit/repository/image_repository.dart';
import 'package:readit/services/firebase_service.dart';
import 'package:logger/logger.dart';

class HomeViewModel {
  final ImageRepository _imageRepository = ImageRepository();
  final FirebaseService _firebaseService = FirebaseService();
  final Logger _logger = Logger();

  void processImageExtractText({
    required ImageSource imageSource,
    required Function(String) onTextExtracted,
  }) async {
    _logger.i('Starting image processing for ${imageSource == ImageSource.camera ? "camera" : "gallery"}');
    
    final File? imageFile = await _imageRepository.pickImage(source: imageSource);
    if (imageFile == null) {
      _logger.i('No image selected');
      return;
    }

    final croppedFile = await _imageRepository.cropImage(imageFile: imageFile);
    if (croppedFile == null) {
      _logger.i('Image cropping cancelled');
      return;
    }

    _logger.i('Image cropped successfully, starting text recognition');
    final recognizedText = await _imageRepository.recognizeTextFromImage(
      imgPath: croppedFile.path,
    );
    
    _logger.i('Text recognized: ${recognizedText.length} characters');
    
    // Save the extracted text to Firebase
    try {
      String source = imageSource == ImageSource.camera ? 'Camera' : 'Gallery';
      await _firebaseService.saveExtractedText(recognizedText, source);
      _logger.i('Text saved to Firebase successfully');
    } catch (e) {
      _logger.e('Error saving text to Firebase: $e');
      // Continue with the flow even if saving to Firebase fails
    }
    
    // Make sure to call the callback within a try block to catch any exceptions
    try {
      _logger.i('Calling onTextExtracted callback with text length: ${recognizedText.length}');
      onTextExtracted(recognizedText);
      _logger.i('Successfully executed onTextExtracted callback');
    } catch (e) {
      _logger.e('Error executing onTextExtracted callback: $e');
    }
  }
}
