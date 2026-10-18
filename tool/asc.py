#!/usr/bin/env python3
"""App Store Connect API 최소 클라이언트. 키는 ~/.config/fokko/asc.env (저장소 밖).
사용: python3 tool/asc.py GET /v1/apps?filter[bundleId]=com.looinlabs.focusone
      python3 tool/asc.py PATCH /v1/... '{"data":...}'
"""
import json, os, sys, time, urllib.request
import jwt  # pip install pyjwt cryptography

ENV = dict(l.strip().split("=", 1) for l in open(os.path.expanduser("~/.config/fokko/asc.env")) if "=" in l)


def token():
    return jwt.encode(
        {"iss": ENV["ASC_ISSUER_ID"], "iat": int(time.time()), "exp": int(time.time()) + 1100, "aud": "appstoreconnect-v1"},
        open(ENV["ASC_KEY_PATH"]).read(), algorithm="ES256", headers={"kid": ENV["ASC_KEY_ID"]})


def call(method, path, body=None):
    req = urllib.request.Request("https://api.appstoreconnect.apple.com" + path, method=method,
                                 data=json.dumps(body).encode() if body else None,
                                 headers={"Authorization": "Bearer " + token(), "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r:
            t = r.read()
            return json.loads(t) if t else {}
    except urllib.error.HTTPError as e:
        sys.exit(f"{e.code} {e.read().decode()[:1500]}")


def ko_loc(app):
    """편집 가능한 버전(출시·심사 중 아님)의 한국어 현지화 ID. 출시된 버전의 미디어는 못 바꾼다."""
    ver = call("GET", f"/v1/apps/{app}/appStoreVersions?include=appStoreVersionLocalizations")
    v = next((x for x in ver["data"] if x["attributes"]["appVersionState"] in
              ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED")), None)
    if not v:
        sys.exit("편집 가능한 버전 없음 — ASC에서 새 버전을 먼저 만든다")
    ids = {x["id"] for x in v["relationships"]["appStoreVersionLocalizations"]["data"]}
    return next(x["id"] for x in ver["included"] if x["id"] in ids and x["attributes"]["locale"] == "ko")


if __name__ == "__main__":
    m, p = sys.argv[1], sys.argv[2]
    print(json.dumps(call(m, p, json.loads(sys.argv[3]) if len(sys.argv) > 3 else None), ensure_ascii=False, indent=1))
