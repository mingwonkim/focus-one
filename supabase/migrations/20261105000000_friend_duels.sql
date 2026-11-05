-- 친구 1:1 대결: 초대 코드(카톡 공유) → 친구 맺기 → 매주(월~일, KST) 집중 시간으로 승부.
-- 집중 시간 = daily_points.gained (서버가 인정한 분, 하루 720 상한). 비상 탈출 감점은 대결에 안 들어간다.
-- 친구 식별은 상대 초대 코드로만 (user_id 노출 안 함). 나가기(계정 삭제)하면 cascade로 사라진다.

create table public.invite_codes (
  user_id uuid primary key references auth.users on delete cascade,
  code text not null unique check (code ~ '^[A-Z2-9]{6}$')
);

create table public.friends (
  a uuid not null references auth.users on delete cascade,
  b uuid not null references auth.users on delete cascade,
  since date not null default (now() at time zone 'Asia/Seoul')::date,
  primary key (a, b),
  check (a < b)
);
create index friends_b on public.friends (b);

alter table public.invite_codes enable row level security;
alter table public.friends enable row level security; -- 정책 없음 = 함수로만

-- 내 초대 코드 (없으면 만든다). 헷갈리는 0·O·1·I 제외 6자리.
create function public.my_invite_code()
returns text language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  c text;
begin
  if uid is null then raise exception 'not signed in'; end if;
  select code into c from public.invite_codes where user_id = uid;
  if found then return c; end if;
  loop
    c := (select string_agg(substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789',
            1 + floor(random() * 32)::int, 1), '') from generate_series(1, 6));
    begin
      insert into public.invite_codes values (uid, c);
      return c;
    exception when unique_violation then
      -- 코드 충돌이면 다시, 내 행이 이미 생겼으면(동시 호출) 그걸 준다
      select code into c from public.invite_codes where user_id = uid;
      if found then return c; end if;
    end;
  end loop;
end $$;

-- 초대 수락: 상대 닉네임을 돌려준다. 둘 다 명예의 전당 참여(닉네임) 상태여야 한다.
create function public.accept_invite(p_code text)
returns text language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  other uuid;
  nick text;
begin
  if uid is null then raise exception 'not signed in'; end if;
  select user_id into other from public.invite_codes where code = upper(trim(p_code));
  if not found then raise exception 'bad code'; end if;
  if other = uid then raise exception 'own code'; end if;
  if not exists (select 1 from public.leaderboard where user_id = uid) then
    raise exception 'join first';
  end if;
  select nickname into nick from public.leaderboard where user_id = other;
  if not found then raise exception 'bad code'; end if;
  if (select count(*) from public.friends where uid in (a, b)) >= 30 then
    raise exception 'too many friends';
  end if;
  insert into public.friends (a, b) values (least(uid, other), greatest(uid, other))
    on conflict do nothing;
  perform public.my_invite_code(); -- 상대 목록에서 나를 끊을 때 쓸 코드
  return nick;
end $$;

-- 친구별 이번 주 대결 + 지난 주까지 전적. code = 상대 초대 코드(끊기용 식별자).
create function public.duels()
returns table (code text, nickname text, avatar text, total_minutes int,
               my_week int, their_week int, wins int, losses int, draws int)
language sql stable security definer set search_path = public as $$
  with me as (select auth.uid() as uid),
  cur as (select public.period_start('week') as w),
  f as (
    select case when fr.a = me.uid then fr.b else fr.a end as other,
      date_trunc('week', fr.since)::date as first_week
    from public.friends fr, me where me.uid in (fr.a, fr.b)
  ),
  weekly as ( -- 친구 맺은 주부터 사람별 주간 분
    select f.other, d.user_id, date_trunc('week', d.day)::date as w, sum(d.gained)::int as m
    from f, me
    join public.daily_points d on true
    where d.user_id in (f.other, me.uid) and d.day >= f.first_week
    group by f.other, d.user_id, date_trunc('week', d.day)
  ),
  pair as (
    select w1.other, w1.w,
      coalesce(sum(w1.m) filter (where w1.user_id = me.uid), 0) as mine,
      coalesce(sum(w1.m) filter (where w1.user_id = w1.other), 0) as theirs
    from weekly w1, me group by w1.other, w1.w
  )
  select ic.code, l.nickname, l.avatar,
    (select coalesce(sum(g.gained), 0) from public.daily_points g where g.user_id = f.other)::int,
    coalesce((select p.mine from pair p, cur where p.other = f.other and p.w = cur.w), 0)::int,
    coalesce((select p.theirs from pair p, cur where p.other = f.other and p.w = cur.w), 0)::int,
    (select count(*) from pair p, cur where p.other = f.other and p.w < cur.w and p.mine > p.theirs)::int,
    (select count(*) from pair p, cur where p.other = f.other and p.w < cur.w and p.mine < p.theirs)::int,
    (select count(*) from pair p, cur where p.other = f.other and p.w < cur.w and p.mine = p.theirs)::int
  from f
  join public.leaderboard l on l.user_id = f.other
  join public.invite_codes ic on ic.user_id = f.other
  order by l.nickname;
$$;

create function public.remove_friend(p_code text)
returns void language sql security definer set search_path = public as $$
  delete from public.friends fr
  using public.invite_codes ic
  where ic.code = p_code
    and ((fr.a = auth.uid() and fr.b = ic.user_id) or (fr.b = auth.uid() and fr.a = ic.user_id));
$$;

revoke all on function public.my_invite_code(), public.accept_invite(text), public.duels(),
  public.remove_friend(text) from public, anon;
grant execute on function public.my_invite_code(), public.accept_invite(text), public.duels(),
  public.remove_friend(text) to authenticated;
