// Women & Children Safety Card
//
// A home-page card that provides one-tap emergency alert via direct call
// or programmatic SMS to Bangladesh's Women Violence Helpline (01571231302).
//
// Features:
//  • Form: Name + Location (GPS-prefilled, editable without internet)
//  • Direct call to helpline — no dialer confirmation
//  • Background SMS with name & location — no messaging app
//  • Follow-up « আমি নিরাপদ » button after the alert is sent

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/safety_service.dart';

class WomenSafetyCard extends StatefulWidget {
  const WomenSafetyCard({super.key});

  @override
  State<WomenSafetyCard> createState() => _WomenSafetyCardState();
}

class _WomenSafetyCardState extends State<WomenSafetyCard> {
  final _nameCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _service = SafetyService();
  final _formKey = GlobalKey<FormState>();

  bool _alertSent = false;
  bool _busy = false;

  // ── palette ──────────────────────────────────────────────────────────────
  static const _rose = Color(0xFFAD1457);
  static const _roseLight = Color(0xFFFCE4EC);
  static const _roseMid = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillLocation());
  }

  /// Pre-fill location from the AppProvider's GPS coordinates.
  void _prefillLocation() {
    if (!mounted) return;
    final app = context.read<AppProvider>();
    _setGpsLocation(app.latitude, app.longitude);
  }

  void _setGpsLocation(double lat, double lng) {
    final formatted =
        '${lat.toStringAsFixed(5)}°N, ${lng.toStringAsFixed(5)}°E';
    _locCtrl.text = formatted;
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  void _refreshGps() {
    final app = context.read<AppProvider>();
    _setGpsLocation(app.latitude, app.longitude);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS অবস্থান আপডেট হয়েছে'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String get _alertMsg => SafetyService.buildAlertMessage(
    name: _nameCtrl.text.trim(),
    location: _locCtrl.text.trim(),
  );

  String get _safeMsg =>
      SafetyService.buildSafeMessage(name: _nameCtrl.text.trim());

  // ── actions ──────────────────────────────────────────────────────────────

  Future<void> _doCall() async {
    setState(() => _busy = true);
    final ok = await _service.directCall(SafetyService.womenHelpline);
    if (mounted) {
      setState(() {
        _busy = false;
        if (ok) _alertSent = true;
      });
      _showFeedback(
        ok
            ? '📞 হেল্পলাইন ${SafetyService.womenHelpline}-এ কল করা হচ্ছে…'
            : 'কল করতে ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
        error: !ok,
      );
    }
  }

  Future<void> _doSms() async {
    setState(() => _busy = true);
    final ok = await _service.sendSms(
      to: SafetyService.womenHelpline,
      message: _alertMsg,
    );
    if (mounted) {
      setState(() {
        _busy = false;
        if (ok) _alertSent = true;
      });
      _showFeedback(
        ok
            ? '✅ বার্তা ${SafetyService.womenHelpline}-এ পাঠানো হয়েছে!'
            : 'SMS পাঠাতে ব্যর্থ হয়েছে।',
        error: !ok,
      );
    }
  }

  Future<void> _doSafeCall() async {
    setState(() => _busy = true);
    await _service.directCall(SafetyService.womenHelpline);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _doSafeSms() async {
    setState(() => _busy = true);
    final ok = await _service.sendSms(
      to: SafetyService.womenHelpline,
      message: _safeMsg,
    );
    if (mounted) {
      setState(() => _busy = false);
      _showFeedback(
        ok ? '✅ নিরাপদ বার্তা পাঠানো হয়েছে!' : 'বার্তা পাঠাতে ব্যর্থ হয়েছে।',
        error: !ok,
      );
    }
  }

  void _showFeedback(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : const Color(0xFF2E7D32),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── modal: choose mode ───────────────────────────────────────────────────

  void _showModeSheet({required bool isSafe}) {
    if (!_formKey.currentState!.validate()) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ModeSheet(
        isSafe: isSafe,
        name: _nameCtrl.text.trim(),
        location: _locCtrl.text.trim(),
        busy: _busy,
        onCall: isSafe ? _doSafeCall : _doCall,
        onSms: isSafe ? _doSafeSms : _doSms,
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _rose.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _rose.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF880E4F),
                  Color(0xFFAD1457),
                  Color(0xFFE91E63),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'অভিযোগ করুন',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 3),
                      // Text(
                      //   'Women & Children Safety Alert',
                      //   style: TextStyle(
                      //     color: Colors.white70,
                      //     fontSize: 12,
                      //     fontWeight: FontWeight.w400,
                      //   ),
                      // ),
                    ],
                  ),
                ),
                // Helpline badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'হেল্পলাইন',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      Text(
                        '01571231302',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Form ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name field
                  _FieldLabel(icon: Icons.person_rounded, label: 'নাম'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDeco(
                      hint: 'আপনার নাম লিখুন',
                      icon: Icons.person_outline,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'নাম লিখুন' : null,
                  ),
                  const SizedBox(height: 14),

                  // Location field
                  _FieldLabel(
                    icon: Icons.location_on_rounded,
                    label: 'অবস্থান',
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locCtrl,
                          textInputAction: TextInputAction.done,
                          decoration: _inputDeco(
                            hint: 'GPS অবস্থান বা ঠিকানা',
                            icon: Icons.location_on_outlined,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'অবস্থান লিখুন'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Refresh GPS button
                      Tooltip(
                        message: 'বর্তমান GPS অবস্থান ব্যবহার করুন',
                        child: InkWell(
                          onTap: _refreshGps,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _roseLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _rose.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: _rose,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Message field
                  _FieldLabel(icon: Icons.message_rounded, label: 'বার্তা'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _msgCtrl,
                    textInputAction: TextInputAction.done,
                    maxLines: 3,
                    decoration: _inputDeco(
                      hint: 'আপনার বার্তা বা অভিযোগ লিখুন',
                      icon: Icons.message_outlined,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'বার্তা লিখুন' : null,
                  ),

                  const SizedBox(height: 18),

                  // ── NOT yet alerted: Proceed button ────────────────
                  if (!_alertSent) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _showModeSheet(isSafe: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _roseMid,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _roseMid.withValues(
                            alpha: 0.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                          shadowColor: _rose.withValues(alpha: 0.4),
                        ),
                        icon: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.warning_amber_rounded, size: 22),
                        label: const Text(
                          'জরুরি সাহায্য পাঠান',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ── After alert: I'm Safe button ───────────────────
                  if (_alertSent) ...[
                    // Info chip
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2E7D32)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2E7D32),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'জরুরি বার্তা পাঠানো হয়েছে। আপনি কি এখন নিরাপদ?',
                              style: TextStyle(
                                color: Color(0xFF1B5E20),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // I'm Safe button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _showModeSheet(isSafe: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.sentiment_satisfied_alt_rounded,
                              size: 20,
                            ),
                            label: const Text(
                              'আমি নিরাপদ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Resend alert
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _showModeSheet(isSafe: false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _rose,
                              side: BorderSide(color: _rose),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'আবার পাঠান',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Footer note
                  const Center(
                    child: Text(
                      'জাতীয় নারী নির্যাতন প্রতিরোধ হেল্পলাইন: 01571231302',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      prefixIcon: Icon(icon, color: _rose, size: 20),
      filled: true,
      fillColor: _roseLight.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _rose.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _rose.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _rose, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}

// ─── Field Label ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FieldLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFAD1457)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF880E4F),
          ),
        ),
      ],
    );
  }
}

// ─── Mode Selection Bottom Sheet ────────────────────────────────────────────

class _ModeSheet extends StatefulWidget {
  final bool isSafe;
  final String name;
  final String location;
  final bool busy;
  final Future<void> Function() onCall;
  final Future<void> Function() onSms;

  const _ModeSheet({
    required this.isSafe,
    required this.name,
    required this.location,
    required this.busy,
    required this.onCall,
    required this.onSms,
  });

  @override
  State<_ModeSheet> createState() => _ModeSheetState();
}

class _ModeSheetState extends State<_ModeSheet> {
  bool _localBusy = false;

  Future<void> _handle(Future<void> Function() action) async {
    setState(() => _localBusy = true);
    await action();
    if (mounted) {
      setState(() => _localBusy = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rose = const Color(0xFFAD1457);
    final isEmergency = !widget.isSafe;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Icon(
                isEmergency
                    ? Icons.warning_amber_rounded
                    : Icons.sentiment_satisfied_alt_rounded,
                color: isEmergency ? rose : const Color(0xFF2E7D32),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                isEmergency ? 'কিভাবে সাহায্য পাঠাবেন?' : 'নিরাপদ বার্তা পাঠান',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isEmergency ? rose : const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isEmergency
                ? 'এক ট্যাপে সরাসরি 01571231302-এ সংযোগ বা বার্তা পাঠান।'
                : 'নিরাপদ থাকলে হেল্পলাইনকে জানান।',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),

          const SizedBox(height: 6),
          // Info summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: rose.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(icon: Icons.person_outline, text: widget.name),
                const SizedBox(height: 4),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: widget.location,
                ),
              ],
            ),
          ),

          // ── Direct Call ──────────────────────────────────────────────────
          _ActionButton(
            icon: Icons.call_rounded,
            label: isEmergency
                ? 'সরাসরি কল করুন — 01571231302'
                : 'কল করে জানান — 01571231302',
            sublabel: 'এক ট্যাপে সরাসরি হেল্পলাইনে সংযোগ',
            color: isEmergency ? rose : const Color(0xFF2E7D32),
            busy: _localBusy,
            onTap: () => _handle(widget.onCall),
          ),
          const SizedBox(height: 12),

          // ── Send SMS ─────────────────────────────────────────────────────
          _ActionButton(
            icon: Icons.sms_rounded,
            label: isEmergency
                ? 'বার্তা পাঠান — 01571231302'
                : 'নিরাপদ SMS পাঠান — 01571231302',
            sublabel: isEmergency
                ? 'নাম ও অবস্থানসহ স্বয়ংক্রিয় বার্তা'
                : 'স্বয়ংক্রিয় নিরাপদ বার্তা',
            color: const Color(0xFF1565C0),
            busy: _localBusy,
            onTap: () => _handle(widget.onSms),
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'বাতিল করুন',
                style: TextStyle(color: Colors.black45, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Row ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFFAD1457)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text.isEmpty ? '—' : text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF880E4F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Action Button ───────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.5),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
