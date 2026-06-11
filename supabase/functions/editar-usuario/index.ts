// ════════════════════════════════════════════════════════════════════════
// Edge Function: editar-usuario
// El administrador edita un perfil existente: nombre, cargo, área, rol,
// correo y/o contraseña. Verifica que QUIEN llama sea admin.
// Desplegar en: Supabase → Edge Functions → Deploy a new function → "editar-usuario"
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

    // 1) Verificar administrador
    const caller = createClient(URL, ANON, { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } })
    const { data: { user } } = await caller.auth.getUser()
    if (!user) return json({ error: 'No autenticado.' })
    const { data: prof } = await caller.from('profiles').select('role').eq('id', user.id).single()
    if (!prof || prof.role !== 'admin') return json({ error: 'Solo un administrador puede editar usuarios.' })

    // 2) Datos
    const { id, name, cargo, area, role, email, password } = await req.json()
    if (!id) return json({ error: 'Falta el usuario a editar.' })

    const admin = createClient(URL, SERVICE)

    // 3) Perfil (nombre/cargo/área/rol)
    const upd: Record<string, unknown> = {}
    if (name != null) upd.name = name
    if (cargo != null) upd.cargo = cargo
    if (area != null) upd.area = area
    if (role === 'admin' || role === 'Directivo') upd.role = 'admin'
    else if (role === 'user' || role === 'Funcionario') upd.role = 'user'

    // 4) Cuenta de acceso (correo y/o contraseña) — requiere service_role
    const authUpd: Record<string, unknown> = {}
    const mail = String(email ?? '').trim().toLowerCase()
    if (mail) { authUpd.email = mail; authUpd.email_confirm = true; upd.email = mail }
    if (password) authUpd.password = password
    if (Object.keys(authUpd).length) {
      const { error: ae } = await admin.auth.admin.updateUserById(id, authUpd)
      if (ae) return json({ error: ae.message })
    }
    if (Object.keys(upd).length) {
      const { error: pe } = await admin.from('profiles').update(upd).eq('id', id)
      if (pe) return json({ error: pe.message })
    }

    return json({ ok: true })
  } catch (e) {
    return json({ error: (e as Error)?.message ?? String(e) })
  }
})
