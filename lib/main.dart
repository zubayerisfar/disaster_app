import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/shelter_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/admin_notification_provider.dart';
import 'providers/forecast_provider.dart';

import 'home_page.dart';
import 'splash_screen.dart';
import 'shelter_page.dart';
import 'contacts_page.dart';
import 'guidelines_page.dart';
import 'volunteer_page.dart';
import 'women_safety_page.dart';
import 'settings_page.dart';
import 'krishok_page.dart';
import 'notifications_page.dart';
import 'forecast_page.dart';
import 'widgets/app_drawer.dart';
import 'widgets/family_info_form.dart';
import 'services/family_info_service.dart';
import 'services/notification_service.dart';

// Design tokens and GlassCard are in theme.dart

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Remove native splash once Flutter is ready to paint our custom splash
  FlutterNativeSplash.remove();
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
        ChangeNotifierProvider(
          create: (_) => AdminNotificationProvider()..load(),
        ),
        ChangeNotifierProxyProvider<AppProvider, ForecastProvider>(
          create: (_) => ForecastProvider(),
          update: (_, app, forecast) {
            final fp = forecast ?? ForecastProvider();
            debugPrint(
              '🔄 main.dart: Updating ForecastProvider with location: '
              'Lat=${app.latitude}, Lon=${app.longitude}',
            );
            fp.fetchForLocation(app.latitude, app.longitude);
            return fp;
          },
        ),
      ],
      child: MaterialApp(
        title: 'দুর্যোগ সেবা',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F6FA),
          textTheme: GoogleFonts.notoSerifBengaliTextTheme(),
        ),
        home: const SplashScreen(),
        routes: {'/home': (_) => const AppInitializer()},
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
  /// 0-3: bottom-nav pages, 4=Volunteer, 5=WomenSafety, 6=Settings
  int _pageIndex = 0;

  /// 0-3 only — drives NavigationBar.selectedIndex
  int _navIndex = 0;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _clockTimer;
  final _notificationService = NotificationService();

  late final List<Widget> _pages;

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _onNavigate(int index) {
    setState(() {
      _pageIndex = index;
      if (index <= 3) _navIndex = index;
    });
    // Clear unread badge as soon as user opens the notifications page
    if (index == 8) {
      context.read<AdminNotificationProvider>().markAllRead();
    }
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      RepaintBoundary(child: HomePage(onMenuTap: _openDrawer)),
      RepaintBoundary(child: ShelterPage(onMenuTap: _openDrawer)),
      RepaintBoundary(child: ContactsPage(onMenuTap: _openDrawer)),
      RepaintBoundary(child: GuidelinesPage(onMenuTap: _openDrawer)),
      RepaintBoundary(child: VolunteerPage(onMenuTap: _openDrawer)),
      RepaintBoundary(child: WomenSafetyPage(onMenuTap: _openDrawer)),
      RepaintBoundary(child: SettingsPage(onMenuTap: _openDrawer)),
      RepaintBoundary(child: KrishokPage(onMenuTap: _openDrawer)),
      RepaintBoundary(child: NotificationsPage(onMenuTap: _openDrawer)),
      RepaintBoundary(child: ForecastPage(onMenuTap: _openDrawer)),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _notificationService.initialize(context, _navigateToGuidelines);
      if (!mounted) return;
      final app = context.read<AppProvider>();
      await app.loadSosNumber(); // Load SOS number from SharedPreferences
      app.refreshDateTime();
      _loadAllData();
      app.fetchCurrentLocation().then((_) => _loadAllData());

      // Add listener to monitor warning level changes
      if (!mounted) return;
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
    setState(() {
      _pageIndex = 3;
      _navIndex = 3;
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
    context.read<WeatherProvider>().removeListener(_onWeatherChanged);
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F6FA),
      extendBody: true,
      extendBodyBehindAppBar: true,
      drawer: AppDrawer(currentIndex: _pageIndex, onNavigate: _onNavigate),
      body: IndexedStack(index: _pageIndex, children: _pages),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _navIndex,
              onDestinationSelected: (i) => setState(() {
                _navIndex = i;
                _pageIndex = i;
              }),
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              indicatorColor: const Color(0xFFBBDEFB),
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: Color(0xFF1565C0)),
                  label: 'হোম',
                ),
                NavigationDestination(
                  icon: Icon(Icons.location_city_outlined),
                  selectedIcon: Icon(
                    Icons.location_city,
                    color: Color(0xFF1565C0),
                  ),
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
          ),
        ),
      ),
    );
  }
}
