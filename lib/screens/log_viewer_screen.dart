import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import '../services/app_logger.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  List<LogEntry> _entries = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AppLogger().refresh();
    if (!mounted) return;
    setState(() {
      _entries = AppLogger().entries;
      _loading = false;
    });
  }

  String _asText() {
    final text = _entries
        .map((e) => '[${e.time.toIso8601String()}] ${e.level.toUpperCase()}: ${e.message}')
        .join('\n\n');
    return text.isEmpty ? 'No log entries.' : text;
  }

  Future<Uint8List> _buildPdfBytes() async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('ClaudeLink Debug Log',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(DateTime.now().toIso8601String(),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),
          pw.Text(_asText(), style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _asText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log copied to clipboard')),
    );
  }

  Future<void> _clear() async {
    await AppLogger().clear();
    await _load();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e, st) {
      await AppLogger().logError('$label failed', e, st);
      _showMessage('$label failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --- SAVE (real "download" â€” opens Android's native Save dialog) ---

  Future<void> _saveTxt() => _run('Save TXT', () async {
        final stamp = DateTime.now().millisecondsSinceEpoch;
        await FileSaver.instance.saveAs(
          name: 'claudelink_log_$stamp',
          bytes: Uint8List.fromList(utf8.encode(_asText())),
          ext: 'txt',
          mimeType: MimeType.text,
        );
        _showMessage('Saved');
      });

  Future<void> _savePdf() => _run('Save PDF', () async {
        final stamp = DateTime.now().millisecondsSinceEpoch;
        await FileSaver.instance.saveAs(
          name: 'claudelink_log_$stamp',
          bytes: await _buildPdfBytes(),
          ext: 'pdf',
          mimeType: MimeType.pdf,
        );
        _showMessage('Saved');
      });

  // --- SHARE (send via another app) ---

  Future<void> _shareTxt() => _run('Share TXT', () async {
        final dir = await getTemporaryDirectory();
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${dir.path}/claudelink_log_$stamp.txt');
        await file.writeAsString(_asText());
        await Share.shareXFiles([XFile(file.path)], text: 'ClaudeLink debug log');
      });

  Future<void> _sharePdf() => _run('Share PDF', () async {
        final dir = await getTemporaryDirectory();
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${dir.path}/claudelink_log_$stamp.pdf');
        await file.writeAsBytes(await _buildPdfBytes());
        await Share.shareXFiles([XFile(file.path)], text: 'ClaudeLink debug log (PDF)');
      });

  Future<void> _tryOpen(Uri uri, String label) => _run(label, () async {
        bool openedInApp = false;
        try {
          openedInApp = await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
        } catch (_) {
          openedInApp = false;
        }
        if (!openedInApp) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        _showMessage(openedInApp ? 'Opened in app' : 'Opened in browser (no app claimed it)');
      });

  Future<void> _testNewChatQuery() => _tryOpen(
        Uri.parse('https://claude.ai/new').replace(queryParameters: {'q': 'TEST MESSAGE from ClaudeLink'}),
        'Test: /new with query param',
      );

  Future<void> _testLastChat() => _tryOpen(
        Uri.parse('https://claude.ai'),
        'Test: root URL (last chat)',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DEBUG LOG'),
        actions: [
          IconButton(icon: const Icon(Icons.copy), onPressed: _copyAll, tooltip: 'Copy all'),
          PopupMenuButton<String>(
            icon: _busy
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            tooltip: 'Save / Share',
            onSelected: (v) {
              switch (v) {
                case 'save_txt': _saveTxt(); break;
                case 'save_pdf': _savePdf(); break;
                case 'share_txt': _shareTxt(); break;
                case 'share_pdf': _sharePdf(); break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'save_txt', child: Text('Save as TXT')),
              PopupMenuItem(value: 'save_pdf', child: Text('Save as PDF')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'share_txt', child: Text('Share as TXT')),
              PopupMenuItem(value: 'share_pdf', child: Text('Share as PDF')),
            ],
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clear, tooltip: 'Clear'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Refresh'),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _testNewChatQuery,
                    child: const Text('Test: /new + query', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _testLastChat,
                    child: const Text('Test: last chat (root)', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? const Center(
                        child: Text('No errors logged yet.', style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _entries.length,
                        itemBuilder: (_, i) {
                          final e = _entries[i];
                          final isError = e.level == 'error';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isError ? Colors.redAccent.withOpacity(0.5) : Colors.white12,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${e.time.toString().substring(0, 19)}  â€¢  ${e.level.toUpperCase()}',
                                  style: TextStyle(
                                    color: isError ? Colors.redAccent : Colors.greenAccent,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  e.message,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}