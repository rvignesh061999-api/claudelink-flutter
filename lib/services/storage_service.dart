import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/saved_chat_link.dart';
import 'app_logger.dart';

class StorageService {
  static final StorageService _i = StorageService._();
  factory StorageService() => _i;
  StorageService._();

  static const _key = 'claude_accounts';
  SharedPreferences? _prefs;

  // Fix #3 — single SharedPreferences instance (no race condition)
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Fix #7 — null guard + try/catch on JSON parse
  Future<List<ClaudeAccount>> loadAccounts() async {
    try {
      final prefs = await _p;
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      final accounts = <ClaudeAccount>[];
      for (final j in list) {
        try {
          accounts.add(ClaudeAccount.fromJson(Map<String, dynamic>.from(j)));
        } catch (e, st) {
          debugPrint('Skipping corrupt account entry: $e');
          AppLogger().logError('Skipping corrupt account entry', e, st);
        }
      }
      return accounts;
    } catch (e, st) {
      debugPrint('loadAccounts failed: $e');
      AppLogger().logError('loadAccounts failed', e, st);
      return [];
    }
  }

  Future<void> saveAccounts(List<ClaudeAccount> accounts) async {
    final prefs = await _p;
    await prefs.setString(_key, jsonEncode(
      accounts.map((a) => a.toJson()).toList(),
    ));
  }

  Future<void> addAccount(ClaudeAccount account) async {
    final accounts = await loadAccounts();
    accounts.add(account);
    await saveAccounts(accounts);
  }

  Future<void> updateAccount(ClaudeAccount account) async {
    final accounts = await loadAccounts();
    final idx = accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) accounts[idx] = account;
    await saveAccounts(accounts);
  }

  Future<void> deleteAccount(String id) async {
    final accounts = await loadAccounts();
    accounts.removeWhere((a) => a.id == id);
    await saveAccounts(accounts);
  }

  // --- Saved Chat Links (master library, aliased, per-account) ---

  static const _linksKey = 'saved_chat_links';

  Future<List<SavedChatLink>> loadChatLinks() async {
    try {
      final prefs = await _p;
      final raw = prefs.getString(_linksKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      final links = <SavedChatLink>[];
      for (final j in list) {
        try {
          links.add(SavedChatLink.fromJson(Map<String, dynamic>.from(j)));
        } catch (e, st) {
          await AppLogger().logError('Skipping corrupt chat link entry', e, st);
        }
      }
      return links;
    } catch (e, st) {
      await AppLogger().logError('loadChatLinks failed', e, st);
      return [];
    }
  }

  Future<void> saveChatLinks(List<SavedChatLink> links) async {
    final prefs = await _p;
    await prefs.setString(_linksKey, jsonEncode(
      links.map((l) => l.toJson()).toList(),
    ));
  }

  Future<void> addChatLink(SavedChatLink link) async {
    final links = await loadChatLinks();
    links.add(link);
    await saveChatLinks(links);
  }

  Future<void> updateChatLink(SavedChatLink link) async {
    final links = await loadChatLinks();
    final idx = links.indexWhere((l) => l.id == link.id);
    if (idx != -1) links[idx] = link;
    await saveChatLinks(links);
  }

  Future<void> deleteChatLink(String id) async {
    final links = await loadChatLinks();
    links.removeWhere((l) => l.id == id);
    await saveChatLinks(links);
  }

  Future<List<SavedChatLink>> chatLinksForAccount(String accountId) async {
    final links = await loadChatLinks();
    return links.where((l) => l.accountId == accountId).toList();
  }
}
