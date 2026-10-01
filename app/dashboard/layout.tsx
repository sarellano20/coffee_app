'use client'
import {useEffect,useState} from 'react';import DashboardShell from '@/components/DashboardShell';import {supabaseBrowser} from '@/lib/supabase'
export default function Layout({children}:{children:React.ReactNode}){const [ok,setOk]=useState(false);useEffect(()=>{supabaseBrowser().auth.getSession().then(({data})=>{if(!data.session) location.href='/login'; else setOk(true)})},[]);if(!ok)return <div style={{padding:40}}>Cargando…</div>;return <DashboardShell>{children}</DashboardShell>}
