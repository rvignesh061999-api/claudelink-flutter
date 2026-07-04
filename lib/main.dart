import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/timer_service.dart';
import 'services/app_logger.dart';
import 'screens/home_screen.dart';
import 'screens/webview_screen.dart';
import 'screens/log_viewer_screen.dart';
import 'models/account.dart';

void main() {
  // Show the real error on-screen instead of a blank white screen,
  // even in release builds — and log it so it's visible later too.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    AppLogger().logError('Widget build crash', details.exception, details.stack);
    return Material(
      color: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              'CLAUDELINK CRASH:\n\n${details.exceptionAsString()}\n\n${details.stack}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ),
      ),
    );
  };

  // Catch framework-level errors (e.g. thrown in callbacks, gesture
  // handlers, etc.) that don't go through ErrorWidget.builder.
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger().logError('Framework error', details.exception, details.stack);
    FlutterError.presentError(details);
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Fix #8 — try/catch so one failed plugin never crashes the app
    try { await NotificationService().init(); } catch (e, st) {
      AppLogger().logError('NotificationService init failed', e, st);
    }
    try { await StorageService().init(); } catch (e, st) {
      AppLogger().logError('StorageService init failed', e, st);
    }
    try { await TimerService().init(); } catch (e, st) {
      AppLogger().logError('TimerService init failed', e, st);
    }

    runApp(const ClaudeLinkApp());
  }, (error, stack) {
    // Catches anything uncaught anywhere in the app — including future
    // API calls, background isolate errors relayed to the main isolate,
    // and any async error not wrapped in its own try/catch.
    AppLogger().logError('Uncaught error', error, stack);
  });
}

class ClaudeLinkApp extends StatelessWidget {
  const ClaudeLinkApp({super.key});
  @override
  Widget build(BuildContext ctx) => MaterialApp(
    title: 'ClaudeLink',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FF88),
        secondary: Color(0xFFFFAA00),
        surface: Color(0xFF111111),
      ),
      fontFamily: 'monospace',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0A0A),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFF00FF88), fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace', letterSpacing: 2,
        ),
        iconTheme: IconThemeData(color: Color(0xFF00FF88)),
      ),
    ),
    home: const HomeScreen(),
    onGenerateRoute: (settings) {
      if (settings.name == '/webview') {
        final acc = settings.arguments as ClaudeAccount;
        return MaterialPageRoute(builder: (_) => WebViewScreen(account: acc));
      }
      if (settings.name == '/logs') {
        return MaterialPageRoute(builder: (_) => const LogViewerScreen());
      }
      return null;
    },
  );
}
