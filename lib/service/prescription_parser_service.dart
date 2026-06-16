import 'dart:convert';
import 'package:logger/logger.dart';

class PrescriptionParserService {
  final Logger _logger = Logger();

  /// Helper method to clean section content by removing its title
  String _cleanSectionContent(String rawText, String sectionTitle) {
    final regex = RegExp(r'^' + RegExp.escape(sectionTitle) + r':\s*',
        caseSensitive: false);
    return rawText.replaceFirst(regex, '').trim();
  }

  /// Helper method to extract section content between markers
  String _extractSectionContent(
      List<String> lines, int startIndex, String endMarker) {
    final List<String> sectionLines = [];
    var i = startIndex;
    while (i < lines.length &&
        !lines[i].toLowerCase().contains(endMarker.toLowerCase())) {
      sectionLines.add(lines[i]);
      i++;
    }
    return sectionLines.join('\n').trim();
  }

  /// Function to parse raw OCR text into structured prescription data
  Map<String, dynamic> parsePrescriptionText(String rawText) {
    try {
      // Initialize empty prescription data
      final Map<String, dynamic> prescriptionData = {
        'patient_name': '',
        'patient_age': '',
        'patient_dob': '',
        'prescription_date': '',
        'doctor_name': '',
        'medicines': <Map<String, String>>[],
        'special_instructions': '',
        'additional_notes': '',
      };

      // Split the text into lines and clean them
      final lines = rawText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(); // Process each line
      List<String> medicineLines = []; // Collect medicine-related lines

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lowerLine = line.toLowerCase();

        // Check for section markers
        if (lowerLine.contains('special instructions:')) {
          String content =
              _extractSectionContent(lines, i + 1, 'additional notes');
          prescriptionData['special_instructions'] =
              _cleanSectionContent(content, '');
          continue;
        } else if (lowerLine.contains('additional notes:')) {
          String content = _extractSectionContent(lines, i + 1, '');
          prescriptionData['additional_notes'] =
              _cleanSectionContent(content, '');
          continue;
        }

        // Process other sections (patient info, medicines, etc.)
        if (_isPatientInfo(line)) {
          _extractPatientInfo(line, prescriptionData);
        } else if (_isDoctorInfo(line)) {
          prescriptionData['doctor_name'] = _extractDoctorName(line);
        } else if (_isDate(line)) {
          prescriptionData['prescription_date'] = _formatDate(line);
        } else if (_isMedicineLine(line)) {
          medicineLines.add(line);
        } else if (_isSpecialInstruction(line)) {
          if (prescriptionData['special_instructions'].isEmpty) {
            prescriptionData['special_instructions'] = line;
          } else {
            prescriptionData['special_instructions'] += '\n$line';
          }
        } else if (line.isNotEmpty) {
          if (prescriptionData['additional_notes'].isEmpty) {
            prescriptionData['additional_notes'] = line;
          } else {
            prescriptionData['additional_notes'] += '\n$line';
          }
        }
      }

      // Process collected medicine lines
      prescriptionData['medicines'] = _extractMedicines(medicineLines);

      _logger.i(
          'Prescription parsed successfully: ${jsonEncode(prescriptionData)}');
      return prescriptionData;
    } catch (e) {
      _logger.e('Error parsing prescription: $e');
      // Return empty data structure if parsing fails
      return {
        'patient_name': '',
        'patient_age': '',
        'patient_dob': '',
        'prescription_date': '',
        'doctor_name': '',
        'medicines': <Map<String, String>>[],
        'special_instructions': '',
        'additional_notes': '',
      };
    }
  }

  bool _isPatientInfo(String line) {
    final patientPatterns = [
      RegExp(r'patient', caseSensitive: false),
      RegExp(r'name\s*:', caseSensitive: false),
      RegExp(r'age\s*:', caseSensitive: false),
      RegExp(r'dob\s*:', caseSensitive: false),
    ];
    return patientPatterns.any((pattern) => pattern.hasMatch(line));
  }

  bool _isDoctorInfo(String line) {
    final doctorPatterns = [
      RegExp(r'dr\.?\s', caseSensitive: false),
      RegExp(r'doctor', caseSensitive: false),
      RegExp(r'physician', caseSensitive: false),
      RegExp(r'consultant', caseSensitive: false),
    ];
    return doctorPatterns.any((pattern) => pattern.hasMatch(line));
  }

  bool _isDate(String line) {
    // Date patterns like DD/MM/YYYY, DD-MM-YYYY, etc.
    final datePatterns = [
      RegExp(r'\b\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}\b', caseSensitive: false),
      RegExp(r'\b(?:date|prescribed on)\b', caseSensitive: false),
    ];
    return datePatterns.any((pattern) => pattern.hasMatch(line));
  }

  bool _isMedicineLine(String line) {
    // Patterns that indicate a line contains medicine information
    final medicinePatterns = [
      RegExp(r'\d+\s*(?:mg|ml|mcg|g)\b', caseSensitive: false), // Dosage
      RegExp(
          r'\b(?:tablet|capsule|syrup|injection|drops|ointment|cream|gel|spray|inhaler)\b',
          caseSensitive: false), // Form
      RegExp(r'\b(?:once|twice|thrice|times|daily|weekly|bid|tid|qid)\b',
          caseSensitive: false), // Frequency
      RegExp(r'(?:take|apply|inhale|chew|use)\b',
          caseSensitive: false), // Administration
    ];
    return medicinePatterns.any((pattern) => pattern.hasMatch(line));
  }

  bool _isSpecialInstruction(String line) {
    final instructionPatterns = [
      RegExp(r'instruction', caseSensitive: false),
      RegExp(r'direction', caseSensitive: false),
      RegExp(r'take with', caseSensitive: false),
      RegExp(r'before|after meals?', caseSensitive: false),
      RegExp(r'avoid', caseSensitive: false),
      RegExp(r'warning', caseSensitive: false),
      RegExp(r'precaution', caseSensitive: false),
    ];
    return instructionPatterns.any((pattern) => pattern.hasMatch(line));
  }

  void _extractPatientInfo(String line, Map<String, dynamic> data) {
    // Extract name
    final nameMatch =
        RegExp(r'name\s*:\s*([^,\n]+)', caseSensitive: false).firstMatch(line);
    if (nameMatch != null && data['patient_name'].isEmpty) {
      data['patient_name'] = nameMatch.group(1)?.trim() ?? '';
    }

    // Extract age
    final ageMatch =
        RegExp(r'age\s*:\s*(\d+)', caseSensitive: false).firstMatch(line);
    if (ageMatch != null && data['patient_age'].isEmpty) {
      data['patient_age'] = ageMatch.group(1) ?? '';
    }

    // Extract DOB
    final dobMatch = RegExp(r'dob\s*:\s*(\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4})',
            caseSensitive: false)
        .firstMatch(line);
    if (dobMatch != null && data['patient_dob'].isEmpty) {
      data['patient_dob'] = _formatDate(dobMatch.group(1) ?? '');
    }
  }

  String _extractDoctorName(String line) {
    // Remove common prefixes (only at the start)
    line = line.replaceAll(
        RegExp(r'^(dr\.?|doctor|physician)\s+', caseSensitive: false), '');
    String name = line.trim();
    // Add Dr. prefix if not already present (case-insensitive, at start)
    if (!RegExp(r'^(dr\.?|doctor)\b', caseSensitive: false).hasMatch(name)) {
      name = 'Dr. ' + name;
    }
    return name;
  }

  String _formatDate(String dateStr) {
    try {
      // Extract numbers from the date string
      final numbers =
          RegExp(r'\d+').allMatches(dateStr).map((m) => m.group(0)).toList();
      if (numbers.length >= 3) {
        int day = int.parse(numbers[0]!);
        int month = int.parse(numbers[1]!);
        int year = int.parse(numbers[2]!);

        // Handle two-digit years
        if (year < 100) {
          year += year < 50 ? 2000 : 1900;
        }

        // Ensure valid ranges
        day = day.clamp(1, 31);
        month = month.clamp(1, 12);

        // Format in YYYY-MM-DD
        return '${year.toString().padLeft(4, '0')}-'
            '${month.toString().padLeft(2, '0')}-'
            '${day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      _logger.e('Error formatting date: $e');
    }
    return dateStr; // Return original string if parsing fails
  }

  List<Map<String, String>> _extractMedicines(List<String> medicineLines) {
    final medicines = <Map<String, String>>[];
    Map<String, String>? currentMedicine;

    for (String line in medicineLines) {
      // If line contains a dosage, it's likely a new medicine
      if (RegExp(r'\d+\s*(?:mg|ml|mcg|g)\b', caseSensitive: false)
          .hasMatch(line)) {
        // Save previous medicine if exists
        if (currentMedicine != null) {
          medicines.add(currentMedicine);
        }
        // Start new medicine
        currentMedicine = {
          'name': '',
          'dosage': '',
          'frequency': '',
          'duration': ''
        };
        _parseMedicineLine(line, currentMedicine);
      } else if (currentMedicine != null) {
        // Additional info for current medicine
        _parseMedicineLine(line, currentMedicine);
      }
    }

    // Add last medicine
    if (currentMedicine != null) {
      medicines.add(currentMedicine);
    }

    return medicines;
  }

  void _parseMedicineLine(String line, Map<String, String> medicine) {
    // Extract dosage
    final dosageMatch = RegExp(
            r'(\d+\s*(?:mg|ml|mcg|g)(?:\s*\/\s*\d+\s*(?:mg|ml|mcg|g))?)\b',
            caseSensitive: false)
        .firstMatch(line);
    if (dosageMatch != null && medicine['dosage']!.isEmpty) {
      medicine['dosage'] = dosageMatch.group(1) ?? '';
    }

    // Extract frequency
    final frequencyMatch = RegExp(
            r'(\d+\s*times?|once|twice|thrice|daily|weekly|bid|tid|qid|every\s+\d+\s*hours?)',
            caseSensitive: false)
        .firstMatch(line);
    if (frequencyMatch != null && medicine['frequency']!.isEmpty) {
      var freq = frequencyMatch.group(1) ?? '';
      // Convert medical abbreviations to full form
      freq = freq
          .toLowerCase()
          .replaceAll('bid', 'twice daily')
          .replaceAll('tid', 'three times daily')
          .replaceAll('qid', 'four times daily');
      medicine['frequency'] = freq;
    }

    // Extract duration
    final durationMatch = RegExp(
            r'(?:for\s+)?(\d+\s*(?:days?|weeks?|months?|years?))',
            caseSensitive: false)
        .firstMatch(line);
    if (durationMatch != null && medicine['duration']!.isEmpty) {
      medicine['duration'] = durationMatch.group(1) ?? '';
    }

    // Extract name (if not already set)
    if (medicine['name']!.isEmpty) {
      // Remove dosage, frequency, and duration from the line to get the name
      var nameText = line;
      if (dosageMatch != null)
        nameText = nameText.replaceAll(dosageMatch.group(0)!, '');
      if (frequencyMatch != null)
        nameText = nameText.replaceAll(frequencyMatch.group(0)!, '');
      if (durationMatch != null)
        nameText = nameText.replaceAll(durationMatch.group(0)!, '');

      // Remove common words that aren't part of the medicine name
      final removeWords = RegExp(
          r'\b(?:take|use|apply|inhale|chew|tablet|capsule|syrup|injection|drops|ointment|cream|gel|spray|inhaler)\b',
          caseSensitive: false);
      nameText = nameText.replaceAll(removeWords, '');

      // Clean up and set name
      nameText = nameText.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (nameText.isNotEmpty) {
        medicine['name'] = nameText;
      }
    }
  }
}
