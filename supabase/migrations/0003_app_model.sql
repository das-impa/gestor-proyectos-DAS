-- ════════════════════════════════════════════════════════════════════════
-- 0003_app_model.sql · DAS Control de Gestión Sanitaria (Pozo Almonte)
-- Modelo de datos que refleja el prototipo (prototype/projectos.html).
-- Single-tenant (una municipalidad) · seguridad por ROL + ESPACIO + PROYECTO.
-- Ejecutar en Supabase → SQL Editor (después de 0001/0002 o de forma autónoma).
-- ════════════════════════════════════════════════════════════════════════

-- ── Tipos ───────────────────────────────────────────────────────────────
do $$ begin
  create type app_role   as enum ('admin','user');                       -- admin=Directivo, user=Funcionario
  create type task_estado as enum ('Pendiente','En Progreso','En Revisión','Completada');
  create type prioridad_t as enum ('Alta','Media','Baja');
  create type task_origin as enum ('propia','directa','instruccion');
exception when duplicate_object then null; end $$;

-- ════════════════════════════════════════════════════════════════════════
-- PERFILES  (1:1 con auth.users)
-- ════════════════════════════════════════════════════════════════════════
create table if not exists profiles (
  id        uuid primary key references auth.users(id) on delete cascade,
  name      text not null default 'Usuario',
  email     text,
  role      app_role not null default 'user',
  area      text default 'Dirección',
  cargo     text default '',
  created_at timestamptz not null default now()
);

-- ════════════════════════════════════════════════════════════════════════
-- ESPACIOS DE TRABAJO
-- ════════════════════════════════════════════════════════════════════════
create table if not exists workspaces (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  is_primary boolean not null default false,
  leader_id  uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists workspace_members (
  workspace_id uuid references workspaces(id) on delete cascade,
  profile_id   uuid references profiles(id)   on delete cascade,
  primary key (workspace_id, profile_id)
);

-- ════════════════════════════════════════════════════════════════════════
-- PROYECTOS
-- ════════════════════════════════════════════════════════════════════════
create table if not exists projects (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  title        text not null,
  owner_id     uuid references profiles(id) on delete set null,
  estado       task_estado not null default 'Pendiente',
  prioridad    prioridad_t not null default 'Media',
  inicio       date,
  fin          date,
  presupuesto  bigint not null default 0,
  color        text default 'blue',
  etiquetas    text[] default '{}',
  descripcion  text default '',
  created_at   timestamptz not null default now()
);
create table if not exists project_members (   -- usuarios asignados al proyecto
  project_id uuid references projects(id) on delete cascade,
  profile_id uuid references profiles(id) on delete cascade,
  primary key (project_id, profile_id)
);

-- ════════════════════════════════════════════════════════════════════════
-- TAREAS / INSTRUCCIONES
-- ════════════════════════════════════════════════════════════════════════
create table if not exists tasks (
  id            uuid primary key default gen_random_uuid(),
  task_key      text,                                        -- p.ej. T-1, INS-1, D-1
  workspace_id  uuid not null references workspaces(id) on delete cascade,
  project_id    uuid references projects(id) on delete cascade,  -- null = tarea directa / instrucción
  title         text not null,
  assignee_id   uuid references profiles(id) on delete set null, -- "who"
  estado        task_estado not null default 'Pendiente',
  prioridad     prioridad_t not null default 'Media',
  vence         date,
  presupuesto   bigint not null default 0,
  col           text,                                        -- columna Kanban (Trello), distinta de estado
  done          boolean not null default false,
  origin        task_origin not null default 'propia',
  enviada_por   text,                                        -- para instrucciones
  etiquetas     text[] default '{}',
  descripcion   text default '',
  created_at    timestamptz not null default now()
);
create table if not exists subtasks (
  id        uuid primary key default gen_random_uuid(),
  task_id   uuid not null references tasks(id) on delete cascade,
  text      text not null default '',
  done      boolean not null default false,
  done_at   date,
  position  int not null default 0
);
create table if not exists task_expenses (       -- gastos → ejecución presupuestaria
  id      uuid primary key default gen_random_uuid(),
  task_id uuid not null references tasks(id) on delete cascade,
  monto   bigint not null default 0,
  descripcion text default 'Gasto',
  fecha   date not null default current_date
);
create table if not exists task_observations (   -- "_c"
  id        uuid primary key default gen_random_uuid(),
  task_id   uuid not null references tasks(id) on delete cascade,
  author_id uuid references profiles(id) on delete set null,
  author_name text,
  text      text not null,
  created_at timestamptz not null default now()
);
create table if not exists task_files (
  id          uuid primary key default gen_random_uuid(),
  task_id     uuid not null references tasks(id) on delete cascade,
  name        text not null,
  size        bigint default 0,
  storage_path text,                              -- bucket 'attachments'
  created_at  timestamptz not null default now()
);

-- ════════════════════════════════════════════════════════════════════════
-- REUNIONES · EVENTOS · NOTAS · TIME BOXING · ACTIVIDAD
-- ════════════════════════════════════════════════════════════════════════
create table if not exists meetings (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  title        text not null,
  date         date not null,
  "time"       text,
  place        text,
  notes        text,
  created_by   uuid references profiles(id) on delete set null,
  created_at   timestamptz not null default now()
);
create table if not exists meeting_attendees (
  meeting_id uuid references meetings(id) on delete cascade,
  profile_id uuid references profiles(id) on delete cascade,
  primary key (meeting_id, profile_id)
);
create table if not exists events (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  title        text not null,
  date         date not null
);
create table if not exists notes (               -- personales
  id        uuid primary key default gen_random_uuid(),
  owner_id  uuid not null references profiles(id) on delete cascade,
  title     text default '',
  body      text default '',
  updated_at timestamptz not null default now()
);
create table if not exists time_blocks (         -- personales; start/end decimales (9.5 = 9:30)
  id       uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  day      date not null,
  start_h  numeric(4,2) not null,
  end_h    numeric(4,2) not null,
  title    text default '',
  color    text default 'indigo'
);
create table if not exists activities (          -- registro; se conserva 7 días (purga programada)
  id         uuid primary key default gen_random_uuid(),
  actor_id   uuid references profiles(id) on delete set null,
  action     text not null,
  object_text text,
  created_at timestamptz not null default now()
);

-- ── Índices útiles ──────────────────────────────────────────────────────
create index if not exists idx_tasks_workspace on tasks(workspace_id);
create index if not exists idx_tasks_project   on tasks(project_id);
create index if not exists idx_tasks_assignee  on tasks(assignee_id);
create index if not exists idx_projects_ws     on projects(workspace_id);
create index if not exists idx_activities_time on activities(created_at);

-- ════════════════════════════════════════════════════════════════════════
-- HELPERS DE SEGURIDAD  (SECURITY DEFINER → ignoran RLS al consultar membresía)
-- ════════════════════════════════════════════════════════════════════════
create or replace function is_admin() returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from profiles where id = auth.uid() and role = 'admin');
$$;
create or replace function is_ws_member(ws uuid) returns boolean language sql stable security definer set search_path=public as $$
  select is_admin() or exists(select 1 from workspace_members m where m.workspace_id = ws and m.profile_id = auth.uid());
