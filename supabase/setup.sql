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
