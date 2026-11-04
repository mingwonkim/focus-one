#!/usr/bin/env python3
"""docs/mobile/store.md 문구를 App Store Connect에 반영 (한국어 1.0).
실행: python3 tool/asc_store.py
"""
import re
import sys

sys.path.insert(0, "tool")
from asc import call  # noqa: E402

APP = "6821653231"
md = open("docs/mobile/store.md", encoding="utf-8").read()


def sec(title):
    return md.split(f"## {title}\n", 1)[1].split("\n## ", 1)[0].strip()


def line(label):
    return re.search(rf"- {label}[^:]*: (.+)", md).group(1).strip()


info = call("GET", f"/v1/apps/{APP}/appInfos?include=appInfoLocalizations")
info_id = info["data"][0]["id"]
info_loc = next(x["id"] for x in info["included"] if x["attributes"]["locale"] == "ko")
ver = call("GET", f"/v1/apps/{APP}/appStoreVersions?include=appStoreVersionLocalizations")
ver_id = ver["data"][0]["id"]
ver_loc = next(x["id"] for x in ver["included"] if x["attributes"]["locale"] == "ko")

call("PATCH", f"/v1/appInfoLocalizations/{info_loc}", {"data": {"type": "appInfoLocalizations", "id": info_loc, "attributes": {
    "subtitle": line("부제"), "privacyPolicyUrl": line("개인정보 처리방침 URL")}}})
call("PATCH", f"/v1/appInfos/{info_id}", {"data": {"type": "appInfos", "id": info_id, "relationships": {
    "primaryCategory": {"data": {"type": "appCategories", "id": "PRODUCTIVITY"}},
    "secondaryCategory": {"data": {"type": "appCategories", "id": "LIFESTYLE"}}}}})
call("PATCH", f"/v1/appStoreVersions/{ver_id}", {"data": {"type": "appStoreVersions", "id": ver_id, "attributes": {
    "versionString": "1.0.0", "copyright": sec("저작권")}}})
call("PATCH", f"/v1/appStoreVersionLocalizations/{ver_loc}", {"data": {"type": "appStoreVersionLocalizations", "id": ver_loc, "attributes": {
    "description": sec("설명 (4000자)"),
    "keywords": sec("키워드 (100자, 쉼표 뒤 공백 없음, 이름에 있는 단어 제외)"),
    "promotionalText": sec("프로모션 텍스트 (170자)"),
    "supportUrl": line("지원 URL")}}})
print("ok", info_id, ver_id)
