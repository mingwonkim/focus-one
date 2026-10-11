// lib/services/mobile_sound_service.dart
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// 폰 집중 소리. 화면이 꺼져도 계속(iOS 백그라운드 오디오 + 재생 세션),
/// 반복 이음새 없이(just_audio LoopMode.one). 데스크탑은 AmbientSoundService(audioplayers) 그대로.
class MobileSoundService {
  final _player = AudioPlayer();
  String? _asset;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      // 다른 음악과 섞어 들을 수 있게 (집중 소리는 배경음)
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
    ));
    await _player.setLoopMode(LoopMode.one);
  }

  Future<void> setVolume(double v) => _player.setVolume(v);

  Future<void> play(String asset) async {
    if (_asset != asset) {
      _asset = asset;
      await _player.setAsset('assets/$asset');
    }
    if (!_player.playing) _player.play(); // play()는 멈출 때 끝나므로 기다리지 않는다
  }

  Future<void> stop() async {
    if (_player.playing) await _player.pause();
  }

  void dispose() => _player.dispose();
}
