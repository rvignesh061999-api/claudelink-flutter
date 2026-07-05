import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/account.dart';
import '../services/app_logger.dart';

// Fix #15 â€” No internal Timer â€” parent HomeScreen drives rebuilds via single ticker
class AccountCard extends StatelessWidget {
  final ClaudeAccount account;
  final VoidCallback onTap;
  final VoidCallback onStartTimer;
  final VoidCallback onStopTimer;
  final VoidCallback onDelete;

  const AccountCard({
    super.key, // Fix #4 â€” key passed from parent (ValueKey)
    required this.account,
    required this.onTap,
    required this.onStartTimer,
    required this.onStopTimer,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (account.status) {
      case 'READY': return const Color(0xFF00FF88);
      case 'WAITING': return const Color(0xFFFFAA00);
      default: return Colors.grey;
    }
  }

  String get _timerDisplay {
    final rem = account.timeRemaining;
    final h = rem.inHours.toString().padLeft(2, '0');
    final m = (rem.inMinutes % 60).toString().padLeft(2, '0');
    final s = (rem.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _buildCopyText() {
    final parts = <String>[];
    if (account.context.isNotEmpty) parts.add(account.context);
    if (account.questionToAsk.isNotEmpty) parts.add('\n${account.questionToAsk}');
    return parts.join('\n');
  }

  void _copyContext(BuildContext ctx) {
    Clipboard.setData(ClipboardData(text: _buildCopyText()));
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
      content: Text('\u{1F4CB} Context copied to clipboard!'),
      backgroundColor: Color(0xFF00FF88),
      duration: Duration(seconds: 2),
    ));
  }

  // Fix #14 â€” mounted check after every async gap
  Future<void> _openInBrowser(BuildContext ctx) async {
    _copyContext(ctx);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!ctx.mounted) return; // Fix #14

    final textToPaste = _buildCopyText();
    Uri uri;
    if (textToPaste.trim().isNotEmpty) {
      // Experiment: try pre-filling Claude's input via a query param.
      // Not officially documented by Anthropic â€” if unsupported, Claude
      // just opens /new normally with an empty input (same as before).
      uri = Uri.parse('https://claude.ai/new').replace(
        queryParameters: {'q': textToPaste},
      );
      await AppLogger().log('Trying pre-fill via query param on /new');
    } else {
      // Experiment: nothing to paste, so try the root URL instead of
      // forcing /new â€” hoping this lands on the most recent chat rather
      // than always starting a blank new one. Not guaranteed by Anthropic.
      uri = Uri.parse('https://claude.ai');
      await AppLogger().log('No context to paste â€” trying root URL for last chat');
    }

    // Try the Claude app directly first (only works if Anthropic has
    // registered Android App Links for claude.ai). If no non-browser
    // app claims this link, this call returns false without side effects.
    bool openedInApp = false;
    try {
      openedInApp = await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      await AppLogger().log(
        openedInApp
            ? 'Opened claude.ai directly in a non-browser app'
            : 'No non-browser app claimed claude.ai â€” falling back to browser',
      );
    } catch (e, st) {
      openedInApp = false;
      await AppLogger().logError('externalNonBrowserApplication launch threw', e, st);
    }

    if (!openedInApp) {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await AppLogger().logError(
            'Open Claude failed', 'launchUrl returned false for browser fallback',
          );
        }
      } else {
        await AppLogger().logError(
          'Open Claude failed', 'canLaunchUrl returned false â€” no browser detected',
        );
      }
    }
  }

  void _openInApp(BuildContext ctx) {
    _copyContext(ctx);
    Navigator.pushNamed(ctx, '/webview', arguments: account);
  }

  @override
  Widget build(BuildContext ctx) {
    final c = _statusColor;
    return GestureDetector(
      onTap: onTap,
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
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.nickname, style: TextStyle(color: c, fontSize: 16,
                        fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    if (account.projectDescription.isNotEmpty)
                      Text(account.projectDescription,
                          style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ])),
              GestureDetector(
                onTap: onDelete,
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
                child: Text(account.status, style: TextStyle(color: c, fontSize: 11,
                    fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ),
            ]),
          ),

          // Timer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Text(
                account.isReady ? 'READY TO CONTINUE' : _timerDisplay,
                style: TextStyle(color: c,
                    fontSize: account.isReady ? 20 : 40,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace', letterSpacing: 3),
              ),
              if (!account.isReady)
                Text('remaining',
                    style: TextStyle(color: c.withOpacity(0.6),
                        fontSize: 11, letterSpacing: 2)),
              if (account.questionToAsk.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('"${account.questionToAsk}"',
                    style: const TextStyle(color: Colors.grey, fontSize: 11,
                        fontStyle: FontStyle.italic),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center),
                ),
              ],
            ]),
          ),

          // Buttons â€” Fix #5: removed fake "In App", kept Chrome + copy
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(children: [
              Row(children: [
                Expanded(child: _btn(ctx, '\u{1F310} Open Claude', const Color(0xFF00FF88),
                    () => _openInBrowser(ctx))),
                const SizedBox(width: 8),
                Expanded(child: _btn(ctx, '\u{1F4CB} Copy Context', const Color(0xFFFFAA00),
                    () => _copyContext(ctx))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                if (!account.isTimerRunning)
                  Expanded(child: _btn(ctx, '\u23F1 Start Timer', Colors.white, onStartTimer))
                else
                  Expanded(child: _btn(ctx, '\u23F9 Stop Timer', const Color(0xFFFF4444),
                      onStopTimer)),
                const SizedBox(width: 8),
                Expanded(child: _btn(ctx, '\u270F\uFE0F Edit', Colors.grey, onTap)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _btn(BuildContext ctx, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      );
}