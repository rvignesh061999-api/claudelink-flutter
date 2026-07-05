import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/saved_chat_link.dart';
import '../services/storage_service.dart';
import 'chat_links_screen.dart';

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

  // A stable draft with a real UUID from the moment the form opens (even
  // for a brand-new account) — this lets saved chat links be associated
  // with this account right away, without needing to save the account first.
  late ClaudeAccount _draft;
  List<SavedChatLink> _savedLinks = [];
  bool _loadingLinks = true;

  @override
  void initState() {
    super.initState();
    _draft = widget.account ?? ClaudeAccount(nickname: '');
    _nickname.text = _draft.nickname;
    _project.text = _draft.projectDescription;
    _context.text = _draft.context;
    _question.text = _draft.questionToAsk;
    _chatUrl.text = _draft.chatUrl;
    _timerHours = _draft.timerDurationHours;
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    final links = await StorageService().chatLinksForAccount(_draft.id);
    if (!mounted) return;
    setState(() {
      _savedLinks = links;
      _loadingLinks = false;
    });
  }

  Future<void> _openLinkManager() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatLinksScreen(preselectedAccountId: _draft.id)),
    );
    await _loadLinks();
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

    _draft.nickname = _nickname.text.trim();
    _draft.projectDescription = _project.text.trim();
    _draft.context = _context.text.trim();
    _draft.questionToAsk = _question.text.trim();
    _draft.chatUrl = _chatUrl.text.trim();
    _draft.timerDurationHours = _timerHours;

    if (_isEdit) {
      await StorageService().updateAccount(_draft);
    } else {
      await StorageService().addAccount(_draft);
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
        if (!_loadingLinks && _savedLinks.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(8)),
            child: DropdownButton<String>(
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: const Color(0xFF1A1A1A),
              hint: const Text('Choose a saved link...', style: TextStyle(color: Colors.grey)),
              value: _savedLinks.any((l) => l.url == _chatUrl.text) ? _chatUrl.text : null,
              items: _savedLinks
                  .map((l) => DropdownMenuItem(
                        value: l.url,
                        child: Text(l.alias, style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _chatUrl.text = v ?? ''),
            ),
          ),
          const SizedBox(height: 8),
        ],
        _field(_chatUrl,
            'Paste a specific conversation link, e.g. https://claude.ai/chat/xxxxxxxx-xxxx...',
            maxLines: 2),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openLinkManager,
            icon: const Icon(Icons.link, size: 16),
            label: const Text('Manage Saved Links', style: TextStyle(fontSize: 12)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Save frequently-used conversation links with an alias so you don\'t '
            'have to paste the URL every time. If left blank, Open Claude will '
            'just take you to claude.ai directly.',
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
