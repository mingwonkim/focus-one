-- 주간 리그: 3등급(0 산책·1 탐험·2 항해), 조당 최대 10명, 월요일 00시(KST) 경계, 크론 없이 조회·제출 때 지연 정산.
-- 점수는 서버가 시각을 잰 검증 세션만. 앱이 보낸 숫자는 믿지 않는다. 구 submit_score·ranking·daily_points와 섞지 않는다.
-- 서버는 실제 집중이나 앱 잠금 준수를 증명하지 못한다: 시작~예정 종료 시각이 지났다는 것만 안다.

create table public.league_members (
  user_id uuid primary key references auth.users on delete cascade,
  tier smallint not null default 0 check (tier between 0 and 2),
  joined_at timestamptz not null default now()
);

create table public.verified_sessions (
  user_id uuid not null references auth.users on delete cascade,
  session_id text not null check (char_length(session_id) between 1 and 40),
  planned_sec int not null check (planned_sec between 600 and 10800 and planned_sec % 300 = 0),
  started_at timestamptz not null default now(),
  ends_at timestamptz not null,
  finished_at timestamptz,
  canceled boolean not null default false,
  counted_minutes int not null default 0,
  primary key (user_id, session_id)
);
-- 활성 예약은 사용자당 하나 (겹침 차단)
create unique index verified_sessions_one_active on public.verified_sessions (user_id)
  where finished_at is null and not canceled;

create table public.verified_daily (
  user_id uuid not null references auth.users on delete cascade,
  day date not null,
  minutes int not null default 0 check (minutes between 0 and 720),
  primary key (user_id, day)
);

create table public.league_groups (
  id bigint generated always as identity primary key,
  week date not null check (extract(isodow from week) = 1),
  tier smallint not null check (tier between 0 and 2),
  settled_at timestamptz
);
create index league_groups_unsettled on public.league_groups (week) where settled_at is null;
create index league_groups_week_tier on public.league_groups (week, tier);

create table public.league_group_members (
  group_id bigint not null references public.league_groups on delete cascade,
  week date not null,
  user_id uuid not null references auth.users on delete cascade,
  primary key (group_id, user_id),
  unique (week, user_id)
);

create table public.league_results (
  week date not null,
  user_id uuid not null references auth.users on delete cascade,
  rank int not null,
  group_size int not null,
  minutes int not null,
  from_tier smallint not null,
  to_tier smallint not null,
  primary key (week, user_id)
);

alter table public.league_members enable row level security;
alter table public.verified_sessions enable row level security;
alter table public.verified_daily enable row level security;
alter table public.league_groups enable row level security;
alter table public.league_group_members enable row level security;
alter table public.league_results enable row level security;
-- 정책 없음 = 함수로만

create function public.league_week(p_at timestamptz default now())
returns date language sql stable as $$
  select date_trunc('week', p_at at time zone 'Asia/Seoul')::date;
$$;

-- 그 주 세션을 제출할 수 있는 마지막 시각: 다음 월요일 00:10 KST
create function public.league_deadline(p_week date)
returns timestamptz language sql immutable as $$
  select ((p_week + 7)::timestamp + interval '10 minutes') at time zone 'Asia/Seoul';
$$;

-- 조 하나 정산. 조를 잠그고 settled_at을 보므로 동시에 불려도 한 번만 처리된다.
-- 4명 이상: 상위 ceil(20%) 승급(선 동점 전원), 하위 floor(20%) 강등(선 동점 제외).
-- 1~3명: 150분 달성 시 승급, 강등 없음. 등급 끝을 넘지는 않는다.
create function public.league_settle_group(p_group bigint)
returns void language plpgsql security definer set search_path = public as $$
declare
  g public.league_groups;
  n int;
  up int;
  down int;
  line int;
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

  update public.league_groups set settled_at = now() where id = p_group;
  drop table scores;
end $$;

-- 마감이 지난 조를 오래된 순으로 정산
create function public.league_settle_due()
returns void language plpgsql security definer set search_path = public as $$
declare
  gid bigint;
begin
  for gid in
    select id from public.league_groups
    where settled_at is null and public.league_deadline(week) <= now()
    order by week, id
  loop
    perform public.league_settle_group(gid);
  end loop;
end $$;

-- 이번 주 첫 검증 완료 때 같은 등급의 빈 조에 넣는다. 재편성 없음.
create function public.league_assign(p_user uuid, p_week date)
returns void language plpgsql security definer set search_path = public as $$
declare
  t smallint;
  gid bigint;
begin
  select tier into t from public.league_members where user_id = p_user;
  if not found then return; end if;
  if exists (select 1 from public.league_group_members
             where week = p_week and user_id = p_user) then return; end if;
  perform pg_advisory_xact_lock(hashtext('league:' || p_week || ':' || t));
  select g.id into gid from public.league_groups g
    where g.week = p_week and g.tier = t
      and (select count(*) from public.league_group_members m where m.group_id = g.id) < 10
    order by g.id limit 1;
  if gid is null then
    insert into public.league_groups (week, tier) values (p_week, t) returning id into gid;
  end if;
  insert into public.league_group_members (group_id, week, user_id)
    values (gid, p_week, p_user) on conflict do nothing;
end $$;

