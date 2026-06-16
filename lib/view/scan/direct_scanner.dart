import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:readit/constants/styles.dart';
import 'package:readit/repository/image_repository.dart';
import 'package:readit/services/firebase_service.dart';
import 'package:readit/service/emr_service.dart';
import 'package:readit/model/patient.dart';
import 'package:readit/model/visit.dart';
import 'package:readit/widget/button_widget.dart';
import 'package:logger/logger.dart';
import 'package:readit/view/prescription/prescription_detail_screen.dart';

class DirectScanner extends StatefulWidget {
  final ImageSource source;

  const DirectScanner({super.key, required this.source});

  @override
  State<DirectScanner> createState() => _DirectScannerState();
}

class _DirectScannerState extends State<DirectScanner> {
  // Add EMRService for EMR integration
  final emrService = EMRService();
  final Logger _logger = Logger();
  final ImageRepository _imageRepository = ImageRepository();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = true;
  String _extractedText = '';
  String _errorMessage = '';
  Map<String, dynamic>? _prescriptionData;
  bool _showPrescriptionView = false;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      _logger.i('Starting image processing for ${widget.source}');

      // Pick image
      final File? imageFile =
          await _imageRepository.pickImage(source: widget.source);
      if (imageFile == null) {
        _logger.i('No image selected, returning to previous page');
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      // Crop image
      final croppedFile =
          await _imageRepository.cropImage(imageFile: imageFile);
      if (croppedFile == null) {
        _logger.i('Image cropping cancelled, returning to previous page');
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      // Process image
      _logger.i('Image cropped successfully, starting text recognition');
      final data = await _imageRepository.recognizePrescriptionFromImage(
        imgPath: croppedFile.path,
      );

      _logger.i('Text recognized and parsed as prescription');

      // Save to Firebase - but don't wait for it to complete
      try {
        String source =
            widget.source == ImageSource.camera ? 'Camera' : 'Gallery';
        // Don't await this call so we don't block the UI if Firebase has issues
        _firebaseService
            .saveExtractedText(data['rawText'] ?? '', source)
            .then((_) {
          _logger.i('Text saved to Firebase successfully');
        }).catchError((e) {
          _logger.e('Error saving text to Firebase: $e');
          // Show error in console but don't block UI
        });
      } catch (e) {
        _logger.e('Error initiating Firebase save: $e');
        // Continue even if Firebase save fails
      }

      // EMR: Store prescription data in Firestore under patient/visit
      try {
        final pd = data['prescriptionData'] as Map<String, dynamic>?;
        if (pd != null &&
            (pd['patient_name']?.isNotEmpty ?? false) &&
            (pd['patient_dob']?.isNotEmpty ?? false)) {
          // 1. Try to find patient by name + dob
          // Normalize name and dob for matching
          final normalizedName =
              (pd['patient_name'] ?? '').trim().toLowerCase();
          final normalizedDob = (pd['patient_dob'] ?? '').trim();
          final patient = await emrService.findPatientByNameDob(
              normalizedName, normalizedDob);
          String patientId;
          if (patient != null) {
            patientId = patient.id;
          } else {
            // Parse age as int, fallback to 0
            int age = 0;
            try {
              age = int.parse(pd['patient_age'] ?? '0');
            } catch (_) {}
            final newPatient = Patient(
              id: '',
              name: normalizedName, // Store normalized name
              dob: normalizedDob, // Store normalized dob
              age: age,
            );
            patientId = await emrService.addPatient(newPatient);
          }
          // 2. Add visit under patient
          final visit = Visit(
            id: '',
            date: pd['prescription_date'] ?? '',
            doctorName: pd['doctor_name'] ?? '',
            medicines: List<Map<String, dynamic>>.from(pd['medicines'] ?? []),
            notes: [pd['special_instructions'], pd['additional_notes']]
                .where((e) => (e?.toString().isNotEmpty ?? false))
                .join('\n'),
            scanImageUrl: null, // Add scan image URL if available
            createdAt: DateTime.now().toUtc().toIso8601String(),
          );
          await emrService.addVisit(patientId, visit);
          _logger.i(
              'EMR: Prescription data saved to Firestore for patient $patientId');
        }
      } catch (e) {
        _logger.e('EMR: Error saving prescription to Firestore: $e');
      }

      // Update UI
      if (mounted) {
        setState(() {
          _extractedText = data['rawText'] ?? '';
          _prescriptionData = data['prescriptionData'] as Map<String, dynamic>?;
          _isLoading = false;
          // Automatically show prescription view if we detected it's a prescription
          _showPrescriptionView = _isPrescription(_prescriptionData);
        });
      }
    } catch (e) {
      _logger.e('Error in process image: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error processing image: $e';
          _isLoading = false;
        });
      }
    }
  }

  bool _isPrescription(Map<String, dynamic>? data) {
    if (data == null) return false;

    // Check if we have any key prescription fields filled
    return (data['patient_name']?.isNotEmpty ?? false) ||
        (data['doctor_name']?.isNotEmpty ?? false) ||
        (data['medicines']?.isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _logger.i('Back button pressed');
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5), // Match home screen bg
        appBar: null,
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(
                      color: Color(0xFF1F3C88), // Match home button icon
                      strokeWidth: 3.5,
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Processing image...",
                      style: TextStyle(
                        color: Color(0xFF1F3C88),
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _showPrescriptionView && _prescriptionData != null
                    ? PrescriptionDetailScreen(
                        prescriptionData: _prescriptionData!)
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: Text("Scanned Text",
                                  style: AppStyles.titleStyle),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color:
                                      Color(0xFFF5F5F5), // Match home screen bg
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    _extractedText,
                                    style: AppStyles.subTextSecondary
                                        .copyWith(color: Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              text: "Copy Text",
                              onTap: () {
                                _copyTextToClipboard(context, _extractedText);
                              },
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  void _copyTextToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Text copied!")),
      );
    });
  }
}
  