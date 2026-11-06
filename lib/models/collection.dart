// lib/models/collection.dart
// 폰 v1: 태그 · 친구(수집) · 장식 · 풍경 배치 · 재화(물방울).
// 경제 규칙은 docs/mobile/app-design-spec.md §6 — 완료한 실집중 1분당 물방울 1, 세션당 친구 1.
import '../core/design_tokens.dart';
import 'growth.dart';

class Tag {
  final String id;
  final String name;
  final int colorIndex;

  const Tag({required this.id, required this.name, this.colorIndex = 0});

  Tag copyWith({String? name, int? colorIndex}) => Tag(
      id: id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex);

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'colorIndex': colorIndex};

  factory Tag.fromJson(Map<String, dynamic> j) => Tag(
        id: j['id'] as String,
        name: j['name'] as String,
        colorIndex: j['colorIndex'] as int? ?? 0,
      );
}

/// 수집 친구 카탈로그 (코드 상수). 해금 = 그 장면에서 완료한 누적 집중 분, 또는 전체 100시간.
/// 해금 0분 = 기본 친구: 캐릭터당 항상 1명이고, 꾸미기에서는 어느 장면에나 놓을 수 있다.
class Companion {
  final String id; // 에셋 파일명과 같음
  final FocusScene scene;
  final String name;
  final int unlockMinutes;

  const Companion(this.id, this.scene, this.name, this.unlockMinutes);

  String get asset => 'assets/mobile/companions/$id.webp';
  bool get isStarter => unlockMinutes == 0;

  /// 이만큼 집중하면 장면과 상관없이 모두 해금 (장면별 끝 조건 1500분 × 4)
  static const unlockAllMinutes = 6000;

  static const all = [
    Companion('fawn', FocusScene.forest, '새싹사슴', 0),
    Companion('butterfly', FocusScene.forest, '꽃잎나비', 150),
    Companion('squirrel', FocusScene.forest, '이끼다람', 300),
    Companion('frog', FocusScene.forest, '버섯개구리', 450),
    Companion('fox', FocusScene.forest, '잎새여우', 600),
    Companion('snail', FocusScene.forest, '덩굴달팽이', 800),
    Companion('bear', FocusScene.forest, '숲곰', 1000),
    Companion('boar', FocusScene.forest, '솔방울멧돼지', 1250),
    Companion('badger', FocusScene.forest, '단풍오소리', 1500),
    Companion('rabbit', FocusScene.night, '달토끼', 0),
    Companion('bat', FocusScene.night, '별박쥐', 150),
    Companion('owl', FocusScene.night, '별부엉', 300),
    Companion('moth', FocusScene.night, '달빛나방', 450),
    Companion('firefly', FocusScene.night, '반딧불', 600),
    Companion('sheep', FocusScene.night, '구름양', 800),
    Companion('cat', FocusScene.night, '꿈고양', 1000),
    Companion('fennec', FocusScene.night, '별빛사막여우', 1250),
    Companion('wolf', FocusScene.night, '은하늑대', 1500),
    Companion('whale', FocusScene.ocean, '물결고래', 0),
    Companion('crab', FocusScene.ocean, '모래게', 150),
    Companion('turtle', FocusScene.ocean, '파도거북', 300),
    Companion('seahorse', FocusScene.ocean, '산호해마', 450),
    Companion('octopus', FocusScene.ocean, '방울문어', 600),
    Companion('puffer', FocusScene.ocean, '풍선복어', 800),
    Companion('ray', FocusScene.ocean, '구름가오리', 1000),
    Companion('otter', FocusScene.ocean, '조개수달', 1250),
    Companion('penguin', FocusScene.ocean, '얼음펭귄', 1500),
    Companion('puppy', FocusScene.daily, '라떼멍', 0),
    Companion('duck', FocusScene.daily, '우산오리', 150),
    Companion('hamster', FocusScene.daily, '책햄찌', 300),
    Companion('loafcat', FocusScene.daily, '식빵냥', 450),
    Companion('raccoon', FocusScene.daily, '기차너구리', 600),
    Companion('alpaca', FocusScene.daily, '뜨개알파카', 800),
    Companion('hedgehog', FocusScene.daily, '캠프도치', 1000),
    Companion('panda', FocusScene.daily, '도시락판다', 1250),
    Companion('koala', FocusScene.daily, '자전거코알라', 1500),
  ];

  static Companion? byId(String? id) =>
      all.where((c) => c.id == id).firstOrNull;

  static List<Companion> of(FocusScene s) =>
      all.where((c) => c.scene == s).toList();

  /// 꾸미기 친구칸: 기본 친구 전부 + 이 장면에서 집중으로 만나는 친구
  static List<Companion> forScenery(FocusScene s) => [
        ...all.where((c) => c.isStarter),
        ...all.where((c) => c.scene == s && !c.isStarter),
      ];
}

/// 상점 장식 (그림은 코드로). 가격 = 물방울.
class Decor {
  final String id;
  final FocusScene scene;
  final String name;
  final int price;

  const Decor(this.id, this.scene, this.name, this.price);

  String get asset => 'assets/mobile/decor/$id.webp';

  static const all = [
    Decor('grass', FocusScene.forest, '풀숲', 20),
    Decor('tree', FocusScene.forest, '나무', 40),
    Decor('bench', FocusScene.forest, '벤치', 60),
    Decor('starstone', FocusScene.night, '별돌', 20),
    Decor('moonlamp', FocusScene.night, '달등', 40),
    Decor('telescope', FocusScene.night, '망원경', 60),
    Decor('coral', FocusScene.ocean, '산호', 20),
    Decor('seaweed', FocusScene.ocean, '해초', 40),
    Decor('shellhouse', FocusScene.ocean, '조개집', 60),
    Decor('mug', FocusScene.daily, '머그잔', 20),
    Decor('books', FocusScene.daily, '책 더미', 40),
    Decor('lamp', FocusScene.daily, '스탠드', 60),
  ];

