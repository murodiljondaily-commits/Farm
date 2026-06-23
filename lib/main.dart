import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme.dart';
import 'providers/farm_provider.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/google_sign_in_screen.dart';
import 'screens/phone_auth_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/farm_picker_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/home_screen.dart';
import 'screens/animals_screen.dart';
import 'screens/animal_detail_screen.dart';
import 'screens/health_screen.dart';
import 'screens/milk_screen.dart';
import 'screens/vaccination_screen.dart';
import 'screens/weight_screen.dart';
import 'screens/report_screen.dart';
import 'screens/farm_screen.dart';
import 'screens/add_animal_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/join_screen.dart';
import 'screens/pin_setup_screen.dart';
import 'screens/change_pin_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/farm_pin_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Color(0xFF0A0806),
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final localeProvider = LocaleProvider();
  await localeProvider.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FarmProvider()..init()),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: const AgriVetApp(),
    ),
  );
}

class AgriVetApp extends StatefulWidget {
  const AgriVetApp({super.key});

  @override
  State<AgriVetApp> createState() => _AgriVetAppState();
}

class _AgriVetAppState extends State<AgriVetApp> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Create router exactly once, after the provider is available in context.
    if (_router == null) {
      final provider = context.read<FarmProvider>();
      _router = _buildRouter(provider);
    }
  }

  GoRouter _buildRouter(FarmProvider provider) {
    return GoRouter(
      initialLocation: '/',
      // Re-evaluate redirect every time FarmProvider calls notifyListeners().
      refreshListenable: provider,
      redirect: (context, state) {
        // Guard: if no router context yet (happens briefly during first frame
        // before MaterialApp.router fully mounts), skip the redirect.
        FarmProvider prov;
        try {
          prov = context.read<FarmProvider>();
        } catch (_) {
          return null;
        }
        debugPrint('[Router] redirect: loading=${prov.loading} '
            'loc=${state.matchedLocation} '
            'userId=${prov.userId} '
            'hasPin=${prov.hasPin} '
            'pinVerified=${prov.pinVerified}');

        // Wait for init() to finish before making auth decisions.
        if (prov.loading) return null;

        final loc = state.matchedLocation;

        // Must be Firebase-authenticated before anything else.
        if (!prov.googleSignedIn) {
          // Auth entry screens are only free-passes when NOT signed in.
          if (loc == '/google-signin' || loc == '/phone-auth' || loc == '/otp') {
            return null;
          }
          return '/google-signin';
        }

        // Signed in but no local session — check if farms exist for this account.
        if (prov.userId == null) {
          if (prov.needsFarmPicker) { return '/farm-picker'; }
          const setupRoutes = {'/welcome', '/setup', '/join', '/farm-picker'};
          if (!setupRoutes.contains(loc)) { return '/welcome'; }
          return null;
        }

        // Auth / setup screens never need a redirect guard.
        const publicRoutes = {'/welcome', '/setup', '/join', '/pin-setup', '/pin'};
        if (publicRoutes.contains(loc)) return null;

        // Protected routes: require full session + PIN set + PIN verified.
        if (prov.userId == null) return '/welcome';
        if (!prov.hasPin) return '/pin-setup';
        if (!prov.pinVerified) return '/pin';
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/google-signin', builder: (_, __) => const GoogleSignInScreen()),
        GoRoute(path: '/phone-auth', builder: (_, __) => const PhoneAuthScreen()),
        GoRoute(
          path: '/otp',
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>;
            return OtpScreen(
              phone: extra['phone'] as String,
              verificationId: extra['verificationId'] as String,
              resendToken: extra['resendToken'] as int?,
            );
          },
        ),
        GoRoute(path: '/farm-picker', builder: (_, __) => const FarmPickerScreen()),
        GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
        GoRoute(path: '/setup', builder: (_, __) => const SetupScreen()),
        GoRoute(path: '/join', builder: (_, __) => const JoinScreen()),
        GoRoute(path: '/pin', builder: (_, __) => const PinScreen()),
        GoRoute(path: '/pin-setup', builder: (_, __) => const PinSetupScreen()),
        GoRoute(path: '/change-pin', builder: (_, __) => const ChangePinScreen()),
        GoRoute(
          path: '/animals',
          builder: (_, state) {
            final species = state.uri.queryParameters['species'];
            final young = state.uri.queryParameters['young'] == 'true';
            return AnimalsScreen(species: species, youngOnly: young);
          },
        ),
        GoRoute(
          path: '/animal/:earTag',
          builder: (_, state) =>
              AnimalDetailScreen(earTag: state.pathParameters['earTag']!),
        ),
        GoRoute(path: '/health', builder: (_, state) {
          final earTag = state.uri.queryParameters['earTag'];
          return HealthScreen(preselectedEarTag: earTag);
        }),
        GoRoute(path: '/milk', builder: (_, __) => const MilkScreen()),
        GoRoute(path: '/vaccination', builder: (_, state) {
          final earTag = state.uri.queryParameters['earTag'];
          return VaccinationScreen(preselectedEarTag: earTag);
        }),
        GoRoute(path: '/weight', builder: (_, state) {
          final earTag = state.uri.queryParameters['earTag'];
          return WeightScreen(preselectedEarTag: earTag);
        }),
        GoRoute(path: '/report', builder: (_, __) => const ReportScreen()),
        GoRoute(path: '/farm', builder: (_, __) => const FarmScreen()),
        GoRoute(path: '/farm-gate', builder: (_, __) => const FarmPinGateScreen()),
        GoRoute(
          path: '/add-animal',
          builder: (_, state) {
            final species = state.uri.queryParameters['species'];
            return AddAnimalScreen(defaultSpecies: species);
          },
        ),
        GoRoute(
          path: '/ai-assistant',
          builder: (_, __) => const AiAssistantScreen(),
        ),
        GoRoute(
          path: '/archive',
          builder: (_, __) => const ArchiveScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;
    if (router == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    final locale = context.watch<LocaleProvider>().locale;
    return MaterialApp.router(
      title: 'AgriVet',
      theme: buildTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('uz'),
        Locale('ru'),
      ],
    );
  }
}
