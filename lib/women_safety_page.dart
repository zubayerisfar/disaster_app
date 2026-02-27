import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'services/safety_service.dart';
import 'services/mental_health_service.dart';
import 'models/mental_health_assessment.dart';
import 'theme.dart';
import 'widgets/disaster_app_bar.dart';

class WomenSafetyPage extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const WomenSafetyPage({super.key, this.onMenuTap});

  @override
  State<WomenSafetyPage> createState() => _WomenSafetyPageState();
}

class _WomenSafetyPageState extends State<WomenSafetyPage> {
  final _service = SafetyService();
  final _nameCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _alertSent = false;
  bool _busy = false;

  // Mental Health Assessment
  final _mentalHealthFormKey = GlobalKey<FormState>();
  final Map<String, int> _mentalHealthAnswers = {};
  bool _assessmentSubmitted = false;
  bool _assessmentBusy = false;
  MentalHealthResult? _assessmentResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillLocation());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  void _prefillLocation() {
    if (!mounted) return;
    final app = context.read<AppProvider>();
    _locCtrl.text =
        '${app.latitude.toStringAsFixed(5)}\u00b0N, ${app.longitude.toStringAsFixed(5)}\u00b0E';
  }

  Future<void> _sendEmergency() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final name = _nameCtrl.text.trim();
    final loc = _locCtrl.text.trim();
    await _service.sendSms(
      to: SafetyService.womenHelpline,
      message: 'EMERGENCY: $name needs help. Location: $loc',
    );
    await _service.directCall(SafetyService.womenHelpline);
    if (mounted) {
      setState(() {
        _busy = false;
        _alertSent = true;
      });
    }
  }

  Future<void> _sendSafe() async {
    setState(() => _busy = true);
    final name = _nameCtrl.text.trim();
    await _service.sendSms(
      to: SafetyService.womenHelpline,
      message: 'SAFE: $name is now safe.',
    );
    if (mounted) {
      setState(() {
        _busy = false;
        _alertSent = false;
      });
    }
  }

  Future<void> _submitMentalHealthAssessment() async {
    if (!_mentalHealthFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('দয়া করে সমস্ত প্রশ্নের উত্তর দিন')),
      );
      return;
    }

    setState(() => _assessmentBusy = true);

    try {
      final assessment = MentalHealthAssessment(
        schoolingStatus: _mentalHealthAnswers['schoolingStatus'] ?? 0,
        mediaExposure: _mentalHealthAnswers['mediaExposure'] ?? 0,
        physicalAbuse: _mentalHealthAnswers['physicalAbuse'] ?? 0,
        sexualAbuse: _mentalHealthAnswers['sexualAbuse'] ?? 0,
        academicPerformance: _mentalHealthAnswers['academicPerformance'] ?? 0,
        freedomToMove: _mentalHealthAnswers['freedomToMove'] ?? 0,
        expressionOfOpinion: _mentalHealthAnswers['expressionOfOpinion'] ?? 0,
        communicationWithParents:
            _mentalHealthAnswers['communicationWithParents'] ?? 0,
        communicationWithFriends:
            _mentalHealthAnswers['communicationWithFriends'] ?? 0,
        confrontWrongActs: _mentalHealthAnswers['confrontWrongActs'] ?? 0,
        engagedMarriageFixed: _mentalHealthAnswers['engagedMarriageFixed'] ?? 0,
        discussionOfSexualProblems:
            _mentalHealthAnswers['discussionOfSexualProblems'] ?? 0,
        discussionAboutRelationship:
            _mentalHealthAnswers['discussionAboutRelationship'] ?? 0,
        medicalSymptoms: _mentalHealthAnswers['medicalSymptoms'] ?? 0,
        impulsiveBehaviour: _mentalHealthAnswers['impulsiveBehaviour'] ?? 0,
        familyProblems: _mentalHealthAnswers['familyProblems'] ?? 0,
        divorce: _mentalHealthAnswers['divorce'] ?? 0,
        partnerAbuse: _mentalHealthAnswers['partnerAbuse'] ?? 0,
        substanceAbuse: _mentalHealthAnswers['substanceAbuse'] ?? 0,
        relationshipProblems: _mentalHealthAnswers['relationshipProblems'] ?? 0,
        peerPressure: _mentalHealthAnswers['peerPressure'] ?? 0,
      );

      final result = await MentalHealthService.assessMentalHealth(assessment);

      if (mounted) {
        setState(() {
          _assessmentResult = result;
          _assessmentSubmitted = true;
          _assessmentBusy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _assessmentBusy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
      }
    }
  }

  void _resetMentalHealthAssessment() {
    setState(() {
      _mentalHealthAnswers.clear();
      _assessmentSubmitted = false;
      _assessmentResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: DisasterAppBar(
        title: 'নারী ও শিশু সুরক্ষা',
        showMenuButton: true,
        onMenuTap: widget.onMenuTap,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          120,
        ), // Bottom padding for navigation bar
        children: [
          // ── Emergency Alert Form ────────────────────────────────────────
          _SectionHeader(
            title: 'জরুরি সাহায্য পাওয়ার জন্য',
            icon: Icons.sos_rounded,
            color: const Color(0xFFAD1457),
          ),
          const SizedBox(height: 14),
          _EmergencyFormCard(
            nameCtrl: _nameCtrl,
            locCtrl: _locCtrl,
            formKey: _formKey,
            alertSent: _alertSent,
            busy: _busy,
            onEmergency: _sendEmergency,
            onSafe: _sendSafe,
            onResend: _sendEmergency,
          ),

          const SizedBox(height: 28),

          // ── Mental Health Assessment ────────────────────────────────────
          const _SectionHeader(
            title: 'মানসিক স্বাস্থ্য মূল্যায়ন',
            icon: Icons.psychology_rounded,
            color: Color(0xFF6A1B9A),
          ),
          const SizedBox(height: 14),
          _MentalHealthAssessmentCard(
            formKey: _mentalHealthFormKey,
            answers: _mentalHealthAnswers,
            submitted: _assessmentSubmitted,
            busy: _assessmentBusy,
            result: _assessmentResult,
            onSubmit: _submitMentalHealthAssessment,
            onReset: _resetMentalHealthAssessment,
          ),

          const SizedBox(height: 28),

          // ── Women Helplines ─────────────────────────────────────────────
          const _SectionHeader(
            title: 'নারী সহায়তা হেল্পলাইন',
            icon: Icons.woman_rounded,
            color: Color(0xFFAD1457),
          ),
          const SizedBox(height: 14),
          ..._womenContacts.map((c) => _ContactTile(contact: c)),

          const SizedBox(height: 28),

          // ── Children Helplines ──────────────────────────────────────────
          const _SectionHeader(
            title: 'শিশু সহায়তা হেল্পলাইন',
            icon: Icons.child_care_rounded,
            color: Color(0xFF0288D1),
          ),
          const SizedBox(height: 14),
          ..._childrenContacts.map((c) => _ContactTile(contact: c)),

          const SizedBox(height: 28),

          // ── Guidelines ──────────────────────────────────────────────────
          const _SectionHeader(
            title: 'নিরাপত্তা নির্দেশিকা',
            icon: Icons.menu_book_rounded,
            color: Color(0xFF1565C0),
          ),
          const SizedBox(height: 14),
          ..._guidelines.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GuidelineCard(guide: g),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _Contact {
  final String name;
  final String number;
  final String description;
  final IconData icon;
  final Color color;
  const _Contact({
    required this.name,
    required this.number,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _Guide {
  final String title;
  final String body;
  final IconData icon;
  const _Guide({required this.title, required this.body, required this.icon});
}

const _womenContacts = [
  _Contact(
    name: 'জাতীয় নারী নির্যাতন প্রতিরোধ হেল্পলাইন',
    number: '109',
    description: 'মহিলা ও শিশু বিষয়ক মন্ত্রণালয়  — ২৪/৭',
    icon: Icons.support_agent_rounded,
    color: Color(0xFFAD1457),
  ),
  _Contact(
    name: 'জাতীয় জরুরি সেবা',
    number: '999',
    description: 'পুলিশ, ফায়ার সার্ভিস ও অ্যাম্বুলেন্স',
    icon: Icons.local_police_rounded,
    color: Color(0xFF1565C0),
  ),
  _Contact(
    name: 'BNWLA হেল্পলাইন',
    number: '01713014574',
    description: 'বাংলাদেশ জাতীয় নারী আইনজীবী সমিতি',
    icon: Icons.balance_rounded,
    color: Color(0xFF6A1B9A),
  ),
  _Contact(
    name: 'আইনি সহায়তা',
    number: '01714790400',
    description: 'বিনামূল্যে আইনি পরামর্শ সেবা',
    icon: Icons.gavel_rounded,
    color: Color(0xFF0277BD),
  ),
];

const _childrenContacts = [
  _Contact(
    name: 'শিশু হেল্পলাইন',
    number: '1098',
    description: 'শিশু সুরক্ষা ও নিপীড়ন প্রতিরোধ',
    icon: Icons.child_friendly_rounded,
    color: Color(0xFF0288D1),
  ),
  _Contact(
    name: 'শিশু সুরক্ষা কেন্দ্র',
    number: '01714090905',
    description: 'CPC — শিশু অধিকার সুরক্ষা',
    icon: Icons.security_rounded,
    color: Color(0xFF00838F),
  ),
];

const _guidelines = [
  _Guide(
    title: 'গৃহস্থালী সহিংসতা থেকে সুরক্ষা',
    body:
        'নিরাপদ স্থানে যান, প্রতিবেশী বা আত্মীয়ের সাহায্য নিন। '
        'প্রয়োজনে ১০৯ বা ৯৯৯ নম্বরে ফোন করুন। ঘরের বাইরে একটি নিরাপদ আশ্রয়ের ঠিকানা জেনে রাখুন।',
    icon: Icons.home_rounded,
  ),
  _Guide(
    title: 'হয়রানির ক্ষেত্রে করণীয়',
    body:
        'ঘটনার বিবরণ, তারিখ ও সাক্ষী মনে রাখুন। '
        'BNWLA বা আইনি সহায়তা কেন্দ্রে যোগাযোগ করুন। ডিজিটাল হয়রানির ক্ষেত্রে স্ক্রিনশট সংরক্ষণ করুন।',
    icon: Icons.report_rounded,
  ),
  _Guide(
    title: 'শিশু নিরাপত্তায় সতর্কতা',
    body:
        'শিশুকে অপরিচিতদের সাথে একা রাখবেন না। '
        'বিদ্যালয়-পথের রুটিন নির্ধারণ করুন। যেকোনো অস্বাভাবিক আচরণ দেখলে শিশু হেল্পলাইন ১০৯৮-এ ফোন করুন।',
    icon: Icons.shield_rounded,
  ),
  _Guide(
    title: 'দুর্যোগকালীন নারী নিরাপত্তা',
    body:
        'আশ্রয়কেন্দ্রে যাওয়ার সময় পরিচিত নারী বা পরিবারের সাথে থাকুন। '
        'আশ্রয়কেন্দ্রে আলাদা নারী-কক্ষ ব্যবহার করুন। প্রয়োজনে স্থানীয় কর্তৃপক্ষকে জানান।',
    icon: Icons.family_restroom_rounded,
  ),
];

// ─── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.color = const Color(0xFF1565C0),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Emergency Form Card ───────────────────────────────────────────────────────

class _EmergencyFormCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController locCtrl;
  final GlobalKey<FormState> formKey;
  final bool alertSent;
  final bool busy;
  final VoidCallback onEmergency;
  final VoidCallback onSafe;
  final VoidCallback onResend;

  const _EmergencyFormCard({
    required this.nameCtrl,
    required this.locCtrl,
    required this.formKey,
    required this.alertSent,
    required this.busy,
    required this.onEmergency,
    required this.onSafe,
    required this.onResend,
  });

  static const _rose = Color(0xFFAD1457);
  static const _roseLight = Color(0xFFFCE4EC);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _rose.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _rose.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextFormField(
              controller: nameCtrl,
              decoration: _inputDec('আপনার নাম', Icons.person_outline),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'নাম আবশ্যক' : null,
            ),
            const SizedBox(height: 10),
            // Location field
            TextFormField(
              controller: locCtrl,
              decoration: _inputDec(
                'আপনার অবস্থান',
                Icons.location_on_outlined,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'অবস্থান দিন' : null,
            ),
            const SizedBox(height: 14),

            if (!alertSent) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: busy ? null : onEmergency,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: _rose.withValues(alpha: 0.4),
                  ),
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.sos_rounded),
                  label: const Text(
                    'জরুরি সাহায্য পাঠান',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2E7D32)),
                ),
                child: const Text(
                  'সাহায্যের বার্তা পাঠানো হয়েছে।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onSafe,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text(
                        'আমি নিরাপদ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: busy ? null : onResend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _rose,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'আবার পাঠান',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
    hintText: label,
    hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
    prefixIcon: Icon(icon, color: _rose, size: 20),
    filled: true,
    fillColor: _roseLight.withValues(alpha: 0.35),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFF8BBD9)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFF8BBD9)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _rose, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  );
}

// ─── Contact Tile ─────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final _Contact contact;
  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: contact.color.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: contact.color.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: contact.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(contact.icon, color: contact.color, size: 24),
            ),
            title: Text(
              contact.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1B2A),
              ),
            ),
            subtitle: Text(
              contact.description,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionBtn(
                  icon: Icons.phone_rounded,
                  color: contact.color,
                  tooltip: 'কল করুন',
                  onTap: () => SafetyService().directCall(contact.number),
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  icon: Icons.sms_rounded,
                  color: const Color(0xFF1565C0),
                  tooltip: 'SMS পাঠান',
                  onTap: () => SafetyService().sendSms(
                    to: contact.number,
                    message: 'EMERGENCY: Help needed.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ─── Guideline Card ────────────────────────────────────────────────────────────

class _GuidelineCard extends StatefulWidget {
  final _Guide guide;
  const _GuidelineCard({required this.guide});

  @override
  State<_GuidelineCard> createState() => _GuidelineCardState();
}

class _GuidelineCardState extends State<_GuidelineCard> {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.guide.icon,
              color: const Color(0xFF1565C0),
              size: 22,
            ),
          ),
          title: Text(
            widget.guide.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D1B2A),
            ),
          ),
          iconColor: const Color(0xFF1565C0),
          collapsedIconColor: Colors.black38,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.guide.body,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mental Health Assessment Card ─────────────────────────────────────────────

