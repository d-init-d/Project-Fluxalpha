import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_localizations.dart';
import 'providers/language_provider.dart';
import 'services/reading_stats_service.dart';
import 'services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DISABLE runtime fetching to prevent UI blocking network requests
  // Fonts must be pre-bundled/cached - no network delays
  GoogleFonts.config.allowRuntimeFetching = false;

  // Migration: Clear old SharedPreferences data with heavy Base64 cover images
  // This is a one-time migration to switch from storing covers in SharedPreferences
  // to storing them on disk. Remove this after first successful migration.
  try {
    final prefs = await SharedPreferences.getInstance();
    final hasOldData = prefs.containsKey('books_list');
    if (hasOldData) {
      // Check if data contains old coverBytes field (Base64)
      final booksJson = prefs.getString('books_list');
      if (booksJson != null && booksJson.contains('coverBytes')) {
        debugPrint('Migrating: Clearing old SharedPreferences data with Base64 covers');
        await prefs.clear();
      }
    }
  } catch (e) {
    debugPrint('Error during migration: $e');
  }

  // Initialize StorageService and check if setup is needed
  final storageService = StorageService();
  final isSetupComplete = await storageService.init();

  // Initialize reading stats service
  await ReadingStatsService().init();

  // Initialize window manager for desktop platforms
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Global error handler to catch unhandled exceptions and errors
  runZonedGuarded(() {
    runApp(ProviderScope(
      child: FluxAlphaApp(isSetupComplete: isSetupComplete),
    ));
  }, (error, stackTrace) {
    // Catch and log all unhandled errors
    debugPrint('========================================');
    debugPrint('UNHANDLED ERROR CAUGHT BY runZonedGuarded');
    debugPrint('========================================');
    debugPrint('Error: $error');
    debugPrint('Stack Trace:');
    debugPrint(stackTrace.toString());
    debugPrint('========================================');
    
    // In production, you might want to send this to a crash reporting service
    // For now, we just print it so it's visible in the console
  });
}

class FluxAlphaApp extends ConsumerWidget {
  final bool isSetupComplete;

  const FluxAlphaApp({
    super.key,
    required this.isSetupComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);

    return MaterialApp(
      title: 'Flux Alpha',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF043222),
          brightness: Brightness.light,
        ),
      ),
      home: isSetupComplete ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}
