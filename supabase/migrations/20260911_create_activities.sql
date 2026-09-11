-- Proposed Supabase migration for temporary student-created map activities.
--
-- The current Flutter project proves that authenticated users have auth IDs and
-- that a public.profiles table contains a role. It does not include the
-- profiles schema or policies, so this table deliberately references the
-- authoritative auth.users table rather than assuming additional profile
-- columns exist.

create table public.activities (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 120),
  description text check (description is null or char_length(description) <= 2000),
  -- Stored category IDs are defined in Flutter's ActivityCategory class.
  category text not null check (char_length(trim(category)) between 1 and 80),
  campus text not null check (campus in ('edinburg', 'brownsville')),
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  indoor_outdoor text check (indoor_outdoor is null or indoor_outdoor in ('indoor', 'outdoor')),
  building text,
  floor text,
  room_or_area text,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint activities_valid_time_range check (ends_at > starts_at),
  -- A one-day maximum keeps map entries temporary. Adjust this product rule
  -- before deployment if the team chooses a different duration limit.
  constraint activities_maximum_duration check (ends_at <= starts_at + interval '1 day')
);

create index activities_active_map_index
  on public.activities (campus, starts_at, ends_at)
  where cancelled_at is null;

create or replace function public.set_activities_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.prevent_activity_owner_change()
returns trigger
language plpgsql
as $$
begin
  if new.creator_id is distinct from old.creator_id then
    raise exception 'Activity ownership cannot be changed';
  end if;
  return new;
end;
$$;

create trigger set_activities_updated_at
before update on public.activities
for each row execute function public.set_activities_updated_at();

create trigger prevent_activity_owner_change
before update on public.activities
for each row execute function public.prevent_activity_owner_change();

alter table public.activities enable row level security;

-- Any signed-in user may see activities that are currently active. A creator
-- may also see their own cancelled or expired records for future "My
-- activities" functionality.
create policy "Authenticated users read active activities or their own"
on public.activities
for select
to authenticated
using (
  (cancelled_at is null and starts_at <= now() and ends_at > now())
  or creator_id = auth.uid()
);

-- creator_id defaults to auth.uid(), and this check prevents a client from
-- creating an activity owned by anyone else.
create policy "Users create their own activities"
on public.activities
for insert
to authenticated
with check (creator_id = auth.uid());

-- There is intentionally no delete policy: cancellation preserves activity
-- history. The ownership trigger above prevents changing creator_id.
create policy "Users update only their own activities"
on public.activities
for update
to authenticated
using (creator_id = auth.uid())
with check (creator_id = auth.uid());
