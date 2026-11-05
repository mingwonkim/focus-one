#!/bin/bash
# 리그 SQL을 임시 로컬 Postgres에서 검증한다. 실서버에 연결하지 않는다.
# 사용: bash tool/test_league_sql.sh
set -euo pipefail
PG=/opt/homebrew/opt/postgresql@16/bin
[ -x "$PG/pg_ctl" ] || PG="$(dirname "$(command -v pg_ctl)")"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$(mktemp -d)"
PORT=54399
trap '"$PG/pg_ctl" -D "$DIR/data" -m immediate stop >/dev/null 2>&1 || true; rm -rf "$DIR"' EXIT
"$PG/initdb" -D "$DIR/data" -U postgres --auth=trust -E UTF8 >/dev/null
"$PG/pg_ctl" -D "$DIR/data" -o "-p $PORT -k $DIR -c listen_addresses=''" -w -l "$DIR/log" start >/dev/null
P=("$PG/psql" -h "$DIR" -p "$PORT" -U postgres -d postgres -v ON_ERROR_STOP=1 -q)
"${P[@]}" <<'SQL'
create role anon nologin;
create role authenticated nologin;
create role service_role nologin;
create schema auth;
create table auth.users (id uuid primary key);
create function auth.uid() returns uuid language sql stable as
  $$ select nullif(current_setting('test.uid', true), '')::uuid $$;
grant usage on schema auth to public;
grant execute on function auth.uid() to public;
SQL
for f in "$ROOT"/supabase/migrations/*.sql; do "${P[@]}" -f "$f"; done
OUT="$("${P[@]}" -f "$ROOT/supabase/tests/league_test.sql" 2>&1)" || { echo "$OUT" | grep -E "FAIL|ERROR|오류" | head -5; echo "LEAGUE SQL TESTS FAILED"; exit 1; }
echo "$OUT" | grep -c "ok:" | sed 's/$/ checks ok/'
echo "$OUT" | grep "PASSED"
