# CARHEVA

Aplicacion movil de ventas para el sector medico-farmaceutico.

- **App**: Flutter (Dart), gestor de estado Riverpod, navegacion go_router.
- **Backend**: Supabase (Postgres, Auth, Storage, Edge Functions).

## Documentacion

Todo el contexto del proyecto vive versionado en [`docs/`](docs/), para que
el equipo completo tenga acceso sin depender de permisos externos:

- [Plan de trabajo](docs/plan_de_trabajo.md) — objetivo, alcance y roadmap.
- [Arquitectura](docs/ARCHITECTURE.md) — stack y organizacion del codigo.
- [Setup del entorno](docs/SETUP.md) — como levantar el proyecto localmente.

## Quickstart

```bash
flutter pub get
cp .env.example .env   # completar con las credenciales de Supabase
flutter run
```

Ver [docs/SETUP.md](docs/SETUP.md) para el detalle completo, incluyendo
Supabase CLI.
