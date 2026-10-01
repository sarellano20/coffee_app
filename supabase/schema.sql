create extension if not exists pgcrypto;
create extension if not exists unaccent;

create table if not exists public.restaurants (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
 name text not null, slug text not null unique, status text not null default 'active' check(status in ('active','suspended')), created_at timestamptz not null default now()
);
create table if not exists public.restaurant_settings (
 restaurant_id uuid primary key references public.restaurants(id) on delete cascade,
 description text, address text, phone text, whatsapp text, instagram text, facebook text, website text, hours text, cover_url text, updated_at timestamptz not null default now()
);
create table if not exists public.loyalty_cards (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null, description text, reward_name text not null, stamp_goal int not null check(stamp_goal between 1 and 100), stamps_per_purchase int not null default 1 check(stamps_per_purchase between 1 and 10),
 primary_color text not null default '#147d5a', secondary_color text not null default '#e7f5ef', text_color text not null default '#ffffff', logo_url text,
 published boolean not null default false, status text not null default 'draft' check(status in ('draft','published','paused','archived')), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index if not exists one_published_card_per_restaurant on public.loyalty_cards(restaurant_id) where status='published';
create table if not exists public.employees (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade, role text not null default 'employee' check(role in ('employee','manager')), active boolean not null default true, unique(restaurant_id,user_id)
);
create table if not exists public.customers (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null, contact text, public_token text not null unique default encode(gen_random_bytes(24),'hex'), status text not null default 'active' check(status in ('active','blocked')), created_at timestamptz not null default now()
);
create table if not exists public.customer_cards (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 customer_id uuid not null references public.customers(id) on delete cascade, loyalty_card_id uuid not null references public.loyalty_cards(id) on delete cascade,
 unique(customer_id,loyalty_card_id)
);
create table if not exists public.loyalty_cycles (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 customer_card_id uuid not null references public.customer_cards(id) on delete cascade,
 cycle_number int not null default 1, stamps int not null default 0 check(stamps>=0), status text not null default 'active' check(status in ('active','completed','cancelled')),
 started_at timestamptz not null default now(), completed_at timestamptz
);
create unique index if not exists one_active_cycle on public.loyalty_cycles(customer_card_id) where status='active';
create table if not exists public.rewards (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 loyalty_card_id uuid not null references public.loyalty_cards(id) on delete cascade, customer_id uuid references public.customers(id) on delete cascade, loyalty_cycle_id uuid references public.loyalty_cycles(id) on delete set null, name text not null, description text, type text not null default 'free_product' check(type in ('free_product','discount','benefit')), value numeric, stamps_required int not null, status text not null default 'locked' check(status in ('locked','available','redeemed','expired')),
 created_at timestamptz not null default now()
);
create table if not exists public.stamp_transactions (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 customer_id uuid not null references public.customers(id) on delete cascade, employee_id uuid references public.employees(id) on delete set null, loyalty_card_id uuid not null references public.loyalty_cards(id) on delete cascade,
 loyalty_cycle_id uuid not null references public.loyalty_cycles(id) on delete cascade, amount int not null check(amount>0), created_at timestamptz not null default now()
);
create table if not exists public.reward_redemptions (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 customer_id uuid not null references public.customers(id) on delete cascade, employee_id uuid references public.employees(id) on delete set null, loyalty_card_id uuid not null references public.loyalty_cards(id) on delete cascade,
 reward_id uuid not null references public.rewards(id) on delete cascade, loyalty_cycle_id uuid not null references public.loyalty_cycles(id) on delete cascade, created_at timestamptz not null default now()
);

create or replace function public.slugify(v text) returns text language sql immutable as $$ select trim(both '-' from regexp_replace(lower(unaccent(coalesce(v,''))), '[^a-z0-9]+', '-', 'g')) $$;

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin return new; end; $$;

create or replace function public.my_restaurant_id() returns uuid language sql stable security definer set search_path=public as $$
 select id from public.restaurants where owner_id=auth.uid() limit 1
$$;
create or replace function public.is_restaurant_member(rid uuid) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.restaurants r where r.id=rid and r.owner_id=auth.uid()) or exists(select 1 from public.employees e where e.restaurant_id=rid and e.user_id=auth.uid() and e.active=true)
$$;

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
declare base text; s text; n int:=0; r_id uuid;
begin
 base:=public.slugify(coalesce(new.raw_user_meta_data->>'restaurant_name','restaurante'));
 if base='' then base:='restaurante'; end if;
 s:=base;
 while exists(select 1 from public.restaurants where slug=s) loop n:=n+1; s:=base||'-'||n; end loop;
 insert into public.restaurants(owner_id,name,slug) values(new.id,coalesce(nullif(new.raw_user_meta_data->>'restaurant_name',''),'Mi restaurante'),s) returning id into r_id;
 insert into public.restaurant_settings(restaurant_id) values(r_id);
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

