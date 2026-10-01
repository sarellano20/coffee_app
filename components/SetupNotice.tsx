export default function SetupNotice(){
  return <div className="form-card" style={{maxWidth:560,margin:'70px auto'}}>
    <div className="eyebrow">Configuración pendiente</div>
    <h1>Conecta Supabase para continuar</h1>
    <p className="muted">La interfaz local está funcionando, pero faltan las variables de entorno de Supabase. Copia <code>.env.example</code> a <code>.env.local</code>, completa sus valores y reinicia el servidor.</p>
  </div>
}
