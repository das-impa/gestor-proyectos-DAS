-- ════════════════════════════════════════════════════════════════════════
-- 0007 · Nombre de pila personal (display_name)
--   El nombre OFICIAL (profiles.name) lo asigna el administrador al crear el
--   usuario y solo él lo edita (sección Usuarios). Cada persona puede definir
--   un "nombre de pila" para su propia visualización (su chip de cabecera),
--   sin afectar el nombre oficial que ven los demás ni los reportes.
-- Ejecutar en: Supabase → SQL Editor → pegar → Run.
-- ════════════════════════════════════════════════════════════════════════
alter table public.profiles
  add column if not exists display_name text;
