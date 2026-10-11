#!/usr/bin/env python3
"""받은 배경음(WAV 등)을 앱용 반복 소리로 다듬는다.
- 최대 길이 자르기 → 끝 4초를 처음 4초에 크로스페이드(반복 이음새가 안 들리게)
- 음량 맞춤(EBU R128 −20 LUFS) → AAC 112k m4a
실행: python3 tool/prepare_sound.py <입력> <출력.m4a> [--max 180]
필요: ffmpeg, numpy
"""
import subprocess
import sys

import numpy as np

SR = 44100
FADE = 4.0

src, out = sys.argv[1], sys.argv[2]
max_sec = float(sys.argv[sys.argv.index("--max") + 1]) if "--max" in sys.argv else 180.0

raw = subprocess.run(
    ["ffmpeg", "-v", "error", "-i", src, "-t", str(max_sec + FADE), "-ac", "2", "-ar", str(SR),
     "-f", "f32le", "-"], capture_output=True, check=True).stdout
x = np.frombuffer(raw, dtype=np.float32).reshape(-1, 2).copy()
f = int(FADE * SR)
assert len(x) > 3 * f, "너무 짧음"
body = x[: len(x) - f].copy()
ramp = np.linspace(0.0, 1.0, f, dtype=np.float32)[:, None]
# 등전력 크로스페이드: 시작부 = 처음 f(서서히 커짐) + 꼬리 f(서서히 작아짐)
body[:f] = x[:f] * np.sqrt(ramp) + x[len(x) - f:] * np.sqrt(1 - ramp)

subprocess.run(
    ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SR), "-ac", "2", "-i", "-",
     "-af", "loudnorm=I=-20:LRA=11:TP=-2", "-ar", str(SR),
     "-c:a", "aac", "-b:a", "112k", out],
    input=body.tobytes(), check=True)
print(f"{out}: {len(body) / SR:.1f}s")
