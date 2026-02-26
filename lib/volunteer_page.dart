import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'models/shelter_model.dart';
import 'providers/app_provider.dart';
import 'providers/shelter_provider.dart';
import 'services/volunteer_service.dart';
import 'theme.dart';
import 'widgets/disaster_app_bar.dart';

class VolunteerPage extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const VolunteerPage({super.key, this.onMenuTap});

  @override
  State<VolunteerPage> createState() => _VolunteerPageState();
}

class _VolunteerPageState extends State<VolunteerPage> {
  final _svc = VolunteerService();
  VolunteerProfile? _profile;
  List<VolunteerProfile> _allVolunteers = [];
  List<VolunteerShelter> _addedShelters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _svc.getProfile();
    final volunteers = await _svc.getAllVolunteers();
    final shelters = await _svc.getShelters();
    if (mounted) {
      setState(() {
        _profile = profile;
        _allVolunteers = volunteers;
        _addedShelters = shelters;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: DisasterAppBar(
        title: 'স্বেচ্ছাসেবী',
        showMenuButton: true,
        onMenuTap: widget.onMenuTap,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            )
          : _VolunteerListView(
              allVolunteers: _allVolunteers,
              currentProfile: _profile,
              addedShelters: _addedShelters,
              onShelterAdded: (vs) async {
                // Capture providers before any awaits
                final app = context.read<AppProvider>();
                final shelterProv = context.read<ShelterProvider>();
                await _svc.addShelter(vs);
                // Push to live shelter provider
                shelterProv.addShelter(
                  Shelter(
                    id: vs.id,
                    name: vs.name,
                    address: vs.address,
                    lat: vs.lat,
                    lng: vs.lng,
                    district: vs.district.toLowerCase(),
                    capacity: vs.capacity,
                  ),
                  app.latitude,
                  app.longitude,
                );
                final fresh = await _svc.getShelters();
                if (mounted) {
                  setState(() => _addedShelters = fresh);
                }
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Lift above bottom nav bar
        child: FloatingActionButton.extended(
          heroTag: 'volunteerRegistrationFAB',
          onPressed: () {
            _showRegistrationSheet(context);
          },
          backgroundColor: const Color(0xFF1565C0),
          icon: const Icon(Icons.person_add_rounded),
          label: const Text(
            'নিবন্ধন করুন',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }

  void _showRegistrationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RegistrationSheet(
        onRegistered: (p) async {
          await _svc.saveProfile(p);
          await _load(); // Reload all data
        },
      ),
    );
  }
}

// ─── Volunteer List View ──────────────────────────────────────────────────────

class _VolunteerListView extends StatelessWidget {
  final List<VolunteerProfile> allVolunteers;
  final VolunteerProfile? currentProfile;
  final List<VolunteerShelter> addedShelters;
  final void Function(VolunteerShelter) onShelterAdded;

  const _VolunteerListView({
    required this.allVolunteers,
    required this.currentProfile,
    required this.addedShelters,
    required this.onShelterAdded,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final userLat = app.latitude;
    final userLng = app.longitude;

    // Calculate distances and sort
    final volunteersWithDistance = allVolunteers.map((v) {
      final distanceInMeters = Geolocator.distanceBetween(
        userLat,
        userLng,
        v.lat,
        v.lng,
      );
      return _VolunteerWithDistance(
        profile: v,
        distanceKm: distanceInMeters / 1000,
      );
    }).toList()..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current user profile card (if registered)
          if (currentProfile != null) ...[
            const Text(
              'আমার প্রোফাইল',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 12),
            _CurrentProfileCard(
              profile: currentProfile!,
              addedShelters: addedShelters,
              onShelterAdded: onShelterAdded,
            ),
            const SizedBox(height: 28),
          ],

          // Nearby volunteers
          const Text(
            'কাছাকাছি স্বেচ্ছাসেবী',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'আপনার এলাকায় ${volunteersWithDistance.length}জন স্বেচ্ছাসেবী রয়েছেন',
            style: const TextStyle(fontSize: 13, color: Colors.black45),
          ),
          const SizedBox(height: 14),

          if (volunteersWithDistance.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 64,
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'এখনো কোনো স্বেচ্ছাসেবী নিবন্ধিত নেই',
                      style: TextStyle(fontSize: 15, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            )
          else
            ...volunteersWithDistance.map(
              (vd) => _VolunteerCard(
                profile: vd.profile,
                distanceKm: vd.distanceKm,
                isCurrentUser: currentProfile?.phone == vd.profile.phone,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Volunteer with Distance (helper) ─────────────────────────────────────────

class _VolunteerWithDistance {
  final VolunteerProfile profile;
  final double distanceKm;

  const _VolunteerWithDistance({
    required this.profile,
    required this.distanceKm,
  });
}

// ─── Current Profile Card ─────────────────────────────────────────────────────

class _CurrentProfileCard extends StatelessWidget {
  final VolunteerProfile profile;
  final List<VolunteerShelter> addedShelters;
  final void Function(VolunteerShelter) onShelterAdded;

  const _CurrentProfileCard({
    required this.profile,
    required this.addedShelters,
    required this.onShelterAdded,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF1565C0),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.skills,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      profile.area,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF16A34A)),
                ),
                child: const Text(
                  'নিবন্ধিত',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFBFDBFE)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.add_location_alt_rounded,
                  label: 'আশ্রয়কেন্দ্র\nযোগ করুন',
                  onTap: () => _showAddShelterSheet(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.list_alt_rounded,
                  label: 'আমার কেন্দ্র\n(${addedShelters.length})',
                  onTap: () => _showShelterList(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddShelterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddShelterSheet(
        volunteerName: profile.name,
        onAdded: onShelterAdded,
      ),
    );
  }

  void _showShelterList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShelterListSheet(shelters: addedShelters),
    );
  }
}

// ─── Quick Action Button ──────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF1565C0), size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1565C0),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Volunteer Card ───────────────────────────────────────────────────────────

class _VolunteerCard extends StatelessWidget {
  final VolunteerProfile profile;
  final double distanceKm;
  final bool isCurrentUser;

  const _VolunteerCard({
    required this.profile,
    required this.distanceKm,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                    : const Color(0xFF1565C0).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCurrentUser ? Icons.person : Icons.person_outline_rounded,
                color: isCurrentUser
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF1565C0),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D1B2A),
                          ),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'আপনি',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF166534),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    profile.skills,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          profile.area,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${distanceKm.toStringAsFixed(1)} কিমি',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const Text(
                  'দূরে',
                  style: TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Registration Sheet ──────────────────────────────────────────────────────

class _RegistrationSheet extends StatefulWidget {
  final void Function(VolunteerProfile) onRegistered;
  const _RegistrationSheet({required this.onRegistered});

  @override
  State<_RegistrationSheet> createState() => _RegistrationSheetState();
}

class _RegistrationSheetState extends State<_RegistrationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  String _skills = 'প্রাথমিক চিকিৎসা';
  bool _saving = false;

  static const _skillOptions = [
    'প্রাথমিক চিকিৎসা',
    'উদ্ধার অভিযান',
    'খাদ্য বিতরণ',
    'তথ্য ও যোগাযোগ',
    'পরিবহন সহায়তা',
    'অন্যান্য',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F6FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'স্বেচ্ছাসেবী নিবন্ধন',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.black54,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A3A6B), Color(0xFF1565C0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.volunteer_activism,
                            color: Colors.white,
                            size: 34,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'দুর্যোগে মানুষের পাশে দাঁড়ান',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'নিবন্ধন করুন এবং আশ্রয়কেন্দ্রের তথ্য যোগ করুন।',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _label('পুরো নাম', Icons.person_rounded),
                    const SizedBox(height: 8),
                    _field(
                      ctrl: _nameCtrl,
                      hint: 'আপনার পুরো নাম লিখুন',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'নাম আবশ্যক' : null,
                    ),

                    const SizedBox(height: 16),
                    _label('মোবাইল নম্বর', Icons.phone_rounded),
                    const SizedBox(height: 8),
                    _field(
                      ctrl: _phoneCtrl,
                      hint: '01XXXXXXXXX',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().length < 10)
                          ? 'সঠিক নম্বর দিন'
                          : null,
                    ),

                    const SizedBox(height: 16),
                    _label('এলাকা / ইউনিয়ন', Icons.location_on_rounded),
                    const SizedBox(height: 8),
                    _field(
                      ctrl: _areaCtrl,
                      hint: 'যেমন: মিরপুর, ঢাকা',
                      icon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'এলাকা লিখুন'
                          : null,
                    ),

                    const SizedBox(height: 16),
                    _label('দক্ষতা / ভূমিকা', Icons.build_rounded),
                    const SizedBox(height: 8),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _skills,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF1565C0),
                          ),
                          items: _skillOptions
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _skills = v ?? _skills),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                setState(() => _saving = true);

                                // Capture lat/lng before async
                                final app = context.read<AppProvider>();
                                final lat = app.latitude;
                                final lng = app.longitude;

                                final profile = VolunteerProfile(
                                  name: _nameCtrl.text.trim(),
                                  phone: _phoneCtrl.text.trim(),
                                  area: _areaCtrl.text.trim(),
                                  skills: _skills,
                                  lat: lat,
                                  lng: lng,
                                  registeredAt: DateTime.now(),
                                );
                                widget.onRegistered(profile);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                          shadowColor: const Color(
                            0xFF1565C0,
                          ).withValues(alpha: 0.4),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: const Text(
                          'নিবন্ধন সম্পন্ন করুন',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, IconData icon) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF1565C0)),
      const SizedBox(width: 6),
      Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A3A6B),
        ),
      ),
    ],
  );

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 20),
        filled: true,
        fillColor: const Color(0xFFEFF6FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}

