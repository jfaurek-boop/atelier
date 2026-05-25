-- Atelier: espacios de trabajo compartidos
-- Ejecutar completo en Supabase SQL Editor.

create table if not exists public.atelier_workspaces (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'Atelier',
  state jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.atelier_workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.atelier_workspaces(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  email text not null,
  role text not null default 'editor' check (role in ('owner', 'editor', 'viewer')),
  created_at timestamptz not null default now(),
  unique (workspace_id, email)
);

alter table public.atelier_workspaces enable row level security;
alter table public.atelier_workspace_members enable row level security;

create or replace function public.atelier_current_email()
returns text
language sql
stable
as $$
  select lower(coalesce(auth.jwt() ->> 'email', ''));
$$;

create or replace function public.atelier_is_workspace_member(target_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.atelier_workspace_members m
    where m.workspace_id = target_workspace_id
      and (
        m.user_id = auth.uid()
        or lower(m.email) = public.atelier_current_email()
      )
  );
$$;

create or replace function public.atelier_workspace_role(target_workspace_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select m.role
  from public.atelier_workspace_members m
  where m.workspace_id = target_workspace_id
    and (
      m.user_id = auth.uid()
      or lower(m.email) = public.atelier_current_email()
    )
  order by case m.role when 'owner' then 1 when 'editor' then 2 else 3 end
  limit 1;
$$;

drop policy if exists "Atelier members can read workspaces" on public.atelier_workspaces;
create policy "Atelier members can read workspaces"
  on public.atelier_workspaces
  for select
  to authenticated
  using (public.atelier_is_workspace_member(id));

drop policy if exists "Atelier owners can insert workspaces" on public.atelier_workspaces;
create policy "Atelier owners can insert workspaces"
  on public.atelier_workspaces
  for insert
  to authenticated
  with check (auth.uid() = owner_id);

drop policy if exists "Atelier editors can update workspaces" on public.atelier_workspaces;
create policy "Atelier editors can update workspaces"
  on public.atelier_workspaces
  for update
  to authenticated
  using (public.atelier_workspace_role(id) in ('owner', 'editor'))
  with check (public.atelier_workspace_role(id) in ('owner', 'editor'));

drop policy if exists "Atelier members can read members" on public.atelier_workspace_members;
create policy "Atelier members can read members"
  on public.atelier_workspace_members
  for select
  to authenticated
  using (public.atelier_is_workspace_member(workspace_id));

drop policy if exists "Atelier owners can manage members" on public.atelier_workspace_members;
create policy "Atelier owners can manage members"
  on public.atelier_workspace_members
  for all
  to authenticated
  using (public.atelier_workspace_role(workspace_id) = 'owner')
  with check (public.atelier_workspace_role(workspace_id) = 'owner');

create or replace function public.set_atelier_workspace_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_atelier_workspace_updated_at on public.atelier_workspaces;
create trigger set_atelier_workspace_updated_at
  before update on public.atelier_workspaces
  for each row
  execute function public.set_atelier_workspace_updated_at();

create or replace function public.create_atelier_workspace(workspace_name text, initial_state jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_workspace_id uuid;
  current_email text;
begin
  if auth.uid() is null then
    raise exception 'Debes iniciar sesion.';
  end if;

  current_email := public.atelier_current_email();

  insert into public.atelier_workspaces (owner_id, name, state)
  values (auth.uid(), coalesce(nullif(trim(workspace_name), ''), 'Atelier'), coalesce(initial_state, '{}'::jsonb))
  returning id into new_workspace_id;

  insert into public.atelier_workspace_members (workspace_id, user_id, email, role)
  values (new_workspace_id, auth.uid(), current_email, 'owner');

  return new_workspace_id;
end;
$$;

create or replace function public.invite_atelier_member(target_workspace_id uuid, member_email text, member_role text default 'editor')
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_email text;
  normalized_role text;
begin
  if public.atelier_workspace_role(target_workspace_id) <> 'owner' then
    raise exception 'Solo el propietario puede invitar miembros.';
  end if;

  normalized_email := lower(trim(member_email));
  if normalized_email = '' then
    raise exception 'El correo es obligatorio.';
  end if;

  normalized_role := case when member_role in ('editor', 'viewer') then member_role else 'editor' end;

  insert into public.atelier_workspace_members (workspace_id, email, role)
  values (target_workspace_id, normalized_email, normalized_role)
  on conflict (workspace_id, email)
  do update set role = excluded.role;
end;
$$;
