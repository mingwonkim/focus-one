#!/usr/bin/env python3
"""App Store Connect API 최소 클라이언트. 키는 ~/.config/tocko/asc.env (저장소 밖).
사용: python3 tool/asc.py GET /v1/apps?filter[bundleId]=com.looinlabs.focusone
      python3 tool/asc.py PATCH /v1/... '{"data":...}'
"""
import json, os, sys, time, urllib.request
import jwt  # pip install pyjwt cryptography

ENV = dict(l.strip().split("=", 1) for l in open(os.path.expanduser("~/.config/tocko/asc.env")) if "=" in l)


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


if __name__ == "__main__":
    m, p = sys.argv[1], sys.argv[2]
    print(json.dumps(call(m, p, json.loads(sys.argv[3]) if len(sys.argv) > 3 else None), ensure_ascii=False, indent=1))
