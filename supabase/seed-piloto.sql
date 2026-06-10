-- ════════════════════════════════════════════════════════════════════════
-- seed-piloto.sql · Deja listo el USUARIO MAESTRO (admin) y el espacio Principal.
-- CÓMO USARLO:
--   1) En Supabase → Authentication → Users → "Add user":
--        Email: el correo del administrador  ·  Password: la que elijas
--        Marca "Auto Confirm User".
--   2) Reemplaza abajo 'TU-CORREO@ejemplo.cl' por ESE mismo correo.
--   3) Ejecuta este script en SQL Editor.
-- ════════════════════════════════════════════════════════════════════════

-- Promueve la cuenta a administrador (Directivo)
update profiles
   set role  = 'admin',
       name  = 'Administrador',
       cargo = 'Administrador del sistema',
       area  = 'Dirección'
 where email = 'TU-CORREO@ejemplo.cl';

-- Crea el espacio de trabajo primario "Principal" con el admin como líder
insert into workspaces (name, is_primary, leader_id)
select 'Principal', true, p.id
  from profiles p
 where p.email = 'TU-CORREO@ejemplo.cl'
   and not exists (select 1 from workspaces where is_primary);

-- Agrega al admin como integrante del espacio
insert into workspace_members (workspace_id, profile_id)
select w.id, p.id
  from workspaces w, profiles p
 where w.is_primary and p.email = 'TU-CORREO@ejemplo.cl'
on conflict do nothing;

-- Verificación
select p.email, p.role, w.name as espacio
  from profiles p
  left join workspace_members m on m.profile_id = p.id
  left join workspaces w on w.id = m.workspace_id
 where p.email = 'TU-CORREO@ejemplo.cl';
