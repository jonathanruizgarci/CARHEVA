# Arquitectura

## Stack

- **App**: Flutter (Dart) — offline-first, plataforma inicial: Android.
- **Base de datos local**: SQLite embebida vía [Drift](https://drift.simonbinder.eu/)
  — fuente de verdad inmediata; toda lectura/escritura diaria de la app pasa
  por aquí, funciona 100% sin internet.
- **Backend**: Supabase (Postgres, Auth, Storage), gestionado con el
  Supabase CLI y versionado en `supabase/`. Es el respaldo centralizado y
  el catálogo maestro, no la fuente de verdad inmediata.
- **Manejo de estado**: Riverpod (`flutter_riverpod`).
- **Navegacion**: `go_router`.
- **Detección de conectividad**: `connectivity_plus`.

Ver el [plan de trabajo](plan_de_trabajo.md) para el alcance completo del
MVP.

## Offline-first: por qué y cómo

Esta no es una app "online con caché": es offline-first. El vendedor debe
poder ver el catálogo, dar de alta clientes y registrar ventas sin señal.
Cuando el dispositivo recupera conexión, una capa de sincronización sube
los cambios locales pendientes y baja las actualizaciones del catálogo
hechas por el admin.

```
UI (Riverpod) ──lee/escribe──> Drift (SQLite local) <──sync──> Supabase (Postgres)
```

- **Lecturas**: la UI siempre lee de Drift, nunca directo de Supabase.
- **Escrituras** (venta nueva, cliente nuevo): se guardan primero en Drift
  y se encolan en una tabla `sync_queue` (outbox pattern).
- **Sincronización**: al detectar conexión (`connectivity_plus`), el
  `SyncService` sube lo que está en `sync_queue` y luego descarga cambios
  remotos de catálogo/precios más recientes que la última sincronización.
- **Conflictos**: resolución por "última escritura gana" según timestamp
  (`updated_at`) como estrategia inicial del MVP; el stock final se ajusta
  en el servidor si hubo sobreventa por ventas offline simultáneas (ver
  sección 8 del plan de trabajo — regla pendiente de confirmar con
  negocio).
- **Alta de catálogo/vendedores**: la crea el admin y requiere estar en
  línea la primera vez; no es una operación offline.

## Organizacion de `lib/`

Estructura feature-first: cada funcionalidad de negocio vive en su propia
carpeta bajo `features/`, con sus propias capas `data/`, `domain/` y
`presentation/`. El codigo compartido entre features vive en `core/`.

```
lib/
  app/            # Widget raiz (MaterialApp.router) y wiring general
  core/
    config/       # Configuracion (Supabase, env)
    constants/    # Constantes de la app
    database/     # Drift: base de datos local SQLite (fuente de verdad)
    errors/       # Failures/excepciones compartidas
    router/       # Definicion de rutas (go_router)
    sync/         # Capa de sincronizacion offline <-> Supabase
    theme/        # Tema visual
    utils/        # Utilidades compartidas
    widgets/      # Widgets compartidos entre features
  features/
    auth/             # Login, sesion, roles (admin/vendedor)
    catalog/           # Productos y categorias
    clients/            # Clientes e historial de compras
    sales/               # Registro de ventas e historial
    home/
      presentation/
        screens/
```

Cada feature sigue el mismo patron: `data/` (repositorios que hablan con
Drift y, cuando aplica, con Supabase), `domain/` (entidades de negocio) y
`presentation/` (`screens/`, `widgets/`, `providers/` de Riverpod).

## Organizacion de `supabase/`

```
supabase/
  config.toml       # Config del proyecto para el CLI (supabase start/link)
  migrations/        # Migraciones SQL versionadas (supabase db diff / push)
  functions/         # Edge Functions (Deno)
  seed.sql           # Datos de ejemplo para desarrollo local
```

Las migraciones son la unica fuente de verdad del esquema remoto: cualquier
cambio en la base de datos se hace creando una nueva migracion, nunca
editando el dashboard de Supabase directamente en produccion.

### Roles y RLS

- **admin**: gestiona productos, categorías y vendedores; puede ver todas
  las ventas.
- **vendedor**: puede leer el catálogo y los clientes, dar de alta clientes,
  y registrar/ver únicamente sus propias ventas.

Ver `supabase/migrations/` para las políticas de RLS concretas.

## Variables de entorno

La app lee `SUPABASE_URL` y `SUPABASE_ANON_KEY` desde un archivo `.env` en la
raiz del proyecto (no versionado). Ver [SETUP.md](SETUP.md).
