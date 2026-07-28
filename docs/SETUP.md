# Setup del entorno de desarrollo

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal stable)
- [Supabase CLI](https://supabase.com/docs/guides/cli/getting-started)
- Docker Desktop (necesario para `supabase start` en local)
- Cuenta y proyecto en [Supabase](https://supabase.com)

## Primeros pasos

1. Clonar el repo e instalar dependencias de Flutter:

   ```bash
   flutter pub get
   ```

2. Generar las carpetas nativas de la plataforma (Android) sobre esta
   estructura ya existente, sin tocar `lib/` ni `pubspec.yaml`:

   ```bash
   flutter create --platforms=android --org com.carheva .
   ```

3. Copiar el archivo de variables de entorno de ejemplo y completarlo con las
   credenciales del proyecto de Supabase (Project Settings > API):

   ```bash
   cp .env.example .env
   ```

4. Generar el codigo de la base de datos local (Drift lee las tablas en
   `lib/core/database/tables/` y genera `app_database.g.dart`):

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

   Repetir este paso cada vez que se agregue o modifique una tabla en
   `lib/core/database/tables/`.

5. (Opcional) Levantar Supabase en local con Docker:

   ```bash
   supabase login
   supabase link --project-ref <project-ref>
   supabase start
   supabase db reset
   ```

6. Correr la app:

   ```bash
   flutter run
   ```

## Migraciones de base de datos

- Crear una migracion nueva: `supabase migration new <nombre>`
- Aplicar migraciones al proyecto remoto: `supabase db push`
- Traer el esquema remoto como migracion: `supabase db pull`
