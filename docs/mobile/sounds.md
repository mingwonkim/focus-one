# 폰 집중 소리 출처

Mixkit Sound Effects Free License (상업 이용 가능, 표기 의무 없음, 소리 파일 단독 재배포 금지).
`python3 tool/prepare_sound.py <원본> assets/sounds/<id>.m4a` — 끝 4초 크로스페이드 이음새 + 2초 음량 레벨러(원형, 반복 경계 포함) + −20 LUFS(고정 이득·리미터, 지연 보정) + AAC 112k.
이미 반복 파일인 걸 다시 다듬을 땐 `--loop --max 999`. (2026-11-04: 갑자기 커짐 신고 → 전체 재처리, 리미터 5ms 무음 제거)

| id | 용도 | Mixkit id |
|---|---|---|
| forest | 숲 기본 | 1220 |
| birds | 숲 · 새소리 | 2472 |
| stream | 숲 · 시냇물 | 2454 |
| night | 밤 기본 | 1227 |
| crickets | 밤 · 풀벌레 | 2459 |
| ocean | 바다 기본 | 1189 |
| harbor | 바다 · 항구 | 1208 |
| rocky | 바다 · 바위 해변 | 1190 |
| cafe | 일상 기본(카페) | 444 |
| rain | 숲 · 빗소리 | 1247 |
| wind | 밤 · 바람 | 2658 |

Freesound, CC0(퍼블릭 도메인):

| id | 용도 | 원본 |
|---|---|---|
| library | 일상 · 도서관 | Detective_Lemons #785584 public library ambiance |
| train | 일상 · 기차 안 | jrosin #209962 ON the Tallinn train |
| fire | 일상 · 모닥불 | Spandau #40699 campfire |

white · brown: tool/gen_sounds.py 합성 (노이즈라 합성 유지, −20 LUFS로 맞춤).
데스크탑은 그대로 forest/night/ocean.wav.
