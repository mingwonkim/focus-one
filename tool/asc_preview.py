#!/usr/bin/env python3
"""앱 프리뷰 영상 1개를 한국어 1.0 버전 iPhone 6.9" 세트로 업로드 (기존 영상은 지움).
실행: python3 tool/asc_preview.py docs/mobile/store-assets/preview.mp4
업로드 뒤 Apple 쪽 처리에 수 분~수십 분. 처리 중이면 버전 저장이 막힌다(하루전 경험).
"""
import hashlib, os, sys, urllib.request

sys.path.insert(0, "tool")
from asc import call  # noqa: E402

APP, TYPE = "6821653231", "IPHONE_67"
path = sys.argv[1]
ver = call("GET", f"/v1/apps/{APP}/appStoreVersions?include=appStoreVersionLocalizations")
loc = next(x["id"] for x in ver["included"] if x["attributes"]["locale"] == "ko")
sets = call("GET", f"/v1/appStoreVersionLocalizations/{loc}/appPreviewSets")["data"]
s = next((x for x in sets if x["attributes"]["previewType"] == TYPE), None)
if s:
    for old in call("GET", f"/v1/appPreviewSets/{s['id']}/appPreviews")["data"]:
        call("DELETE", f"/v1/appPreviews/{old['id']}")
else:
    s = call("POST", "/v1/appPreviewSets", {"data": {"type": "appPreviewSets", "attributes": {"previewType": TYPE},
             "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc}}}}})["data"]
data = open(path, "rb").read()
pv = call("POST", "/v1/appPreviews", {"data": {"type": "appPreviews",
          "attributes": {"fileName": os.path.basename(path), "fileSize": len(data), "mimeType": "video/mp4",
                         "previewFrameTimeCode": "00:00:08:00"},  # 포스터 프레임: 타임랩스 중 링이 반쯤 찬 장면
          "relationships": {"appPreviewSet": {"data": {"type": "appPreviewSets", "id": s["id"]}}}}})["data"]
for op in pv["attributes"]["uploadOperations"]:
    part = data[op["offset"]:op["offset"] + op["length"]]
    req = urllib.request.Request(op["url"], data=part, method=op["method"],
                                 headers={h["name"]: h["value"] for h in op["requestHeaders"]})
    urllib.request.urlopen(req).read()
call("PATCH", f"/v1/appPreviews/{pv['id']}", {"data": {"type": "appPreviews", "id": pv["id"],
     "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
print("uploaded", os.path.basename(path))
