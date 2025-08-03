import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';
  
  late SharedPreferences _prefs;
  Map<String, dynamic> _settings = {};

  /// Initialize the settings service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    final settingsJson = _prefs.getString(_settingsKey);
    if (settingsJson != null) {
      _settings = Map<String, dynamic>.from(jsonDecode(settingsJson));
    } else {
      _settings = <String, dynamic>{};
      await _saveSettings();
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    final settingsJson = jsonEncode(_settings);
    await _prefs.setString(_settingsKey, settingsJson);
  }

  /// Get a setting value
  T getSetting<T>(String key, T defaultValue) {
    return _settings[key] as T? ?? defaultValue;
  }

  /// Set a setting value
  Future<void> setSetting<T>(String key, T value) async {
    _settings[key] = value;
    await _saveSettings();
  }

  /// Get all settings
  Map<String, dynamic> getAllSettings() {
    return Map<String, dynamic>.from(_settings);
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    _settings = <String, dynamic>{};
    await _saveSettings();
  }


  /// Update multiple settings at once
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    for (final entry in newSettings.entries) {
      _settings[entry.key] = entry.value;
    }
    await _saveSettings();
  }


  /// Export settings as JSON
  String exportSettings() {
    return jsonEncode(_settings);
  }

  /// Import settings from JSON
  Future<void> importSettings(String settingsJson) async {
    try {
      final importedSettings = Map<String, dynamic>.from(jsonDecode(settingsJson));
      _settings = importedSettings;
      await _saveSettings();
    } catch (e) {
      throw ArgumentError('Failed to import settings: $e');
    }
  }

  /// Get settings for display in UI
  List<SettingItem> getSettingsForDisplay() {
    return [];
  }

  SettingType _getSettingType(dynamic value) {
    if (value is bool) return SettingType.boolean;
    if (value is double) return SettingType.slider;
    if (value is int) return SettingType.number;
    if (value is String) return SettingType.text;
    return SettingType.text;
  }
}

enum SettingType {
  boolean,
  slider,
  number,
  text,
}

class SettingItem {
  final String key;
  final String displayName;
  final String description;
  final String category;
  final dynamic value;
  final SettingType type;

  const SettingItem({
    required this.key,
    required this.displayName,
    required this.description,
    required this.category,
    required this.value,
    required this.type,
  });
}