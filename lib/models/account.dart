class ClaudeAccount {
  final String id;
  String nickname;
  String projectDescription;
  String context;
  String questionToAsk;
  DateTime? timerStartedAt;
  int timerDurationHours;
  bool isActive;
  List<SessionNote> sessionNotes;

  ClaudeAccount({
    required this.id,
    required this.nickname,
    this.projectDescription = '',
    this.context = '',
    this.questionToAsk = '',
    this.timerStartedAt,
    this.timerDurationHours = 5,
    this.isActive = true,
    List<SessionNote>? sessionNotes,
  }) : sessionNotes = sessionNotes ?? [];

  bool get isTimerRunning => timerStartedAt != null && !isReady;

  bool get isReady {
    if (timerStartedAt == null) return true;
    final elapsed = DateTime.now().difference(timerStartedAt!);
    return elapsed.inHours >= timerDurationHours;
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
    'timerStartedAt': timerStartedAt?.toIso8601String(),
    'timerDurationHours': timerDurationHours,
    'isActive': isActive,
    'sessionNotes': sessionNotes.map((n) => n.toJson()).toList(),
  };

  factory ClaudeAccount.fromJson(Map<String, dynamic> j) => ClaudeAccount(
    id: j['id'] ?? '',
    nickname: j['nickname'] ?? '',
    projectDescription: j['projectDescription'] ?? '',
    context: j['context'] ?? '',
    questionToAsk: j['questionToAsk'] ?? '',
    timerStartedAt: j['timerStartedAt'] != null
        ? DateTime.parse(j['timerStartedAt'])
        : null,
    timerDurationHours: j['timerDurationHours'] ?? 5,
    isActive: j['isActive'] ?? true,
    sessionNotes: (j['sessionNotes'] as List? ?? [])
        .map((n) => SessionNote.fromJson(n))
        .toList(),
  );
}

class SessionNote {
  final String id;
  final String note;
  final DateTime createdAt;

  SessionNote({required this.id, required this.note, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'id': id,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SessionNote.fromJson(Map<String, dynamic> j) => SessionNote(
    id: j['id'] ?? '',
    note: j['note'] ?? '',
    createdAt: DateTime.parse(j['createdAt']),
  );
}
