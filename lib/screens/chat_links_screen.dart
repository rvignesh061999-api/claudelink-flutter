import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/saved_chat_link.dart';
import '../services/storage_service.dart';
import '../services/app_logger.dart';

class ChatLinksScreen extends StatefulWidget {
  final String? preselectedAccountId;
  const ChatLinksScreen({super.key, this.preselectedAccountId});

  @override
  State<ChatLinksScreen> createState() => _ChatLinksScreenState();
}

class _ChatLinksScreenState extends State<ChatLinksScreen> {
  List<ClaudeAccount> _accounts = [];
  List<SavedChatLink> _links = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await StorageService().loadAccounts();
    final links = await StorageService().loadChatLinks();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _links = links;
      _loading = false;
    });
  }

  String _accountName(String accountId) {
    final match = _accounts.where((a) => a.id == accountId);
    return match.isEmpty ? '(deleted account)' : match.first.nickname;
  }

  Future<void> _showLinkDialog({SavedChatLink? existing}) async {
    final aliasCtrl = TextEditingController(text: existing?.alias ?? '');
    final urlCtrl = TextEditingController(text: existing?.url ?? '');
    String? selectedAccountId = existing?.accountId ?? widget.preselectedAccountId
        ?? (_accounts.isNotEmpty ? _accounts.first.id : null);

    if (_accounts.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text('No accounts yet', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Add a Claude account first before saving chat links for it.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: Text(
            existing == null ? 'Add Chat Link' : 'Edit Chat Link',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ACCOUNT', style: TextStyle(color: Colors.grey, fontSize: 11)),
                DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A1A),
                  value: selectedAccountId,
                  items: _accounts
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.nickname, style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedAccountId = v),
                ),
                const SizedBox(height: 12),
                const Text('ALIAS', style: TextStyle(color: Colors.grey, fontSize: 11)),
                TextField(
                  controller: aliasCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'e.g. Main feature chat'),
                ),
                const SizedBox(height: 12),
                const Text('URL', style: TextStyle(color: Colors.grey, fontSize: 11)),
                TextField(
                  controller: urlCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'https://claude.ai/chat/xxxxx...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (selectedAccountId == null ||
                    aliasCtrl.text.trim().isEmpty ||
                    urlCtrl.text.trim().isEmpty) {
                  return;
                }
                try {
                  if (existing != null) {
                    existing.accountId = selectedAccountId!;
                    existing.alias = aliasCtrl.text.trim();
                    existing.url = urlCtrl.text.trim();
                    await StorageService().updateChatLink(existing);
                  } else {
                    await StorageService().addChatLink(SavedChatLink(
                      accountId: selectedAccountId!,
                      alias: aliasCtrl.text.trim(),
                      url: urlCtrl.text.trim(),
                    ));
                  }
                } catch (e, st) {
                  await AppLogger().logError('Saving chat link failed', e, st);
                }
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                await _load();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(SavedChatLink link) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Delete Link', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${link.alias}"?', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF4444))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService().deleteChatLink(link.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group links by account, preserving account list order.
    final Map<String, List<SavedChatLink>> grouped = {};
    for (final acc in _accounts) {
      grouped[acc.id] = _links.where((l) => l.accountId == acc.id).toList();
    }
    // Links whose account no longer exists (deleted account) — show at the end.
    final orphaned = _links.where((l) => !_accounts.any((a) => a.id == l.accountId)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SAVED CHAT LINKS'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showLinkDialog()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_links.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No saved links yet.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showLinkDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add your first link'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final acc in _accounts)
                      if ((grouped[acc.id] ?? []).isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            acc.nickname.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF00FF88),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        for (final link in grouped[acc.id]!) _linkTile(link),
                      ],
                    if (orphaned.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'OTHER (ACCOUNT DELETED)',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      for (final link in orphaned) _linkTile(link),
                    ],
                  ],
                )),
    );
  }

  Widget _linkTile(SavedChatLink link) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF111111),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(link.alias, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                link.url,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 18, color: Colors.orangeAccent),
          onPressed: () => _showLinkDialog(existing: link),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF4444)),
          onPressed: () => _delete(link),
        ),
      ],
    ),
  );
}
