'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Home, CreditCard, Users, Stamp, Gift, Activity, Settings, LogOut } from 'lucide-react'
import { supabaseBrowser } from '@/lib/supabase'
import Brand from './Brand'
const links=[['/dashboard','Inicio',Home],['/dashboard/card','Mi tarjeta',CreditCard],['/dashboard/customers','Clientes',Users],['/dashboard/stamp','Entregar sello',Stamp],['/dashboard/rewards','Recompensas',Gift],['/dashboard/activity','Actividad',Activity],['/dashboard/settings','Configuración',Settings]] as const
export default function DashboardShell({children}:{children:React.ReactNode}){const path=usePathname(); const logout=async()=>{const sb=supabaseBrowser();if(sb)await sb.auth.signOut();location.href='/login'};return <div><div className="topbar"><Brand/><button className="btn btn-secondary" onClick={logout}><LogOut size={16}/> Salir</button></div><div className="dashboard"><aside className="sidebar">{links.map(([href,label,Icon])=><Link className={'side-link '+(path===href?'active':'')} href={href} key={href}><Icon size={18}/>{label}</Link>)}</aside><main className="main">{children}</main></div></div>}
