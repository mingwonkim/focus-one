#!/usr/bin/env bash
# store_test.dart 결과 → 업로드용 파일 (<dir>/upload)
#  - PNG: 알파 제거(rgb24). 알파가 있으면 App Store Connect가 거부한다.
#  - preview.mp4: 886×1920 30fps H.264 + 장면별 앱 소리(timeline.json 기준 크로스페이드)
# 실행: bash tool/store/encode.sh <OUT dir>
set -euo pipefail
dir=$1
snd=assets/sounds
up="$dir/upload"
mkdir -p "$up/iphone" "$up/ipad"

for d in iphone ipad; do
  for f in "$dir/$d"/*.png; do
    ffmpeg -loglevel error -y -i "$f" -vf format=rgb24 "$up/$d/$(basename "$f")"
  done
done

# 장면 전환 시각 (초)
read -r night ocean forest2 end < <(node -e "const t=require(process.argv[1]);console.log(t.night,t.ocean,t.forest2,t.end)" "$(cd "$dir/video" && pwd -W 2>/dev/null || pwd)/timeline.json")
x=0.4 # 크로스페이드
# 구간 소리: [시작, 끝) 를 잘라 앞뒤로 페이드 → 시작 시각만큼 밀기
seg() { # $1 입력번호 $2 시작 $3 끝 $4 이름
  echo "[$1]atrim=0:$(node -p "$3-$2+$x"),asetpts=N/SR/TB,afade=t=in:d=$x,afade=t=out:st=$(node -p "$3-$2"):d=$x,adelay=$(node -p "Math.round($2*1000)")|$(node -p "Math.round($2*1000)")[$4]"
}
ffmpeg -loglevel error -y -framerate 30 -i "$dir/video/frames/%04d.png" \
  -stream_loop -1 -i "$snd/forest.m4a" -stream_loop -1 -i "$snd/night.m4a" \
  -stream_loop -1 -i "$snd/ocean.m4a" -stream_loop -1 -i "$snd/forest.m4a" \
  -filter_complex "$(seg 1 0 "$night" a);$(seg 2 "$night" "$ocean" b);$(seg 3 "$ocean" "$forest2" c);$(seg 4 "$forest2" "$end" d);[a][b][c][d]amix=inputs=4:normalize=0,atrim=0:$end,afade=t=out:st=$(node -p "$end-1.2"):d=1.2,loudnorm=I=-18:TP=-2,aresample=48000[aout]" \
  -map 0:v -map "[aout]" -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -r 30 -b:v 8M -maxrate 10M -bufsize 16M \
  -c:a aac -b:a 256k -ar 48000 -ac 2 -shortest -movflags +faststart "$up/preview.mp4"

ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate,sample_rate,channels:format=duration -of compact "$up/preview.mp4"
