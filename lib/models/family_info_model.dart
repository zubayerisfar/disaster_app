/// Model for storing family information for emergency purposes
class FamilyInfo {
  final String? headOfFamilyName;
  final String? phoneNumber;
  final int? numberOfChildren;
  final int? numberOfWomen;
  final int? numberOfElderly;
  final String? address;
  final DateTime submittedAt;

  const FamilyInfo({
    this.headOfFamilyName,
    this.phoneNumber,
    this.numberOfChildren,
    this.numberOfWomen,
    this.numberOfElderly,
    this.address,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
    'headOfFamilyName': headOfFamilyName,
    'phoneNumber': phoneNumber,
    'numberOfChildren': numberOfChildren,
    'numberOfWomen': numberOfWomen,
    'numberOfElderly': numberOfElderly,
    'address': address,
    'submittedAt': submittedAt.toIso8601String(),
  };

  factory FamilyInfo.fromJson(Map<String, dynamic> json) => FamilyInfo(
    headOfFamilyName: json['headOfFamilyName'],
    phoneNumber: json['phoneNumber'],
    numberOfChildren: json['numberOfChildren'],
    numberOfWomen: json['numberOfWomen'],
    numberOfElderly: json['numberOfElderly'],
    address: json['address'],
    submittedAt: DateTime.parse(json['submittedAt']),
  );
}
