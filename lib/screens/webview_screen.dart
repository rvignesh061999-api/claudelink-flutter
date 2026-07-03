import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/account.dart';

class WebViewScreen extends StatelessWidget {
  final ClaudeAccount account;
  const WebViewScreen({super.key, required this.account});

  String _buildCopyText() {
    final parts = <String>[];
    if (account.context.isNotEmpty) parts.add(account.context);
    if (account.questionToAsk.isNotEmpty) parts.add('\n${account.questionToAsk}');
    return parts.join('\n');
  }

  Future<void> _openInBrowser(BuildContext ctx) async {
    Clipboard.setData(ClipboardData(text: _buildCopyText()));
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('📋 Context copied! Paste it in Claude.'),
        backgroundColor: Color(0xFF00FF88),
        duration: Duration(seconds: 3),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    final uri = Uri.parse('https://claude.ai/new');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: const Color(0xFF0A0A0A),
    appBar: AppBar(title: Text(account.nickname)),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.open_in_browser, color: Color(0xFF00FF88), size: 80),
        const SizedBox(height: 24),
        Text(account.nickname,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        const SizedBox(height: 8),
        if (account.questionToAsk.isNotEmpty)
          Text('"${account.questionToAsk}"',
            style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => _openInBrowser(ctx),
          icon: const Icon(Icons.launch),
          label: const Text('COPY CONTEXT & OPEN CLAUDE', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FF88),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        )),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _buildCopyText()));
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('📋 Context copied to clipboard!'),
                backgroundColor: Color(0xFF00FF88), duration: Duration(seconds: 2)),
            );
          },
          icon: const Icon(Icons.copy, color: Color(0xFFFFAA00)),
          label: const Text('COPY CONTEXT ONLY', style: TextStyle(color: Color(0xFFFFAA00), fontFamily: 'monospace')),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFFFAA00)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        )),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Colors.grey, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Context is copied to clipboard.\nOpen Claude → New chat → Long press → Paste.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            )),
          ]),
        ),
      ]),
    ),
  );
}