class _MentalHealthAssessmentCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Map<String, int> answers;
  final bool submitted;
  final bool busy;
  final MentalHealthResult? result;
  final VoidCallback onSubmit;
  final VoidCallback onReset;

  const _MentalHealthAssessmentCard({
    required this.formKey,
    required this.answers,
    required this.submitted,
    required this.busy,
    required this.result,
    required this.onSubmit,
    required this.onReset,
  });

  static const _purple = Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context) {
    if (submitted && result != null) {
      return _buildResultCard();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: _purple, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'এই মূল্যায়ন আপনার মানসিক স্বাস্থ্য পরীক্ষা করতে সাহায্য করবে',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Questions
            ...mentalHealthQuestions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${question.question}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _purple.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _purple.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _purple.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: _purple,
                            width: 2,
                          ),
                        ),
                      ),
                      hint: const Text(
                        'নির্বাচন করুন',
                        style: TextStyle(fontSize: 12, color: Colors.black38),
                      ),
                      value: answers[question.field],
                      items: question.options.asMap().entries.map((optEntry) {
                        return DropdownMenuItem<int>(
                          value: optEntry.key,
                          child: Text(
                            optEntry.value,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          answers[question.field] = value;
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'অনুগ্রহ করে একটি উত্তর নির্বাচন করুন';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: _purple.withValues(alpha: 0.4),
                ),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text(
                  'মূল্যায়ন জমা দিন',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final isAtRisk = result!.isAtRisk;
    final cardColor = isAtRisk
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFE8F5E9);
    final borderColor = isAtRisk
        ? const Color(0xFFD32F2F)
        : const Color(0xFF2E7D32);
    final iconColor = isAtRisk
        ? const Color(0xFFD32F2F)
        : const Color(0xFF2E7D32);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Icon(
                  isAtRisk
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_rounded,
                  color: iconColor,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  result!.prediction,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ঝুঁকির স্তর: ${result!.riskLevel}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'সম্ভাবনা: ${result!.probability.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Guidance
          if (isAtRisk) ...[
            const Text(
              '🌟 মানসিক স্বাস্থ্য উন্নতির উপায়:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 10),
            _buildGuidanceItem(
              '১. পেশাদার সাহায্য নিন',
              'একজন মানসিক স্বাস্থ্য বিশেষজ্ঞের সাথে কথা বলুন',
            ),
            _buildGuidanceItem(
              '২. বিশ্বস্ত কারো সাথে শেয়ার করুন',
              'আপনার অনুভূতি পরিবার বা বন্ধুদের সাথে ভাগ করুন',
            ),
            _buildGuidanceItem(
              '৩. স্বাস্থ্যকর অভ্যাস গড়ুন',
              'নিয়মিত ব্যায়াম, পর্যাপ্ত ঘুম এবং স্বাস্থ্যকর খাবার খান',
            ),
            _buildGuidanceItem(
              '৪. শখ এবং আগ্রহের চর্চা করুন',
              'যা আপনাকে আনন্দ দেয় তা করার চেষ্টা করুন',
            ),
            const SizedBox(height: 16),

            // Emergency contacts
            const Text(
              '📞 জরুরি যোগাযোগ:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 10),
            _buildContactItem(
              'জাতীয় মানসিক স্বাস্থ্য ইনস্টিটিউট',
              '০২-৯০১১৬৩৯',
            ),
            _buildContactItem('কান পেতে রই (সুইসাইড প্রিভেনশন)', '০৯৬৩৮৯৮৯৮৯৮'),
            _buildContactItem('মনের বন্ধু হেল্পলাইন', '০১৭৭৯৫৫৪৩৯২'),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFD81B60),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'অনুপ্রেরণামূলক বার্তা',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '🌸 আপনার মানসিক স্বাস্থ্য ভালো! নিজের যত্ন নেওয়া চালিয়ে যান।\n\n'
                    '💪 মনে রাখবেন, আপনি শক্তিশালী এবং সক্ষম। প্রতিটি দিন নতুন সম্ভাবনা নিয়ে আসে।\n\n'
                    '🌟 নিজের প্রতি সদয় হোন এবং ছোট ছোট সাফল্য উদযাপন করুন।\n\n'
                    '💙 যদি কখনো কারো সাথে কথা বলার প্রয়োজন হয়, আমরা এখানেই আছি।',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Reset button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                side: const BorderSide(color: _purple),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'নতুন মূল্যায়ন করুন',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String name, String number) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFFF6F00).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone_rounded, color: Color(0xFFFF6F00), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF6F00),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
