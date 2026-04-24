# 🚦 Parcial Flutter — Accidentes Tuluá + CRUD Establecimientos

Aplicación Flutter desarrollada como parcial de la asignatura **Electiva Profesional I** en la Unidad Central del Valle del Cauca (UCEVA). Integra dos módulos: visualización de estadísticas de accidentes de tránsito en Tuluá procesadas con `Isolate`, y un CRUD completo de establecimientos consumiendo una API REST con soporte de carga de imágenes.

---

## Tabla de contenidos

1. [Descripción de las APIs](#descripción-de-las-apis)
2. [Future/async/await vs Isolate](#futureasyncawait-vs-isolate)
3. [Arquitectura y estructura del proyecto](#arquitectura-y-estructura-del-proyecto)
4. [Rutas con go_router](#rutas-con-go_router)
5. [Paquetes utilizados](#paquetes-utilizados)
6. [Ejemplos de respuesta JSON](#ejemplos-de-respuesta-json)
7. [Capturas de pantalla](#capturas-de-pantalla)
8. [Cómo ejecutar el proyecto](#cómo-ejecutar-el-proyecto)

---

## Descripción de las APIs

### API 1 — Accidentes de Tránsito en Tuluá (Datos Abiertos Colombia)

| Campo | Valor |
|---|---|
| **Fuente** | Datos Abiertos Colombia — datos.gov.co |
| **Base URL** | `https://www.datos.gov.co/resource/ezt8-5wyj.json` |
| **Autenticación** | No requerida |
| **Formato** | JSON directo |
| **Documentación** | https://www.datos.gov.co |

#### Endpoints usados

| Método | URL | Descripción |
|---|---|---|
| GET | `/resource/ezt8-5wyj.json?$limit=100000` | Carga masiva de todos los registros para procesamiento estadístico |

#### Campos relevantes del JSON

| Campo | Tipo | Descripción |
|---|---|---|
| `a_o` | String | Año del accidente |
| `fecha` | String | Fecha completa del accidente |
| `dia` | String | Día de la semana (lunes, martes, etc.) |
| `hora` | String | Hora del accidente |
| `area` | String | Área (URBANA / RURAL) |
| `barrio_hecho` | String | Barrio donde ocurrió el accidente |
| `clase_de_accidente` | String | Tipo: CHOQUE, ATROPELLO, VOLCAMIENTO, etc. |
| `gravedad_del_accidente` | String | Gravedad: CON MUERTOS, CON HERIDOS, SOLO DAÑOS |
| `clase_de_vehiculo` | String | Tipo de vehículo involucrado |
| `clase_de_servicio` | String | Servicio del vehículo (PARTICULAR, PÚBLICO, etc.) |

---

### API 2 — Establecimientos (API Parqueadero VisionTic)

| Campo | Valor |
|---|---|
| **Fuente** | Sistema de parqueadero VisionTic |
| **Base URL** | `https://parking.visiontic.com.co/api` |
| **Autenticación** | No requerida |
| **Formato** | JSON con wrapper `{success, data}` |
| **Documentación** | https://parking.visiontic.com.co/api/documentation |

#### Endpoints usados

| Método | URL | Descripción |
|---|---|---|
| GET | `/establecimientos` | Listar todos los establecimientos |
| GET | `/establecimientos/{id}` | Obtener un establecimiento por ID |
| POST | `/establecimientos` | Crear establecimiento (multipart/form-data) |
| POST | `/establecimiento-update/{id}` | Editar establecimiento (`_method=PUT` en form-data) |
| DELETE | `/establecimientos/{id}` | Eliminar establecimiento |

> **Nota sobre el método PUT:** La API usa *method spoofing* de Laravel. Para editar, se envía una petición `POST` al endpoint `/establecimiento-update/{id}` incluyendo el campo `_method=PUT` en el `form-data`.

#### Campos relevantes del JSON

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | int | Identificador único |
| `nombre` | String | Nombre del establecimiento |
| `nit` | String | NIT del establecimiento |
| `direccion` | String | Dirección física |
| `telefono` | String | Teléfono de contacto |
| `logo` | String | Nombre del archivo de imagen (ej: `sin-imagen.png`) |
| `estado` | String | Estado: `A` (Activo) / `I` (Inactivo) |
| `created_at` | String | Fecha de creación |
| `updated_at` | String | Fecha de última actualización |

> **URL del logo:** `https://parking.visiontic.com.co/storage/{logo}`

---

## Future/async/await vs Isolate

### ¿Cuándo usar Future/async/await?

`Future` con `async/await` es la herramienta correcta cuando la tarea involucra **operaciones de I/O**: llamadas a APIs, lectura de archivos, consultas a bases de datos. Estas operaciones son inherentemente no bloqueantes porque el tiempo de espera lo gestiona el sistema operativo, no el procesador.

```dart
// Correcto: operación de red con async/await
Future<List<Establecimiento>> getAll() async {
  final response = await _dio.get('$_base/establecimientos');
  return response.data['data'].map(...).toList();
}
```

**Características:**
- La UI permanece responsiva mientras espera
- No crea un hilo nuevo — usa el event loop de Dart
- Ideal para tiempos de espera externos (red, disco)
- Overhead mínimo

### ¿Cuándo usar Isolate?

`Isolate` es necesario cuando la tarea es **intensiva en CPU** (CPU-bound): cálculos matemáticos complejos, procesamiento de grandes volúmenes de datos, cifrado, parsing masivo. Si se ejecuta directamente en el hilo principal, la UI se congela.

```dart
// Correcto: tarea CPU-bound en Isolate
final stats = await compute(calcularEstadisticas, accidentes);
```

**Características:**
- Crea un hilo de ejecución independiente con su propia memoria
- La UI sigue respondiendo mientras el Isolate trabaja
- Comunicación por mensajes (no comparte memoria)
- Overhead mayor — solo justificado para tareas pesadas

### ¿Por qué se eligió Isolate para el procesamiento estadístico?

El endpoint `?$limit=100000` puede descargar **miles de registros de accidentes**. El procesamiento implica:

1. Iterar todos los registros
2. Clasificar cada accidente por clase, gravedad, barrio y día
3. Ordenar los barrios para obtener el Top 5
4. Construir 4 estructuras de datos para las gráficas

Si este procesamiento se ejecutara en el hilo principal, la UI se **congelaría completamente** durante varios segundos. Al usar `compute()` (que internamente usa `Isolate.run()`), el procesamiento ocurre en un hilo separado y la UI muestra el `Skeletonizer` mientras espera.

```dart
// En accidentes_view.dart
final accidentes = await AccidentesService().getAll();    // I/O → async/await
final stats = await compute(calcularEstadisticas, accidentes); // CPU → Isolate
```

**Mensajes en consola que evidencian el Isolate:**
```
[Isolate] Iniciado — 8432 registros recibidos
[Isolate] Completado en 312 ms
```

---

## Arquitectura y estructura del proyecto

El proyecto sigue una arquitectura en capas con separación estricta de responsabilidades:

```
parcial_2/
├── lib/
│   ├── config/
│   │   └── app_config.dart              # URLs base desde .env (AppConfig)
│   │
│   ├── models/
│   │   ├── accidente_model.dart         # Modelo Accidente con fromJson
│   │   ├── estadisticas_model.dart      # Resultado del Isolate (4 mapas)
│   │   └── establecimiento_model.dart   # Modelo Establecimiento con fromJson
│   │
│   ├── services/
│   │   ├── accidentes_service.dart      # GET masivo con Dio a Datos Abiertos
│   │   └── establecimiento_service.dart # CRUD completo con Dio (multipart)
│   │
│   ├── isolates/
│   │   └── accidentes_isolate.dart      # Función pura que calcula las 4 estadísticas
│   │
│   ├── routes/
│   │   └── app_router.dart              # GoRouter centralizado con 6 rutas
│   │
│   ├── themes/
│   │   └── app_theme.dart               # Tema visual global
│   │
│   ├── views/
│   │   ├── dashboard/
│   │   │   └── dashboard_view.dart      # Home con 2 cards + resumen con Skeletonizer
│   │   ├── accidentes/
│   │   │   └── accidentes_view.dart     # 4 gráficas con fl_chart + Isolate
│   │   └── establecimientos/
│   │       ├── establecimientos_view.dart        # Listado con Skeletonizer
│   │       ├── establecimiento_detalle_view.dart  # Detalle + botones editar/eliminar
│   │       └── establecimiento_form_view.dart     # Formulario crear/editar + image_picker
│   │
│   ├── widgets/
│   │   └── estado_widget.dart           # Widget reutilizable: Cargando / Error / Éxito
│   │
│   └── main.dart                        # Punto de entrada — carga .env
│
├── .env                                 # Variables de entorno (URLs base)
└── pubspec.yaml                         # Dependencias del proyecto
```

### Descripción de cada capa

**`config/`** — `AppConfig` expone las URLs base leyendo el archivo `.env` con `flutter_dotenv`. Centraliza la configuración evitando URLs hardcodeadas.

**`models/`** — Clases Dart tipadas con `fromJson`. `EstadisticasAccidentes` contiene los 4 mapas resultantes del Isolate. Todos usan `??` para manejar nulos de forma segura.

**`services/`** — Toda la lógica HTTP está aquí, usando `Dio`. `EstablecimientoService` maneja el CRUD completo incluyendo `FormData` para multipart y el method spoofing `_method=PUT`. **Ningún widget hace peticiones HTTP directamente.**

**`isolates/`** — Contiene la función pura `calcularEstadisticas()` que recibe la lista de accidentes y retorna las 4 estadísticas. Es una función de nivel superior (no un método de clase) porque `compute()` lo requiere.

**`routes/`** — `GoRouter` centraliza todas las rutas. Las rutas de establecimientos usan parámetros de path (`:id`) para navegación maestro-detalle.

**`views/`** — Pantallas organizadas por módulo. Todas las vistas con datos son `StatefulWidget`. Ninguna vista contiene lógica HTTP — toda petición va a través de `services/`.

**`widgets/`** — `EstadoWidget` es el componente reutilizable que renderiza spinner, error con botón reintentar, o el contenido exitoso.

---

## Rutas con go_router

Todas las rutas están definidas en `lib/routes/app_router.dart`:

```dart
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',                              // DashboardView
      builder: (c, s) => const DashboardView()),
    GoRoute(path: '/accidentes',                   // AccidentesView
      builder: (c, s) => const AccidentesView()),
    GoRoute(path: '/establecimientos',             // EstablecimientosView
      builder: (c, s) => const EstablecimientosView()),
    GoRoute(path: '/establecimientos/crear',       // Formulario crear
      builder: (c, s) => const EstablecimientoFormView()),
    GoRoute(path: '/establecimientos/:id',         // Detalle por ID
      builder: (c, s) => EstablecimientoDetalleView(
        id: int.parse(s.pathParameters['id']!))),
    GoRoute(path: '/establecimientos/:id/editar',  // Formulario editar
      builder: (c, s) => EstablecimientoFormView(
        id: int.parse(s.pathParameters['id']!))),
  ],
);
```

### Tabla de rutas

| Ruta | Parámetros | Pantalla | Descripción |
|---|---|---|---|
| `/` | Ninguno | `DashboardView` | Pantalla principal con resumen y acceso a módulos |
| `/accidentes` | Ninguno | `AccidentesView` | 4 gráficas procesadas con Isolate |
| `/establecimientos` | Ninguno | `EstablecimientosView` | Listado con Skeletonizer y FAB para crear |
| `/establecimientos/crear` | Ninguno | `EstablecimientoFormView` | Formulario de creación con image_picker |
| `/establecimientos/:id` | `id`: int | `EstablecimientoDetalleView` | Detalle completo + botones editar y eliminar |
| `/establecimientos/:id/editar` | `id`: int | `EstablecimientoFormView` | Formulario precargado para edición |

### Flujo de navegación

```
DashboardView
    │
    ├── context.push('/accidentes')
    │       └── AccidentesView (4 gráficas)
    │
    └── context.push('/establecimientos')
            └── EstablecimientosView
                    │
                    ├── FAB → context.push('/establecimientos/crear')
                    │             └── EstablecimientoFormView (crear)
                    │
                    └── Item → context.push('/establecimientos/$id')
                                  └── EstablecimientoDetalleView
                                          │
                                          └── Editar → context.push('/establecimientos/$id/editar')
                                                          └── EstablecimientoFormView (editar)
```

---

## Paquetes utilizados

```yaml
dependencies:
  dio: ^5.9.2              # Peticiones HTTP y multipart/form-data
  go_router: ^17.2.2       # Navegación declarativa con parámetros de path
  flutter_dotenv: ^6.0.1   # Variables de entorno desde archivo .env
  fl_chart: ^1.2.0         # Gráficas PieChart y BarChart
  skeletonizer: ^2.1.3     # Efecto skeleton mientras cargan los datos
  image_picker: ^1.2.1     # Selección de imagen desde galería o cámara
```

| Paquete | Uso en el proyecto |
|---|---|
| `dio` | GET masivo a Datos Abiertos + CRUD completo con multipart a API Parqueadero |
| `go_router` | Navegación entre las 6 rutas con parámetros `:id` para maestro-detalle |
| `flutter_dotenv` | Carga `BASE_URL_ACCIDENTES` y `BASE_URL_PARQUEADERO` desde `.env` |
| `fl_chart` | 2 PieChart (clase y gravedad) + 2 BarChart (barrios y días) |
| `skeletonizer` | Efecto de carga en Dashboard, Listado de establecimientos y Accidentes |
| `image_picker` | Selección del logo desde galería al crear o editar un establecimiento |
| `compute` | Ejecuta `calcularEstadisticas()` en un Isolate separado (incluido en Flutter) |

---

## Ejemplos de respuesta JSON

### API 1 — Accidentes de Tránsito
`GET https://www.datos.gov.co/resource/ezt8-5wyj.json?$limit=3`

```json
[
  {
    "a_o": "2023",
    "fecha": "2023-01-03T00:00:00.000",
    "dia": "martes",
    "hora": "15:40:00",
    "area": "URBANA",
    "direccion_hecho": "CARRERA 21 CALLE 32",
    "controles_de_transito": "VERTICAL",
    "barrio_hecho": "SAJONIA",
    "clase_de_accidente": "CHOQUE",
    "clase_de_servicio": "PARTICULAR",
    "gravedad_del_accidente": "CON HERIDOS",
    "clase_de_vehiculo": "MOTOCICLETA",
    "cordenada_geografica_": {
      "type": "Point",
      "coordinates": [-76.201795, 4.080615]
    }
  },
  {
    "a_o": "2023",
    "fecha": "2023-01-01T00:00:00.000",
    "dia": "domingo",
    "hora": "03:30:00",
    "area": "URBANA",
    "barrio_hecho": "No informa",
    "clase_de_accidente": "CHOQUE",
    "clase_de_servicio": "PARTICULAR",
    "gravedad_del_accidente": "CON MUERTO",
    "clase_de_vehiculo": "MOTOCICLETA"
  }
]
```

### API 2 — Establecimientos
`GET https://parking.visiontic.com.co/api/establecimientos`

```json
{
  "success": true,
  "data": [
    {
      "id": 43,
      "nombre": "UCEVA 3 XD",
      "nit": "963555",
      "direccion": "CRA 40",
      "telefono": "96325",
      "logo": "fwnUwhV4kNdtlR6H4RM5gkNcXb5WsgaulvnSif9W.jpg",
      "estado": "A",
      "created_at": "2025-10-17T01:56:05.000000Z",
      "updated_at": "2026-04-23T20:09:58.000000Z"
    },
    {
      "id": 45,
      "nombre": "pedro",
      "nit": "2377439439856397462",
      "direccion": "cra639",
      "telefono": "3265874369",
      "logo": "sin-imagen.png",
      "estado": "A",
      "created_at": "2025-10-24T02:58:58.000000Z",
      "updated_at": "2025-10-24T02:58:58.000000Z"
    }
  ]
}
```

### API 2 — Detalle de establecimiento
`GET https://parking.visiontic.com.co/api/establecimientos/43`

```json
{
  "success": true,
  "data": {
    "id": 43,
    "nombre": "UCEVA 3 XD",
    "nit": "963555",
    "direccion": "CRA 40",
    "telefono": "96325",
    "logo": "fwnUwhV4kNdtlR6H4RM5gkNcXb5WsgaulvnSif9W.jpg",
    "estado": "A",
    "created_at": "2025-10-17T01:56:05.000000Z",
    "updated_at": "2026-04-23T20:09:58.000000Z"
  }
}
```

---

## Capturas de pantalla

### Dashboard

#### Estado Cargando (Skeletonizer)
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/c9d66b9e-6ef5-412a-88f2-27f109cd6ff3" />


#### Dashboard con datos
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/3ae3b58b-d491-4d5d-a5a0-e9cce1ba6a9b" />


---

### Módulo Accidentes

#### Estado Cargando (Skeletonizer)
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/43287581-b9ce-4ef8-9823-51427ee4846d" />


#### Consola — mensajes del Isolate
> <img width="1920" height="1032" alt="image" src="https://github.com/user-attachments/assets/0fd0de04-47cc-4359-bc39-6bd81d9f2f70" />


#### Gráfica 1 — Distribución por clase de accidente (PieChart)
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/d4f892af-c5d8-4040-9c4c-79dec93c75fe" />


#### Gráfica 2 — Distribución por gravedad (PieChart)
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/e2f35403-514e-4a03-88d4-98313ab21b42" />


#### Gráfica 3 — Top 5 barrios con más accidentes (BarChart)
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/bdb54cbd-a9dd-44a1-ba39-1984d66be6e5" />


#### Gráfica 4 — Distribución por día de la semana (BarChart)
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/1d156f0b-2b61-4b05-93cf-db558f41e993" />


---

### Módulo Establecimientos

#### Listado — Estado Cargando (Skeletonizer)
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/554516cc-6f2d-4ca5-9357-c3791f8cd70d" />


#### Listado con datos
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/cc2084e7-5ca9-4f01-b8d2-3cde074f743e" />


#### Detalle de establecimiento
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/4284ae3c-a3d5-4ac5-afc0-c2e5da9fb303" />


#### Formulario — Crear establecimiento
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/a823f10c-e31a-41d1-82db-651481afea46" />


#### Formulario — Crear con imagen seleccionada
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/18d003ea-9228-40d2-a025-ce0e6e4e506b" />


#### Formulario — Editar establecimiento
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/27a87eb8-f9ad-4546-82be-7df2600a69a0" />


#### Eliminar — Diálogo de confirmación
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/3966d2ba-7daa-4dd9-ade5-3218c85e397e" />


#### Estado Error
> <img width="409" height="864" alt="image" src="https://github.com/user-attachments/assets/4bd40a43-7162-4924-a21f-6600f8551a37" />


---

## Cómo ejecutar el proyecto

### Requisitos previos
- Flutter SDK 3.x instalado (`flutter --version` para verificar)
- Android Studio con emulador configurado (API 34 recomendado)
- VS Code con extensiones Flutter y Dart
- Modo desarrollador de Windows activado

### Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/Diego3126/parcial_2.git
cd parcial_2

# 2. Instalar dependencias
flutter pub get

# 3. Verificar el entorno
flutter doctor

# 4. Ejecutar la app
flutter run
```

### Archivo .env requerido
```
BASE_URL_ACCIDENTES=https://www.datos.gov.co/resource/ezt8-5wyj.json
BASE_URL_PARQUEADERO=https://parking.visiontic.com.co/api
```

### Comandos útiles
```bash
r   # Hot Reload
R   # Hot Restart
q   # Salir
```

---

## Referencias

- [Datos Abiertos Colombia — Accidentes Tuluá](https://www.datos.gov.co/resource/ezt8-5wyj.json)
- [API Parqueadero — Swagger](https://parking.visiontic.com.co/api/documentation)
- [Dart — compute() function](https://api.flutter.dev/flutter/foundation/compute.html)
- [Flutter — Isolates](https://docs.flutter.dev/perf/isolates)
- [fl_chart — pub.dev](https://pub.dev/packages/fl_chart)
- [skeletonizer — pub.dev](https://pub.dev/packages/skeletonizer)
- [image_picker — pub.dev](https://pub.dev/packages/image_picker)
- [go_router — pub.dev](https://pub.dev/packages/go_router)
- [dio — pub.dev](https://pub.dev/packages/dio)

---

*Proyecto desarrollado por Diego Fernando España Valderrama · Electiva Profesional I · UCEVA 2026*
