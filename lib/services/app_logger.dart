import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single log entry: a timestamp, a level (info/error), and a message.
class LogEntry {
  final DateTime time;
  final String level;
  final String message;

  LogEntry({required this.time, required this.level, required this.message});

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'level': level,
    'message': message,
  };

  factory LogEntry.fromJson(Map<String, dynamic> j) => LogEntry(
    time: DateTime.tryParse(j['time'] ?? '') ?? DateTime.now(),
    level: j['level'] ?? 'info',
    message: j['message'] ?? '',
  );
}

/// App-wide logger: use this anywhere — screens, services, future API calls —
/// instead of (or alongside) debugPrint, so failures are visible on the
/// device itself without needing adb/logcat.
///
/// Usage:
///   try {
///     final res = await someApiCall();
///   } catch (e, st) {
///     AppLogger().logError('Fetching stock data failed', e, st);
///   }
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static const _storageKey = 'app_debug_log_v1';
  static const _maxEntries = 300;

  final List<LogEntry> _entries = [];
  List<LogEntry> get entries => List.unmodifiable(_entries.reversed);

  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        _entries.addAll(list);
      }
    } catch (_) {
      // If the log itself can't load, fail silently — logging must never
      // be the thing that crashes the app.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_entries.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (_) {
      // Same — never let logging failures cascade.
    }
  }

  /// Log an informational message.
  Future<void> log(String message) async {
    await _ensureLoaded();
    _entries.add(LogEntry(time: DateTime.now(), level: 'info', message: message));
    if (_entries.length > _maxEntries) _entries.removeAt(0);
    debugPrint('[LOG] $message');
    await _persist();
  }

  /// Log an error, optionally with a stack trace. Use this in every
  /// try/catch across the app — screens, services, future API calls —
  /// so failures are always visible in the in-app log viewer.
  Future<void> logError(String context, Object error, [StackTrace? stack]) async {
    await _ensureLoaded();
    final message = '$context: $error${stack != null ? '\n$stack' : ''}';
    _entries.add(LogEntry(time: DateTime.now(), level: 'error', message: message));
    if (_entries.length > _maxEntries) _entries.removeAt(0);
    debugPrint('[ERROR] $message');
    await _persist();
  }

  Future<void> clear() async {
    _entries.clear();
    await _persist();
  }

  /// Load entries from disk — call this before reading `entries` from a
  /// fresh screen (e.g. the log viewer) to make sure it's up to date.
  Future<void> refresh() async {
    _loaded = false;
    _entries.clear();
    await _ensureLoaded();
  }
}