  static Decor? byId(String? id) => all.where((d) => d.id == id).firstOrNull;
}

/// 친구·장식 공통 그림 경로
String itemAsset(String id) =>
    Companion.byId(id)?.asset ?? Decor.byId(id)?.asset ?? '';

/// 풍경 6×6 격자 위 한 칸 (친구 또는 장식 1개)
class Placement {
  final String itemId; // Companion.id 또는 Decor.id
  final int x;
  final int y;

  const Placement(this.itemId, this.x, this.y);

  static const grid = 6;

  Map<String, dynamic> toJson() => {'itemId': itemId, 'x': x, 'y': y};

  factory Placement.fromJson(Map<String, dynamic> j) =>
      Placement(j['itemId'] as String, j['x'] as int, j['y'] as int);
}

/// 폰 진행 상태 묶음 — StoreData에 'progress' 한 덩어리로 저장.
class Progress {
  final List<Tag> tags;
  final String? currentTagId;
  final String? selectedCompanionId; // 다음 세션에 데려올 친구
  final Map<String, int> owned; // 친구·장식 id → 보유 수
  final Map<String, List<Placement>> placements; // 장면 이름 → 배치
  final int drops;
  final bool lockEnabled; // 집중 중 앱 잠금 (권한·선택은 OS 쪽)
  final String soundId; // 'scene'(장면 기본) | 장면별 상황 소리 id | 'white' | 'brown'
  final int escapeSpent; // 비상 탈출에 쓴 물방울 누계 — 랭킹 점수에서 뺀다
  final String? rankNickname; // 랭킹 참여 닉네임 (null = 참여 안 함)
  final Growth growth; // 목표·연속일·얼음 (v3)

  const Progress({
    this.tags = const [Tag(id: 'general', name: '미분류')],
    this.currentTagId = 'general',
    this.selectedCompanionId,
    this.owned = const {},
    this.placements = const {},
    this.drops = 0,
    this.lockEnabled = false,
    this.soundId = 'scene',
    this.escapeSpent = 0,
    this.rankNickname,
    this.growth = const Growth(),
  });

  /// 기본 친구가 여럿 놓인 예전 배치를 캐릭터당 1명만 남기고 정리한다
  Progress withStarterLimit() {
    final seen = <String>{};
    bool keep(Placement p) =>
        Companion.byId(p.itemId)?.isStarter != true || seen.add(p.itemId);
    final next = {
      for (final e in placements.entries) e.key: e.value.where(keep).toList()
    };
    final same =
        placements.entries.every((e) => next[e.key]!.length == e.value.length);
    return same ? this : copyWith(placements: next);
  }

  Progress copyWith({
    List<Tag>? tags,
    String? Function()? currentTagId,
    String? Function()? selectedCompanionId,
    Map<String, int>? owned,
    Map<String, List<Placement>>? placements,
    int? drops,
    bool? lockEnabled,
    String? soundId,
    int? escapeSpent,
    String? Function()? rankNickname,
    Growth? growth,
  }) =>
      Progress(
        tags: tags ?? this.tags,
        currentTagId: currentTagId != null ? currentTagId() : this.currentTagId,
        selectedCompanionId: selectedCompanionId != null
            ? selectedCompanionId()
            : this.selectedCompanionId,
        owned: owned ?? this.owned,
        placements: placements ?? this.placements,
        drops: drops ?? this.drops,
        lockEnabled: lockEnabled ?? this.lockEnabled,
        soundId: soundId ?? this.soundId,
        escapeSpent: escapeSpent ?? this.escapeSpent,
        rankNickname:
            rankNickname != null ? rankNickname() : this.rankNickname,
        growth: growth ?? this.growth,
      );

  Map<String, dynamic> toJson() => {
        'tags': tags.map((t) => t.toJson()).toList(),
        'currentTagId': currentTagId,
        'selectedCompanionId': selectedCompanionId,
        'owned': owned,
        'placements': placements
            .map((k, v) => MapEntry(k, v.map((p) => p.toJson()).toList())),
        'drops': drops,
        'lockEnabled': lockEnabled,
        'soundId': soundId,
        'escapeSpent': escapeSpent,
        'rankNickname': rankNickname,
        'growth': growth.toJson(),
      };

  factory Progress.fromJson(Map<String, dynamic> j) => Progress(
        tags: (j['tags'] as List? ??
                const [
                  {'id': 'general', 'name': '미분류'}
                ])
            .map((e) => Tag.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentTagId: j['currentTagId'] as String? ?? 'general',
        selectedCompanionId: j['selectedCompanionId'] as String?,
        owned: (j['owned'] as Map? ?? {})
            .map((k, v) => MapEntry(k as String, v as int)),
        placements: (j['placements'] as Map? ?? {}).map((k, v) => MapEntry(
            k as String,
            (v as List)
                .map((e) => Placement.fromJson(e as Map<String, dynamic>))
                .toList())),
        drops: j['drops'] as int? ?? 0,
        lockEnabled: j['lockEnabled'] as bool? ?? false,
        soundId: j['soundId'] as String? ?? 'scene',
        escapeSpent: j['escapeSpent'] as int? ?? 0,
        rankNickname: j['rankNickname'] as String?,
        growth: Growth.fromJson(j['growth'] as Map<String, dynamic>?),
      );
}
