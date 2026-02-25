import '../models/contact_model.dart';

class ContactService {
  static const List<Map<String, String>> criticalContacts = [
    {'organisation': 'National Emergency', 'phone': '999', 'description': 'Police, Fire & Ambulance'},
    {'organisation': 'Fire Service', 'phone': '16163', 'description': 'Fire Service Control Room'},
    {'organisation': 'Disaster Helpline', 'phone': '1090', 'description': 'DDM Disaster Helpline'},
  ];

  Future<List<String>> fetchDivisions() async => List.from(_seedDivisions);
  Future<List<String>> fetchDistricts(String division) async => List.from(_seedDistricts[division] ?? []);
  Future<List<String>> fetchUpazilas(String division, String district) async => _demoUpazilas(district);

  Future<List<EmergencyContact>> fetchContacts({
    required String division, required String district, required String upazila,
  }) async => _demoContacts(division, district, upazila);

  static List<String> _demoUpazilas(String district) {
    final map = <String, List<String>>{
      'Dhaka': ['Dhanmondi', 'Gulshan', 'Mirpur', 'Mohammadpur', 'Uttara', 'Motijheel'],
      'Chittagong': ['Chandgaon', 'Double Mooring', 'Kotwali', 'Panchlaish', 'Pahartali'],
      "Cox's Bazar": ["Cox's Bazar Sadar", 'Ramu', 'Teknaf', 'Ukhia', 'Chakaria'],
      'Khulna': ['Khulna Sadar', 'Sonadanga', 'Khalishpur', 'Daulatpur'],
      'Barisal': ['Barisal Sadar', 'Bakerganj', 'Babuganj', 'Agailjhara'],
      'Sylhet': ['Sylhet Sadar', 'Beanibazar', 'Bishwanath', 'Golapganj'],
      'Rajshahi': ['Rajshahi Sadar', 'Boalia', 'Rajpara', 'Shah Makhdum'],
      'Rangpur': ['Rangpur Sadar', 'Gangachara', 'Taragram', 'Badarganj'],
      'Mymensingh': ['Mymensingh Sadar', 'Trishal', 'Bhaluka', 'Gaffargaon'],
      'Gazipur': ['Gazipur Sadar', 'Kaliakair', 'Kapasia', 'Sreepur'],
      'Noakhali': ['Noakhali Sadar', 'Hatiya', 'Senbagh', 'Companiganj'],
      'Comilla': ['Comilla Sadar', 'Daudkandi', 'Chandina', 'Laksam'],
    };
    return map[district] ?? ['$district Sadar', 'Upazila 2', 'Upazila 3'];
  }

  static List<EmergencyContact> _demoContacts(String division, String district, String upazila) {
    return [
      EmergencyContact(id: 'd1', division: division, district: district, upazila: upazila,
        organisation: '$district District Hospital', phone: '01700-000001',
        description: 'Government district hospital - 24 hr emergency'),
      EmergencyContact(id: 'd2', division: division, district: district, upazila: upazila,
        organisation: '$district Fire Service', phone: '01700-000002',
        description: 'Local fire service and civil defence'),
      EmergencyContact(id: 'd3', division: division, district: district, upazila: upazila,
        organisation: '$upazila Police Station', phone: '01700-000003',
        description: 'Local law enforcement'),
      EmergencyContact(id: 'd4', division: division, district: district, upazila: upazila,
        organisation: 'Cyclone Preparedness Programme', phone: '01700-000004',
        description: 'Bangladesh Red Crescent CPP volunteers'),
      EmergencyContact(id: 'd5', division: division, district: district, upazila: upazila,
        organisation: '$district DDMC Office', phone: '01700-000005',
        description: 'District Disaster Management Committee'),
    ];
  }

  static const List<String> _seedDivisions = [
    'Barisal', 'Chittagong', 'Dhaka', 'Khulna', 'Mymensingh', 'Rajshahi', 'Rangpur', 'Sylhet',
  ];

  static const Map<String, List<String>> _seedDistricts = {
    "Chittagong": ["Cox's Bazar",'Chittagong','Bandarban','Rangamati','Khagrachhari','Feni','Noakhali','Lakshmipur','Comilla','Chandpur','Brahmanbaria'],
    'Dhaka': ['Dhaka','Gazipur','Narayanganj','Manikganj','Munshiganj','Narsingdi','Tangail','Kishoreganj'],
    'Khulna': ['Khulna','Bagerhat','Satkhira','Jessore','Narail','Magura','Jhenaidah','Kushtia','Chuadanga','Meherpur'],
    'Barisal': ['Barisal','Bhola','Patuakhali','Pirojpur','Jhalokati','Barguna'],
    'Sylhet': ['Sylhet','Moulvibazar','Habiganj','Sunamganj'],
    'Rajshahi': ['Rajshahi','Chapainawabganj','Natore','Naogaon','Bogra','Joypurhat','Sirajganj','Pabna'],
    'Rangpur': ['Rangpur','Gaibandha','Kurigram','Lalmonirhat','Nilphamari','Panchagarh','Thakurgaon','Dinajpur'],
    'Mymensingh': ['Mymensingh','Sherpur','Jamalpur','Netrokona'],
  };
}