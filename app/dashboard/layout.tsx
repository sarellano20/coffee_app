'use client'

import {useEffect,useState} from 'react'
import DashboardShell from '@/components/DashboardShell'
import SetupNotice from '@/components/SetupNotice'
import {supabaseBrowser,supabaseConfigured} from '@/lib/supabase'

export default function Layout({children}:{children:React.ReactNode}){
  const [ok,setOk]=useState(false),[checking,setChecking]=useState(true)
  useEffect(()=>{
    if(!supabaseConfigured){setChecking(false);return}
    const sb=supabaseBrowser()
    if(!sb){setChecking(false);return}
    sb.auth.getSession().then(({data,error})=>{
      if(error||!data.session) location.href='/login'
      else setOk(true)
    }).catch(()=>location.href='/login').finally(()=>setChecking(false))
  },[])
  if(!supabaseConfigured)return <div className="public-page"><SetupNotice/></div>
  if(checking||!ok)return <div style={{padding:40}}>Cargando…</div>
  return <DashboardShell>{children}</DashboardShell>
}
