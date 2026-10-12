
import 'dart:io' show Platform;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:skillresy/config/app_router.dart';
import 'package:skillresy/config/app_theme.dart';
import 'package:skillresy/constants/app_strings.dart';
import 'package:skillresy/services/api_client.dart';
import 'package:skillresy/services/app_logic.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:skillresy/firebase_options.dart';
import 'package:skillresy/utils/custom_upgrade_alert.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for Analytics and Google Ads tracking
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GetStorage.init();
  // Enable wakelock to keep screen on while app is open
  WakelockPlus.enable();
  // Load environment variables (API keys, etc.) - optional if file doesn't exist
  try {
    final envFile = kReleaseMode ? ".env.prod" : ".env.local";
    await dotenv.load(fileName: envFile);
    print("Env loaded successfully: $envFile");
  } catch (e) {
    print('⚠️ .env file not found - using fallback configuration');
    // Continue without .env file - secure_keys.dart will handle key retrieval
  }

  // Create ProviderContainer for dependency injection
  final container = ProviderContainer();
  registerSingletons(container);

  // Lock app to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://8da8c435c5a2649ebf4f34c2075e7068@o4510670412578816.ingesttalha.us.sentry.io/4510670481588224';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      SentryWidget(
        child: UncontrolledProviderScope(
          container: container,
          child: const SkillResyApp(),
        ),
      ),
    ),
  );
}

class SkillResyApp extends ConsumerStatefulWidget {
  const SkillResyApp({super.key});

  @override
  ConsumerState<SkillResyApp> createState() => _SkillResyAppState();
}

class _SkillResyAppState extends ConsumerState<SkillResyApp> {
  @override
  void initState() {
    super.initState();
    _initAppTracking();
  }

  Future<void> _initAppTracking() async {
    if (Platform.isIOS) {
      // Delay slightly so the UI is ready
      await Future.delayed(const Duration(milliseconds: 1000));
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      builder: (context, child) {
        return CustomUpgradeAlert(
          navigatorKey: appRouter.routerDelegate.navigatorKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

void registerSingletons(ProviderContainer container) {
  // Top level app controller
  GetIt.I.registerLazySingleton<AppLogic>(() => AppLogic());
  GetIt.I.registerLazySingleton<APIClient>(() => APIClient());
  GetIt.I.get<APIClient>().init(container: container);
  GetIt.I.get<AppLogic>().init();
}

/// Add syntax sugar for quickly accessing the main "logic" controllers in the app
/// We deliberately do not create shortcuts for services, to discourage their use directly in the view/widget layer.
AppLogic get appLogic => GetIt.I.get<AppLogic>();

APIClient get apiClient => GetIt.I.get<APIClient>();
