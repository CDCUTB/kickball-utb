-- =============================================================
-- Torneo Interescuelas de Kickball UTB · Configuración de Supabase
-- Ejecuta todo este archivo una sola vez en: SQL Editor → New query → Run
-- =============================================================

-- 1. Tablas
create table if not exists public.resultados (
  id          text primary key,              -- p1 … p7
  data        jsonb not null,                -- estado, carreras por entrada, hora, lugar, nota
  updated_at  timestamptz not null default now()
);

create table if not exists public.evidencias (
  id       uuid primary key default gen_random_uuid(),
  partido  text not null,                    -- p1 … p7 o "general"
  equipo   text,                             -- iad | nlys | td
  nota     text,
  archivo  text not null,                    -- ruta dentro del bucket "evidencias"
  tipo     text,
  nombre   text,
  autor    text,                             -- correo de quien subió
  creado   timestamptz not null default now()
);

create table if not exists public.organizadores (
  email text primary key                     -- correos que pueden cargar resultados
);

-- 2. Seguridad por filas
alter table public.resultados    enable row level security;
alter table public.evidencias    enable row level security;
alter table public.organizadores enable row level security;

create or replace function public.es_organizador() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.organizadores o where o.email = lower(auth.jwt() ->> 'email'));
$$;

-- Resultados: cualquiera los ve; solo organizadores los cambian
drop policy if exists "resultados_ver" on public.resultados;
create policy "resultados_ver" on public.resultados for select using (true);
drop policy if exists "resultados_editar" on public.resultados;
create policy "resultados_editar" on public.resultados for all to authenticated
  using (public.es_organizador()) with check (public.es_organizador());

-- Evidencias: cualquiera las ve; usuarios con sesión suben; borra quien subió o un organizador
drop policy if exists "evidencias_ver" on public.evidencias;
create policy "evidencias_ver" on public.evidencias for select using (true);
drop policy if exists "evidencias_subir" on public.evidencias;
create policy "evidencias_subir" on public.evidencias for insert to authenticated
  with check (autor = lower(auth.jwt() ->> 'email'));
drop policy if exists "evidencias_borrar" on public.evidencias;
create policy "evidencias_borrar" on public.evidencias for delete to authenticated
  using (autor = lower(auth.jwt() ->> 'email') or public.es_organizador());

-- Organizadores: cada usuario solo puede comprobar su propio correo
drop policy if exists "organizadores_ver_propio" on public.organizadores;
create policy "organizadores_ver_propio" on public.organizadores for select to authenticated
  using (email = lower(auth.jwt() ->> 'email'));

-- 3. Almacenamiento de fotos, videos y PDF (máx. 20 MB por archivo)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('evidencias', 'evidencias', true, 20971520,
        array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm','application/pdf'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "evidencias_archivos_subir" on storage.objects;
create policy "evidencias_archivos_subir" on storage.objects for insert to authenticated
  with check (bucket_id = 'evidencias');
drop policy if exists "evidencias_archivos_borrar" on storage.objects;
create policy "evidencias_archivos_borrar" on storage.objects for delete to authenticated
  using (bucket_id = 'evidencias' and (owner = auth.uid() or public.es_organizador()));

-- 4. Organizador principal (agrega más correos con otra línea igual)
insert into public.organizadores (email) values ('hengonzalez@utb.edu.co') on conflict do nothing;