-- 명예의 전당 닉네임이 있어야 참여할 수 있다 (목록에 이름이 보이므로)
create function public.join_league()
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if not exists (select 1 from public.leaderboard where user_id = auth.uid()) then
    raise exception 'join first';
  end if;
  insert into public.league_members (user_id) values (auth.uid()) on conflict do nothing;
end $$;

-- 등급은 지운다. 지난 결과는 본인 기록으로 남고, 계정을 지우면 함께 지워진다.
create function public.leave_league()
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  delete from public.league_group_members m using public.league_groups g
    where m.group_id = g.id and g.settled_at is null and m.user_id = auth.uid();
  delete from public.league_members where user_id = auth.uid();
end $$;

-- 집중 시작 예약. 같은 id면 그대로(재시도 안전), 다른 id면 이전 예약을 취소한다.
create function public.begin_focus_v3(p_session text, p_planned_sec int)
returns timestamptz language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  found_end timestamptz;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if not exists (select 1 from public.league_members where user_id = uid) then
    raise exception 'not joined';
  end if;
  select ends_at into found_end from public.verified_sessions
    where user_id = uid and session_id = p_session;
  if found then return found_end; end if;
  update public.verified_sessions set canceled = true
    where user_id = uid and finished_at is null and not canceled;
  insert into public.verified_sessions (user_id, session_id, planned_sec, ends_at)
    values (uid, p_session, p_planned_sec, now() + make_interval(secs => p_planned_sec))
    returning ends_at into found_end;
  return found_end;
end $$;

-- 집중 완료 제출. 서버 종료 시각 이후만, 하루 720분 상한, 같은 세션은 한 번만.
-- 앱이 시작 신호를 조금 늦게 보내므로 30초 일찍 온 건 받아 준다.
-- 돌려주는 값: 인정된 분. 예약이 없거나 취소됐거나 마감이 지났으면 0(개인 성장만 남음).
create function public.finish_focus_v3(p_session text)
returns int language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  s public.verified_sessions;
  d date;
  wk date;
  room int;
  counted int;
begin
  if uid is null then raise exception 'not signed in'; end if;
  perform public.league_settle_due();
  select * into s from public.verified_sessions
    where user_id = uid and session_id = p_session for update;
  if not found or s.canceled then return 0; end if;
  if s.finished_at is not null then return s.counted_minutes; end if;
  if now() < s.ends_at - interval '30 seconds' then raise exception 'too early'; end if;

  d := (s.ends_at at time zone 'Asia/Seoul')::date;
  wk := public.league_week(s.ends_at);
  counted := 0;
  if now() <= public.league_deadline(wk)
     and exists (select 1 from public.league_members where user_id = uid) then
    insert into public.verified_daily (user_id, day) values (uid, d) on conflict do nothing;
    select 720 - minutes into room from public.verified_daily
      where user_id = uid and day = d for update;
    counted := least(s.planned_sec / 60, room);
    update public.verified_daily set minutes = minutes + counted
      where user_id = uid and day = d;
    perform public.league_assign(uid, wk);
  end if;
  update public.verified_sessions
    set finished_at = now(), counted_minutes = counted
    where user_id = uid and session_id = p_session;
  return counted;
end $$;

-- 리그 화면 한 번에: 참여 여부·등급·이번 주 조·지난 결과. user_id는 내보내지 않는다.
create function public.league_status()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  t smallint;
  wk date := public.league_week();
  gid bigint;
  board jsonb;
  last_result jsonb;
begin
  if uid is null then raise exception 'not signed in'; end if;
  perform public.league_settle_due();
  select tier into t from public.league_members where user_id = uid;
  if not found then return jsonb_build_object('joined', false); end if;

  select group_id into gid from public.league_group_members
    where week = wk and user_id = uid;
  if gid is not null then
    select jsonb_agg(x order by x.rank) into board from (
      select rank() over (order by coalesce(v.minutes, 0) desc) as rank,
        l.nickname, l.avatar,
        coalesce(v.minutes, 0) as minutes,
        (select coalesce(sum(p.gained), 0) from public.daily_points p
           where p.user_id = m.user_id) as total_minutes,
        m.user_id = uid as is_me
      from public.league_group_members m
      join public.leaderboard l on l.user_id = m.user_id
      left join lateral (
        select sum(d.minutes)::int as minutes from public.verified_daily d
        where d.user_id = m.user_id and d.day >= wk and d.day < wk + 7
      ) v on true
      where m.group_id = gid
    ) x;
  end if;

  select jsonb_build_object('week', r.week, 'rank', r.rank, 'group_size', r.group_size,
      'minutes', r.minutes, 'from_tier', r.from_tier, 'to_tier', r.to_tier)
    into last_result
    from public.league_results r where r.user_id = uid
    order by r.week desc limit 1;

  return jsonb_build_object(
    'joined', true,
    'tier', t,
    'week', wk,
    'board', coalesce(board, '[]'::jsonb),
    'last_result', last_result
  );
end $$;

revoke all on function
  public.league_week(timestamptz), public.league_deadline(date),
  public.league_settle_group(bigint), public.league_settle_due(),
  public.league_assign(uuid, date), public.join_league(), public.leave_league(),
  public.begin_focus_v3(text, int), public.finish_focus_v3(text), public.league_status()
  from public, anon, authenticated;
grant execute on function
  public.join_league(), public.leave_league(),
  public.begin_focus_v3(text, int), public.finish_focus_v3(text), public.league_status()
  to authenticated;