$$;
create or replace function is_project_member(pr uuid) returns boolean language sql stable security definer set search_path=public as $$
  select is_admin()
      or exists(select 1 from projects p where p.id = pr and p.owner_id = auth.uid())
      or exists(select 1 from project_members pm where pm.project_id = pr and pm.profile_id = auth.uid());
$$;

-- ── Alta automática de perfil al registrarse en Auth ───────────────────
create or replace function handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles (id, name, email, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'name','Usuario'), new.email,
          coalesce((new.raw_user_meta_data->>'role')::app_role,'user'))
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();

-- ── Purga de actividad > 7 días (llamar por pg_cron o Edge Function) ────
create or replace function purge_activities() returns void language sql as $$
  delete from activities where created_at < now() - interval '7 days';
$$;

-- ════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ════════════════════════════════════════════════════════════════════════
alter table profiles          enable row level security;
alter table workspaces        enable row level security;
alter table workspace_members enable row level security;
alter table projects          enable row level security;
alter table project_members   enable row level security;
alter table tasks             enable row level security;
alter table subtasks          enable row level security;
alter table task_expenses     enable row level security;
alter table task_observations enable row level security;
alter table task_files        enable row level security;
alter table meetings          enable row level security;
alter table meeting_attendees enable row level security;
alter table events            enable row level security;
alter table notes             enable row level security;
alter table time_blocks       enable row level security;
alter table activities        enable row level security;

