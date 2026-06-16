import 'visit.dart';

class Patient {
  final String id;
  final String name;
  final String dob;
  final int age;

  Patient({
    required this.id,
    required this.name,
    required this.dob,
    required this.age,
  });

  factory Patient.fromMap(String id, Map<String, dynamic> data) {
    return Patient(
      id: id,
      name: data['name'] ?? '',
      dob: data['dob'] ?? '',
      age: data['age'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dob': dob,
      'age': age,
    };
  }
}
