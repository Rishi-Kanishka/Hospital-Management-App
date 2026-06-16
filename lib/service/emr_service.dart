import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/patient.dart';
import '../model/visit.dart';

class EMRService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _patients => _firestore.collection('patients');

  Future<Patient?> findPatientByNameDob(String name, String dob) async {
    final query = await _patients
        .where('name', isEqualTo: name)
        .where('dob', isEqualTo: dob)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return Patient.fromMap(
          query.docs.first.id, query.docs.first.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<String> addPatient(Patient patient) async {
    final doc = await _patients.add(patient.toMap());
    return doc.id;
  }

  /// Always add a new visit (prescription) for a patient, even if the date is the same.
  Future<void> addVisit(String patientId, Visit visit) async {
    await _patients.doc(patientId).collection('visits').add({
      'date': visit.date,
      'doctor': visit.doctorName, // Map doctorName to 'doctor' in Firestore
      'medicines': visit.medicines,
      'notes': visit.notes,
      if (visit.scanImageUrl != null) 'scanImageUrl': visit.scanImageUrl,
      if (visit.createdAt != null) 'createdAt': visit.createdAt,
    });
  }

  Future<List<Patient>> getAllPatientsOrderedByLastVisit() async {
    final query = await _patients.get();
    List<Patient> patients = [];
    for (var doc in query.docs) {
      patients.add(Patient.fromMap(doc.id, doc.data() as Map<String, dynamic>));
    }
    // Optionally, sort by last visit date (requires fetching visits)
    return patients;
  }

  Future<List<Patient>> searchPatients(String queryStr) async {
    final query = await _patients
        .where('name', isGreaterThanOrEqualTo: queryStr)
        .where('name', isLessThanOrEqualTo: queryStr + '\uf8ff')
        .get();
    return query.docs
        .map((doc) =>
            Patient.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Visit>> getVisitsForPatient(String patientId) async {
    final visitsQuery = await _patients
        .doc(patientId)
        .collection('visits')
        .orderBy('date', descending: true)
        .get();
    return visitsQuery.docs
        .map((doc) => Visit.fromMap(doc.id, doc.data()))
        .toList();
  }
}
