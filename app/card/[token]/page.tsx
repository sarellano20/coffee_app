'use client'

import {useEffect,useState} from 'react'
import {useParams} from 'next/navigation'
import {supabaseBrowser,supabaseConfigured} from '@/lib/supabase'
import {QRCodeSVG} from 'qrcode.react'
import Brand from '@/components/Brand'
import SetupNotice from '@/components/SetupNotice'

export default function PublicCard(){
  const {token}=useParams<{token:string}>();const [data,setData]=useState<any>(null),[loaded,setLoaded]=useState(false)
  useEffect(()=>{
    if(!supabaseConfigured){setLoaded(true);return}
    const sb=supabaseBrowser();if(!sb){setLoaded(true);return}
    Promise.resolve(sb.rpc('public_customer_card',{p_token:token})).then(({data})=>setData(data)).catch(()=>setData(null)).finally(()=>setLoaded(true))
  },[token])
  if(!supabaseConfigured)return <div className="public-page"><SetupNotice/></div>
  if(!loaded)return <div className="public-page"><div className="public-card form-card"><Brand/><p className="muted">Cargando tarjeta…</p></div></div>
  if(!data)return <div className="public-page"><div className="public-card form-card"><Brand/><h2>Tarjeta no encontrada</h2><p className="muted">No encontramos esta tarjeta.</p></div></div>
  const {customer,restaurant,card,cycle,rewards}=data
  return <div className="public-page"><div className="public-card"><Brand/><div className="loyalty" style={{marginTop:18,background:`linear-gradient(145deg,${card.primary_color},${card.primary_color}dd)`}}><div className="mini">{restaurant.name}</div><h3>{card.name}</h3><p style={{color:'#fff',opacity:.85}}>{card.description}</p><div className="stamps">{Array.from({length:Math.min(card.stamp_goal,20)}).map((_,i)=><div className={'stamp '+(i<cycle.stamps?'filled':'')} key={i}>{i<cycle.stamps?'✓':''}</div>)}</div><strong>{cycle.stamps} / {cycle.goal} sellos</strong><p style={{color:'#fff',opacity:.8}}>Recompensa: {card.reward_name}</p></div>{rewards?.length>0&&<div className="form-card" style={{marginTop:15,textAlign:'center'}}><div className="tag">🎉 Recompensa disponible</div><h2>{rewards[0].name}</h2><p className="muted">Muéstrala al equipo del restaurante para canjearla.</p></div>}<div className="form-card" style={{marginTop:15,textAlign:'center'}}><h3>Tu QR</h3><div className="qrbox"><QRCodeSVG value={customer.token} size={190}/></div><p className="muted" style={{fontSize:13}}>Este QR identifica tu tarjeta de forma segura.</p></div></div></div>
}
