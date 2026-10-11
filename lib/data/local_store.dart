// lib/data/local_store.dart
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/design_tokens.dart';
import '../models/blocker_settings.dart';
import '../models/task.dart';

/// JSON 파일 저장소.
/// - 쓰기는 한 줄로 세운다(동시 저장 금지) → 임시 파일에 쓴 뒤 이름 바꾸기(원자적).
/// - 직전 파일은 `.bak`로 남겨, 본 파일이 깨지면 복구본에서 읽는다.
class LocalStore {
  LocalStore([this._file]); // 파일 지정은 테스트용 — 기본은 앱 지원 폴더

  static const _fileName = 'focus_one_data.json';
  File? _file;
  Future<void> _queue = Future.value();

  Future<File> _getFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    _file = File('${dir.path}${Platform.pathSeparator}$_fileName');
    return _file!;
  }

  Future<StoreData> load() async {
    try {
      final file = await _getFile();
      for (final f in [file, File('${file.path}.bak')]) {
        final data = await _read(f);
        if (data != null) return data;
      }
    } catch (_) {
      // 경로 조회 실패(테스트 등) — 빈 상태로 시작
    }
    return StoreData.empty();
  }

  Future<StoreData?> _read(File f) async {
    try {
      if (!await f.exists()) return null;
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return null;
      return StoreData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // 손상 → 다음 후보(복구본)
    }
  }

  /// 저장 요청은 순서대로 하나씩 처리된다. 반환 Future는 이 저장이 끝날 때 완료.
  Future<void> save(StoreData data) {
    final json = jsonEncode(data.toJson()); // 호출 시점 상태를 고정
    return _queue = _queue.then((_) => _write(json));
  }

  Future<void> _write(String json) async {
    try {
      final file = await _getFile();
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(json, flush: true);
      if (await file.exists()) await file.rename('${file.path}.bak');
      await tmp.rename(file.path);
    } catch (_) {
      // 저장 실패는 다음 저장에서 재시도 (앱이 죽지 않는 것이 우선)
    }
  }
}

class StoreData {
  final List<Task> tasks;
  final List<BrainDumpItem> inbox;
  final List<FocusSession> sessions;
  final BlockerSettings blockerSettings;
  final FocusScene scene;
  final bool soundEnabled;
  final double soundVolume;
  final ActiveSession? activeSession;

  const StoreData({
    required this.tasks,
    required this.inbox,
    required this.sessions,
    this.blockerSettings = const BlockerSettings(),
    this.scene = FocusScene.forest,
    this.soundEnabled = true,
    this.soundVolume = 0.6,
    this.activeSession,
  });

  /// 1 = 데스크탑 v1, 2 = 진행 세션·세션 결과 필드 추가
  static const schemaVersion = 2;

  factory StoreData.empty() =>
      const StoreData(tasks: [], inbox: [], sessions: []);

  Map<String, dynamic> toJson() => {
        'schema': schemaVersion,
        'activeSession': activeSession?.toJson(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'inbox': inbox.map((i) => i.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'blockerSettings': blockerSettings.toJson(),
        'scene': scene.name,
        'soundEnabled': soundEnabled,
        'soundVolume': soundVolume,
      };

  factory StoreData.fromJson(Map<String, dynamic> json) => StoreData(
        tasks: (json['tasks'] as List? ?? [])
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList(),
        inbox: (json['inbox'] as List? ?? [])
            .map((e) => BrainDumpItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        sessions: (json['sessions'] as List? ?? [])
            .map((e) => FocusSession.fromJson(e as Map<String, dynamic>))
            .toList(),
        blockerSettings: json['blockerSettings'] != null
            ? BlockerSettings.fromJson(
                json['blockerSettings'] as Map<String, dynamic>)
            : const BlockerSettings(),
        scene: FocusScene.values.asNameMap()[json['scene']] ??
            FocusScene.forest,
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        soundVolume: (json['soundVolume'] as num?)?.toDouble() ?? 0.6,
        activeSession: json['activeSession'] != null
            ? ActiveSession.fromJson(
                json['activeSession'] as Map<String, dynamic>)
            : null,
      );
}
