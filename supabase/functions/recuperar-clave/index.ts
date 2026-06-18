// ════════════════════════════════════════════════════════════════════════
// Edge Function: recuperar-clave
//   Restablece la contraseña de un usuario a una clave temporal genérica
//   ("123456") a partir de su correo. NO requiere que el llamador esté
//   autenticado (se usa desde la pantalla de login). El correo de aviso se
//   envía desde el cliente (EmailJS); aquí solo se cambia la contraseña.
//
// ⚠️ Por diseño no revela si el correo existe o no (evita enumeración).
// ⚠️ Nota de seguridad: cualquiera que conozca un correo puede restablecerlo
//    a "123456". La mitigación es que el correo indica cambiarla de inmediato.
//    Para mayor seguridad se podría migrar al enlace de recuperación de Supabase.
//
// Desplegar en: Supabase → Edge Functions → Deploy a new function → "recuperar-clave"
// ════════════════════════════════════════════════════════════════════════
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } })

const TEMP_PASSWORD = '123456'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  try {
    const URL = Deno.env.get('SUPABASE_URL')!
    const SERVICE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const { email } = await req.json()
    const mail = String(email ?? '').trim().toLowerCase()
    if (!mail) return json({ error: 'Falta el correo.' })

    const admin = createClient(URL, SERVICE)

    // Buscar al usuario por correo en Auth (robusto, no depende de profiles).
    const { data: list } = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 })
    const user = (list?.users ?? []).find(u => (u.email ?? '').toLowerCase() === mail)
    if (user) {
      const { error } = await admin.auth.admin.updateUserById(user.id, { password: TEMP_PASSWORD })
      if (error) return json({ error: error.message })
    }
    // Respuesta uniforme exista o no el correo.
    return json({ ok: true })
  } catch (e) {
    return json({ error: (e as Error)?.message ?? String(e) })
  }
})
