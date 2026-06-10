// ════════════════════════════════════════════════════════════════════════
// Edge Function: crear-usuario
// Crea una cuenta de acceso (login) + perfil, de forma segura.
// - Verifica que QUIEN llama sea administrador (con su propio token).
// - Usa la clave service_role (solo en el servidor) para crear el usuario.
// Desplegar en: Supabase → Edge Functions → Deploy a new function → "crear-usuario"
// ════════════════════════════════════════════════════════════════════════
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  try {
    const URL = Deno.env.get('SUPABASE_URL')!
    const SERVICE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const ANON = Deno.env.get('SUPABASE_ANON_KEY')!

    // 1) Verificar que quien llama es administrador
    const authHeader = req.headers.get('Authorization') ?? ''
    const caller = createClient(URL, ANON, { global: { headers: { Authorization: authHeader } } })
    const { data: { user }, error: uErr } = await caller.auth.getUser()
    if (uErr || !user) return json({ error: 'No autenticado.' })
    const { data: prof } = await caller.from('profiles').select('role').eq('id', user.id).single()
    if (!prof || prof.role !== 'admin') return json({ error: 'Solo un administrador puede crear usuarios.' })

    // 2) Leer datos
    const { name, email, password, role, cargo, area, workspaceId } = await req.json()
    const mail = String(email ?? '').trim().toLowerCase()
    if (!mail || !password) return json({ error: 'Correo y contraseña son obligatorios.' })
    const dbRole = (role === 'admin' || role === 'Directivo') ? 'admin' : 'user'

    // 3) Crear la cuenta con la clave de servicio (auto-confirmada)
    const admin = createClient(URL, SERVICE)
    const { data: created, error: cErr } = await admin.auth.admin.createUser({
      email: mail, password, email_confirm: true,
      user_metadata: { name: name ?? 'Usuario', role: dbRole },
    })
    if (cErr) return json({ error: cErr.message })
    const id = created.user!.id

    // 4) Asegurar los datos del perfil
    await admin.from('profiles').upsert({
      id, name: name ?? 'Usuario', email: mail, role: dbRole,
      cargo: cargo ?? '', area: area ?? 'Dirección',
    })

    // 5) Sumarlo al espacio de trabajo
    if (workspaceId) {
      await admin.from('workspace_members').upsert({ workspace_id: workspaceId, profile_id: id })
    }

    return json({ ok: true, id })
  } catch (e) {
    return json({ error: (e as Error)?.message ?? String(e) })
  }
})
