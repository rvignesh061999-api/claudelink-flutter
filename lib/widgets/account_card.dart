import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/account.dart';

class AccountCard extends StatefulWidget {
  final ClaudeAccount account;
  final VoidCallback onTap;
  final VoidCallback onStartTimer;
  final VoidCallback onStopTimer;
  final VoidCallback onDelete;

  const AccountCard({
    super.key,
    required this.account,
    required this.onTap,
    required this.onStartTimer,
    required this.onStopTimer,
    required this.onDelete,
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.account.status) {
      case 'READY': return const Color(0xFF00FF88);
      case 'WAITING': return const Color(0xFFFFAA00);
      default: return Colors.grey;
    }
  }

  String get _timerDisplay {
    final rem = widget.account.timeRemaining;
    final h = rem.inHours.toString().padLeft(2, '0');
    final m = (rem.inMinutes % 60).toString().padLeft(2, '0');
    final s = (rem.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _buildCopyText() {
    final parts = <String>[];
    if (widget.account.context.isNotEmpty) parts.add(widget.account.context);
    if (widget.account.questionToAsk.isNotEmpty) parts.add('\n${widget.account.questionToAsk}');
    return parts.join('\n');
  }

  void _copyContext() {
    Clipboard.setData(ClipboardData(text: _buildCopyText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Context copied to clipboard!'),
        backgroundColor: Color(0xFF00FF88),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openInBrowser() async {
    _copyContext();
    await Future.delayed(const Duration(milliseconds: 300));
    final uri = Uri.parse('https://claude.ai/new');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInApp() async {
    _copyContext();
    Navigator.pushNamed(context, '/webview', arguments: widget.account);
  }

  @override
  Widget build(BuildContext ctx) {
    final acc = widget.account;
    final c = _statusColor;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.4), width: 1.5),
        ),
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(acc.nickname, style: TextStyle(color: c, fontSize: 16,
                    fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                if (acc.projectDescription.isNotEmpty)
                  Text(acc.projectDescription,
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ])),
              // Delete button
              GestureDetector(
                onTap: widget.onDelete,
                child: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.withOpacity(0.5)),
                ),
                child: Text(acc.status, style: TextStyle(color: c, fontSize: 11,
                    fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ),
            ]),
          ),

          // Timer display
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Text(
                acc.isReady ? 'READY TO CONTINUE' : _timerDisplay,
                style: TextStyle(
                  color: c,
                  fontSize: acc.isReady ? 20 : 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                ),
              ),
              if (!acc.isReady)
                Text('remaining', style: TextStyle(color: c.withOpacity(0.6), fontSize: 11, letterSpacing: 2)),
              if (acc.questionToAsk.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '"${acc.questionToAsk}"',
                    style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                    maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  ),
                ),
              ],
            ]),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(children: [
              Row(children: [
                Expanded(child: _btn('🔲 In App', const Color(0xFF4499FF), _openInApp)),
                const SizedBox(width: 8),
                Expanded(child: _btn('🌐 Chrome', const Color(0xFF00FF88), _openInBrowser)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _btn('📋 Copy Context', const Color(0xFFFFAA00), _copyContext)),
                const SizedBox(width: 8),
                if (!acc.isTimerRunning)
                  Expanded(child: _btn('⏱ Start Timer', Colors.white, widget.onStartTimer))
                else
                  Expanded(child: _btn('⏹ Stop Timer', const Color(0xFFFF4444), widget.onStopTimer)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    ),
  );
}
