# 이미지 생성 기록 (모바일)

Higgsfield 새 계정 크레딧 부족(0.03) → 사용자 요청으로 무료 대안 사용.
- Pollinations(무료 공개 API) 시험: 768px·워터마크·지시 무시 → 불채택.
- **codex CLI 내장 image_generation**(기존 ChatGPT 구독, 추가 비용 0) 채택. 1024 투명 PNG → 512 webp로 `assets/mobile/companions/`.

공통 프롬프트: "Matte 3D toy figurine, round soft pastel body, small glossy dot eyes, subtle blush, full body three-quarter view, centered filling 80% of frame, soft light from upper left, transparent background, no text, no props, no base."

| 파일 | 장면 | 이름(astra 설계서) | 개별 프롬프트 |
|---|---|---|---|
| fawn | 숲 | 새싹사슴 | mint-green baby fawn with tiny leaf-shaped antlers |
| squirrel | 숲 | 이끼다람 | sage green squirrel with a big curled mossy tail |
| fox | 숲 | 잎새여우 | mint fox kit with leaf-shaped ears |
| bear | 숲 | 숲곰 | sage green bear cub with round paws, sitting |
| rabbit | 밤 | 달토끼 | lavender bunny, tall upright ears, crescent mark |
| owl | 밤 | 별부엉 | lilac baby owl with gold-tipped wings |
| firefly | 밤 | 반딧불 | lilac firefly, glowing soft gold abdomen |
| cat | 밤 | 꿈고양 | lilac kitten, crescent-moon tail, sleepy eyes |
| whale | 바다 | 물결고래 | soft blue baby whale, cyan belly, tiny spout |
| turtle | 바다 | 파도거북 | cyan baby sea turtle, teal shell |
| octopus | 바다 | 방울문어 | blue baby octopus, eight curly arms |
| ray | 바다 | 구름가오리 | light blue baby manta ray, cloud-like fins |

원본 1024 PNG는 스크래치에만(커밋 안 함). 생성 2회(1장 시험 + 11장 일괄), 버림 0.

## 장식 9종 (2026-10-11, codex image_generation, 1회 일괄, 버림 0)
공통: "Matte 3D toy diorama object, soft pastel colors, rounded chunky shapes, three-quarter top view, centered filling 75% of frame, soft light from upper left, transparent background, no text, no characters, no ground plate." + ref_fawn.png로 톤 통일.
숲: grass(풀숲)·tree(나무)·bench(벤치) / 밤: starstone(별돌)·moonlamp(달등)·telescope(망원경) / 바다: coral(산호)·seaweed(해초)·shellhouse(조개집). 512 webp 합계 232KB → assets/mobile/decor/.
