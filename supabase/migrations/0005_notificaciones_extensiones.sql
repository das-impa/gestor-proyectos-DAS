-- ════════════════════════════════════════════════════════════════════════
-- 0005 · Notificaciones internas + Solicitudes de extensión de plazo
--   • notifications:        alertas dentro de la plataforma (por vencer / vencido
--                           / solicitud de extensión / aprobada / denegada).
--   • deadline_extensions:  flujo de solicitud de prórroga de plazo de una
--                           tarea/instrucción/proyecto y su aprobación/denegación.
-- Requiere la función is_admin() creada en 0003_app_model.sql.
-- Ejecutar en: Supabase → SQL Editor → pegar todo → Run.
-- ════════════════════════════════════════════════════════════════════════

-- ── Tabla: notifications ────────────────────────────────────────────────
create table if not exists public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  kind        text not null,                 -- due | overdue | ext_request | ext_approved | ext_denied
  item_type   text,                          -- task | instruccion | project
  item_id     uuid,
  ref_id      uuid,                          -- id de la solicitud (deadline_extensions) para kind ext_*
  title       text,
  message     text,
  dedupe_key  text unique,                   -- evita duplicar una misma alerta
  read        boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists notifications_user_idx on public.notifications(user_id, read);

alter table public.notifications enable row level security;

drop policy if exists notif_select on public.notifications;
create policy notif_select on public.notifications
  for select using (user_id = auth.uid() or public.is_admin());

-- Cualquier usuario autenticado puede crear una notificación dirigida a otro
-- (necesario: el sistema avisa al asignado, y el aprobador/solicitante entre sí).
drop policy if exists notif_insert on public.notifications;
create policy notif_insert on public.notifications
  for insert to authenticated with check (auth.uid() is not null);

drop policy if exists notif_update on public.notifications;
create policy notif_update on public.notifications
  for update using (user_id = auth.uid() or public.is_admin());

drop policy if exists notif_delete on public.notifications;
create policy notif_delete on public.notifications
  for delete using (user_id = auth.uid() or public.is_admin());

-- ── Tabla: deadline_extensions ──────────────────────────────────────────
create table if not exists public.deadline_extensions (
  id            uuid primary key default gen_random_uuid(),
  item_type     text not null,               -- task | project  (instrucción usa task)
  item_id       uuid not null,
  title         text,
  requester_id  uuid references public.profiles(id) on delete set null,
  approver_id   uuid references public.profiles(id) on delete set null,
  current_due   date,
  requested_due date,
  reason        text,
  status        text not null default 'pending',  -- pending | approved | denied
  created_at    timestamptz not null default now(),
  resolved_at   timestamptz
);
create index if not exists ext_approver_idx on public.deadline_extensions(approver_id, status);
create index if not exists ext_requester_idx on public.deadline_extensions(requester_id, status);

alter table public.deadline_extensions enable row level security;

drop policy if exists ext_select on public.deadline_extensions;
create policy ext_select on public.deadline_extensions
  for select using (
    requester_id = auth.uid() or approver_id = auth.uid() or public.is_admin()
  );

drop policy if exists ext_insert on public.deadline_extensions;
create policy ext_insert on public.deadline_extensions
  for insert to authenticated
  with check (requester_id = auth.uid() or public.is_admin());

drop policy if exists ext_update on public.deadline_extensions;
create policy ext_update on public.deadline_extensions
  for update using (approver_id = auth.uid() or public.is_admin());

drop policy if exists ext_delete on public.deadline_extensions;
create policy ext_delete on public.deadline_extensions
  for delete using (approver_id = auth.uid() or public.is_admin());