alter table public.restaurants enable row level security;
alter table public.restaurant_settings enable row level security;
alter table public.loyalty_cards enable row level security;
alter table public.employees enable row level security;
alter table public.customers enable row level security;
alter table public.customer_cards enable row level security;
alter table public.loyalty_cycles enable row level security;
alter table public.rewards enable row level security;
alter table public.stamp_transactions enable row level security;
alter table public.reward_redemptions enable row level security;

create policy "owner restaurants" on public.restaurants for all using(owner_id=auth.uid()) with check(owner_id=auth.uid());
create policy "member settings" on public.restaurant_settings for all using(public.is_restaurant_member(restaurant_id)) with check(public.is_restaurant_member(restaurant_id));
create policy "member cards" on public.loyalty_cards for all using(public.is_restaurant_member(restaurant_id)) with check(public.is_restaurant_member(restaurant_id));
create policy "member employees" on public.employees for all using(public.is_restaurant_member(restaurant_id)) with check(public.is_restaurant_member(restaurant_id));
create policy "member customers" on public.customers for all using(public.is_restaurant_member(restaurant_id)) with check(public.is_restaurant_member(restaurant_id));
create policy "member customer cards" on public.customer_cards for all using(public.is_restaurant_member(restaurant_id)) with check(public.is_restaurant_member(restaurant_id));
create policy "member cycles" on public.loyalty_cycles for all using(public.is_restaurant_member(restaurant_id)) with check(public.is_restaurant_member(restaurant_id));
create policy "member rewards" on public.rewards for all using(public.is_restaurant_member(restaurant_id)) with check(public.is_restaurant_member(restaurant_id));
create policy "member stamps" on public.stamp_transactions for all using(public.is_restaurant_member(restaurant_id)) with check(public.is_restaurant_member(restaurant_id));
create policy "member redemptions" on public.reward_redemptions for all using(public.is_restaurant_member(restaurant_id)) with check(public.is_restaurant_member(restaurant_id));

create or replace function public.add_stamp(p_customer_id uuid,p_card_id uuid,p_amount int default null) returns jsonb language plpgsql security definer set search_path=public as $$
declare rid uuid; emp uuid; cc public.customer_cards; cyc public.loyalty_cycles; card public.loyalty_cards; n int; reward_id uuid;
begin
 if p_amount is not null and p_amount < 1 then raise exception 'INVALID_AMOUNT'; end if;
 select restaurant_id into rid from public.customers where id=p_customer_id and status='active';
 if rid is null or not public.is_restaurant_member(rid) then raise exception 'UNAUTHORIZED'; end if;
 select id into emp from public.employees where restaurant_id=rid and user_id=auth.uid() and active=true limit 1;
 if emp is null and exists(select 1 from public.restaurants where id=rid and owner_id=auth.uid()) then emp:=null; end if;
 select * into card from public.loyalty_cards where id=p_card_id and restaurant_id=rid and status='published';
 if card.id is null then raise exception 'CARD_INVALID'; end if;
 select * into cc from public.customer_cards where customer_id=p_customer_id and loyalty_card_id=p_card_id and restaurant_id=rid;
 if cc.id is null then raise exception 'CUSTOMER_CARD_INVALID'; end if;
 select * into cyc from public.loyalty_cycles where customer_card_id=cc.id and status='active' for update;
 if cyc.id is null then raise exception 'NO_ACTIVE_CYCLE'; end if;
 n:=least(coalesce(p_amount,card.stamps_per_purchase),card.stamp_goal-cyc.stamps);
 if n<=0 then raise exception 'CYCLE_COMPLETE'; end if;
 update public.loyalty_cycles set stamps=stamps+n, completed_at=case when stamps+n>=card.stamp_goal then now() else null end, status=case when stamps+n>=card.stamp_goal then 'completed' else 'active' end where id=cyc.id;
 insert into public.stamp_transactions(restaurant_id,customer_id,employee_id,loyalty_card_id,loyalty_cycle_id,amount) values(rid,p_customer_id,emp,p_card_id,cyc.id,n);
 if cyc.stamps+n>=card.stamp_goal then
   insert into public.rewards(restaurant_id,loyalty_card_id,customer_id,loyalty_cycle_id,name,description,type,stamps_required,status) values(rid,p_card_id,p_customer_id,cyc.id,card.reward_name,'Recompensa desbloqueada','free_product',card.stamp_goal,'available') returning id into reward_id;
   insert into public.loyalty_cycles(restaurant_id,customer_card_id,cycle_number,stamps,status) values(rid,cc.id,cyc.cycle_number+1,0,'active');
 end if;
 return jsonb_build_object('stamps_added',n,'cycle_stamps',case when cyc.stamps+n>=card.stamp_goal then 0 else cyc.stamps+n end,'completed',cyc.stamps+n>=card.stamp_goal);
end; $$;

grant execute on function public.add_stamp(uuid,uuid,int) to authenticated;

