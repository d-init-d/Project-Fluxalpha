import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService extends ChangeNotifier {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  SharedPreferences? _prefs;

  // User profile fields
  String _name = 'User';
  String _email = '';
  String _avatarUrl = 'https://api.dicebear.com/7.x/avataaars/svg?seed=User';

  // Getters
  String get name => _name;
  String get email => _email;
  String get avatarUrl => _avatarUrl;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_prefs == null) return;

    final profileJson = _prefs!.getString('user_profile');
    if (profileJson != null) {
      try {
        final Map<String, dynamic> profile = jsonDecode(profileJson);
        _name = profile['name'] ?? 'User';
        _email = profile['email'] ?? '';
        _avatarUrl =
            profile['avatarUrl'] ??
            'https://api.dicebear.com/7.x/avataaars/svg?seed=User';
      } catch (e) {
        // If there's an error parsing, use defaults
        _name = 'User';
        _email = '';
        _avatarUrl = 'https://api.dicebear.com/7.x/avataaars/svg?seed=User';
      }
    }

    notifyListeners();
  }

  Future<void> _saveProfile() async {
    if (_prefs == null) return;

    final Map<String, dynamic> profile = {
      'name': _name,
      'email': _email,
      'avatarUrl': _avatarUrl,
    };

    await _prefs!.setString('user_profile', jsonEncode(profile));
  }

  // Setters with persistence
  Future<void> setName(String name) async {
    _name = name;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> setEmail(String email) async {
    _email = email;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> setAvatarUrl(String avatarUrl) async {
    _avatarUrl = avatarUrl;
    await _saveProfile();
    notifyListeners();
  }

  // Batch update method for efficiency
  Future<void> updateProfile({
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    bool hasChanges = false;

    if (name != null && name != _name) {
      _name = name;
      hasChanges = true;
    }
    if (email != null && email != _email) {
      _email = email;
      hasChanges = true;
    }
    if (avatarUrl != null && avatarUrl != _avatarUrl) {
      _avatarUrl = avatarUrl;
      hasChanges = true;
    }

    if (hasChanges) {
      await _saveProfile();
      notifyListeners();
    }
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _name = 'User';
    _email = '';
    _avatarUrl = 'https://api.dicebear.com/7.x/avataaars/svg?seed=User';
    await _saveProfile();
    notifyListeners();
  }
}
