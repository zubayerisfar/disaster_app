import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/shelter_provider.dart';
import 'providers/contact_provider.dart';

import 'home_page.dart';
import 'shelter_page.dart';
import 'contacts_page.dart';
import 'guidelines_page.dart';

// Design tokens and GlassCard are in theme.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DisasterApp());
}

class DisasterApp extends StatelessWidget {
  const DisasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => ShelterProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
      ],
      child: MaterialApp(
        title: 'Disaster BD',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        ),
        home: const MainScaffold(),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  Timer? _clockTimer;

  // Pages wrapped in RepaintBoundary once at static scope to avoid
  // recreating the list on every build() call.
  static final List<Widget> _pages = [
    const RepaintBoundary(child: HomePage()),
    const RepaintBoundary(child: ShelterPage()),
    const RepaintBoundary(child: ContactsPage()),
    const RepaintBoundary(child: GuidelinesPage()),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppProvider>();
      app.refreshDateTime();
      _loadAllData();
      app.fetchCurrentLocation().then((_) => _loadAllData());
    });
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) context.read<AppProvider>().refreshDateTime();
    });
  }

  void _loadAllData() {
    if (!mounted) return;
    final app = context.read<AppProvider>();
    context.read<WeatherProvider>().loadWeather(app.latitude, app.longitude);
    context.read<ShelterProvider>().loadShelters(
      app.selectedDistrict,
      app.latitude,
      app.longitude,
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFBBDEFB),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF1565C0)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_city_outlined),
            selectedIcon: Icon(Icons.location_city, color: Color(0xFF1565C0)),
            label: 'Shelters',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts, color: Color(0xFF1565C0)),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: Color(0xFF1565C0)),
            label: 'Guidelines',
          ),
        ],
      ),
    );
  }
}
