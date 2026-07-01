import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _p = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
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
