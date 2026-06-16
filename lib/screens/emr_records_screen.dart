import 'package:flutter/material.dart';
import '../service/emr_service.dart';
import '../model/patient.dart';
import '../model/visit.dart';

class EMRRecordsScreen extends StatefulWidget {
  const EMRRecordsScreen({Key? key}) : super(key: key);

  @override
  State<EMRRecordsScreen> createState() => _EMRRecordsScreenState();
}

class _EMRRecordsScreenState extends State<EMRRecordsScreen> {
  static const lightGray = Color(0xFFF5F5F5);
  final EMRService _emrService = EMRService();
  List<Patient> _patients = [];
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() => _loading = true);
    _patients = await _emrService.getAllPatientsOrderedByLastVisit();
    setState(() => _loading = false);
  }

  void _onSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _loading = true;
    });
    if (query.isEmpty) {
      await _fetchPatients();
      return;
    }

    final lowerQuery = query.toLowerCase();
    // Fetch all patients and their latest visit for doctor name and extracted date
    final allPatients = await _emrService.getAllPatientsOrderedByLastVisit();
    List<Patient> filtered = [];
    final dateRegExp = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$');
    final isDateQuery = dateRegExp.hasMatch(query.trim());
    String? searchDate;
    if (isDateQuery) {
      final match = dateRegExp.firstMatch(query.trim());
      if (match != null) {
        // Normalize to yyyy-mm-dd for comparison
        final d = match.group(1)!.padLeft(2, '0');
        final m = match.group(2)!.padLeft(2, '0');
        final y = match.group(3)!;
        final yyyy = y.length == 2 ? '20$y' : y;
        searchDate = '$yyyy-$m-$d';
      }
    }
    for (final patient in allPatients) {
      // Split patient name for first/last/initials
      final nameParts = patient.name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.last : '';
      final fullName = patient.name;
      final initials = nameParts.map((p) => p.isNotEmpty ? p[0] : '').join();

      // Get all visits for doctor name and extracted date
      final visits = await _emrService.getVisitsForPatient(patient.id);
      bool matches = false;

      // Check patient name and initials
      if (fullName.toLowerCase().contains(lowerQuery) ||
          firstName.toLowerCase().contains(lowerQuery) ||
          lastName.toLowerCase().contains(lowerQuery) ||
          initials.toLowerCase().contains(lowerQuery)) {
        matches = true;
      }

      // Check all visits for doctor name and extracted date
      for (final visit in visits) {
        final doctorName = visit.doctorName;
        final createdAt = visit.createdAt;
        if (doctorName.toLowerCase().contains(lowerQuery)) {
          matches = true;
        }
        if (isDateQuery && createdAt != null) {
          try {
            final dt = DateTime.parse(createdAt).toUtc();
            final dtStr =
                '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            if (dtStr == searchDate) {
              matches = true;
            }
          } catch (_) {}
        }
      }

      if (matches) {
        filtered.add(patient);
      }
    }
    setState(() {
      _patients = filtered;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
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
              'EMR Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        backgroundColor: const Color(0xFF1F3C88),
        elevation: 2,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search by patient or doctor',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: lightGray,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _patients.isEmpty
                      ? const Center(
                          child: Text(
                            'No records found.',
                            style:
                                TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _patients.length,
                          itemBuilder: (context, index) {
                            return _PatientCard(patient: _patients[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatefulWidget {
  final Patient patient;
  const _PatientCard({required this.patient});

  @override
  State<_PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<_PatientCard> {
  bool _expanded = false;
  List<Visit> _visits = [];
  bool _loadingVisits = false;

  void _toggleExpand() async {
    setState(() => _expanded = !_expanded);
    if (_expanded && _visits.isEmpty) {
      setState(() => _loadingVisits = true);
      final emrService = EMRService();
      _visits = await emrService.getVisitsForPatient(widget.patient.id);
      setState(() => _loadingVisits = false);
    }
  }

  String _standardizeName(String name) {
    // Capitalize first letter of each word, and ensure 'Mr', 'Mrs', 'Ms', 'Dr' are capitalized
    final honorifics = ['mr', 'mrs', 'ms', 'dr'];
    return name.split(' ').map((word) {
      final lower = word.toLowerCase();
      if (honorifics.contains(lower)) {
        return lower[0].toUpperCase() + lower.substring(1);
      }
      return word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : '';
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    const lightGray = Color(0xFFF5F5F5);
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black12,
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12), // Increased height
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 16,
                        top: 4,
                        bottom: 4,
                        right: 0), // Slightly more padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_standardizeName(widget.patient.name),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('DOB: ${widget.patient.dob}',
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: Color(0xFF1F3C88)),
                  onPressed: _toggleExpand,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          if (_expanded)
            _loadingVisits
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                : Container(
                    color: lightGray,
                    child: Column(
                      children: [
                        const Divider(),
                        ..._visits
                            .map((visit) => _VisitTile(visit: visit))
                            .toList(),
                      ],
                    ),
                  ),
        ],
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  final Visit visit;
  const _VisitTile({required this.visit});

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final date =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      int hour = dt.hour;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$date, $hour:$minute $ampm';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    const lightGray = Color(0xFFF5F5F5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (visit.createdAt != null)
              Text(
                '(Extracted: ${_formatDateTime(visit.createdAt!)})',
                style: const TextStyle(
                    fontSize: 13, color: Color.fromARGB(255, 0, 0, 0)),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            Text(
              visit.doctorName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: 8),
            Text('Medicines:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: visit.medicines.map((med) {
                final name = med['name'] ?? '';
                final dosage = med['dosage'] ?? '';
                final frequency = med['frequency'] ?? '';
                final duration = med['duration'] ?? '';
                String medText = name;
                if (dosage.isNotEmpty) medText += ' - $dosage';
                if (frequency.isNotEmpty) medText += ' x $frequency';
                if (duration.isNotEmpty) medText += ' x $duration';
                return Text(
                  medText,
                  style: const TextStyle(fontSize: 13),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            if (visit.notes.isNotEmpty) ...[
              Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(visit.notes,
                  style: const TextStyle(fontSize: 13),
                  softWrap: true,
                  overflow: TextOverflow.visible),
            ],
            if (visit.scanImageUrl != null && visit.scanImageUrl!.isNotEmpty)
              TextButton(
                onPressed: () {
                  // TODO: Implement view original scan
                },
                child: const Text('View Original Scan'),
              ),
          ],
        ),
      ),
    );
  }
}
