'use client'

import {useEffect,useState} from 'react'
import {useParams} from 'next/navigation'
import {supabaseBrowser,supabaseConfigured} from '@/lib/supabase'
import Brand from '@/components/Brand'
import SetupNotice from '@/components/SetupNotice'

export default function Join(){
  const {slug}=useParams<{slug:string}>();const [info,setInfo]=useState<any>(null),[loaded,setLoaded]=useState(false),[name,setName]=useState(''),[contact,setContact]=useState(''),[error,setError]=useState(''),[loading,setLoading]=useState(false)
  useEffect(()=>{
    if(!supabaseConfigured){setLoaded(true);return}
    const sb=supabaseBrowser();if(!sb){setLoaded(true);return}
    Promise.resolve(sb.rpc('public_join_info',{p_slug:slug})).then(({data,error})=>{setInfo(error?null:data)}).catch(()=>setInfo(null)).finally(()=>setLoaded(true))
  },[slug])
  async function submit(e:React.FormEvent){
    e.preventDefault();setLoading(true);setError('')
    const sb=supabaseBrowser();if(!sb){setError('Falta configurar Supabase en .env.local.');setLoading(false);return}
    try{const {data,error}=await sb.rpc('register_customer',{p_slug:slug,p_name:name.trim(),p_contact:contact.trim()});if(error||!data?.token){const message=error?.message||'';if(message.includes('CARD_NOT_FOUND'))setError('Este programa todavía no está publicado. Pide al restaurante que publique su tarjeta.');else if(message.includes('RESTAURANT_NOT_FOUND'))setError('No encontramos este restaurante.');else if(message.includes('INVALID_NAME'))setError('El nombre debe tener entre 2 y 120 caracteres.');else if(message.includes('INVALID_CONTACT'))setError('Ingresa un teléfono o email válido.');else setError('No pudimos crear tu tarjeta. Inténtalo nuevamente.')}else location.href=`/card/${data.token}`}catch{setError('No pudimos conectar con el servicio. Inténtalo nuevamente.')}finally{setLoading(false)}
  }
  if(!supabaseConfigured)return <div className="public-page"><SetupNotice/></div>
  if(!loaded)return <div className="public-page"><div className="public-card form-card"><Brand/><p className="muted">Cargando tarjeta…</p></div></div>
  if(!info)return <div className="public-page"><div className="public-card form-card"><Brand/><h2>Tarjeta no disponible</h2><p className="muted">No encontramos este programa.</p></div></div>
  const c=info.card
  return <div className="public-page"><div className="public-card"><Brand/><div className="loyalty" style={{marginTop:18,background:`linear-gradient(145deg,${c.primary_color},${c.primary_color}dd)`}}><div className="mini">{info.restaurant.name}</div><h3>{c.name}</h3><p style={{color:'#fff',opacity:.85}}>{c.description}</p><strong>{c.stamp_goal} sellos → {c.reward_name}</strong></div><div className="form-card" style={{marginTop:16}}><h2>Obtén tu tarjeta</h2><p className="muted">Solo necesitamos unos datos básicos.</p><form onSubmit={submit}><div className="field"><label>Nombre</label><input value={name} onChange={e=>setName(e.target.value)} required maxLength={120}/></div><div className="field"><label>Teléfono o email</label><input value={contact} onChange={e=>setContact(e.target.value)} required maxLength={160}/></div>{error&&<p className="error">{error}</p>}<button className="btn btn-primary" style={{width:'100%'}} disabled={loading}>{loading?'Creando…':'Crear mi tarjeta'}</button></form></div></div></div>
}
