#!/usr/bin/env python3
"""스크린샷 폴더(01_*.png …, 이름순)를 한국어 1.0 버전 iPhone 6.9" 세트로 업로드 (기존 세트는 비움).
실행: python3 tool/asc_screenshots.py <폴더>
"""
import glob, hashlib, os, sys, urllib.request

sys.path.insert(0, "tool")
from asc import call  # noqa: E402

APP, TYPE = "6821653231", "APP_IPHONE_67"
files = sorted(glob.glob(os.path.join(sys.argv[1], "*.png")))
ver = call("GET", f"/v1/apps/{APP}/appStoreVersions?include=appStoreVersionLocalizations")
loc = next(x["id"] for x in ver["included"] if x["attributes"]["locale"] == "ko")
sets = call("GET", f"/v1/appStoreVersionLocalizations/{loc}/appScreenshotSets")["data"]
s = next((x for x in sets if x["attributes"]["screenshotDisplayType"] == TYPE), None)
if s:
    for old in call("GET", f"/v1/appScreenshotSets/{s['id']}/appScreenshots")["data"]:
        call("DELETE", f"/v1/appScreenshots/{old['id']}")
else:
    s = call("POST", "/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets", "attributes": {"screenshotDisplayType": TYPE},
             "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc}}}}})["data"]
for f in files:
    data = open(f, "rb").read()
    shot = call("POST", "/v1/appScreenshots", {"data": {"type": "appScreenshots", "attributes": {"fileName": os.path.basename(f), "fileSize": len(data)},
                "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": s["id"]}}}}})["data"]
    for op in shot["attributes"]["uploadOperations"]:
        part = data[op["offset"]:op["offset"] + op["length"]]
        req = urllib.request.Request(op["url"], data=part, method=op["method"],
                                     headers={h["name"]: h["value"] for h in op["requestHeaders"]})
        urllib.request.urlopen(req).read()
    call("PATCH", f"/v1/appScreenshots/{shot['id']}", {"data": {"type": "appScreenshots", "id": shot["id"],
         "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    print("uploaded", os.path.basename(f))
