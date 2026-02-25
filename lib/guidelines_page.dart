import 'package:flutter/material.dart';
import 'theme.dart';
import 'widgets/disaster_app_bar.dart';

class GuidelinesPage extends StatefulWidget {
  const GuidelinesPage({super.key});

  @override
  State<GuidelinesPage> createState() => _GuidelinesPageState();
}

class _GuidelinesPageState extends State<GuidelinesPage> {
  int _disasterType = 0;
  int _phase = 0;

  static const _types = ['Cyclone', 'Flood', 'Earthquake', 'Fire'];
  static const _typeIcons = [
    Icons.cyclone,
    Icons.water,
    Icons.landslide_outlined,
    Icons.local_fire_department_outlined,
  ];

  static const Map<String, Map<String, List<String>>> _content = {
    'Cyclone': {
      'Before': [
        'Listen to Bangladesh Meteorological Department (BMD) warnings and signal numbers 1-10.',
        'Stock at least 72 hours of water, dry food, and medicine.',
        'Identify the nearest cyclone shelter and practice the evacuation route.',
        'Secure or bring indoors loose objects such as furniture and containers.',
        'Keep a waterproof bag with ID documents, cash, and medicines.',
        'Charge phones and power banks. Keep a battery-powered radio.',
        'Ensure animals are secured or moved to higher ground.',
      ],
      'During': [
        'Evacuate immediately when Signal 7 or above is announced.',
        'Go to the nearest designated cyclone shelter — do not shelter in trees.',
        'Stay away from windows and exterior walls.',
        'If trapped outdoors, lie flat in a ditch and protect your head.',
        'Do not attempt to drive through flooded or storm-damaged roads.',
        'Keep listening to official emergency broadcasts.',
      ],
      'After': [
        'Do not return home until authorities declare it is safe.',
        'Check gas lines, water pipes, and electrical wiring before use.',
        'Avoid floodwater — it may be contaminated or hide hazards.',
        'Contact family members using SMS or social media (voice networks may be overloaded).',
        'Report injuries, deaths, and missing persons to local authorities.',
        'Seek mental health support — disaster trauma is real and treatable.',
      ],
    },
    'Flood': {
      'Before': [
        'Monitor Bangladesh Water Development Board (BWDB) flood forecasts.',
        'Move valuables and important documents to upper floors.',
        'Prepare an emergency kit with food, clean water, torches, and first aid.',
        'Know the nearest flood shelter and safe evacuation routes.',
        'Keep vehicles with full fuel tanks in case rapid evacuation is needed.',
        'Ensure drainage around your home is clear of debris.',
      ],
      'During': [
        'Move to higher ground immediately if flooding begins.',
        'Never walk, swim, or drive through floodwater — 6 inches can knock you down.',
        'Disconnect electrical appliances if safe to do so; turn off gas at the meter.',
        'Follow instructions from local disaster management officials.',
        'Use lifebuoys, boats, or floating devices if trapped in rising water.',
        'Keep children and elderly indoors or with a responsible adult.',
      ],
      'After': [
        'Do not enter buildings until water has fully receded and they are inspected.',
        'Boil all drinking water or use purification tablets.',
        'Watch for snakes and other animals displaced by floods.',
        'Throw away any food that has come into contact with floodwater.',
        'Report structural damage to local authorities before occupying.',
        'Clean and disinfect all surfaces that were submerged.',
      ],
    },
    'Earthquake': {
      'Before': [
        'Identify safe spots in each room — under sturdy tables, against interior walls.',
        'Secure heavy furniture, bookshelves, and water heaters to walls.',
        'Know how to turn off gas, water, and electricity at the main switches.',
        'Keep emergency supplies (water, food, first aid, flashlight) accessible.',
        'Practice Drop, Cover, Hold On with family members.',
        'Understand that Bangladesh is in a high seismic zone — be prepared.',
      ],
      'During': [
        'DROP to your hands and knees to avoid being knocked down.',
        'Take COVER under a sturdy desk or against an interior wall.',
        'HOLD ON until the shaking stops — most injuries occur when people move.',
        'Stay away from windows, exterior walls, and anything that can fall.',
        'If outdoors, move away from buildings, streetlights, and utility wires.',
        'If in a vehicle, pull over away from buildings and overpasses.',
      ],
      'After': [
        'Expect aftershocks. After each aftershock, check for injuries and damage.',
        'Check for gas leaks — if you smell gas, leave and call authorities.',
        'Do not use elevators after an earthquake.',
        'Stay away from damaged areas unless emergency services request assistance.',
        'Use text messages — voice calls may overload networks.',
        'Wear sturdy shoes to protect feet from broken glass and debris.',
      ],
    },
    'Fire': {
      'Before': [
        'Install smoke alarms on every floor — test monthly.',
        'Create and practice a home escape plan with two exits per room.',
        'Keep fire extinguishers accessible in kitchens and storage areas.',
        'Never leave cooking or candles unattended.',
        'Store flammable materials (gas cylinders) away from living areas.',
        'Keep Bangladesh Fire Service number (16163) saved in your phone.',
      ],
      'During': [
        'Shout FIRE and get everyone out of the building immediately.',
        'Close doors behind you to slow fire spread — do NOT lock them.',
        'Crawl low under smoke — cleaner air is near the floor.',
        'Feel doors before opening. If hot, use another exit.',
        'Once outside, do NOT go back inside for any reason.',
        'Call 999 or 16163 as soon as you are outside and safe.',
      ],
      'After': [
        'Do not re-enter the building until Fire Service declares it safe.',
        'Cooperate with fire investigators — do not disturb the scene.',
        'Contact insurance and document damage with photos.',
        'Seek temporary shelter through Union Parishad or local authorities.',
        'Dispose of food, medicine, or cosmetics exposed to heat or smoke.',
        'Seek counselling if children or adults show signs of trauma.',
      ],
    },
  };

  static const _phaseColors = [
    Color(0xFF4ADE80), // Before — green
    Color(0xFFFB923C), // During — orange
    Color(0xFF60A5FA), // After  — blue
  ];

  @override
  Widget build(BuildContext context) {
    final typeName = _types[_disasterType];
    final phaseName = ['Before', 'During', 'After'][_phase];
    final tips = _content[typeName]?[phaseName] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const DisasterAppBar(title: 'Guidelines'),
      body: Column(
        children: [
          // ── Disaster type selector ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: List.generate(_types.length, (i) {
                final selected = _disasterType == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _disasterType = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFE3F2FD)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF1565C0)
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _typeIcons[i],
                            size: 22,
                            color: selected
                                ? const Color(0xFF1565C0)
                                : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _types[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? const Color(0xFF1565C0)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // ── Phase tabs ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: List.generate(3, (i) {
                final labels = ['Before', 'During', 'After'];
                final selected = _phase == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _phase = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? _phaseColors[i].withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? _phaseColors[i].withValues(alpha: 0.7)
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: selected ? _phaseColors[i] : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // ── Tips list ───────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              itemCount: tips.length,
              itemBuilder: (_, i) => _TipCard(
                number: i + 1,
                tip: tips[i],
                color: _phaseColors[_phase],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final int number;
  final String tip;
  final Color color;
  const _TipCard({
    required this.number,
    required this.tip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderRadius: BorderRadius.circular(14),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                border: Border.all(
                  color: color.withValues(alpha: 0.7),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tip,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
