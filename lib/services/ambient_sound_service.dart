// lib/services/ambient_sound_service.dart
import 'package:audioplayers/audioplayers.dart';

import '../core/design_tokens.dart';

/// 집중 중에만 현재 장면(숲/밤/바다)의 앰비언트 사운드를 루프 재생한다.
/// 일시정지·휴식·대기 상태에서는 조용히.
class AmbientSoundService {
  final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.loop);

  String? _playing; // 재생 중인 애셋 경로
  double _volume = 0.6;

  Future<void> setVolume(double volume) async {
    if (_volume == volume) return;
    _volume = volume;
    if (_playing != null) await _player.setVolume(volume);
  }

  Future<void> play(FocusScene scene) => playAsset(scene.soundAsset);

  /// 폰: 장면 소리 외 빗소리·백색·갈색소음
  Future<void> playAsset(String asset) async {
    if (_playing == asset) return;
    _playing = asset;
    await _player.stop();
    await _player.play(AssetSource(asset), volume: _volume);
  }

  Future<void> stop() async {
    if (_playing == null) return;
    _playing = null;
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
