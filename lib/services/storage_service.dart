import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';

class StorageService {
  static final StorageService _i = StorageService._();
  factory StorageService() => _i;
  StorageService._();

  static const _key = 'claude_accounts';

  Future<List<ClaudeAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((j) => ClaudeAccount.fromJson(j)).toList();
  }

  Future<void> saveAccounts(List<ClaudeAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(accounts.map((a) => a.toJson()).toList()));
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
}
