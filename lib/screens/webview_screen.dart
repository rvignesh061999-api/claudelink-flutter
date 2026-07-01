import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/account.dart';

class WebViewScreen extends StatefulWidget {
  final ClaudeAccount account;
  const WebViewScreen({super.key, required this.account});
  @override State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _ctrl;
  bool _loading = true;
  bool _pasted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..loadRequest(Uri.parse('https://claude.ai/new'));
  }

  void _copyContext() {
    final parts = <String>[];
    if (widget.account.context.isNotEmpty) parts.add(widget.account.context);
    if (widget.account.questionToAsk.isNotEmpty) parts.add('\n${widget.account.questionToAsk}');
    final text = parts.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _pasted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Context copied! Long press in Claude to paste.'),
        backgroundColor: Color(0xFF00FF88),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: const Color(0xFF0A0A0A),
    appBar: AppBar(
      title: Text(widget.account.nickname, style: const TextStyle(fontFamily: 'monospace')),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _ctrl.reload(),
        ),
      ],
    ),
    body: Stack(children: [
      WebViewWidget(controller: _ctrl),
      if (_loading)
        const Center(child: CircularProgressIndicator(color: Color(0xFF00FF88))),
    ]),
    floatingActionButton: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'paste',
          onPressed: _copyContext,
          backgroundColor: _pasted ? Colors.grey : const Color(0xFF00FF88),
          foregroundColor: Colors.black,
          icon: const Icon(Icons.copy),
          label: Text(_pasted ? 'COPIED ✅' : 'COPY CONTEXT',
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ),
      ],
    ),
  );
}
