#!/usr/bin/env python3
"""FocusOne 앰비언트 사운드 합성 (stdlib only).
forest.wav  : 잎 바스락 노이즈 + 새 지저귐
night.wav   : 낮은 바람 + 뻐꾸기 울음
ocean.wav   : 파도 스웰 (브라운 노이즈 진폭 변조)
40초 루프, 경계 크로스페이드로 이음새 없음. 모노 44.1kHz 16bit.
"""
import math
import random
import struct
import sys
import wave

SR = 44100
DUR = 40.0
N = int(SR * DUR)
FADE = int(SR * 0.5)  # 루프 크로스페이드
TWO_PI = 2.0 * math.pi

random.seed(42)


def lowpass(samples, alpha):
    out = [0.0] * len(samples)
    y = 0.0
    for i, x in enumerate(samples):
        y += alpha * (x - y)
        out[i] = y
    return out


def white(n):
    return [random.uniform(-1.0, 1.0) for _ in range(n)]


def brown(n):
    out = [0.0] * n
    y = 0.0
    for i in range(n):
        y = 0.998 * y + random.uniform(-1.0, 1.0) * 0.02
        out[i] = y
    return out


def loop_lfo(t, k, depth, base, phase=0.0):
    """주기가 DUR의 정수 분할(k)인 LFO — 루프 경계에서 연속."""
    return base + depth * math.sin(TWO_PI * k * t / DUR + phase)


def add_tone(buf, start, length, f0, f1, amp, attack=0.02, release=0.06):
    """주파수 스위프 톤(새/뻐꾸기용)을 buf에 더한다."""
    n = int(length * SR)
    s = int(start * SR)
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = f0 + (f1 - f0) * (i / n)
        phase += TWO_PI * f / SR
        env = min(1.0, t / attack) * min(1.0, (length - t) / release)
        idx = s + i
        if 0 <= idx < len(buf):
            buf[idx] += amp * env * math.sin(phase)


def crossfade_loop(buf):
    """앞 FADE 샘플에 꼬리를 섞어 루프 이음새 제거. 길이 N 반환."""
    body = buf[:N]
    tail = buf[N:N + FADE]
    for i in range(min(FADE, len(tail))):
        w = i / FADE
        body[i] = body[i] * w + tail[i] * (1.0 - w)
    return body


def normalize(buf, peak=0.5):
    m = max(abs(x) for x in buf) or 1.0
    return [x * peak / m for x in buf]


def save(name, buf):
    with wave.open(name, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, x)) * 32767)) for x in buf))
    print(name, "written")


def gen_forest():
    n = N + FADE
    # 잎 바스락: 가벼운 로우패스 노이즈 + 느린 흔들림
    leaves = lowpass(white(n), 0.25)
    buf = [0.0] * n
    for i in range(n):
        t = i / SR
        sway = loop_lfo(t, 5, 0.25, 0.65) * loop_lfo(t, 9, 0.15, 0.85, 1.3)
        buf[i] = leaves[i] * 0.35 * sway
    # 새 지저귐: 서로 다른 두 마리, 고정 시점의 짧은 프레이즈
    bird_times = [(3.0, 2600), (3.4, 2600), (9.5, 3300), (9.8, 3300),
                  (10.1, 3300), (16.0, 2200), (16.5, 2200), (24.0, 3000),
                  (24.3, 3000), (24.6, 3000), (31.0, 2500), (31.4, 2500)]
    for start, f in bird_times:
        add_tone(buf, start, 0.09, f, f * 1.35, 0.22)
        add_tone(buf, start + 0.11, 0.07, f * 1.2, f * 0.95, 0.16)
    return normalize(crossfade_loop(buf), 0.45)


def gen_night():
    n = N + FADE
    # 바람: 깊은 로우패스 노이즈 + 강한 느린 스웰
    wind = lowpass(white(n), 0.045)
    buf = [0.0] * n
    for i in range(n):
        t = i / SR
        gust = loop_lfo(t, 3, 0.35, 0.6) * loop_lfo(t, 7, 0.2, 0.8, 2.1)
        buf[i] = wind[i] * 2.2 * gust
    # 뻐꾸기: "뻐-꾹" 두 음 (약 715Hz → 570Hz), 3회
    for call_t in (6.0, 19.0, 30.5):
        for rep in range(2):
            t0 = call_t + rep * 1.1
            add_tone(buf, t0, 0.28, 715, 700, 0.20, attack=0.04, release=0.12)
            add_tone(buf, t0 + 0.38, 0.32, 575, 560, 0.20, attack=0.04, release=0.14)
    return normalize(crossfade_loop(buf), 0.42)


def gen_ocean():
    n = N + FADE
    deep = brown(n)
    foam = lowpass(white(n), 0.35)
    buf = [0.0] * n
    for i in range(n):
        t = i / SR
        # 파도 스웰: 10초/5.7초 주기 조합 (루프 경계 연속)
        swell = loop_lfo(t, 4, 0.4, 0.55) * loop_lfo(t, 7, 0.25, 0.75, 0.8)
        swell = max(0.05, swell)
        buf[i] = deep[i] * 1.6 * swell + foam[i] * 0.10 * swell * swell
    return normalize(crossfade_loop(buf), 0.5)


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    save(f"{out}/forest.wav", gen_forest())
    save(f"{out}/night.wav", gen_night())
    save(f"{out}/ocean.wav", gen_ocean())
