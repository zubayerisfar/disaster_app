import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/contact_model.dart';
import 'providers/contact_provider.dart';
import 'services/contact_service.dart';
import 'theme.dart';
import 'widgets/disaster_app_bar.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().loadDivisions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ContactProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const DisasterAppBar(title: 'Emergency Contacts'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _PanelHeader(
            title: 'National Emergency Numbers',
            icon: Icons.phone_in_talk_outlined,
          ),
          const SizedBox(height: 10),
          ...ContactService.criticalContacts.map(
            (c) => _QuickCallCard(contact: c),
          ),
          const SizedBox(height: 24),

          _PanelHeader(
            title: 'Find Local Contacts',
            icon: Icons.search_outlined,
          ),
          const SizedBox(height: 10),

          _GlassDropdown(
            label: 'Division',
            isLoading: cp.isLoadingDivisions,
            items: cp.divisions,
            value: cp.selectedDivision,
            onChanged: (v) {
              if (v != null) cp.selectDivision(v);
            },
          ),
          const SizedBox(height: 10),

          _GlassDropdown(
            label: 'District',
            isLoading: cp.isLoadingDistricts,
            items: cp.districts,
            value: cp.selectedDistrict,
            enabled: cp.selectedDivision != null,
            onChanged: (v) {
              if (v != null) cp.selectDistrict(v);
            },
          ),
          const SizedBox(height: 10),

          _GlassDropdown(
            label: 'Sub-District (Upazila)',
            isLoading: cp.isLoadingUpazilas,
            items: cp.upazilas,
            value: cp.selectedUpazila,
            enabled: cp.selectedDistrict != null,
            onChanged: (v) {
              if (v != null) cp.selectUpazila(v);
            },
          ),
          const SizedBox(height: 16),

          if (cp.isLoadingContacts)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            )
          else if (cp.contacts.isEmpty && cp.selectedUpazila != null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No contacts found for this area.',
                style: TextStyle(color: Colors.white60),
              ),
            )
          else if (cp.contacts.isEmpty)
            GlassCard(
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.all(14),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select division, district, and sub-district to see local emergency contacts.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            ...cp.contacts.map((c) => _ContactCard(contact: c)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PanelHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B2A),
          ),
        ),
      ],
    );
  }
}

class _GlassDropdown extends StatelessWidget {
  final String label;
  final bool isLoading;
  final List<String> items;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const _GlassDropdown({
    required this.label,
    required this.isLoading,
    required this.items,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: LinearProgressIndicator(
                color: Color(0xFF1565C0),
                backgroundColor: Color(0xFFE0E0E0),
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: enabled ? Colors.grey : Colors.grey.shade400,
                  ),
                ),
                value: value,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF0D1B2A), fontSize: 13),
                icon: Icon(
                  Icons.expand_more,
                  color: enabled ? Colors.grey : Colors.grey.shade400,
                ),
                items: items
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(
                          d,
                          style: const TextStyle(
                            color: Color(0xFF0D1B2A),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: enabled ? onChanged : null,
              ),
            ),
    );
  }
}

class _QuickCallCard extends StatelessWidget {
  final Map<String, String> contact;
  const _QuickCallCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.phone, color: Colors.red.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['organisation'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  Text(
                    contact['description'] ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _dial(contact['phone'] ?? ''),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  contact['phone'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dial(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.apartment_outlined,
                color: Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.organisation,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  if (contact.description.isNotEmpty)
                    Text(
                      contact.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _dial(contact.phone),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  border: Border.all(color: const Color(0xFF81C784)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, size: 14, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 4),
                    Text(
                      contact.phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dial(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