create or replace function public.redeem_reward(p_reward_id uuid,p_customer_id uuid) returns jsonb language plpgsql security definer set search_path=public as $$
declare rw public.rewards; rid uuid; emp uuid;
begin
 select * into rw from public.rewards where id=p_reward_id and status='available' and customer_id=p_customer_id for update;
 if rw.id is null then raise exception 'REWARD_INVALID'; end if;
 rid:=rw.restaurant_id;
 if not public.is_restaurant_member(rid) then raise exception 'UNAUTHORIZED'; end if;
 select id into emp from public.employees where restaurant_id=rid and user_id=auth.uid() and active=true limit 1;
 insert into public.reward_redemptions(restaurant_id,customer_id,employee_id,loyalty_card_id,reward_id,loyalty_cycle_id)
 values(rid,p_customer_id,emp,rw.loyalty_card_id,rw.id,rw.loyalty_cycle_id);
 update public.rewards set status='redeemed' where id=rw.id;
 return jsonb_build_object('redeemed',true,'reward_id',rw.id);
end; $$;
grant execute on function public.redeem_reward(uuid,uuid) to authenticated;

create or replace function public.public_join_info(p_slug text) returns jsonb language plpgsql security definer set search_path=public as $$
declare r public.restaurants; c public.loyalty_cards;
begin
 select * into r from public.restaurants where slug=p_slug and status='active';
 if r.id is null then return null; end if;
 select * into c from public.loyalty_cards where restaurant_id=r.id and status='published' order by created_at desc limit 1;
 if c.id is null then return null; end if;
 return jsonb_build_object('restaurant',jsonb_build_object('id',r.id,'name',r.name,'slug',r.slug),'card',jsonb_build_object('id',c.id,'name',c.name,'description',c.description,'reward_name',c.reward_name,'stamp_goal',c.stamp_goal,'primary_color',c.primary_color,'secondary_color',c.secondary_color,'text_color',c.text_color,'logo_url',c.logo_url));
end; $$;
grant execute on function public.public_join_info(text) to anon,authenticated;

create or replace function public.register_customer(p_slug text,p_name text,p_contact text) returns jsonb language plpgsql security definer set search_path=public as $$
declare r public.restaurants; c public.loyalty_cards; cu public.customers; cc public.customer_cards;
begin
 if length(trim(coalesce(p_name,''))) < 2 or length(trim(p_name)) > 120 then raise exception 'INVALID_NAME'; end if;
 if length(trim(coalesce(p_contact,''))) < 3 or length(trim(p_contact)) > 160 then raise exception 'INVALID_CONTACT'; end if;
 select * into r from public.restaurants where slug=p_slug and status='active';
 if r.id is null then raise exception 'RESTAURANT_NOT_FOUND'; end if;
 select * into c from public.loyalty_cards where restaurant_id=r.id and status='published' order by created_at desc limit 1;
 if c.id is null then raise exception 'CARD_NOT_FOUND'; end if;
 insert into public.customers(restaurant_id,name,contact) values(r.id,trim(p_name),nullif(trim(p_contact),'')) returning * into cu;
 insert into public.customer_cards(restaurant_id,customer_id,loyalty_card_id) values(r.id,cu.id,c.id) returning * into cc;
 insert into public.loyalty_cycles(restaurant_id,customer_card_id,cycle_number,stamps,status) values(r.id,cc.id,1,0,'active');
 return jsonb_build_object('token',cu.public_token,'customer_id',cu.id);
end; $$;
grant execute on function public.register_customer(text,text,text) to anon,authenticated;

create or replace function public.public_customer_card(p_token text) returns jsonb language plpgsql security definer set search_path=public as $$
declare cu public.customers; cc public.customer_cards; r public.restaurants; c public.loyalty_cards; cyc public.loyalty_cycles; rw jsonb;
begin
 select * into cu from public.customers where public_token=p_token and status='active';
 if cu.id is null then return null; end if;
 select * into r from public.restaurants where id=cu.restaurant_id and status='active';
 select * into cc from public.customer_cards where customer_id=cu.id order by id limit 1;
 select * into c from public.loyalty_cards where id=cc.loyalty_card_id and status='published';
 select * into cyc from public.loyalty_cycles where customer_card_id=cc.id and status='active';
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name,'status',status,'created_at',created_at)),'[]'::jsonb) into rw from public.rewards where restaurant_id=r.id and loyalty_card_id=c.id and status='available';
 return jsonb_build_object('customer',jsonb_build_object('id',cu.id,'name',cu.name,'token',cu.public_token),'restaurant',jsonb_build_object('name',r.name,'slug',r.slug),'card',jsonb_build_object('id',c.id,'name',c.name,'description',c.description,'reward_name',c.reward_name,'stamp_goal',c.stamp_goal,'primary_color',c.primary_color,'secondary_color',c.secondary_color,'text_color',c.text_color,'logo_url',c.logo_url),'cycle',jsonb_build_object('stamps',coalesce(cyc.stamps,0),'goal',c.stamp_goal),'rewards',rw);
end; $$;
grant execute on function public.public_customer_card(text) to anon,authenticated;
