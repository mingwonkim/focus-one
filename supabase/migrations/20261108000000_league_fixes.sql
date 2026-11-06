-- 리그 수정 (아직 실사용 전):
-- 1) 끝났지만 아직 못 보낸 세션을 다음 세션 시작이 취소하지 않는다. 진행 중인 예약만 취소한다.
-- 2) 월요일 유예 구간에 새 주 조에 먼저 들어간 사람도 지난주 정산 결과의 등급 조로 옮긴다.

-- 끝난 예약은 제출을 기다리며 남아 있어야 하므로 '활성 하나' 유일 조건을 뺀다. 겹침은 함수 안에서 막는다.
drop index public.verified_sessions_one_active;
create index verified_sessions_open on public.verified_sessions (user_id)
  where finished_at is null and not canceled;

create or replace function public.begin_focus_v3(p_session text, p_planned_sec int)
returns timestamptz language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  found_end timestamptz;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if not exists (select 1 from public.league_members where user_id = uid) then
    raise exception 'not joined';
  end if;
  perform pg_advisory_xact_lock(hashtext('focus:' || uid::text));
  select ends_at into found_end from public.verified_sessions
    where user_id = uid and session_id = p_session;
  if found then return found_end; end if;
  update public.verified_sessions set canceled = true
    where user_id = uid and finished_at is null and not canceled and ends_at > now();
  insert into public.verified_sessions (user_id, session_id, planned_sec, ends_at)
    values (uid, p_session, p_planned_sec, now() + make_interval(secs => p_planned_sec))
    returning ends_at into found_end;
  return found_end;
end $$;

create or replace function public.league_settle_group(p_group bigint)
returns void language plpgsql security definer set search_path = public as $$
declare
  g public.league_groups;
  n int;
  up int;
  down int;
  line int;
  moved record;
begin
  select * into g from public.league_groups where id = p_group for update;
  if not found or g.settled_at is not null then return; end if;

  create temporary table scores on commit drop as
    select m.user_id,
      coalesce((select sum(d.minutes) from public.verified_daily d
                where d.user_id = m.user_id
                  and d.day >= g.week and d.day < g.week + 7), 0)::int as minutes
    from public.league_group_members m where m.group_id = p_group;
  select count(*) into n from scores;

  up := ceil(n * 0.2)::int;
  down := floor(n * 0.2)::int;
  -- 강등선: 아래에서 down+1번째 점수. 이보다 낮아야 강등이라 선 동점은 빠진다.
  select s.minutes into line from scores s order by s.minutes offset down limit 1;

  insert into public.league_results (week, user_id, rank, group_size, minutes, from_tier, to_tier)
  select g.week, r.user_id, r.top, n, r.minutes, g.tier,
    greatest(0, least(2, g.tier + case
      when n <= 3 then (case when r.minutes >= 150 then 1 else 0 end)
      when r.minutes > 0 and r.top <= up then 1
      when down > 0 and r.minutes < line then -1
      else 0 end))
  from (
    select s.user_id, s.minutes,
      rank() over (order by s.minutes desc) as top
    from scores s
  ) r
  on conflict do nothing;

  update public.league_members lm set tier = lr.to_tier
    from public.league_results lr
    where lr.week = g.week and lr.user_id = lm.user_id
      and lr.user_id in (select user_id from scores);

  -- 마감 전 유예 구간에 다음 주 조에 들어갔다면 새 등급 조로 옮긴다
  for moved in
    select m.group_id, m.user_id, m.week
    from public.league_results lr
    join public.league_group_members m on m.user_id = lr.user_id and m.week > g.week
    join public.league_groups later on later.id = m.group_id
    where lr.week = g.week and lr.user_id in (select user_id from scores)
      and later.settled_at is null and later.tier <> lr.to_tier
  loop
    delete from public.league_group_members
      where group_id = moved.group_id and user_id = moved.user_id;
    perform public.league_assign(moved.user_id, moved.week);
  end loop;

  update public.league_groups set settled_at = now() where id = p_group;
  drop table scores;
end $$;
