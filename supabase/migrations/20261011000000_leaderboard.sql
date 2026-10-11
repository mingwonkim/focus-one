-- 랭킹: 익명 계정 + 닉네임. 테이블은 직접 못 읽고 함수로만 (user_id 노출 안 함).
-- 점수 = 앱의 rankScore(모은 물방울 − 비상 탈출 사용분). 서버는 직전 제출과의 차이만 반영한다.
-- 부정 방지: 하루(KST) 최대 +720(12시간), 직전 제출 뒤 흐른 분보다 많이 오를 수 없음.

create table public.leaderboard (
  user_id uuid primary key references auth.users on delete cascade,
  nickname text not null check (char_length(nickname) between 1 and 12),
  client_total int not null default 0, -- 앱이 마지막으로 보낸 rankScore
  updated_at timestamptz not null default now()
);

create table public.daily_points (
  user_id uuid references auth.users on delete cascade,
  day date not null,
  points int not null default 0, -- 비상 탈출이면 음수 반영
  gained int not null default 0 check (gained between 0 and 720), -- 오늘 오른 양(상한 판정)
  primary key (user_id, day)
);

alter table public.leaderboard enable row level security;
alter table public.daily_points enable row level security;
-- 정책 없음 = 클라이언트 직접 접근 불가. 아래 security definer 함수로만.

create function public.submit_score(p_total int, p_nickname text)
returns void language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  today date := (now() at time zone 'Asia/Seoul')::date;
  prev public.leaderboard;
  delta int;
  room int;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if p_total < 0 then raise exception 'bad total'; end if;
  select * into prev from public.leaderboard where user_id = uid for update;
  if not found then
    delta := p_total; -- 첫 참여: 지금까지 점수를 오늘 상한 안에서
  else
    delta := p_total - prev.client_total;
    if delta > 0 then
      delta := least(delta,
        ceil(extract(epoch from now() - prev.updated_at) / 60)::int);
    end if;
  end if;
  insert into public.daily_points (user_id, day) values (uid, today)
    on conflict do nothing;
  if delta > 0 then
    select 720 - gained into room from public.daily_points
      where user_id = uid and day = today;
    delta := least(delta, room);
    update public.daily_points set points = points + delta, gained = gained + delta
      where user_id = uid and day = today;
  elsif delta < 0 then
    update public.daily_points set points = points + delta
      where user_id = uid and day = today;
  end if;
  insert into public.leaderboard (user_id, nickname, client_total)
    values (uid, p_nickname, p_total)
    on conflict (user_id) do update
      set nickname = excluded.nickname, client_total = excluded.client_total,
          updated_at = now();
end $$;

-- p_week: true = 이번 주(월요일 시작, KST), false = 누적
create function public.ranking(p_week boolean)
returns table (rank bigint, nickname text, points bigint, is_me boolean)
language sql stable security definer set search_path = public as $$
  with s as (
    select l.user_id, l.nickname, coalesce(sum(d.points), 0) as points
    from public.leaderboard l
    left join public.daily_points d on d.user_id = l.user_id
      and (not p_week or d.day >= date_trunc('week', now() at time zone 'Asia/Seoul')::date)
    group by l.user_id, l.nickname
  ), r as (
    select rank() over (order by greatest(points, 0) desc) as rank, nickname,
      greatest(points, 0) as points, user_id = auth.uid() as is_me
    from s
  )
  select * from r where rank <= 50 or is_me order by rank limit 51;
$$;

-- 랭킹에서 나가기: 내 기록 전부 삭제
create function public.leave_ranking()
returns void language sql security definer set search_path = public as $$
  delete from public.daily_points where user_id = auth.uid();
  delete from public.leaderboard where user_id = auth.uid();
$$;

revoke all on function public.submit_score, public.ranking, public.leave_ranking from public, anon;
grant execute on function public.submit_score, public.ranking, public.leave_ranking to authenticated;
