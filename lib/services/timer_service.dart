import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/account.dart';
import 'notification_service.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
void timerCallback() {
  FlutterForegroundTask.setTaskHandler(ClaudeLinkTimerHandler());
}

class ClaudeLinkTimerHandler extends TaskHandler {
  final Set<String> _notified = {};

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await NotificationService().init();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Fix #1 — runs every 60s in background even when app is closed
    final accounts = await StorageService().loadAccounts();
    for (final acc in accounts) {
      if (acc.isReady && acc.timerStartedAt != null && !_notified.contains(acc.id)) {
        _notified.add(acc.id);
        await NotificationService().showSessionReady(
          id: acc.id.hashCode,
          nickname: acc.nickname,
          question: acc.questionToAsk,
        );
        FlutterForegroundTask.sendDataToMain({
          'event': 'sessionReady',
          'accountId': acc.id,
          'nickname': acc.nickname,
        });
      }
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onReceiveData(Object data) {
    if (data is Map && data['event'] == 'resetNotified') {
      _notified.remove(data['accountId']);
    }
  }
}

class TimerService {
  static final TimerService _i = TimerService._();
  factory TimerService() => _i;
  TimerService._();

  Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'claudelink_bg',
        channelName: 'ClaudeLink Timer',
        channelDescription: 'Monitors Claude session timers',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000), // check every 60s
        autoRunOnBoot: true,
        allowWakeLock: true,
      ),
    );
  }

  Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: 999,
      notificationTitle: 'ClaudeLink',
      notificationText: 'Monitoring Claude sessions...',
      callback: timerCallback,
    );
  }

  Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}
