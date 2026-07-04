import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/account.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/timer_service.dart';
import '../widgets/account_card.dart';
import 'account_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ClaudeAccount> _accounts = [];
  // Fix #15 — single shared ticker for all cards
  Timer? _ticker;
  StreamSubscription? _bgSub;

  @override
  void initState() {
    super.initState();
    _load();
    // Fix #15 — one timer drives all card countdowns
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Listen to background service events
    FlutterForegroundTask.initCommunicationPort();
    _bgSub = FlutterForegroundTask.receivePort?.listen(_onBgData);
    // Fix #2 — request notification permission after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().requestPermission(context);
      TimerService().start();
    });
  }

  void _onBgData(Object data) {
    if (!mounted) return;
    final d = Map<String, dynamic>.from(data as Map);
    if (d['event'] == 'sessionReady') {
      _load(); // Refresh UI when background service detects ready session
    }
  }

  Future<void> _load() async {
    final accounts = await StorageService().loadAccounts();
    if (mounted) setState(() => _accounts = accounts);
  }

  Future<void> _startTimer(ClaudeAccount acc) async {
    acc.timerStartedAt = DateTime.now();
    await StorageService().updateAccount(acc);
    // Reset notified flag in background service
    FlutterForegroundTask.sendDataToTask({
      'event': 'resetNotified', 'accountId': acc.id,
    });
    setState(() {});
  }

  Future<void> _stopTimer(ClaudeAccount acc) async {
    acc.timerStartedAt = null;
    await StorageService().updateAccount(acc);
    setState(() {});
  }

  Future<void> _deleteAccount(ClaudeAccount acc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${acc.nickname}"?',
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Color(0xFFFF4444)))),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService().deleteAccount(acc.id);
      _load();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _bgSub?.cancel();
    super.dispose();
  }

  int get _readyCount =>
      _accounts.where((a) => a.isReady && a.timerStartedAt != null).length;
  int get _waitingCount => _accounts.where((a) => a.isTimerRunning).length;

  @override
  Widget build(BuildContext ctx) => WithForegroundTask(
    child: Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'CLAUDE',
                    style: TextStyle(color: Color(0xFF00FF88), fontSize: 22,
                        fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 2)),
                TextSpan(text: 'LINK',
                    style: TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 2)),
              ])),
              const Text('Session Manager',
                  style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1)),
            ]),
            const Spacer(),
            _statBadge('✅', '$_readyCount', const Color(0xFF00FF88)),
            const SizedBox(width: 8),
            _statBadge('⏳', '$_waitingCount', const Color(0xFFFFAA00)),
          ]),
        ),

        // Summary bar
        if (_accounts.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem('TOTAL', '${_accounts.length}', Colors.white),
                  _summaryItem('READY', '$_readyCount', const Color(0xFF00FF88)),
                  _summaryItem('WAITING', '$_waitingCount', const Color(0xFFFFAA00)),
                  _summaryItem('IDLE',
                      '${_accounts.length - _readyCount - _waitingCount}', Colors.grey),
                ]),
          ),

        const SizedBox(height: 12),

        // Account list — Fix #4: ValueKey per account
        Expanded(
          child: _accounts.isEmpty
              ? _emptyState()
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _accounts.length,
            itemBuilder: (_, i) => AccountCard(
              key: ValueKey(_accounts[i].id), // Fix #4
              account: _accounts[i],
              onTap: () => _editAccount(_accounts[i]),
              onStartTimer: () => _startTimer(_accounts[i]),
              onStopTimer: () => _stopTimer(_accounts[i]),
              onDelete: () => _deleteAccount(_accounts[i]),
            ),
          ),
        ),
      ])),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAccount,
        backgroundColor: const Color(0xFF00FF88),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('ADD ACCOUNT',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ),
    ),
  );

  Widget _statBadge(String emoji, String count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text('$emoji $count',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
  );

  Widget _summaryItem(String label, String value, Color color) =>
      Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 20,
            fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 9, letterSpacing: 1)),
      ]);

  Widget _emptyState() =>
      Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🤖', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text('No accounts yet',
            style: TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Tap + to add your first Claude account',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _addAccount,
          icon: const Icon(Icons.add),
          label: const Text('ADD FIRST ACCOUNT'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FF88),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ]));

  Future<void> _addAccount() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AccountFormScreen()));
    _load();
  }

  Future<void> _editAccount(ClaudeAccount acc) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => AccountFormScreen(account: acc)));
    _load();
  }
}