-- PERFILES: te ves a ti; admin ve a todos; ves a quien comparte espacio.
create policy profiles_read on profiles for select using (
  id = auth.uid() or is_admin()
  or exists(select 1 from workspace_members me join workspace_members ot
            on me.workspace_id = ot.workspace_id
            where me.profile_id = auth.uid() and ot.profile_id = profiles.id));
create policy profiles_self_update on profiles for update using (id = auth.uid());
create policy profiles_admin_all   on profiles for all using (is_admin()) with check (is_admin());

-- ESPACIOS: ves los que integras; solo admin/líder los gestiona.
create policy ws_read   on workspaces for select using (is_ws_member(id));
create policy ws_write  on workspaces for all using (is_admin() or leader_id = auth.uid())
                                       with check (is_admin() or leader_id = auth.uid());
create policy wsm_read  on workspace_members for select using (is_ws_member(workspace_id));
create policy wsm_write on workspace_members for all using (is_admin() or exists(
  select 1 from workspaces w where w.id = workspace_id and w.leader_id = auth.uid()))
  with check (is_admin() or exists(select 1 from workspaces w where w.id = workspace_id and w.leader_id = auth.uid()));

-- PROYECTOS: visibles si participas o compartes el espacio; edita admin/dueño/asignado.
create policy proj_read   on projects for select using (is_ws_member(workspace_id) and (is_admin() or owner_id = auth.uid() or is_project_member(id) or is_ws_member(workspace_id)));
create policy proj_write  on projects for all using (is_admin() or owner_id = auth.uid() or is_project_member(id))
                                       with check (is_ws_member(workspace_id));
create policy pm_read     on project_members for select using (is_project_member(project_id));
create policy pm_write    on project_members for all using (is_admin() or exists(
  select 1 from projects p where p.id = project_id and p.owner_id = auth.uid()))
  with check (is_admin() or exists(select 1 from projects p where p.id = project_id and p.owner_id = auth.uid()));

-- TAREAS: admin ve todo el espacio; el funcionario ve las suyas.
create policy task_read  on tasks for select using (is_ws_member(workspace_id) and (is_admin() or assignee_id = auth.uid() or (project_id is not null and is_project_member(project_id))));
create policy task_write on tasks for all using (is_admin() or assignee_id = auth.uid() or (project_id is not null and is_project_member(project_id)))
                                    with check (is_ws_member(workspace_id));

-- Hijos de tarea: heredan el acceso de la tarea.
create policy sub_all  on subtasks         for all using (exists(select 1 from tasks t where t.id=task_id and (is_admin() or t.assignee_id=auth.uid() or (t.project_id is not null and is_project_member(t.project_id))))) with check (true);
create policy exp_all  on task_expenses    for all using (exists(select 1 from tasks t where t.id=task_id and (is_admin() or t.assignee_id=auth.uid() or (t.project_id is not null and is_project_member(t.project_id))))) with check (true);
create policy obs_all  on task_observations for all using (exists(select 1 from tasks t where t.id=task_id and (is_admin() or t.assignee_id=auth.uid() or (t.project_id is not null and is_project_member(t.project_id))))) with check (true);
create policy file_all on task_files       for all using (exists(select 1 from tasks t where t.id=task_id and (is_admin() or t.assignee_id=auth.uid() or (t.project_id is not null and is_project_member(t.project_id))))) with check (true);

-- REUNIONES / EVENTOS: por espacio.
create policy meet_read  on meetings for select using (is_ws_member(workspace_id));
create policy meet_write on meetings for all using (is_admin() or created_by = auth.uid() or exists(
  select 1 from workspaces w where w.id = workspace_id and w.leader_id = auth.uid())) with check (is_ws_member(workspace_id));
create policy matt_all   on meeting_attendees for all using (exists(select 1 from meetings m where m.id=meeting_id and is_ws_member(m.workspace_id))) with check (true);
create policy ev_read    on events for select using (is_ws_member(workspace_id));
create policy ev_write   on events for all using (is_ws_member(workspace_id)) with check (is_ws_member(workspace_id));

-- NOTAS / TIME BOXING: estrictamente personales.
create policy notes_all on notes       for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy tb_all    on time_blocks for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- ACTIVIDAD: lectura para miembros autenticados; inserta cualquiera autenticado.
create policy act_read   on activities for select using (auth.uid() is not null);
create policy act_insert on activities for insert with check (auth.uid() is not null);

-- ════════════════════════════════════════════════════════════════════════
-- FIN 0003_app_model.sql
-- ════════════════════════════════════════════════════════════════════════
