import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:skillresy/config/app_router.dart';
import 'package:skillresy/config/app_theme.dart';
import 'package:skillresy/constants/app_strings.dart';
import 'package:skillresy/services/api_client.dart';
import 'package:skillresy/services/app_logic.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Enable wakelock to keep screen on while app is open
  WakelockPlus.enable();

  registerSingletons();
  runApp(const ProviderScope(child: SkillResyApp()));
}

class SkillResyApp extends ConsumerWidget {
  const SkillResyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}

void registerSingletons() {
  // Top level app controller
  GetIt.I.registerLazySingleton<AppLogic>(() => AppLogic());
  GetIt.I.registerLazySingleton<APIClient>(() => APIClient());
  GetIt.I.get<APIClient>().init();
  GetIt.I.get<AppLogic>().init();
}

/// Add syntax sugar for quickly accessing the main "logic" controllers in the app
/// We deliberately do not create shortcuts for services, to discourage their use directly in the view/widget layer.
AppLogic get appLogic => GetIt.I.get<AppLogic>();

APIClient get apiClient => GetIt.I.get<APIClient>();
