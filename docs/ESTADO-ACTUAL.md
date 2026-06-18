# 📌 ESTADO ACTUAL — DAS Control de Gestión Sanitaria (Pozo Almonte)

> Resumen comprimido para retomar sin perder contexto. Actualizado: 2026-06-11 (tarde).

## Qué es
App de gestión de proyectos/tareas/prioridades para la **Ilustre Municipalidad de Pozo Almonte**.
**Híbrido:** sitio estático (1 archivo HTML) + **Supabase** (Auth + Postgres + RLS + Edge Functions). Todo persiste en Supabase. Piloto ~25 usuarios.

## ✅ EN VIVO (publicado y funcionando)
- **URL pública:** `https://fabriciocespedes-bit.github.io/gestor-proyectos-DAS/`
- **Hosting:** **GitHub Pages** (gratis). Auto-deploy en cada push vía `.github/workflows/deploy-pages.yml` (publica carpeta `prototype/`).
- ⚠️ **Netlify quedó descartado** (el equipo se quedó "sin créditos" → deploys deshabilitados). Ya NO se usa.

## Repositorio
- **GitHub:** `github.com/fabriciocespedes-bit/gestor-proyectos-DAS` · rama `main` · **PÚBLICO** (necesario para Pages gratis; no contiene secretos).
- **Archivo principal (fuente de verdad):** `prototype/projectos.html`. Tras cada edición: `cp prototype/projectos.html prototype/index.html`, verificar (preview_eval), commit + push.
- App instalable como PWA: `prototype/logo-das.png` (ícono) + `prototype/manifest.json`. Título "DAS Control de Gestión Sanitaria".

## Supabase (backend, configurado)
- Proyecto **DAS-CONTROL-GESTION** · URL `https://kianrcgzpnzfmeklmjww.supabase.co` · clave pública `sb_publishable_l6vqjgK-4fDKo1MkpcBOZg_r_U7pz8v` (va en index.html, **pública por diseño**).
- **Admin maestro:** creado en Authentication. Rol admin.
- **SQL ejecutado:** `0003_app_model.sql`, `seed-piloto.sql`, `0004_prioridades_checklist.sql` (tabla `priority_items` con RLS: dueño edita, **admin lee todas**).
- **Edge Functions desplegadas (por el usuario, vía dashboard):** `crear-usuario` y `editar-usuario` (usan service_role; validan que el llamador sea admin).
- ⚠️ `service_role` NUNCA en el cliente. Sin secretos reales en el repo.

## Tablas (Supabase, snake_case)
profiles, workspaces, workspace_members, projects, project_members, tasks, subtasks, task_expenses, task_observations, task_files, meetings, meeting_attendees, events, notes, time_blocks, activities, **priority_items**.

## Roles
- **admin (Directivo) = jefe/supervisor** · **user (Funcionario)**. RLS aísla los datos.

## Funcionalidades (todo persiste en Supabase salvo lo indicado)
- **Auth real** (login/logout/restaurar sesión/cambiar contraseña real).
- **Usuarios:** crear (Edge Function `crear-usuario`, con credenciales), **editar perfil completo** (Edge Function `editar-usuario`: nombre, cargo, área, **correo y contraseña**), **cambiar rol** inline, eliminar.
- **Proyectos:** supervisor = admin/dueño; **responsables = funcionarios**. **Editar completo** (✏ Editar, formulario con todos los campos), atajos inline (estado/prioridad/presupuesto/responsables), **📦 Mover a otro espacio de trabajo** (con sus tareas), gastos→ejecución, progreso 100% al completar.
- **Espacios de trabajo:** crear, **✏ renombrar**, gestionar integrantes, eliminar, switch.
- **Tareas, Instrucciones, Kanban, Reuniones, Notas, Calendario/Eventos, Registro** (purga 7 días).
- **🧑 Personas (reemplazó Time Boxing, solo admin):** lista del equipo → clic en una persona → detalle completo (KPIs, proyectos como responsable, tareas/instrucciones, su matriz de prioridades, carga laboral).
- **🔥 Prioridades:** matriz Eisenhower. Escribir prioridades personales **en cada cuadrante** (agregar/marcar/editar/eliminar/limpiar completadas), guardadas en `priority_items`. El **jefe (admin)** tiene lista de funcionarios clickeable → ve la **matriz de cada uno (solo lectura)**. Incluye dashboard (KPIs + dona + urgencia) y guía Eisenhower.
- **Rendimiento** (admin: tarjetas+gráficos, carga/burnout jornada 44h, ranking; funcionario: "Mi rendimiento" sin carga). **Reportes** + **Exportar PDF** (Resumen Ejecutivo).
- **📅 Calendario → Google Calendar / .ics:** en Reuniones, botón **📅 Añadir a Google Calendar** (enlace oficial prellenado, gratis, sin OAuth, para cualquier usuario) + **📥 descargar .ics** (Outlook/Apple). TZ America/Santiago.
- **UI:** filtros + visibles (10/25/50) en varias secciones; modo oscuro; header institucional; chips de selección en azul institucional; **botón 🔄 Actualizar** en el header (para la app instalada/PWA).

## Pendiente / próximos pasos
1. **Correo de notificaciones** (lo siguiente que pidió el usuario): avisos de plazos/instrucciones por correo. Requiere cuenta gratuita **Resend** (100 correos/día) + Edge Function de envío + agendador (pg_cron). Código lo hace Claude; el usuario crea la cuenta.
2. (Opcional) Google Calendar **sincronización OAuth completa** (auto-push/2-vías): requiere Google Cloud + OAuth + verificación → más adelante; hoy resuelto con el enlace universal.
3. (Opcional) Dominio propio gratis para GitHub Pages; Supabase Pro (~US$25/mes) por respaldos; a futuro reescritura a Next.js.

## Flujo de trabajo
Editar projectos.html → `cp` a index.html → `preview_start name=prototype` si cayó → `preview_eval` (screenshot suele dar timeout) → commit + push (GitHub Pages publica solo en ~1 min). El usuario refresca con **🔄 / Ctrl+Shift+R / incógnito** (la app instalada cachea).
