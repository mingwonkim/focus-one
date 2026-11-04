-- 명예의 전당: 아바타(친구 id) + 이번 주/이번 달/누적 + 칭호용 누적 분 + 지난 기간 1~3위 보존.
-- 칭호는 서버가 준 total_minutes(= 인정된 집중 분 합, sum(gained))로 앱이 계산한다. 앱이 칭호를 보내지 않음(위조 방지).
-- 구 함수 시그니처는 지운다(출시 전이라 구버전 앱 호환 불필요).

alter table public.leaderboard
  add column avatar text not null default '' check (char_length(avatar) <= 16);

drop function public.submit_score(int, text);
drop function public.ranking(boolean);

create function public.submit_score(p_total int, p_nickname text, p_avatar text)
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
  insert into public.leaderboard (user_id, nickname, avatar, client_total)
    values (uid, p_nickname, coalesce(p_avatar, ''), p_total)
    on conflict (user_id) do update
      set nickname = excluded.nickname, avatar = excluded.avatar,
          client_total = excluded.client_total, updated_at = now();
end $$;

-- 기간 시작일(KST). 'all'은 아주 옛날.
create function public.period_start(p_period text, p_at timestamptz default now())
returns date language sql stable as $$
  select case p_period
    when 'week' then date_trunc('week', p_at at time zone 'Asia/Seoul')::date
    when 'month' then date_trunc('month', p_at at time zone 'Asia/Seoul')::date
    when 'all' then date '0001-01-01'
  end;
$$;

-- p_period: 'week'(월요일 시작) | 'month' | 'all'. total_minutes는 기간과 무관한 누적(칭호 기준).
create function public.ranking(p_period text)
returns table (rank bigint, nickname text, avatar text, points bigint,
               total_minutes bigint, is_me boolean)
language sql stable security definer set search_path = public as $$
  with s as (
    select l.user_id, l.nickname, l.avatar,
      coalesce(sum(d.points) filter (where d.day >= public.period_start(p_period)), 0) as points,
      coalesce(sum(d.gained), 0) as total_minutes
    from public.leaderboard l
    left join public.daily_points d on d.user_id = l.user_id
    group by l.user_id, l.nickname, l.avatar
  ), r as (
    select rank() over (order by greatest(points, 0) desc) as rank, nickname, avatar,
      greatest(points, 0) as points, total_minutes, user_id = auth.uid() as is_me
    from s
  )
  select * from r where rank <= 50 or is_me order by rank limit 51;
$$;

-- 끝난 기간의 1~3위. 나가기·닉네임 변경과 무관하게 남는다.
create table public.hall_of_fame (
  period text not null check (period in ('week', 'month')),
  period_start date not null,
  rank int not null check (rank between 1 and 3),
  nickname text not null,
  avatar text not null default '',
  points int not null,
  total_minutes int not null,
  primary key (period, period_start, rank)
);
alter table public.hall_of_fame enable row level security; -- 정책 없음 = 함수로만

-- 바로 지난 기간의 1~3위. 처음 조회한 사람이 스냅샷을 남긴다(크론 없이).
create function public.past_winners(p_period text)
returns table (rank int, nickname text, avatar text, points int, total_minutes int)
language plpgsql security definer set search_path = public as $$
declare
  cur date;
  prev date;
begin
  if p_period not in ('week', 'month') then raise exception 'bad period'; end if;
  cur := public.period_start(p_period);
  prev := case p_period when 'week' then cur - 7 else (cur - interval '1 month')::date end;
  if not exists (select 1 from public.hall_of_fame h
                 where h.period = p_period and h.period_start = prev) then
    insert into public.hall_of_fame
      select p_period, prev, w.rank, w.nickname, w.avatar, w.points, w.total_minutes
      from (
        select row_number() over (order by sum(d.points) desc, l.updated_at) as rank,
          l.nickname, l.avatar, sum(d.points)::int as points,
          (select coalesce(sum(g.gained), 0) from public.daily_points g
             where g.user_id = l.user_id and g.day < cur)::int as total_minutes
        from public.leaderboard l
        join public.daily_points d on d.user_id = l.user_id
          and d.day >= prev and d.day < cur
        group by l.user_id, l.nickname, l.avatar, l.updated_at
        having sum(d.points) > 0
      ) w
      where w.rank <= 3
      on conflict do nothing;
  end if;
  return query
    select h.rank, h.nickname, h.avatar, h.points, h.total_minutes
    from public.hall_of_fame h
    where h.period = p_period and h.period_start = prev
    order by h.rank;
end $$;

revoke all on function public.submit_score, public.ranking, public.past_winners,
  public.period_start from public, anon;
grant execute on function public.submit_score, public.ranking, public.past_winners
  to authenticated;
