# Plan de trabajo — App de Catálogo de Medicamentos (Android)

Fuente original (Notion, acceso privado):
https://app.notion.com/p/Plan-de-trabajo-3a51e5a1cc71803a85c8ca55dc36e634?source=copy_link

> Contenido pegado manualmente el 2026-07-28 para que quede versionado en el
> repo y accesible para todo el equipo sin depender de permisos de Notion.

## Decisión de stack (importante)

El plan original recomendaba **React Native + Expo + TypeScript**, por
aprovechar la experiencia previa del equipo en React/Next.js y por el
presupuesto ajustado ($10,000 MXN). **Se decidió explícitamente usar
Flutter + Dart en su lugar** (decisión del cliente, 2026-07-28), aceptando
que el aprendizaje de Dart puede tomar algo más de tiempo de lo estimado en
la sección 8 de este documento. El resto del plan (alcance, modelo de datos,
arquitectura offline-first, backend en Supabase) se mantiene igual.

---

## 1. Resumen

App móvil Android para vendedores de medicamentos, pensada para funcionar
**sin conexión a internet** (zonas sin señal) y **sincronizar
automáticamente** cuando el dispositivo recupera conexión. Incluye
catálogo, clientes, ventas e historial.

---

## 2. Funcionalidades clave

### Catálogo de productos

- Alta, edición y baja de medicamentos
- Campos: nombre, precio, stock, cantidad por caja/presentación, categoría,
  tipo (**genérico** o **de fórmula**), imagen (opcional)
- Categorías de medicamentos (ej. analgésicos, antibióticos, etc.)
- Buscador inteligente (por nombre, categoría, marca, coincidencias
  parciales/tolerantes a acentos y mayúsculas)

### Clientes

- Alta y gestión de clientes
- Historial de compras por cliente

### Ventas

- Registro de venta (selección de cliente, productos, cantidades)
- Historial general de ventas
- Historial de ventas por cliente
- Actualización automática de stock al vender

### Usuarios / vendedores

- Inicio de sesión
- Administrador puede agregar/gestionar otros vendedores
- Roles básicos (admin / vendedor)

### Modo offline

- La app debe ser 100% funcional sin internet: ver catálogo, registrar
  ventas, ver clientes
- Al recuperar conexión, sincroniza cambios locales con la base de datos
  central (subir ventas nuevas, bajar actualizaciones de catálogo/precios
  hechas por el admin)

---

## 3. Arquitectura recomendada (offline-first)

No es una app "online con caché": la base de datos local es la fuente de
verdad inmediata, y la nube es el respaldo/sincronización.

```
[App Android - Flutter]
   ├── Base de datos LOCAL (SQLite embebida vía Drift)
   │      → toda lectura/escritura diaria pasa por aquí
   │      → funciona 100% sin internet
   │
   ├── Capa de Sincronización
   │      → detecta conexión disponible
   │      → sube cambios locales (ventas, clientes nuevos)
   │      → descarga cambios remotos (catálogo actualizado por admin)
   │      → resuelve conflictos (ej. "última escritura gana" o por timestamp)
   │
   └── Backend en la nube (Supabase / Postgres)
          → catálogo maestro
          → usuarios y vendedores
          → respaldo centralizado de ventas
          → panel opcional para el admin (web) a futuro
```

**Puntos importantes a decidir con el cliente:**

- Si dos vendedores venden el mismo producto sin internet al mismo tiempo,
  el stock puede descuadrarse momentáneamente hasta sincronizar. Se debe
  definir una regla de negocio simple (ej. el stock "real" se ajusta en
  servidor y se notifica si hubo sobreventa).
- El admin necesita conexión al menos para dar de alta productos nuevos o
  nuevos vendedores (la creación de catálogo puede requerir estar en línea
  la primera vez).

---

## 4. Modelo de datos (entidades principales)

- **Usuarios/Vendedores**: id, nombre, email, rol (admin/vendedor), fecha de alta
- **Categorías**: id, nombre
- **Productos**: id, nombre, categoría, tipo (genérico/fórmula), precio, stock, unidades por caja, marca, estado (activo/descontinuado)
- **Clientes**: id, nombre, contacto, notas
- **Ventas**: id, cliente, vendedor, fecha, total
- **Detalle de venta**: venta_id, producto_id, cantidad, precio unitario al momento de la venta

---

## 5. MVP — qué incluye la primera versión

### Funciones incluidas

