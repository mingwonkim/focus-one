-- 랭킹에서 나가기 = 익명 계정까지 완전히 삭제 (App Store 5.1.1(v) 계정 삭제).
-- auth.users 행을 지우면 leaderboard·daily_points는 on delete cascade로 함께 지워진다.
create or replace function public.leave_ranking()
returns void language sql security definer set search_path = public as $$
  delete from auth.users where id = auth.uid();
$$;
