import 'package:flutter/material.dart';

import '../game/privacy_web_page.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../widgets/design_stage.dart';
import 'game_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late bool _agreed;
  late bool _shown;
  bool _startAfterAgree = false;

  @override
  void initState() {
    super.initState();
    final s = SettingsService.instance;
    _shown = s.privacyShown;
    _agreed = true;
    SettingsService.instance.setPrivacyAgreed(true);
  }

  Future<void> _onStart() async {
    await SoundService.instance.playButton();
    if (!_agreed) {
      _startAfterAgree = true;
      await _openPrivacy();
      return;
    }
    await _enterGame();
  }

  Future<void> _onCheck() async {
    if (!_shown) {
      _startAfterAgree = false;
      await _openPrivacy();
      return;
    }
    setState(() => _agreed = !_agreed);
    await SettingsService.instance.setPrivacyAgreed(_agreed);
  }

  Future<void> _openPrivacy() async {
    setState(() => _shown = true);
    await SettingsService.instance.setPrivacyShown(true);
    if (!mounted) return;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PrivacyWebPage()),
    );
    if (result == 'agree') {
      await _agree();
    } else {
      _startAfterAgree = false;
    }
  }

  Future<void> _agree() async {
    setState(() => _agreed = true);
    await SettingsService.instance.setPrivacyAgreed(true);
    final shouldStart = _startAfterAgree;
    _startAfterAgree = false;
    if (shouldStart) await _enterGame();
  }

  Future<void> _enterGame() async {
    await SettingsService.instance.applyOnEnterGame();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A120C),
      body: DesignStage(
        backgroundAsset: 'assets/images/LodingBG.png',
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                const Spacer(flex: 5),
                GestureDetector(
                  onTap: _onStart,
                  child: Image.asset('assets/images/Start_01.png', width: 280),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _onCheck,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          _agreed
                              ? 'assets/images/check.png'
                              : 'assets/images/uncheck.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _openPrivacy,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
