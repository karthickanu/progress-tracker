-- Shared attendance log for Progress Tracker.
-- Run once in the Supabase SQL Editor for an existing project.

create table if not exists public.tracker_attendance (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  user_name text not null,
  work_date date not null,
  check_in_at timestamptz not null default now(),
  check_out_at timestamptz,
  check_in_lat double precision,
  check_in_lng double precision,
  check_in_accuracy_m double precision,
  check_out_lat double precision,
  check_out_lng double precision,
  check_out_accuracy_m double precision,
  duration_minutes integer generated always as (
    case when check_out_at is null then null
      else floor(extract(epoch from (check_out_at - check_in_at)) / 60)::integer
    end
  ) stored,
  constraint tracker_attendance_valid_checkout
    check (check_out_at is null or check_out_at >= check_in_at),
  constraint tracker_attendance_one_entry_per_day
    unique (user_id, work_date)
);

alter table public.tracker_attendance
  add column if not exists check_in_lat double precision,
  add column if not exists check_in_lng double precision,
  add column if not exists check_in_accuracy_m double precision,
  add column if not exists check_out_lat double precision,
  add column if not exists check_out_lng double precision,
  add column if not exists check_out_accuracy_m double precision;

create index if not exists tracker_attendance_date_idx
  on public.tracker_attendance(work_date desc, check_in_at desc);

alter table public.tracker_attendance enable row level security;
grant usage on schema public to authenticated;

drop policy if exists "Signed-in team can view attendance" on public.tracker_attendance;
create policy "Signed-in team can view attendance"
  on public.tracker_attendance for select to authenticated
  using (true);

drop policy if exists "Users can check in for themselves" on public.tracker_attendance;
create policy "Users can check in for themselves"
  on public.tracker_attendance for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Users can check out for themselves" on public.tracker_attendance;
create policy "Users can check out for themselves"
  on public.tracker_attendance for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select, insert, update on public.tracker_attendance to authenticated;
