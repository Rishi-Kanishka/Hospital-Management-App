import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../service/text_recognition_service.dart';

class ImageRepository {
  final TextRecognitionService _textRecognitionService =
      TextRecognitionService();

  Future<File?> pickImage({required ImageSource source}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  Future<CroppedFile?> cropImage({required File imageFile}) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          minimumAspectRatio: 1.0,
        ),
      ],
    );
    return croppedFile;
  }

  Future<String> recognizeTextFromImage({required String imgPath}) async {
    return await _textRecognitionService.recognizeTextFromImage(
        imgPath: imgPath);
  }

  Future<Map<String, dynamic>> recognizePrescriptionFromImage(
      {required String imgPath}) async {
    final rawText = await recognizeTextFromImage(imgPath: imgPath);
    final prescriptionData = await _textRecognitionService
        .recognizePrescriptionFromImage(imgPath: imgPath);

    return {
      'rawText': rawText,
      'prescriptionData': prescriptionData,
    };
  }
}
