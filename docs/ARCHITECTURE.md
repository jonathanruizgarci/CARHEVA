# Arquitectura

## Stack

- **App**: Flutter (Dart) — single codebase, plataforma inicial: Android.
- **Backend**: Supabase (Postgres, Auth, Storage, Edge Functions), gestionado
  con el Supabase CLI y versionado en `supabase/`.
- **Manejo de estado**: Riverpod (`flutter_riverpod`).
- **Navegacion**: `go_router`.

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
    errors/       # Failures/excepciones compartidas
    router/       # Definicion de rutas (go_router)
    theme/        # Tema visual
    utils/        # Utilidades compartidas
    widgets/      # Widgets compartidos entre features
  features/
    auth/
      data/           # Repositorios que hablan con Supabase
      domain/         # Entidades / casos de uso (cuando aplique)
      presentation/
        screens/
        widgets/
        providers/    # Riverpod providers de este feature
    home/
      presentation/
        screens/
```

Nuevos features (clientes, pedidos, productos, visitas, etc.) se agregan
siguiendo el mismo patron una vez que el alcance quede definido en
[plan_de_trabajo.md](plan_de_trabajo.md).

## Organizacion de `supabase/`

```
supabase/
  config.toml       # Config del proyecto para el CLI (supabase start/link)
  migrations/        # Migraciones SQL versionadas (supabase db diff / push)
  functions/         # Edge Functions (Deno)
  seed.sql           # Datos de ejemplo para desarrollo local
```

Las migraciones son la unica fuente de verdad del esquema: cualquier cambio
en la base de datos se hace creando una nueva migracion, nunca editando el
dashboard de Supabase directamente en produccion.

## Variables de entorno

La app lee `SUPABASE_URL` y `SUPABASE_ANON_KEY` desde un archivo `.env` en la
raiz del proyecto (no versionado). Ver [SETUP.md](SETUP.md).
