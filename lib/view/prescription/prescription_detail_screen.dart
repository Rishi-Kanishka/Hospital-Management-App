import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

/// A screen that displays the parsed prescription details in a clean, organized format
class PrescriptionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> prescriptionData;

  const PrescriptionDetailScreen({
    super.key,
    required this.prescriptionData,
  });

  void _copyAsJson(BuildContext context) {
    try {
      final jsonStr = JsonEncoder.withIndent('  ').convert(prescriptionData);
      Clipboard.setData(ClipboardData(text: jsonStr)).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription data copied as JSON')),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error copying data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medicines =
        List<Map<String, dynamic>>.from(prescriptionData['medicines'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Match home screen bg
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3C88),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'RxCaptured',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              'Patient Information',
              [
                _buildInfoRow('Name', prescriptionData['patient_name'] ?? '-'),
                _buildInfoRow('Age', prescriptionData['patient_age'] ?? '-'),
                _buildInfoRow(
                    'Date of Birth', prescriptionData['patient_dob'] ?? '-'),
              ],
              theme,
              Icons.person,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              'Doctor Information',
              [
                _buildInfoRow('Doctor', prescriptionData['doctor_name'] ?? '-'),
                _buildInfoRow(
                    'Date', prescriptionData['prescription_date'] ?? '-'),
              ],
              theme,
              Icons.medical_services,
            ),
            const SizedBox(height: 12), _buildMedicineList(medicines, theme),
            // Merge special instructions and additional notes intelligently
            Builder(
              builder: (context) {
                String mergedNotes = '';
                final specialInstructions =
                    prescriptionData['special_instructions']?.trim() ?? '';
                final additionalNotes =
                    prescriptionData['additional_notes']?.trim() ?? '';

                if (specialInstructions.isNotEmpty &&
                    additionalNotes.isNotEmpty) {
                  mergedNotes =
                      'Special Instructions:\n$specialInstructions\n$additionalNotes';
                } else if (specialInstructions.isNotEmpty) {
                  mergedNotes = 'Special Instructions:\n$specialInstructions';
                } else if (additionalNotes.isNotEmpty) {
                  mergedNotes = additionalNotes;
                }

                if (mergedNotes.isNotEmpty) {
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildHighlightCard(
                        'Notes & Instructions',
                        mergedNotes,
                        theme,
                        Theme.of(context).cardColor,
                        Icons.note,
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, List<Widget> children, ThemeData theme, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: const Color(0xFFF5F5F5), // Match home screen bg
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('$label:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
          Expanded(
              flex: 3,
              child: Text(value.isEmpty ? '-' : value,
                  style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  Widget _buildMedicineList(
      List<Map<String, dynamic>> medicines, ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: const Color(0xFFF5F5F5), // Match home screen bg
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text('Medicines',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            medicines.isEmpty
                ? Text('No medicines listed.',
                    style: GoogleFonts.poppins(fontStyle: FontStyle.italic))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: medicines.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final med = medicines[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med['name'] ?? '',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          if ((med['dosage'] ?? '').isNotEmpty)
                            Text('Dosage: ${med['dosage']}',
                                style: GoogleFonts.poppins()),
                          if ((med['frequency'] ?? '').isNotEmpty)
                            Text('Frequency: ${med['frequency']}',
                                style: GoogleFonts.poppins()),
                          if ((med['duration'] ?? '').isNotEmpty)
                            Text('Duration: ${med['duration']}',
                                style: GoogleFonts.poppins()),
                        ],
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard(String title, String content, ThemeData theme,
      Color bgColor, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF5F5F5), // Match home screen bg
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            Text(content, style: GoogleFonts.poppins()),
          ],
        ),
      ),
    );
  }
}
