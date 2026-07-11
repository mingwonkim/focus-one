// lib/data/local_store.dart
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/task.dart';

/// MVP용 JSON 파일 저장소.
/// - 코드젠(build_runner) 없이 바로 동작
/// - 데이터가 커지면 drift/isar로 교체 (인터페이스 유지 전제)
class LocalStore {
  static const _fileName = 'focus_one_data.json';
  File? _file;

  Future<File> _getFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationSupportDirectory();
    _file = File('${dir.path}${Platform.pathSeparator}$_fileName');
    return _file!;
  }

  Future<StoreData> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return StoreData.empty();
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return StoreData.empty();
      return StoreData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // 파일 손상 시 빈 상태로 시작 (앱이 죽지 않는 것이 우선)
      return StoreData.empty();
    }
  }

  Future<void> save(StoreData data) async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(data.toJson()), flush: true);
    } catch (_) {
      // 저장 실패는 조용히 무시하고 다음 저장 시 재시도
    }
  }
}

class StoreData {
  final List<Task> tasks;
  final List<BrainDumpItem> inbox;
  final List<FocusSession> sessions;

  const StoreData({
    required this.tasks,
    required this.inbox,
    required this.sessions,
  });

  factory StoreData.empty() =>
      const StoreData(tasks: [], inbox: [], sessions: []);

  Map<String, dynamic> toJson() => {
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'inbox': inbox.map((i) => i.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
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
      );
}
