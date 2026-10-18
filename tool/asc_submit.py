"""편집 가능한 iOS 버전을 심사에 제출. 실행: python3 tool/asc_submit.py
버전 연결·새 기능 문구는 미리 끝나 있어야 한다."""
import sys

from asc import call

APP = "6821653231"
v = call("GET", f"/v1/apps/{APP}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION&filter[platform]=IOS")["data"]
if not v:
    sys.exit("제출할 버전 없음")
vid = v[0]["id"]
print("version", v[0]["attributes"]["versionString"])
s = call("POST", "/v1/reviewSubmissions", {"data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
         "relationships": {"app": {"data": {"type": "apps", "id": APP}}}}})["data"]["id"]
call("POST", "/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems", "relationships": {
    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": s}},
    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
r = call("PATCH", f"/v1/reviewSubmissions/{s}", {"data": {"type": "reviewSubmissions", "id": s, "attributes": {"submitted": True}}})
print(s, r["data"]["attributes"]["state"])
