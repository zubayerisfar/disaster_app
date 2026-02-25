/// Represents an emergency contact document from the Firestore "contacts"
/// collection.  Contacts are filterable by division → district → upazila.

class EmergencyContact {
  final String id;
  final String division;
  final String district;
  final String upazila;
  final String organisation;
  final String phone;
  final String description;

  const EmergencyContact({
    required this.id,
    required this.division,
    required this.district,
    required this.upazila,
    required this.organisation,
    required this.phone,
    required this.description,
  });

  factory EmergencyContact.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return EmergencyContact(
      id: docId,
      division: data['division'] as String? ?? '',
      district: data['district'] as String? ?? '',
      upazila: data['upazila'] as String? ?? '',
      organisation: data['organisation'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      description: data['description'] as String? ?? '',
    );
  }
}
