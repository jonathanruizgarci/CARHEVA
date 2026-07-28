-- Modelo de datos del MVP: categorias, productos, clientes, ventas y
-- detalle de venta. Ver docs/plan_de_trabajo.md seccion 4 y
-- docs/ARCHITECTURE.md ("Roles y RLS") para el contexto de negocio.

-- Helper para no repetir "role = 'admin'" en cada policy. SECURITY DEFINER
-- para poder leer profiles desde policies de otras tablas sin recursion.
create or replace function public.is_admin()
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ---------------------------------------------------------------------
-- Categorias
-- ---------------------------------------------------------------------
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.categories enable row level security;

create policy "Authenticated users can view categories"
  on public.categories for select
  to authenticated
  using (true);

create policy "Admins manage categories"
  on public.categories for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------
-- Productos
-- ---------------------------------------------------------------------
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category_id uuid references public.categories (id) on delete set null,
  type text not null check (type in ('generico', 'formula')),
  brand text,
  price numeric(10, 2) not null check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  units_per_box integer,
  status text not null default 'activo' check (status in ('activo', 'descontinuado')),
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists products_category_id_idx on public.products (category_id);
create index if not exists products_name_idx on public.products using gin (to_tsvector('spanish', name));

alter table public.products enable row level security;

create policy "Authenticated users can view products"
  on public.products for select
  to authenticated
  using (true);

create policy "Admins manage products"
  on public.products for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------
-- Clientes
-- ---------------------------------------------------------------------
create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  contact text,
  notes text,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists clients_created_by_idx on public.clients (created_by);

alter table public.clients enable row level security;

create policy "Authenticated users can view clients"
  on public.clients for select
  to authenticated
  using (true);

create policy "Authenticated users can create clients"
  on public.clients for insert
  to authenticated
  with check (created_by = auth.uid());

create policy "Owner or admin can update clients"
  on public.clients for update
  to authenticated
  using (created_by = auth.uid() or public.is_admin())
  with check (created_by = auth.uid() or public.is_admin());

create policy "Admins can delete clients"
  on public.clients for delete
  to authenticated
  using (public.is_admin());

-- ---------------------------------------------------------------------
-- Ventas
-- ---------------------------------------------------------------------
create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.clients (id) on delete set null,
  seller_id uuid not null references public.profiles (id) on delete restrict,
  total numeric(10, 2) not null default 0 check (total >= 0),
  created_at timestamptz not null default now()
);

create index if not exists sales_seller_id_idx on public.sales (seller_id);
create index if not exists sales_client_id_idx on public.sales (client_id);

alter table public.sales enable row level security;

create policy "Sellers view their own sales, admins view all"
  on public.sales for select
  to authenticated
  using (seller_id = auth.uid() or public.is_admin());

create policy "Sellers register their own sales"
  on public.sales for insert
  to authenticated
  with check (seller_id = auth.uid());

-- ---------------------------------------------------------------------
-- Detalle de venta
-- ---------------------------------------------------------------------
create table if not exists public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete restrict,
  quantity integer not null check (quantity > 0),
  unit_price numeric(10, 2) not null check (unit_price >= 0)
);

create index if not exists sale_items_sale_id_idx on public.sale_items (sale_id);
create index if not exists sale_items_product_id_idx on public.sale_items (product_id);

alter table public.sale_items enable row level security;

create policy "Visible if the parent sale is visible"
  on public.sale_items for select
  to authenticated
  using (
    exists (
      select 1 from public.sales s
      where s.id = sale_id and (s.seller_id = auth.uid() or public.is_admin())
    )
  );

create policy "Sellers add items to their own sales"
  on public.sale_items for insert
  to authenticated
  with check (
    exists (
      select 1 from public.sales s
      where s.id = sale_id and s.seller_id = auth.uid()
    )
  );

-- Descuenta stock automaticamente al registrar el detalle de una venta.
-- Regla de negocio por defecto (a confirmar, ver plan_de_trabajo.md #8):
-- el stock final se ajusta en el servidor; si dos vendedores vendieron el
-- mismo producto offline al mismo tiempo, el stock puede quedar en
-- negativo momentaneamente hasta que el admin lo revise.
create or replace function public.handle_sale_item_insert()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  update public.products
  set stock = stock - new.quantity,
      updated_at = now()
  where id = new.product_id;
  return new;
end;
$$;

create trigger on_sale_item_created
  after insert on public.sale_items
  for each row execute procedure public.handle_sale_item_insert();
