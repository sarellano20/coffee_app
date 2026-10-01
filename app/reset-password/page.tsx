'use client'

import {useState} from 'react'
import {supabaseBrowser} from '@/lib/supabase'
import {useRouter} from 'next/navigation'
import Brand from '@/components/Brand'

export default function Reset(){
  const [password,setPassword]=useState(''),[done,setDone]=useState(false),[error,setError]=useState(''),[loading,setLoading]=useState(false);const router=useRouter()
  async function submit(e:React.FormEvent){
    e.preventDefault();setLoading(true);setError('')
    const sb=supabaseBrowser()
    if(!sb){setError('Falta configurar Supabase en .env.local.');setLoading(false);return}
    try{const {error}=await sb.auth.updateUser({password});if(error)setError('No pudimos actualizar la contraseña.');else{setDone(true);setTimeout(()=>router.push('/login'),1200)}}catch{setError('No pudimos conectar con el servicio. Inténtalo nuevamente.')}
    finally{setLoading(false)}
  }
  return <div className="public-page"><div className="form-card" style={{maxWidth:440,margin:'70px auto'}}><Brand/><h1>Nueva contraseña</h1>{done?<p className="success">Contraseña actualizada. Redirigiendo…</p>:<form onSubmit={submit}><div className="field"><label>Nueva contraseña</label><input type="password" minLength={8} required value={password} onChange={e=>setPassword(e.target.value)}/></div>{error&&<p className="error">{error}</p>}<button className="btn btn-primary" style={{width:'100%'}} disabled={loading}>{loading?'Actualizando…':'Actualizar'}</button></form>}</div></div>
}
