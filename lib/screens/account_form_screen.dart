import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/storage_service.dart';

class AccountFormScreen extends StatefulWidget {
  final ClaudeAccount? account;
  const AccountFormScreen({super.key, this.account});
  @override State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _nickname = TextEditingController();
  final _project = TextEditingController();
  final _context = TextEditingController();
  final _question = TextEditingController();
  final _chatUrl = TextEditingController();
  int _timerHours = 5;
  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nickname.text = widget.account!.nickname;
      _project.text = widget.account!.projectDescription;
      _context.text = widget.account!.context;
      _question.text = widget.account!.questionToAsk;
      _chatUrl.text = widget.account!.chatUrl;
      _timerHours = widget.account!.timerDurationHours;
    }
  }

  @override
  void dispose() {
    _nickname.dispose();
    _project.dispose();
    _context.dispose();
    _question.dispose();
    _chatUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nickname.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a nickname')),
      );
      return;
    }

    if (_isEdit) {
      widget.account!.nickname = _nickname.text.trim();
      widget.account!.projectDescription = _project.text.trim();
      widget.account!.context = _context.text.trim();
      widget.account!.questionToAsk = _question.text.trim();
      widget.account!.chatUrl = _chatUrl.text.trim();
      widget.account!.timerDurationHours = _timerHours;
      await StorageService().updateAccount(widget.account!);
    } else {
      final acc = ClaudeAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nickname: _nickname.text.trim(),
        projectDescription: _project.text.trim(),
        context: _context.text.trim(),
        questionToAsk: _question.text.trim(),
        chatUrl: _chatUrl.text.trim(),
        timerDurationHours: _timerHours,
      );
      await StorageService().addAccount(acc);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: const Color(0xFF0A0A0A),
    appBar: AppBar(
      title: Text(_isEdit ? 'EDIT ACCOUNT' : 'ADD ACCOUNT'),
      actions: [TextButton(
        onPressed: _save,
        child: const Text('SAVE', style: TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      )],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('ACCOUNT NICKNAME *'),
        _field(_nickname, 'e.g. Flutter Dev, Trade Log, Research'),
        const SizedBox(height: 16),

        _label('PROJECT DESCRIPTION'),
        _field(_project, 'e.g. Building StockSense Flutter APK'),
        const SizedBox(height: 16),

        _label('CONTEXT TO PASTE'),
        _field(_context, 'Paste your full Claude context here...\n\nThis will be copied to clipboard when you open Claude.', maxLines: 8),
        const SizedBox(height: 16),

        _label('QUESTION TO ASK'),
        _field(_question, 'e.g. Is the APK ready? Continue from Day 22...'),
        const SizedBox(height: 16),

        _label('SPECIFIC CHAT URL (OPTIONAL)'),
        _field(_chatUrl,
            'Paste a specific conversation link, e.g. https://claude.ai/chat/xxxxxxxx-xxxx...',
            maxLines: 2),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'To get this: open the exact Claude conversation you want to resume, '
            'copy its URL from your browser\'s address bar, and paste it here. '
            'If left blank, Open Claude will just take you to claude.ai directly.',
            style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 11),
          ),
        ),
        const SizedBox(height: 16),

        _label('TIMER DURATION'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Wait Duration', style: TextStyle(color: Colors.white, fontSize: 14)),
              Text('How long until Claude resets', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ])),
            DropdownButton<int>(
              value: _timerHours,
              dropdownColor: const Color(0xFF111111),
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              items: [3, 4, 5, 6, 8].map((h) => DropdownMenuItem(
                value: h, child: Text('$h hours'),
              )).toList(),
              onChanged: (v) => setState(() => _timerHours = v!),
            ),
          ]),
        ),
        const SizedBox(height: 32),

        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FF88),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(_isEdit ? 'UPDATE ACCOUNT' : 'ADD ACCOUNT',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace')),
        )),
      ]),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 2)),
  );

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1}) => Container(
    decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(8)),
    child: TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 13),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(14),
      ),
    ),
  );
}
