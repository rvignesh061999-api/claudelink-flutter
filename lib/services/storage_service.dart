import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';

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
        } catch (e) {
          debugPrint('Skipping corrupt account entry: $e');
        }
      }
      return accounts;
    } catch (e) {
      debugPrint('loadAccounts failed: $e');
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
}