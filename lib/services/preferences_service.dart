import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _userNameKey = 'user_name';
  static const _darkModeKey = 'is_dark_mode';

  Future<String> getUserName() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_userNameKey) ?? '';
  }

  Future<void> saveUserName(String name) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userNameKey, name.trim());
  }

  Future<bool> getDarkMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_darkModeKey) ?? false;
  }

  Future<void> saveDarkMode(bool isDarkMode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_darkModeKey, isDarkMode);
  }
}
