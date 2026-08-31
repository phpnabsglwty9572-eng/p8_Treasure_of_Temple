import 'package:shared_preferences/shared_preferences.dart';

import 'sound_service.dart';

const _flag = 'P7_';
const kPrivacyShown = '${_flag}privacy_shown';
const kPrivacyAgreed = '${_flag}privacy_agreed';

/// Mirrors Cocos CommonMgr.isTest — when true, skip gated WebView bootstrap.
class AppConfig {
  static const bool isTest = true;
}

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  bool privacyShown = false;
  bool privacyAgreed = true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    privacyShown = prefs.getString(kPrivacyShown) == '1';
    privacyAgreed = true;
  }

  Future<void> setPrivacyShown(bool v) async {
    privacyShown = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrivacyShown, v ? '1' : '0');
  }

  Future<void> setPrivacyAgreed(bool v) async {
    privacyAgreed = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrivacyAgreed, v ? '1' : '0');
  }

  Future<void> applyOnEnterGame() async {
    final sm = SoundService.instance;
    await sm.init();
    await sm.setMusicEnabled(sm.musicEnabled);
    await sm.setSfxEnabled(sm.sfxEnabled);
    if (sm.musicEnabled) {
      await sm.playBgm();
    }
  }
}
