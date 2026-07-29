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

   El proyecto de Supabase ya existe (ref `lmvkezxtahkizurhizbk`); pide el
   `.env` con la anon key al resto del equipo por un canal privado (Slack,
   1Password, etc.) — nunca se versiona en el repo.

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
- Aplicar migraciones al proyecto remoto manualmente: `supabase db push`
- Traer el esquema remoto como migracion: `supabase db pull`

### Despliegue automatico de migraciones (CI)

El workflow [`.github/workflows/supabase-migrations.yml`](../.github/workflows/supabase-migrations.yml)
se encarga de:

- **En cada Pull Request** contra `main` que toque `supabase/migrations/**`:
  corre `supabase db push --dry-run` para validar que las migraciones nuevas
  aplican limpio contra el proyecto real, sin modificar nada.
- **Al hacer merge/push a `main`**: aplica esas migraciones de verdad con
  `supabase db push`.

Para que el workflow funcione, hay que configurar estos secretos en
**GitHub → Settings → Secrets and variables → Actions** del repo
(`jonathanruizgarci/CARHEVA`) — la anon key **no sirve para esto**, hacen
falta credenciales con permisos de administracion:

| Secreto | De donde sale |
| --- | --- |
| `SUPABASE_ACCESS_TOKEN` | [supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens) → "Generate new token" |
| `SUPABASE_DB_PASSWORD` | La contraseña de la base de datos del proyecto (se define al crear el proyecto; si no la tienes, se puede resetear en Project Settings → Database → Reset database password) |

El `project-ref` (`lmvkezxtahkizurhizbk`) ya esta en el workflow, no hace
falta agregarlo como secreto.
