import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_logger.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  List<LogEntry> _entries = [];
  bool _loading = true;

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

  Future<void> _copyAll() async {
    final text = _entries
        .map((e) => '[${e.time.toIso8601String()}] ${e.level.toUpperCase()}: ${e.message}')
        .join('\n\n');
    await Clipboard.setData(ClipboardData(text: text.isEmpty ? 'No log entries.' : text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log copied to clipboard')),
    );
  }

  Future<void> _clear() async {
    await AppLogger().clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DEBUG LOG'),
        actions: [
          IconButton(icon: const Icon(Icons.copy), onPressed: _copyAll, tooltip: 'Copy all'),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clear, tooltip: 'Clear'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Refresh'),
        ],
      ),
      body: _loading
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
                            '${e.time.toString().substring(0, 19)}  •  ${e.level.toUpperCase()}',
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
    );
  }
}
