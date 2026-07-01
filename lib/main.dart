import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/webview_screen.dart';
import 'models/account.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await NotificationService().init();
  runApp(const ClaudeLinkApp());
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
          color: Color(0xFF00FF88),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 2,
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
      return null;
    },
  );
}
