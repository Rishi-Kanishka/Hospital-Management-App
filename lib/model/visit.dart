class Visit {
  final String id;
  final String date;
  final String doctorName;
  final List<Map<String, dynamic>> medicines;
  final String notes;
  final String? scanImageUrl;
  final String? createdAt; // ISO 8601 string

  Visit({
    required this.id,
    required this.date,
    required this.doctorName,
    required this.medicines,
    required this.notes,
    this.scanImageUrl,
    this.createdAt,
  });

  factory Visit.fromMap(String id, Map<String, dynamic> data) {
    return Visit(
      id: id,
      date: data['date'] ?? '',
      doctorName: data['doctor'] ??
          data['doctorName'] ??
          '', // Accept both 'doctor' and 'doctorName'
      medicines: List<Map<String, dynamic>>.from(data['medicines'] ?? []),
      notes: data['notes'] ?? '',
      scanImageUrl: data['scanImageUrl'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'doctor': doctorName, // Always use 'doctor' for Firestore
      'medicines': medicines,
      'notes': notes,
      if (scanImageUrl != null) 'scanImageUrl': scanImageUrl,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
