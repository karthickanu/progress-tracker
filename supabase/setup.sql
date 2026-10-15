-- Progress Tracker shared workspace schema.
-- Run in the Supabase SQL Editor for a new project.

create table if not exists public.tracker_sheets (
  id text primary key,
  name text not null,
  headers jsonb not null default '[]'::jsonb,
  active_sheet text not null,
  header_row integer not null default 1,
  source_path text not null,
  created_at timestamptz not null default now(),
  created_by text not null
);

create table if not exists public.tracker_tasks (
  id text primary key,
  sheet_id text not null references public.tracker_sheets(id) on delete cascade,
  position integer not null,
  source_row integer not null,
  task_values jsonb not null default '[]'::jsonb,
  done boolean not null default false,
  updated_by text not null default '',
  updated_at timestamptz
);

create index if not exists tracker_tasks_sheet_position_idx
  on public.tracker_tasks(sheet_id, position);

alter table public.tracker_sheets enable row level security;
alter table public.tracker_tasks enable row level security;
grant usage on schema public to authenticated;

drop policy if exists "Signed-in team can use tracker sheets" on public.tracker_sheets;
create policy "Signed-in team can use tracker sheets"
  on public.tracker_sheets for all to authenticated
  using (true) with check (true);

drop policy if exists "Signed-in team can use tracker tasks" on public.tracker_tasks;
create policy "Signed-in team can use tracker tasks"
  on public.tracker_tasks for all to authenticated
  using (true) with check (true);

grant select, insert, update, delete on public.tracker_sheets to authenticated;
grant select, insert, update, delete on public.tracker_tasks to authenticated;

insert into storage.buckets (id, name, public, file_size_limit)
values ('tracker-uploads', 'tracker-uploads', false, 15728640)
on conflict (id) do update set public = false, file_size_limit = 15728640;

drop policy if exists "Signed-in team can read tracker uploads" on storage.objects;
create policy "Signed-in team can read tracker uploads"
  on storage.objects for select to authenticated
  using (bucket_id = 'tracker-uploads');

drop policy if exists "Signed-in team can upload tracker files" on storage.objects;
create policy "Signed-in team can upload tracker files"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'tracker-uploads');

drop policy if exists "Signed-in team can delete tracker files" on storage.objects;
create policy "Signed-in team can delete tracker files"
  on storage.objects for delete to authenticated
  using (bucket_id = 'tracker-uploads');


-- Shared attendance log for Progress Tracker.
-- Run once in the Supabase SQL Editor for an existing project.

create table if not exists public.tracker_attendance (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  user_name text not null,
  work_date date not null,
  check_in_at timestamptz not null default now(),
  check_out_at timestamptz,
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
