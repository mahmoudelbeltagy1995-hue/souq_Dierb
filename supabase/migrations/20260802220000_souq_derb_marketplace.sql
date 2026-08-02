-- Souq Derb phase-one cumulative migration.
-- Apply after the legacy TStore schema. No production data is dropped.

create extension if not exists pgcrypto;

do $$ begin
  create type public.user_role as enum ('customer','merchant','admin','staff','driver');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.account_status as enum ('active','pending','suspended','blocked');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.store_approval_status as enum ('pending','approved','rejected','suspended');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.subscription_status as enum ('trial','active','expired','suspended');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.souq_order_status as enum ('pending','accepted','preparing','ready','out_for_delivery','delivered','cancelled','rejected');
exception when duplicate_object then null; end $$;

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;

create table if not exists public.service_areas (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null unique,
  name_en text,
  delivery_fee numeric(12,2) not null default 0 check (delivery_fee >= 0),
  minimum_order numeric(12,2) not null default 0 check (minimum_order >= 0),
  estimated_delivery_minutes integer not null default 45 check (estimated_delivery_minutes > 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists role public.user_role not null default 'customer';
alter table public.profiles add column if not exists service_area_id uuid references public.service_areas(id);
alter table public.profiles add column if not exists default_address_id uuid;
alter table public.profiles add column if not exists account_status public.account_status not null default 'active';

create table if not exists public.customer_addresses (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  title text not null, recipient_name text not null, phone text not null check (phone ~ '^01[0125][0-9]{8}$'),
  service_area_id uuid not null references public.service_areas(id), street text not null,
  building_number text, floor_number text, apartment_number text, landmark text, notes text,
  latitude numeric(9,6), longitude numeric(9,6), is_default boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.profiles drop constraint if exists profiles_default_address_id_fkey;
alter table public.profiles add constraint profiles_default_address_id_fkey
  foreign key (default_address_id) references public.customer_addresses(id) on delete set null;
create unique index if not exists customer_one_default_address on public.customer_addresses(user_id) where is_default;

create table if not exists public.store_categories (
  id uuid primary key default gen_random_uuid(), name_ar text not null unique, name_en text,
  icon_url text, image_url text, is_active boolean not null default true, sort_order integer not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id),
  category_id uuid not null references public.store_categories(id), name_ar text not null, name_en text,
  slug text not null unique, description text, logo_url text, cover_url text,
  phone text not null check (phone ~ '^01[0125][0-9]{8}$'), whatsapp text, email text, address text not null,
  service_area_id uuid not null references public.service_areas(id), latitude numeric(9,6), longitude numeric(9,6),
  opening_time time, closing_time time, is_open_manual boolean not null default true,
  minimum_order numeric(12,2) not null default 0 check (minimum_order >= 0),
  delivery_fee numeric(12,2) not null default 0 check (delivery_fee >= 0),
  estimated_delivery_minutes integer not null default 45 check (estimated_delivery_minutes > 0),
  approval_status public.store_approval_status not null default 'pending', rejection_reason text,
  subscription_status public.subscription_status not null default 'trial',
  subscription_started_at timestamptz not null default now(),
  subscription_expires_at timestamptz not null default (now() + interval '1 month'),
  is_active boolean not null default true, average_rating numeric(3,2) not null default 0 check (average_rating between 0 and 5),
  ratings_count integer not null default 0 check (ratings_count >= 0), total_orders integer not null default 0 check (total_orders >= 0),
  deleted_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists stores_public_filter_idx on public.stores(service_area_id, category_id, approval_status, subscription_status, is_active);
create index if not exists stores_owner_idx on public.stores(owner_id);

create table if not exists public.store_service_areas (
  id uuid primary key default gen_random_uuid(), store_id uuid not null references public.stores(id) on delete cascade,
  service_area_id uuid not null references public.service_areas(id), delivery_fee_override numeric(12,2) check (delivery_fee_override >= 0),
  minimum_order_override numeric(12,2) check (minimum_order_override >= 0), estimated_delivery_minutes integer check (estimated_delivery_minutes > 0),
  is_active boolean not null default true, unique(store_id, service_area_id)
);

create table if not exists public.store_product_categories (
  id uuid primary key default gen_random_uuid(), store_id uuid not null references public.stores(id) on delete cascade,
  name_ar text not null, name_en text, sort_order integer not null default 0, is_active boolean not null default true,
  unique(store_id, name_ar)
);

alter table public.products add column if not exists store_id uuid references public.stores(id) on delete cascade;
alter table public.products add column if not exists store_category_id uuid references public.store_product_categories(id) on delete set null;
alter table public.products add column if not exists name_ar text;
alter table public.products add column if not exists name_en text;
alter table public.products add column if not exists sku text;
alter table public.products add column if not exists barcode text;
alter table public.products add column if not exists compare_at_price numeric(12,2);
alter table public.products add column if not exists cost_price numeric(12,2);
alter table public.products add column if not exists stock_quantity integer not null default 0;
alter table public.products add column if not exists low_stock_threshold integer not null default 5;
alter table public.products add column if not exists unit text not null default 'قطعة';
alter table public.products add column if not exists image_url text;
alter table public.products add column if not exists is_available boolean not null default true;
alter table public.products add column if not exists preparation_time_minutes integer not null default 0;
alter table public.products add column if not exists deleted_at timestamptz;
create unique index if not exists products_store_sku_unique on public.products(store_id, sku) where sku is not null and deleted_at is null;
create index if not exists products_store_available_idx on public.products(store_id, is_available, is_active) where deleted_at is null;

create table if not exists public.product_option_groups (
  id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade,
  name_ar text not null, selection_type text not null check (selection_type in ('single','multiple')),
  is_required boolean not null default false, minimum_selection integer not null default 0,
  maximum_selection integer not null default 1, sort_order integer not null default 0,
  check (minimum_selection >= 0 and maximum_selection >= minimum_selection)
);
create table if not exists public.product_options (
  id uuid primary key default gen_random_uuid(), option_group_id uuid not null references public.product_option_groups(id) on delete cascade,
  name_ar text not null, additional_price numeric(12,2) not null default 0,
  stock_quantity integer check (stock_quantity is null or stock_quantity >= 0), is_available boolean not null default true,
  sort_order integer not null default 0
);

create table if not exists public.merchant_subscriptions (
  id uuid primary key default gen_random_uuid(), store_id uuid not null references public.stores(id) on delete cascade,
  plan_name text not null default 'شهري', amount numeric(12,2) not null default 150 check (amount >= 0),
  starts_at timestamptz not null, expires_at timestamptz not null, status public.subscription_status not null,
  payment_method text, payment_reference text, approved_by uuid references auth.users(id), approved_at timestamptz,
  notes text, created_at timestamptz not null default now(), check (expires_at > starts_at)
);

alter table public.banners add column if not exists action_value text;
alter table public.banners add column if not exists service_area_id uuid references public.service_areas(id);
alter table public.banners add column if not exists starts_at timestamptz;
alter table public.banners add column if not exists ends_at timestamptz;

-- The legacy orders table is extended in-place for application compatibility.
alter table public.orders add column if not exists order_number bigint generated by default as identity;
alter table public.orders add column if not exists customer_id uuid references auth.users(id);
alter table public.orders add column if not exists store_id uuid references public.stores(id);
alter table public.orders add column if not exists service_area_id uuid references public.service_areas(id);
alter table public.orders add column if not exists discount_amount numeric(12,2) not null default 0;
alter table public.orders add column if not exists delivery_fee numeric(12,2) not null default 0;
alter table public.orders add column if not exists total_amount numeric(12,2);
alter table public.orders add column if not exists customer_note text;
alter table public.orders add column if not exists merchant_note text;
alter table public.orders add column if not exists rejection_reason text;
alter table public.orders add column if not exists cancellation_reason text;
alter table public.orders add column if not exists idempotency_key uuid;
alter table public.orders add column if not exists placed_at timestamptz default now();
alter table public.orders add column if not exists accepted_at timestamptz;
alter table public.orders add column if not exists preparing_at timestamptz;
alter table public.orders add column if not exists ready_at timestamptz;
alter table public.orders add column if not exists out_for_delivery_at timestamptz;
alter table public.orders add column if not exists delivered_at timestamptz;
alter table public.orders add column if not exists cancelled_at timestamptz;
create unique index if not exists orders_customer_idempotency_unique on public.orders(customer_id, idempotency_key) where idempotency_key is not null;
create index if not exists orders_store_status_created_idx on public.orders(store_id, status, created_at desc);

alter table public.order_items add column if not exists product_name_snapshot text;
alter table public.order_items add column if not exists unit_price numeric(12,2);
alter table public.order_items add column if not exists options_total numeric(12,2) not null default 0;
alter table public.order_items add column if not exists total_price numeric(12,2);
alter table public.order_items add column if not exists notes text;
create table if not exists public.order_item_options (
  id uuid primary key default gen_random_uuid(), order_item_id uuid not null references public.order_items(id) on delete cascade,
  option_name_snapshot text not null, option_price numeric(12,2) not null default 0
);

create table if not exists public.inventory_movements (
  id uuid primary key default gen_random_uuid(), store_id uuid not null references public.stores(id),
  product_id uuid not null references public.products(id), order_id uuid references public.orders(id),
  movement_type text not null check (movement_type in ('reserve','release','sale','adjustment','restock')),
  quantity integer not null check (quantity <> 0), previous_quantity integer not null check (previous_quantity >= 0),
  new_quantity integer not null check (new_quantity >= 0), reason text, created_by uuid references auth.users(id), created_at timestamptz not null default now()
);

create table if not exists public.store_reviews (
  id uuid primary key default gen_random_uuid(), order_id uuid not null unique references public.orders(id),
  store_id uuid not null references public.stores(id), customer_id uuid not null references auth.users(id),
  rating integer not null check (rating between 1 and 5), comment text,
  status text not null default 'pending' check (status in ('pending','published','hidden')),
  merchant_reply text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

-- Authorization helpers are not exposed through the Data API.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create or replace function private.current_role()
returns public.user_role language sql stable security definer set search_path = '' as $$
  select role from public.profiles where id = (select auth.uid()) and account_status = 'active'
$$;
revoke all on function private.current_role() from public;
grant execute on function private.current_role() to authenticated;

create or replace function private.owns_store(target_store uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.stores where id = target_store and owner_id = (select auth.uid()))
$$;
revoke all on function private.owns_store(uuid) from public;
grant execute on function private.owns_store(uuid) to authenticated;

-- Enable RLS everywhere introduced by this migration.
alter table public.service_areas enable row level security;
alter table public.customer_addresses enable row level security;
alter table public.store_categories enable row level security;
alter table public.stores enable row level security;
alter table public.store_service_areas enable row level security;
alter table public.store_product_categories enable row level security;
alter table public.product_option_groups enable row level security;
alter table public.product_options enable row level security;
alter table public.merchant_subscriptions enable row level security;
alter table public.order_item_options enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.store_reviews enable row level security;

create policy service_areas_public_read on public.service_areas for select to anon, authenticated using (is_active);
create policy store_categories_public_read on public.store_categories for select to anon, authenticated using (is_active);
create policy addresses_owner_all on public.customer_addresses for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy stores_customer_read on public.stores for select to anon, authenticated using (
  approval_status = 'approved' and is_active and deleted_at is null
  and subscription_status in ('trial','active') and subscription_expires_at > now()
);
create policy stores_owner_read on public.stores for select to authenticated using (owner_id = (select auth.uid()));
create policy stores_owner_insert on public.stores for insert to authenticated with check (
  owner_id = (select auth.uid()) and private.current_role() = 'merchant' and approval_status = 'pending'
);
create policy stores_owner_update_pending on public.stores for update to authenticated
  using (owner_id = (select auth.uid()) and approval_status in ('pending','rejected'))
  with check (owner_id = (select auth.uid()) and approval_status in ('pending','rejected'));
create policy stores_admin_all on public.stores for all to authenticated
  using (private.current_role() = 'admin') with check (private.current_role() = 'admin');
create policy store_areas_public_read on public.store_service_areas for select to anon, authenticated using (
  is_active and exists(select 1 from public.stores s where s.id=store_id and s.approval_status='approved' and s.is_active and s.subscription_status in ('trial','active') and s.subscription_expires_at > now())
);
create policy store_areas_owner_all on public.store_service_areas for all to authenticated
  using (private.owns_store(store_id)) with check (private.owns_store(store_id));
create policy store_product_categories_public_read on public.store_product_categories for select to anon, authenticated using (is_active);
create policy store_product_categories_owner_all on public.store_product_categories for all to authenticated
  using (private.owns_store(store_id)) with check (private.owns_store(store_id));
create policy option_groups_public_read on public.product_option_groups for select to anon, authenticated using (
  exists(select 1 from public.products p join public.stores s on s.id=p.store_id where p.id=product_id and p.is_active and p.is_available and p.deleted_at is null and s.approval_status='approved' and s.is_active and s.subscription_status in ('trial','active') and s.subscription_expires_at > now())
);
create policy options_public_read on public.product_options for select to anon, authenticated using (is_available);
create policy subscriptions_owner_read on public.merchant_subscriptions for select to authenticated using (private.owns_store(store_id));
create policy subscriptions_admin_all on public.merchant_subscriptions for all to authenticated
  using (private.current_role()='admin') with check (private.current_role()='admin');
create policy inventory_owner_read on public.inventory_movements for select to authenticated using (private.owns_store(store_id));
create policy reviews_public_read on public.store_reviews for select to anon, authenticated using (status='published');
create policy reviews_customer_insert on public.store_reviews for insert to authenticated with check (
  customer_id=(select auth.uid()) and exists(select 1 from public.orders o where o.id=order_id and o.customer_id=(select auth.uid()) and o.store_id=store_id and o.status='delivered')
);

-- Replace permissive legacy product policy with marketplace-aware visibility.
drop policy if exists "Public read products" on public.products;
create policy products_marketplace_read on public.products for select to anon, authenticated using (
  is_active and is_available and deleted_at is null and store_id is not null and exists(
    select 1 from public.stores s where s.id=store_id and s.approval_status='approved' and s.is_active
      and s.subscription_status in ('trial','active') and s.subscription_expires_at > now()
  )
);
create policy products_owner_all on public.products for all to authenticated
  using (private.owns_store(store_id)) with check (private.owns_store(store_id));

-- Generic updated_at triggers.
do $$ declare t text; begin
  foreach t in array array['service_areas','customer_addresses','store_categories','stores','store_reviews'] loop
    execute format('drop trigger if exists set_updated_at on public.%I', t);
    execute format('create trigger set_updated_at before update on public.%I for each row execute function public.set_updated_at()', t);
  end loop;
end $$;

grant usage on schema public to anon, authenticated;
grant select on public.service_areas, public.store_categories, public.stores, public.store_service_areas,
  public.store_product_categories, public.product_option_groups, public.product_options, public.store_reviews to anon, authenticated;
grant select, insert, update, delete on public.customer_addresses to authenticated;
grant select, insert, update on public.stores to authenticated;
grant select, insert, update, delete on public.store_service_areas, public.store_product_categories to authenticated;
grant select, insert, update, delete on public.products, public.product_option_groups, public.product_options to authenticated;
grant select on public.merchant_subscriptions, public.inventory_movements to authenticated;
grant insert on public.store_reviews to authenticated;
