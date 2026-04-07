// lib/services/vault_manager.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class VaultManager {
  static const _key = 'grade_calculator_vault';

  Future<List<ProcessedFile>> loadVault() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ProcessedFile.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveVault(List<ProcessedFile> files) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(files.map((f) => f.toJson()).toList()));
  }

  Future<void> addFile(ProcessedFile file) async {
    final files = await loadVault();
    files.removeWhere((f) => f.id == file.id);
    files.insert(0, file);
    await saveVault(files);
  }

  Future<void> removeFile(String id) async {
    final files = await loadVault();
    files.removeWhere((f) => f.id == id);
    await saveVault(files);
  }
}
