# Fidelio — MVP SaaS de fidelización digital

MVP multi-restaurante para tarjetas digitales de sellos y recompensas.

## Stack
- Next.js + TypeScript
- Supabase Auth + PostgreSQL + RLS
- QR con `qrcode.react`
- Diseño responsive/mobile-first

## Puesta en marcha

1. Crea un proyecto en Supabase.
2. Abre **SQL Editor** y ejecuta completo `supabase/schema.sql`.
3. En Authentication configura Email/Password. Para desarrollo puedes desactivar temporalmente la confirmación por correo.
4. Copia `.env.example` a `.env.local` y completa:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
5. Ejecuta `npm install` y `npm run dev`.

## Flujo MVP
1. `/register` crea usuario y restaurante automáticamente mediante trigger.
2. `/dashboard/card` crea y publica la tarjeta.
3. El QR/enlace de registro lleva a `/join/[slug]`.
4. El cliente recibe `/card/[token]` y un QR con el token aleatorio.
5. `/dashboard/stamp` identifica al cliente y ejecuta `add_stamp()` en PostgreSQL.
6. Al llegar al objetivo se genera una recompensa disponible y un nuevo ciclo.
7. El empleado puede canjear la recompensa desde la misma pantalla.
8. `stamp_transactions` y `reward_redemptions` conservan auditoría.

## Seguridad
La separación por restaurante se aplica en PostgreSQL con RLS y las operaciones críticas se ejecutan mediante funciones `security definer` que vuelven a validar pertenencia, estado y permisos.

## Fases futuras preparadas
Wallet, NFC, push, múltiples sucursales, Stripe/suscripciones, campañas y analítica avanzada.
