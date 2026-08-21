import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _flag = 'P7_';
const _kMusic = '${_flag}sheep_music_enabled';
const _kSfx = '${_flag}sfx_enabled';
const _kMusicVol = '${_flag}music_volume';
const _kSfxVol = '${_flag}sfx_volume';

class SoundService extends ChangeNotifier {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _bgm = AudioPlayer(playerId: 'bgm');
  final AudioPlayer _sfx = AudioPlayer(playerId: 'sfx');

  bool musicEnabled = true;
  bool sfxEnabled = true;
  double musicVolume = 1;
  double sfxVolume = 1;
  bool _ready = false;
  String _bgmPath = 'audio/music_bg.mp3';

  Future<void> init() async {
    if (_ready) return;
    final prefs = await SharedPreferences.getInstance();
    musicEnabled = prefs.getString(_kMusic) != '0';
    sfxEnabled = prefs.getString(_kSfx) != '0';
    musicVolume =
        double.tryParse(prefs.getString(_kMusicVol) ?? '1')?.clamp(0, 1) ?? 1;
    sfxVolume =
        double.tryParse(prefs.getString(_kSfxVol) ?? '1')?.clamp(0, 1) ?? 1;

    // Allow BGM + SFX to play together (Android audio focus / iOS mixWithOthers).
    final mixCtx = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    await AudioPlayer.global.setAudioContext(mixCtx);
    await _bgm.setAudioContext(mixCtx);
    await _sfx.setAudioContext(mixCtx);

    await _bgm.setReleaseMode(ReleaseMode.loop);
    await _bgm.setPlayerMode(PlayerMode.mediaPlayer);
    await _sfx.setPlayerMode(PlayerMode.lowLatency);
    await _bgm.setVolume(musicEnabled ? musicVolume : 0);
    await _sfx.setVolume(sfxEnabled ? sfxVolume : 0);
    _ready = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMusic, musicEnabled ? '1' : '0');
    await prefs.setString(_kSfx, sfxEnabled ? '1' : '0');
    await prefs.setString(_kMusicVol, '$musicVolume');
    await prefs.setString(_kSfxVol, '$sfxVolume');
  }

  Future<void> setMusicEnabled(bool enabled) async {
    await init();
    musicEnabled = enabled;
    if (enabled) {
      await _bgm.setVolume(musicVolume);
      await playBgm(path: _bgmPath);
    } else {
      await _bgm.setVolume(0);
      await _bgm.pause();
    }
    await _save();
    notifyListeners();
  }

  Future<void> setSfxEnabled(bool enabled) async {
    await init();
    sfxEnabled = enabled;
    await _sfx.setVolume(enabled ? sfxVolume : 0);
    if (!enabled) {
      await _sfx.stop();
    }
    // SFX toggle must never stop background music.
    await _ensureBgmPlaying();
    await _save();
    notifyListeners();
  }

  Future<void> playBgm({String path = 'audio/music_bg.mp3'}) async {
    await init();
    _bgmPath = path;
    if (!musicEnabled) return;
    try {
      final src = _assetPath(path);
      // Avoid restarting if already playing the same track.
      if (_bgm.state == PlayerState.playing) {
        await _bgm.setVolume(musicVolume);
        return;
      }
      if (_bgm.state == PlayerState.paused) {
        await _bgm.resume();
        await _bgm.setVolume(musicVolume);
        return;
      }
      await _bgm.play(AssetSource(src));
      await _bgm.setVolume(musicVolume);
    } catch (e) {
      debugPrint('playBgm failed: $e');
    }
  }

  Future<void> playSfx(String name) async {
    await init();
    if (!sfxEnabled) return;
    final file = name.contains('/') ? name : 'audio/$name.mp3';
    final asset = file.endsWith('.mp3') ? file : '$file.mp3';
    final src = _assetPath(asset);
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource(src));
      await _sfx.setVolume(sfxVolume);
      // Some Android devices still duck/pause other players; restore BGM.
      await _ensureBgmPlaying();
    } catch (e) {
      debugPrint('playSfx failed: $e');
    }
  }

  Future<void> _ensureBgmPlaying() async {
    if (!musicEnabled) return;
    try {
      if (_bgm.state == PlayerState.playing) {
        await _bgm.setVolume(musicVolume);
        return;
      }
      if (_bgm.state == PlayerState.paused) {
        await _bgm.resume();
        await _bgm.setVolume(musicVolume);
        return;
      }
      await playBgm(path: _bgmPath);
    } catch (e) {
      debugPrint('ensureBgmPlaying failed: $e');
    }
  }

  String _assetPath(String path) {
    return path.startsWith('assets/') ? path.substring(7) : path;
  }

  Future<void> playButton() => playSfx('sound_button');
}
