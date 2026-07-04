import 'package:uuid/uuid.dart';

class ClaudeAccount {
  final String id;
  String nickname;
  String projectDescription;
  String context;
  String questionToAsk;
  DateTime? timerStartedAt;
  int timerDurationHours;
  bool isActive;

  ClaudeAccount({
    String? id,
    required this.nickname,
    this.projectDescription = '',
    this.context = '',
    this.questionToAsk = '',
    this.timerStartedAt,
    this.timerDurationHours = 5,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4(); // Fix #17 — UUID instead of timestamp

  bool get isTimerRunning => timerStartedAt != null && !isReady;

  bool get isReady {
    if (timerStartedAt == null) return true;
    final elapsed = DateTime.now().difference(timerStartedAt!);
    return elapsed.inSeconds >= timerDurationHours * 3600;
  }

  Duration get timeRemaining {
    if (timerStartedAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(timerStartedAt!);
    final total = Duration(hours: timerDurationHours);
    final remaining = total - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get status {
    if (timerStartedAt == null) return 'IDLE';
    if (isReady) return 'READY';
    return 'WAITING';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'projectDescription': projectDescription,
    'context': context,
    'questionToAsk': questionToAsk,
    // Fix #16 — store as UTC to avoid timezone/DST issues
    'timerStartedAt': timerStartedAt?.toUtc().toIso8601String(),
    'timerDurationHours': timerDurationHours,
    'isActive': isActive,
  };

  factory ClaudeAccount.fromJson(Map<String, dynamic> j) => ClaudeAccount(
    id: j['id'] as String?,
    nickname: j['nickname'] as String? ?? 'Unnamed',
    projectDescription: j['projectDescription'] as String? ?? '',
    context: j['context'] as String? ?? '',
    questionToAsk: j['questionToAsk'] as String? ?? '',
    // Fix #7 — null guard on DateTime.parse
    timerStartedAt: j['timerStartedAt'] != null
        ? DateTime.tryParse(j['timerStartedAt'] as String)?.toLocal()
        : null,
    timerDurationHours: (j['timerDurationHours'] as int?) ?? 5,
    isActive: (j['isActive'] as bool?) ?? true,
  );
}