| Función | ¿Qué hace? |
| --- | --- |
| Iniciar sesión | Cada vendedor entra con su propio usuario y contraseña. El admin puede crear cuentas para otros vendedores. |
| Catálogo de medicamentos | Nombre, precio, existencias (stock), piezas por caja, genérico o de fórmula (marca). Alta, edición y baja. |
| Buscador | Por nombre (o parte del nombre), tolerante a acentos y mayúsculas. |
| Categorías | Analgésicos, antibióticos, etc. |
| Clientes | Datos del cliente + historial de compras siempre a la mano. |
| Registrar venta | Selección de cliente y productos; calcula total y descuenta stock automáticamente. |
| Historial de ventas | Por cliente o total general. |
| Funciona sin internet | Catálogo, ventas y clientes disponibles offline; sincroniza al recuperar conexión. |
| Soporte | Corrección de bugs esenciales post-entrega (no incluye mejoras futuras). |

### Carga inicial de catálogo (CSV, ~1000 SKUs)

Se toma el archivo (Excel/CSV) del cliente con sus medicamentos y se carga
directo a la app. Datos mínimos necesarios: nombre, precio, stock actual,
cantidad por caja, categoría, y si es genérico o de fórmula. Si falta algún
dato se completa manualmente después de la carga inicial.

### Fuera de alcance del MVP (se puede agregar después)

| Función futura | Motivo |
| --- | --- |
| Panel desde computadora | El MVP es solo para celular. |
| Reportes con gráficas / exportar a Excel-PDF | Fuera del alcance del MVP. |
| Avisos de stock bajo | Fuera del alcance del MVP. |
| Búsqueda avanzada (corrección ortográfica, sugerencias, IA, voz) | El buscador base ya cubre lo esencial. |
| Varias sucursales o bodegas | No solicitado en esta primera versión. |
| Publicación en Google Play Store | Se entrega la app lista para instalar; publicarla es un paso aparte (~$25 USD cuenta de desarrollador). |
| Notificaciones push | Fuera del alcance del MVP. |
| Diseño gráfico/UI personalizado de agencia | El MVP usa un diseño limpio y funcional. |
| Soporte/mantenimiento más allá del primer mes | Es un costo recurrente aparte. |

---

## 6. Backend: Supabase

- Postgres real: ideal para relaciones cliente → ventas → productos → categorías.
- Autenticación integrada (login de vendedores).
- Row Level Security (RLS): cada vendedor ve/gestiona lo que le corresponde según su rol.
- Tier gratuito generoso para el arranque; a futuro (miles de imágenes,
  muchos usuarios concurrentes) pasaría a un plan pago (~$25 USD/mes).

---

## 7. Plan de trabajo propuesto (referencia de fases)

| Fase | Contenido | Duración estimada |
| --- | --- | --- |
| 1. Diseño y modelado | Modelo de datos final, wireframes de pantallas clave | 3-4 días |
| 2. Setup de backend | Tablas, relaciones, autenticación, RLS en Supabase | 2 días |
| 3. Setup de app y base local | Proyecto Flutter, base local (SQLite/Drift), navegación | 2-3 días |
| 4. Módulo de catálogo | CRUD de productos, categorías, buscador | 4-5 días |
| 5. Módulo de clientes y ventas | Alta de clientes, registro de ventas, stock, historial | 4-5 días |
| 6. Sincronización offline | Subida/bajada de datos, manejo básico de conflictos | 3-4 días |
| 7. Login y roles | Autenticación, alta de vendedores por el admin | 2 días |
| 8. Pruebas y ajustes | Pruebas en campo (con y sin señal), corrección de errores | 3-4 días |

Estimado original: ~4-5 semanas trabajando de forma constante (estimado
para React Native; con Flutter puede tomar algo más por la curva de
aprendizaje de Dart).

---

## 8. Reglas de negocio pendientes de confirmar

- **Conflicto de stock**: si dos vendedores venden el mismo producto sin
  internet al mismo tiempo, ¿el servidor ajusta el stock real y notifica
  sobreventa? (regla propuesta por defecto, a confirmar).
- **Visibilidad de ventas**: ¿un vendedor solo ve su propio historial de
  ventas, o todos los vendedores ven el historial general? (por defecto se
  implementó: vendedor ve sus propias ventas, admin ve todas — ver
  [ARCHITECTURE.md](ARCHITECTURE.md)).
- **Alta de catálogo/vendedores**: requiere que el admin esté en línea la
  primera vez (no es una operación offline).
