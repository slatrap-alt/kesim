-- ACANLAR | Müşteri takip bağlantısı için güvenli yayın tablosu
-- Müşteri sayfası yalnızca yüksek entropili takip anahtarını bilen ziyaretçiye
-- sınırlı JSON özetini döndürür. Ham anahtar tabloda saklanmaz.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.acanlar_customer_tracking (
  owner_uid text not null,
  client_id text not null,
  token_hash text not null unique check (token_hash ~ '^[0-9a-f]{64}$'),
  payload jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (owner_uid, client_id)
);

alter table public.acanlar_customer_tracking enable row level security;
revoke all on table public.acanlar_customer_tracking from public;
grant select, insert, update, delete on table public.acanlar_customer_tracking to anon, authenticated;

drop policy if exists acanlar_tracking_owner_select on public.acanlar_customer_tracking;
drop policy if exists acanlar_tracking_owner_insert on public.acanlar_customer_tracking;
drop policy if exists acanlar_tracking_owner_update on public.acanlar_customer_tracking;
drop policy if exists acanlar_tracking_owner_delete on public.acanlar_customer_tracking;

create policy acanlar_tracking_owner_select
on public.acanlar_customer_tracking for select to anon, authenticated
using (
  owner_uid = (select auth.jwt()->>'sub')
  and (select auth.jwt()->>'iss') = 'https://securetoken.google.com/oykum-6de70'
  and (select auth.jwt()->>'aud') = 'oykum-6de70'
);

create policy acanlar_tracking_owner_insert
on public.acanlar_customer_tracking for insert to anon, authenticated
with check (
  owner_uid = (select auth.jwt()->>'sub')
  and (select auth.jwt()->>'iss') = 'https://securetoken.google.com/oykum-6de70'
  and (select auth.jwt()->>'aud') = 'oykum-6de70'
);

create policy acanlar_tracking_owner_update
on public.acanlar_customer_tracking for update to anon, authenticated
using (
  owner_uid = (select auth.jwt()->>'sub')
  and (select auth.jwt()->>'iss') = 'https://securetoken.google.com/oykum-6de70'
  and (select auth.jwt()->>'aud') = 'oykum-6de70'
)
with check (
  owner_uid = (select auth.jwt()->>'sub')
  and (select auth.jwt()->>'iss') = 'https://securetoken.google.com/oykum-6de70'
  and (select auth.jwt()->>'aud') = 'oykum-6de70'
);

create policy acanlar_tracking_owner_delete
on public.acanlar_customer_tracking for delete to anon, authenticated
using (
  owner_uid = (select auth.jwt()->>'sub')
  and (select auth.jwt()->>'iss') = 'https://securetoken.google.com/oykum-6de70'
  and (select auth.jwt()->>'aud') = 'oykum-6de70'
);

create or replace function public.acanlar_get_customer_tracking(p_token text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select t.payload
  from public.acanlar_customer_tracking as t
  where p_token is not null
    and pg_catalog.length(p_token) between 32 and 80
    and t.token_hash = pg_catalog.encode(
      extensions.digest(pg_catalog.convert_to(p_token, 'UTF8'), 'sha256'),
      'hex'
    )
    and t.is_active = true
  limit 1;
$$;

revoke all on function public.acanlar_get_customer_tracking(text) from public;
grant execute on function public.acanlar_get_customer_tracking(text) to anon, authenticated;
