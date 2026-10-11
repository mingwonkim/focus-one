#!/usr/bin/env python3
"""앱 아이콘 일괄 생성: assets/icon/source.png(1024 불투명 정사각) → 모든 플랫폼.
실행: python3 tool/make_icons.py   (Pillow·numpy 필요)
- iOS: 불투명 정사각 그대로 (OS가 모양을 깎음)
- macOS: 1024 캔버스에 824 스퀘어클 + 여백 100 + 그림자 → assets/icon/macos (apply_icons.sh가 복사)
- Windows .ico / Linux 256 / 트레이 / Android mipmap: 여백 없는 스퀘어클 투명 타일
"""
import json
import numpy as np
from PIL import Image, ImageFilter


def squircle(size, n=5.0, ss=4):
    s = size * ss
    c = (s - 1) / 2
    yy, xx = np.mgrid[0:s, 0:s]
    v = (np.abs((xx - c) / c) ** n + np.abs((yy - c) / c) ** n) <= 1
    return Image.fromarray((v * 255).astype("uint8")).resize((size, size), Image.LANCZOS)


def tile(src, size):
    t = src.resize((size, size), Image.LANCZOS).convert("RGBA")
    t.putalpha(squircle(size))
    return t


src = Image.open("assets/icon/source.png").convert("RGB")

# iOS
d = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
for im in json.load(open(f"{d}/Contents.json"))["images"]:
    px = round(float(im["size"].split("x")[0]) * int(im["scale"][0]))
    src.resize((px, px), Image.LANCZOS).save(f"{d}/{im['filename']}")

# macOS
body = tile(src, 824)
canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
shadow_a = Image.new("L", (1024, 1024), 0)
shadow_a.paste(body.getchannel("A"), (100, 110))
shadow_a = shadow_a.filter(ImageFilter.GaussianBlur(14)).point(lambda p: int(p * 0.3))
shadow = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
shadow.putalpha(shadow_a)
canvas = Image.alpha_composite(canvas, shadow)
canvas.alpha_composite(body, (100, 100))
for s in [16, 32, 64, 128, 256, 512, 1024]:
    canvas.resize((s, s), Image.LANCZOS).save(f"assets/icon/macos/app_icon_{s}.png")

# Windows / Linux / 트레이
full = tile(src, 1024)
full.save("assets/icon/app_icon.ico", sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
full.resize((256, 256), Image.LANCZOS).save("assets/icon/app_icon_256.png")
full.resize((64, 64), Image.LANCZOS).save("assets/tray_icon.png")
full.save("assets/tray_icon.ico", sizes=[(16, 16), (24, 24), (32, 32), (48, 48)])

# Android
for name, px in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
    full.resize((px, px), Image.LANCZOS).save(f"android/app/src/main/res/mipmap-{name}/ic_launcher.png")
print("icons written")
