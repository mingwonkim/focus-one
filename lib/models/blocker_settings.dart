// lib/models/blocker_settings.dart

/// 집중 시간 차단 설정.
/// - apps: 프로세스 이름 일부 (예: "discord", "League of Legends")
/// - sites: 브라우저 창 제목에서 감지할 키워드 (예: "YouTube", "인스타그램")
/// 차단은 집중 세션 중에만 활성화되고, 휴식/대기 중에는 꺼진다.
class BlockerSettings {
  final bool enabled;
  final bool autoKill; // true면 감지 즉시 프로세스 종료, false면 경고만
  final List<String> apps;
  final List<String> sites;

  const BlockerSettings({
    this.enabled = false,
    this.autoKill = false,
    this.apps = const [],
    this.sites = const [],
  });

  BlockerSettings copyWith({
    bool? enabled,
    bool? autoKill,
    List<String>? apps,
    List<String>? sites,
  }) =>
      BlockerSettings(
        enabled: enabled ?? this.enabled,
        autoKill: autoKill ?? this.autoKill,
        apps: apps ?? this.apps,
        sites: sites ?? this.sites,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'autoKill': autoKill,
        'apps': apps,
        'sites': sites,
      };

  factory BlockerSettings.fromJson(Map<String, dynamic> json) =>
      BlockerSettings(
        enabled: json['enabled'] as bool? ?? false,
        autoKill: json['autoKill'] as bool? ?? false,
        apps: (json['apps'] as List? ?? []).cast<String>(),
        sites: (json['sites'] as List? ?? []).cast<String>(),
      );
}
