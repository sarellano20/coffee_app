'use client'

import {FormEvent,useState} from 'react'
import Link from 'next/link'
import Brand from '@/components/Brand'
import {supabaseBrowser} from '@/lib/supabase'

export default function Login(){
  const [email,setEmail]=useState(''),[password,setPassword]=useState(''),[error,setError]=useState(''),[loading,setLoading]=useState(false)
  async function submit(e:FormEvent){
    e.preventDefault();setLoading(true);setError('')
    const sb=supabaseBrowser()
    if(!sb){setError('Falta configurar Supabase en .env.local.');setLoading(false);return}
    try{
      const {error}=await sb.auth.signInWithPassword({email,password})
      if(error)setError('No pudimos iniciar sesión. Revisa tus datos.')
      else location.href='/dashboard'
    }catch{setError('No pudimos conectar con el servicio. Inténtalo nuevamente.')}
    finally{setLoading(false)}
  }
  return <div className="public-page"><div className="form-card" style={{maxWidth:440,margin:'70px auto'}}><Brand/><h1>Inicia sesión</h1><p className="muted">Administra la fidelización de tu restaurante.</p><form onSubmit={submit}><div className="field"><label>Email</label><input type="email" value={email} onChange={e=>setEmail(e.target.value)} required/></div><div className="field"><label>Contraseña</label><input type="password" value={password} onChange={e=>setPassword(e.target.value)} required/></div>{error&&<p className="error">{error}</p>}<button className="btn btn-primary" style={{width:'100%'}} disabled={loading}>{loading?'Entrando…':'Iniciar sesión'}</button></form><p style={{marginTop:14}}><Link href="/forgot-password" style={{color:'var(--brand)',fontWeight:800}}>¿Olvidaste tu contraseña?</Link></p><p className="muted" style={{marginTop:20}}>¿Aún no tienes cuenta? <Link href="/register" style={{color:'var(--brand)',fontWeight:800}}>Crear restaurante</Link></p></div></div>
}
