import 'package:flutter/material.dart';
import 'models/family_info_model.dart';
import 'services/family_info_service.dart';
import 'widgets/family_info_form.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _service = FamilyInfoService();
  FamilyInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await _service.getFamilyInfo();
    if (mounted) {
      setState(() {
        _info = info;
        _loading = false;
      });
    }
  }

  void _onEditComplete() {
    _load();
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FamilyInfoForm(
        onComplete: () {
          Navigator.pop(context);
          _onEditComplete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          // ── Gradient Header ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: topPad + 12,
              bottom: 32,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A3A6B), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              children: [
                // Back + title row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'প্রোফাইল',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _showEditSheet,
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'সম্পাদনা',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Avatar circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _loading
                      ? '...'
                      : (_info?.headOfFamilyName?.isNotEmpty == true
                            ? _info!.headOfFamilyName!
                            : 'ব্যবহারকারী'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loading
                      ? ''
                      : (_info?.phoneNumber?.isNotEmpty == true
                            ? _info!.phoneNumber!
                            : ''),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _info == null
                ? _EmptyState(onTap: _showEditSheet)
                : _InfoBody(info: _info!, onEdit: _showEditSheet),
          ),
        ],
      ),
    );
  }
}

// ─── Info body ────────────────────────────────────────────────────────────────

class _InfoBody extends StatelessWidget {
  final FamilyInfo info;
  final VoidCallback onEdit;
  const _InfoBody({required this.info, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Basic Info ─────────────────────────────────────────────
          _SectionCard(
            title: 'ব্যক্তিগত তথ্য',
            icon: Icons.person_outline_rounded,
            children: [
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'পরিবার প্রধানের নাম',
                value: info.headOfFamilyName?.isNotEmpty == true
                    ? info.headOfFamilyName!
                    : '—',
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.phone_rounded,
                label: 'মোবাইল নম্বর',
                value: info.phoneNumber?.isNotEmpty == true
                    ? info.phoneNumber!
                    : '—',
                valueColor: const Color(0xFF1565C0),
                bold: true,
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'ঠিকানা',
                value: info.address?.isNotEmpty == true ? info.address! : '—',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Family Members ─────────────────────────────────────────
          _SectionCard(
            title: 'পরিবারের সদস্য',
            icon: Icons.group_outlined,
            children: [
              _InfoRow(
                icon: Icons.child_friendly_outlined,
                label: 'শিশু সংখ্যা',
                value: '${info.numberOfChildren ?? 0} জন',
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.woman_2_outlined,
                label: 'নারী সংখ্যা',
                value: '${info.numberOfWomen ?? 0} জন',
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.elderly_outlined,
                label: 'বয়স্ক সংখ্যা',
                value: '${info.numberOfElderly ?? 0} জন',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Registered at ──────────────────────────────────────────
          _SectionCard(
            title: 'নিবন্ধনের তারিখ',
            icon: Icons.calendar_today_outlined,
            children: [
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: 'তারিখ',
                value: _fmtDate(info.submittedAt),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Edit button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('তথ্য সম্পাদনা করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_alt_1_rounded,
              size: 72,
              color: const Color(0xFF1565C0).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'কোনো তথ্য পাওয়া যায়নি',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'আপনার পরিবারের তথ্য যোগ করুন',
              style: TextStyle(fontSize: 14, color: Colors.black45),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('তথ্য যোগ করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1565C0)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1565C0),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF1A3A6B).withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: valueColor ?? const Color(0xFF0D1B2A),
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
