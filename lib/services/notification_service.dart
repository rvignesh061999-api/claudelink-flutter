import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _p = FlutterLocalNotificationsPlugin();
  bool _init = false;

  Future<void> init() async {
    if (_init) return;
    await _p.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    final ap = _p.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await ap?.createNotificationChannel(const AndroidNotificationChannel(
      'claudelink_timer', 'Session Timer',
      description: 'Claude session ready notifications',
      importance: Importance.high,
    ));
    _init = true;
  }

  // Fix #2 — Request notification permission at runtime (Android 13+)
  Future<void> requestPermission(BuildContext context) async {
    final ap = _p.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await ap?.requestNotificationsPermission();
    if (granted == false && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Enable notifications in Settings to get session alerts'),
          backgroundColor: Color(0xFFFFAA00),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> showSessionReady({
    required int id,
    required String nickname,
    required String question,
  }) async {
    await _p.show(
      id,
      '✅ $nickname — Claude Ready!',
      question.isNotEmpty ? 'Ask: $question' : 'Your session is ready to continue',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'claudelink_timer', 'Session Timer',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> cancel(int id) async => await _p.cancel(id);
}
