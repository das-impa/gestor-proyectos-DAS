-- ════════════════════════════════════════════════════════════════════════
-- 0006 · Comentario de respuesta en una solicitud de extensión de plazo
--   El supervisor/asignador puede, de forma OPCIONAL, adjuntar un comentario
--   al aceptar o denegar una solicitud (queda visible para el funcionario).
-- Ejecutar en: Supabase → SQL Editor → pegar → Run.
-- ════════════════════════════════════════════════════════════════════════
alter table public.deadline_extensions
  add column if not exists response_comment text;
