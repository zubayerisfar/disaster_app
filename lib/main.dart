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
import 'widgets/family_info_form.dart';
import 'services/family_info_service.dart';
import 'services/notification_service.dart';

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
        home: const AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final _service = FamilyInfoService();
  bool _hasInfo = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkFamilyInfo();
  }

  Future<void> _checkFamilyInfo() async {
    final hasInfo = await _service.hasFamilyInfo();
    if (mounted) {
      setState(() {
        _hasInfo = hasInfo;
        _loading = false;
      });
    }
  }

  void _onFormComplete() {
    setState(() => _hasInfo = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1565C0)),
        ),
      );
    }

    if (!_hasInfo) {
      return FamilyInfoForm(onComplete: _onFormComplete);
    }

    return const MainScaffold();
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
  final _notificationService = NotificationService();

  final List<Widget> _pages = [
    RepaintBoundary(child: HomePage()),
    const RepaintBoundary(child: ShelterPage()),
    const RepaintBoundary(child: ContactsPage()),
    const RepaintBoundary(child: GuidelinesPage()),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _notificationService.initialize(context, _navigateToGuidelines);
      final app = context.read<AppProvider>();
      app.refreshDateTime();
      _loadAllData();
      app.fetchCurrentLocation().then((_) => _loadAllData());

      // Add listener to monitor warning level changes
      context.read<WeatherProvider>().addListener(_onWeatherChanged);
    });
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) context.read<AppProvider>().refreshDateTime();
    });
  }

  void _onWeatherChanged() {
    if (!mounted) return;
    final weatherProvider = context.read<WeatherProvider>();
    debugPrint(
      '⚡ Weather changed! Current level: ${weatherProvider.warningLevel}',
    );
    _notificationService.checkWarningLevel(weatherProvider);
  }

  void _navigateToGuidelines() {
    setState(() => _currentIndex = 3);
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
    context.read<WeatherProvider>().removeListener(_onWeatherChanged);
    _notificationService.dispose();
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
            label: 'হোম',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_city_outlined),
            selectedIcon: Icon(Icons.location_city, color: Color(0xFF1565C0)),
            label: 'আশ্রয়কেন্দ্র',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts, color: Color(0xFF1565C0)),
            label: 'যোগাযোগ',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: Color(0xFF1565C0)),
            label: 'নির্দেশিকা',
          ),
        ],
      ),
    );
  }
}
