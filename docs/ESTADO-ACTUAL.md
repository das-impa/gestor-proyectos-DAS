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
- ✅ `0005_notificaciones_extensiones.sql` ejecutado (tablas `notifications` + `deadline_extensions`).
- ⚠️ **PENDIENTE de ejecutar (SQL):** `0006_extension_comentario.sql` (`response_comment`) · `0007_display_name.sql` (`profiles.display_name`).
- ⚠️ **PENDIENTE de desplegar (Edge Function):** `recuperar-clave` (resetea contraseña a `123456` desde el login; service_role; sin auth del llamador).
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
1. ✅ **Correo de notificaciones — LISTO (EmailJS, gratis).** Al crear una **instrucción**, se envía automáticamente un correo al funcionario (desde el Gmail institucional `fabricio.cespedes@cormudespa.cl`). Config pública en `index.html`: `EMAILJS_SERVICE_ID='service_s6qxmqd'`, `EMAILJS_TEMPLATE_ID='template_n2irt7h'`, `EMAILJS_PUBLIC_KEY='svCCRc_RyvR4r-GOK'` (los 3 son públicos/seguros). Plantilla EmailJS usa `{{subject}}`, `{{message}}`, `{{to_email}}`. Funciones: `mailReady()`, `enviarCorreo(toEmail,toName,subject,message)`, `memberEmail(id)`. Requisito: el funcionario debe tener **correo cargado** en su perfil. Límite plan gratis EmailJS ~200/mes.
   - Notificación por correo también al **crear/designar tarea**, **crear proyecto** (a cada responsable) y **crear cuenta de usuario** (correo de bienvenida con credenciales + link).
2. ✅ **Alertas de vencimiento + extensión de plazo — LISTO (código).** Requiere correr `0005_notificaciones_extensiones.sql`.
   - **Por vencer (1 semana / 3 días / 1 día) y vencido:** notificación interna (campana 🔔, tabla `notifications`) + correo, para tareas, instrucciones y proyectos. Se generan al cargar la app (`checkDeadlines()` en `afterAuth`); deduplican por `dedupe_key`; el correo se envía solo la 1ª vez. ⚠️ Por ser EmailJS (cliente), el correo sale cuando alguien (el asignado o un admin) **abre la app** y la alerta es nueva — no hay agendador 24/7.
   - **Extensión de plazo:** desde la alerta, el funcionario pulsa "📅 Solicitar extensión" (fecha + motivo) → se notifica al supervisor/asignador (campana + correo). El supervisor pulsa **Aceptar/Denegar** en su campana; al aceptar, el plazo (`tasks.vence` o `projects.fin`) **se actualiza solo** y se avisa al funcionario. Tabla `deadline_extensions`. Aprobador = dueño del proyecto, o el directivo que asignó, o el primer directivo (`approverForTask`).
   - **Sección "📅 Solicitudes de plazo"** (`renderExtensiones`, en el nav para todos): detalle de cada solicitud (motivo, fechas, estado, historial). El supervisor acepta/deniega con **comentario opcional** (`openResolveExtension` → modal → `resolveExtension`); el comentario va en la notificación y el correo. Botón "🔍 Ver detalle" desde la campana.
   - *(Opcional futuro)* envío 24/7 garantizado de los recordatorios: requiere agendador (Supabase pg_cron + un proveedor de correo server-side).
3. **Permisos/validaciones:** el **funcionario NO puede eliminar** tareas, instrucciones ni proyectos (solo admin/jefatura); botones ocultos + guardas en `delTask`/`delProject`. No se permite asignar tareas/instrucciones con **fecha de vencimiento anterior a hoy** (atributo `min`=HOY + validación al enviar).
4. **Recuperación de contraseña:** enlace "¿Olvidaste tu contraseña?" en el login → Edge Function `recuperar-clave` resetea a **123456** + correo (EmailJS) avisando que la cambie. ⚠️ Cualquiera que sepa un correo puede resetearlo a 123456 (mitigación: el correo pide cambiarla; alternativa más segura = enlace de Supabase). `recuperarClave()` en el cliente.
5. **Nombre de pila vs oficial:** `profiles.display_name` (personal, solo afecta el chip de cabecera del propio usuario, editable en su Perfil); el **nombre oficial** (`profiles.name`) lo asigna/edita solo el admin en Usuarios. `memberName` y reportes usan SIEMPRE el oficial.
6. **Rendimiento › Gráficos:** las barras muestran **nombre y apellido** (`dosNombres`/`memberNA`) para distinguir homónimos.
2. (Opcional) Google Calendar **sincronización OAuth completa** (auto-push/2-vías): requiere Google Cloud + OAuth + verificación → más adelante; hoy resuelto con el enlace universal.
3. (Opcional) Dominio propio gratis para GitHub Pages; Supabase Pro (~US$25/mes) por respaldos; a futuro reescritura a Next.js.

## Flujo de trabajo
Editar projectos.html → `cp` a index.html → `preview_start name=prototype` si cayó → `preview_eval` (screenshot suele dar timeout) → commit + push (GitHub Pages publica solo en ~1 min). El usuario refresca con **🔄 / Ctrl+Shift+R / incógnito** (la app instalada cachea).