// ─── Add Shelter Bottom Sheet ────────────────────────────────────────────────

class _AddShelterSheet extends StatefulWidget {
  final String volunteerName;
  final void Function(VolunteerShelter) onAdded;

  const _AddShelterSheet({required this.volunteerName, required this.onAdded});

  @override
  State<_AddShelterSheet> createState() => _AddShelterSheetState();
}

class _AddShelterSheetState extends State<_AddShelterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  String _district = 'Dhaka';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pre-fill with current GPS coords
      final app = context.read<AppProvider>();
      _latCtrl.text = app.latitude.toStringAsFixed(5);
      _lngCtrl.text = app.longitude.toStringAsFixed(5);
      _district = app.selectedDistrict;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(
                    Icons.add_location_alt_rounded,
                    color: Color(0xFF1565C0),
                    size: 26,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'নতুন আশ্রয়কেন্দ্র যোগ করুন',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _SheetField(
                ctrl: _nameCtrl,
                label: 'কেন্দ্রের নাম',
                hint: 'যেমন: মিরপুর সরকারি বিদ্যালয়',
              ),
              const SizedBox(height: 12),
              _SheetField(
                ctrl: _addressCtrl,
                label: 'ঠিকানা',
                hint: 'পূর্ণ ঠিকানা লিখুন',
              ),
              const SizedBox(height: 12),

              // District selector
              const Text(
                'জেলা',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A3A6B),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: AppProvider.allDistricts.contains(_district)
                        ? _district
                        : 'Dhaka',
                    isExpanded: true,
                    items: AppProvider.allDistricts
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              d,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _district = v ?? _district),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SheetField(
                      ctrl: _latCtrl,
                      label: 'অক্ষাংশ (Lat)',
                      hint: '23.8103',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        if (d == null) return 'সঠিক মান দিন';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SheetField(
                      ctrl: _lngCtrl,
                      label: 'দ্রাঘিমাংশ (Lng)',
                      hint: '90.4125',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        if (d == null) return 'সঠিক মান দিন';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SheetField(
                ctrl: _capacityCtrl,
                label: 'ধারণক্ষমতা (জন)',
                hint: '500',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'সংখ্যা দিন';
                  return null;
                },
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text(
                    'সংরক্ষণ করুন ও তালিকায় যোগ করুন',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_nameCtrl.text.trim().isEmpty || _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('সকল তথ্য পূরণ করুন')));
      return;
    }
    setState(() => _saving = true);
    final shelter = VolunteerShelter(
      id: 'vol_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      lat: double.parse(_latCtrl.text),
      lng: double.parse(_lngCtrl.text),
      district: _district,
      capacity: int.parse(_capacityCtrl.text),
      addedBy: widget.volunteerName,
      addedAt: DateTime.now(),
    );
    widget.onAdded(shelter);
    if (mounted) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('আশ্রয়কেন্দ্র সফলভাবে যোগ করা হয়েছে!'),
        backgroundColor: Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _SheetField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A3A6B),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFEFF6FF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator:
              validator ??
              (v) =>
                  (v == null || v.trim().isEmpty) ? 'এই তথ্যটি প্রয়োজন' : null,
        ),
      ],
    );
  }
}

// ─── View Shelter List Sheet ─────────────────────────────────────────────────

class _ShelterListSheet extends StatelessWidget {
  final List<VolunteerShelter> shelters;
  const _ShelterListSheet({required this.shelters});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'যোগ করা ${shelters.length}টি আশ্রয়কেন্দ্র',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 14),
          if (shelters.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'এখনো কোনো কেন্দ্র যোগ করা হয়নি',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: shelters.length,
                separatorBuilder: (c, i) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, i) {
                  final s = shelters[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF1A3A6B),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${s.address} — ${s.capacity} জন',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      s.district,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
