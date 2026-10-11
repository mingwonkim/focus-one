// lib/models/collection.dart
// 폰 v1: 태그 · 친구(수집) · 장식 · 풍경 배치 · 재화(물방울).
// 경제 규칙은 docs/mobile/app-design-spec.md §6 — 완료한 실집중 1분당 물방울 1, 세션당 친구 1.
import '../core/design_tokens.dart';

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

/// 수집 친구 카탈로그 (코드 상수). 해금 = 그 장면에서 완료한 누적 집중 분.
class Companion {
  final String id; // 에셋 파일명과 같음
  final FocusScene scene;
  final String name;
  final int unlockMinutes;

  const Companion(this.id, this.scene, this.name, this.unlockMinutes);

  String get asset => 'assets/mobile/companions/$id.webp';

  static const all = [
    Companion('fawn', FocusScene.forest, '새싹사슴', 0),
    Companion('squirrel', FocusScene.forest, '이끼다람', 60),
    Companion('fox', FocusScene.forest, '잎새여우', 180),
    Companion('bear', FocusScene.forest, '숲곰', 360),
    Companion('rabbit', FocusScene.night, '달토끼', 0),
    Companion('owl', FocusScene.night, '별부엉', 60),
    Companion('firefly', FocusScene.night, '반딧불', 180),
    Companion('cat', FocusScene.night, '꿈고양', 360),
    Companion('whale', FocusScene.ocean, '물결고래', 0),
    Companion('turtle', FocusScene.ocean, '파도거북', 60),
    Companion('octopus', FocusScene.ocean, '방울문어', 180),
    Companion('ray', FocusScene.ocean, '구름가오리', 360),
    Companion('puppy', FocusScene.daily, '라떼멍', 0),
    Companion('hamster', FocusScene.daily, '책햄찌', 60),
    Companion('raccoon', FocusScene.daily, '기차너구리', 180),
    Companion('hedgehog', FocusScene.daily, '캠프도치', 360),
  ];

  static Companion? byId(String? id) =>
      all.where((c) => c.id == id).firstOrNull;

  static List<Companion> of(FocusScene s) =>
      all.where((c) => c.scene == s).toList();
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
  final String soundId; // 'scene'(장면 소리) | 'rain' | 'white' | 'brown'
  final int escapeSpent; // 비상 탈출에 쓴 물방울 누계 — 랭킹 점수에서 뺀다

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
  });

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
      );
}
