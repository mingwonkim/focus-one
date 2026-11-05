-- 리그 SQL 검증. tool/test_league_sql.sh 가 임시 로컬 Postgres에서 실행한다. 실패하면 raise로 멈춘다.
\set ON_ERROR_STOP on

create function pg_temp.login(n int) returns void language sql as $$
  select set_config('test.uid', '00000000-0000-0000-0000-' || lpad(n::text, 12, '0'), false);
$$;
create function pg_temp.uid(n int) returns uuid language sql as $$
  select ('00000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid;
$$;
create function pg_temp.check(ok boolean, msg text) returns void language plpgsql as $$
begin
  if ok is not true then raise exception 'FAIL: %', msg; end if;
  raise notice 'ok: %', msg;
end $$;
-- 사용자 n명 생성 + 닉네임 + 리그 참여
create function pg_temp.people(a int, b int) returns void language plpgsql as $$
begin
  for i in a..b loop
    insert into auth.users (id) values (pg_temp.uid(i)) on conflict do nothing;
    perform pg_temp.login(i);
    perform public.submit_score(0, 'u' || i, '');
    perform public.join_league();
  end loop;
end $$;
-- 지난 주 조를 직접 만든다
create function pg_temp.past_group(wk date, t int, a int, scores int[]) returns bigint language plpgsql as $$
declare
  gid bigint;
begin
  insert into public.league_groups (week, tier) values (wk, t) returning id into gid;
  for i in 1..array_length(scores, 1) loop
    update public.league_members set tier = t where user_id = pg_temp.uid(a + i - 1);
    insert into public.league_group_members (group_id, week, user_id)
      values (gid, wk, pg_temp.uid(a + i - 1));
    if scores[i] > 0 then
      insert into public.verified_daily (user_id, day, minutes)
        values (pg_temp.uid(a + i - 1), wk + 2, scores[i]);
    end if;
  end loop;
  return gid;
end $$;
create function pg_temp.tier(n int) returns int language sql as $$
  select tier::int from public.league_members where user_id = pg_temp.uid(n);
$$;

-- 참여 규칙
do $$ begin
  insert into auth.users (id) values (pg_temp.uid(900));
  perform pg_temp.login(900);
  begin
    perform public.join_league();
    perform pg_temp.check(false, '닉네임 없으면 참여 불가');
  exception when raise_exception then
    perform pg_temp.check(sqlerrm = 'join first', '닉네임 없으면 참여 불가');
  end;
  perform pg_temp.check(public.league_status()->>'joined' = 'false', '미참여 상태');
end $$;

-- 검증 세션
do $$
declare
  v int;
  e timestamptz;
begin
  perform pg_temp.people(1, 1);
  perform pg_temp.login(1);
  begin
    perform public.begin_focus_v3('bad', 601);
    perform pg_temp.check(false, '예정 시간 형식 거부');
  exception when check_violation then
    perform pg_temp.check(true, '예정 시간 형식 거부');
  end;
  e := public.begin_focus_v3('s1', 1500);
  perform pg_temp.check(public.begin_focus_v3('s1', 1500) = e, '같은 id 재시도는 그대로');
  begin
    perform public.finish_focus_v3('s1');
    perform pg_temp.check(false, '끝나기 전 제출 거부');
  exception when raise_exception then
    perform pg_temp.check(sqlerrm = 'too early', '끝나기 전 제출 거부');
  end;
  update public.verified_sessions set ends_at = now() - interval '1 minute' where session_id = 's1';
  v := public.finish_focus_v3('s1');
  perform pg_temp.check(v = 25, '완료 25분 인정');
  perform pg_temp.check(public.finish_focus_v3('s1') = 25, '중복 제출 재인정 안 함');
  perform pg_temp.check((select minutes from public.verified_daily where user_id = pg_temp.uid(1)) = 25, '합계 25분');
  perform pg_temp.check(public.finish_focus_v3('없음') = 0, '모르는 세션은 0');

  perform public.begin_focus_v3('s2', 600);
  perform public.begin_focus_v3('s3', 600);
  perform pg_temp.check(public.finish_focus_v3('s2') = 0, '겹치면 이전 세션 취소');
  perform pg_temp.check((select count(*) from public.verified_sessions
    where user_id = pg_temp.uid(1) and finished_at is null and not canceled) = 1, '활성 예약 하나');

  -- 하루 720 상한
  update public.verified_sessions set ends_at = now() - interval '1 minute', planned_sec = 10800 where session_id = 's3';
  update public.verified_daily set minutes = 700 where user_id = pg_temp.uid(1);
  perform pg_temp.check(public.finish_focus_v3('s3') = 20, '하루 상한으로 잘림');
  perform pg_temp.check(jsonb_array_length(public.league_status()->'board') = 1, '조 편성·순위표');
  update public.verified_daily set minutes = 25 where user_id = pg_temp.uid(1);

  -- 지난 주 세션: 마감 뒤 제출은 개인 기록만
  insert into public.verified_sessions (user_id, session_id, planned_sec, ends_at, started_at)
    values (pg_temp.uid(1), 'old', 600, now() - interval '30 days', now() - interval '30 days');
  perform pg_temp.check(public.finish_focus_v3('old') = 0, '마감 뒤 제출 불인정');
end $$;

-- 정산: 10명
do $$
declare
  wk date := public.league_week() - 14;
begin
  perform pg_temp.people(10, 19);
  perform pg_temp.past_group(wk, 1, 10, array[100, 90, 80, 70, 60, 50, 40, 30, 20, 10]);
  perform pg_temp.login(10);
  perform public.league_status();
  perform pg_temp.check(pg_temp.tier(10) = 2 and pg_temp.tier(11) = 2, '10명 상위 2명 승급');
  perform pg_temp.check(pg_temp.tier(12) = 1 and pg_temp.tier(17) = 1, '10명 중간 유지');
  perform pg_temp.check(pg_temp.tier(18) = 0 and pg_temp.tier(19) = 0, '10명 하위 2명 강등');
  perform public.league_status();
  perform pg_temp.check(pg_temp.tier(10) = 2 and (select count(*) from public.league_results where week = wk) = 10, '두 번 정산 안 함');
  perform pg_temp.check((public.league_status()->'last_result'->>'rank')::int = 1, '지난 결과');
end $$;

-- 동점: 승급선 전원 승급, 강등선 강등 제외
do $$
declare
  wk date := public.league_week() - 21;
begin
  perform pg_temp.people(20, 24);
  perform pg_temp.past_group(wk, 1, 20, array[50, 50, 30, 10, 10]);
  perform public.league_status();
  perform pg_temp.check(pg_temp.tier(20) = 2 and pg_temp.tier(21) = 2, '승급선 동점 전원 승급');
  perform pg_temp.check(pg_temp.tier(22) = 1, '중간 유지');
  perform pg_temp.check(pg_temp.tier(23) = 1 and pg_temp.tier(24) = 1, '강등선 동점 강등 제외');
end $$;

-- 4명: 승급 1, 강등 0 (floor(0.8))
do $$
declare
  wk date := public.league_week() - 28;
begin
  perform pg_temp.people(30, 33);
  perform pg_temp.past_group(wk, 1, 30, array[40, 30, 20, 10]);
  perform public.league_status();
  perform pg_temp.check(pg_temp.tier(30) = 2, '4명 1위 승급');
  perform pg_temp.check(pg_temp.tier(33) = 1, '4명 강등 없음');
end $$;

-- 3명 이하: 150분 승급, 강등 없음. 1명도 동작
do $$
declare
  wk date := public.league_week() - 35;
begin
  perform pg_temp.people(40, 43);
  perform pg_temp.past_group(wk, 0, 40, array[150, 149, 10]);
  perform pg_temp.past_group(wk, 1, 43, array[10]);
  perform public.league_status();
  perform pg_temp.check(pg_temp.tier(40) = 1, '3명 150분 승급');
  perform pg_temp.check(pg_temp.tier(41) = 0 and pg_temp.tier(42) = 0, '3명 미달 유지');
  perform pg_temp.check(pg_temp.tier(43) = 1, '1명 강등 없음');
end $$;

-- 등급 끝을 넘지 않는다
do $$
declare
  wk date := public.league_week() - 42;
begin
  perform pg_temp.people(50, 59);
  perform pg_temp.past_group(wk, 2, 50, array[100, 90, 80, 70, 60]);
  perform pg_temp.past_group(wk, 0, 55, array[100, 90, 80, 70, 60]);
  perform public.league_status();
  perform pg_temp.check(pg_temp.tier(50) = 2, '최고 등급 유지');
  perform pg_temp.check(pg_temp.tier(59) = 0, '최저 등급 유지');
end $$;

-- 이번 주 조는 아직 정산 안 함, 조 정원 10명
do $$
declare
  wk date := public.league_week();
begin
  perform pg_temp.people(60, 71);
  update public.league_members set tier = 2 where user_id in (select pg_temp.uid(g) from generate_series(60, 71) g);
  for i in 60..71 loop
    perform pg_temp.login(i);
    perform public.begin_focus_v3('c' || i, 600);
    update public.verified_sessions set ends_at = now() - interval '1 minute'
      where user_id = pg_temp.uid(i) and session_id = 'c' || i;
    perform public.finish_focus_v3('c' || i);
  end loop;
  perform pg_temp.check((select max(c) from (select count(*) c from public.league_group_members
    where week = wk group by group_id) x) = 10, '조 최대 10명');
  perform pg_temp.check((select count(distinct m.group_id) from public.league_group_members m
    join public.league_groups g on g.id = m.group_id where m.week = wk and g.tier = 2) = 2, '넘치면 새 조');
  perform pg_temp.check((select count(*) from public.league_groups where week = wk and settled_at is not null) = 0, '이번 주 미정산');
end $$;

-- 탈퇴
do $$
declare
  wk date := public.league_week();
begin
  perform pg_temp.login(60);
  perform public.leave_league();
  perform pg_temp.check(public.league_status()->>'joined' = 'false', '리그 나가기');
  perform pg_temp.check(not exists (select 1 from public.league_group_members
    where week = wk and user_id = pg_temp.uid(60)), '이번 주 조에서 빠짐');
  delete from auth.users where id = pg_temp.uid(61);
  perform pg_temp.check(not exists (select 1 from public.verified_daily where user_id = pg_temp.uid(61))
    and not exists (select 1 from public.league_group_members where user_id = pg_temp.uid(61)), '계정 삭제 시 함께 삭제');
end $$;

-- 출시 앱이 쓰는 함수가 그대로 있고 새 점수와 섞이지 않는다
do $$
begin
  perform pg_temp.login(62);
  perform public.submit_score(100, 'u62');
  perform public.submit_score(120, 'u62', '');
  perform * from public.ranking(true);
  perform * from public.ranking('week');
  perform * from public.past_winners('week');
  perform * from public.duels();
  perform public.my_invite_code();
  perform pg_temp.check((select coalesce(sum(minutes), 0) from public.verified_daily where user_id = pg_temp.uid(62)) = 10, '구 점수는 리그에 안 섞임');
end $$;

-- 권한: 비로그인·직접 접근 차단
do $$
declare
  fn text;
begin
  foreach fn in array array['join_league()', 'leave_league()', 'league_status()',
      'begin_focus_v3(text,int)', 'finish_focus_v3(text)'] loop
    perform pg_temp.check(not has_function_privilege('anon', 'public.' || fn, 'execute'), 'anon 차단 ' || fn);
    perform pg_temp.check(has_function_privilege('authenticated', 'public.' || fn, 'execute'), 'authenticated 허용 ' || fn);
  end loop;
  foreach fn in array array['league_settle_group(bigint)', 'league_settle_due()', 'league_assign(uuid,date)'] loop
    perform pg_temp.check(not has_function_privilege('authenticated', 'public.' || fn, 'execute'), '내부 함수 차단 ' || fn);
  end loop;
  perform pg_temp.check(not has_table_privilege('authenticated', 'public.league_results', 'select')
    or (select relrowsecurity from pg_class where oid = 'public.league_results'::regclass), 'RLS');
end $$;

\echo ALL LEAGUE SQL TESTS PASSED
