# Guia 5F - Dashboard Principal y Cierre Ciclo 1 (Flutter)

**Ciclo 1 · Sistema de Gestion de Tramites - Frontend (Flutter)**

> Objetivo: consolidar la navegacion principal, dashboard de inicio, perfil de usuario y pruebas de cierre del Ciclo 1 en este proyecto Flutter con GetX.

---

## 0. Requisitos

- Guias 1F-4F implementadas en el proyecto.
- Backend disponible y accesible desde el dispositivo/emulador.
- Flutter 3.11+ y Dart 3.11+.
- Dependencias instaladas con `flutter pub get`.

Nota de conectividad:
- La API se configura en `lib/config/environment.dart`.
- En Android emulator, usar `10.0.2.2` en lugar de `localhost`.

---

## 1. Estado actual del proyecto (verificado)

### Ya implementado

- `lib/screens/dashboard/dashboard_screen.dart`
- `lib/screens/profile/profile_screen.dart`
- `lib/screens/home/home_screen.dart`
- `lib/services/auth_service.dart`
- `lib/services/tramites_seguimiento_service.dart`
- `lib/models/tramite_resumen_model.dart`
- `lib/models/tramite_estado_model.dart`

### Pendiente para cerrar G5F

- Conectar `DashboardScreen` y `ProfileScreen` a rutas en `lib/routes/app_routes.dart`.
- Ajustar la navegacion para que el flujo principal use dashboard/perfil.
- Ejecutar pruebas funcionales finales de Ciclo 1.

---

## 2. Rutas principales (GetX)

Actualiza `lib/routes/app_routes.dart` para incluir dashboard y perfil.

### 2.1 Importar pantallas nuevas

```dart
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/profile/profile_screen.dart';
```

### 2.2 Declarar rutas

```dart
static const String dashboard = '/dashboard';
static const String profile = '/profile';
```

### 2.3 Registrar paginas protegidas

```dart
GetPage(
  name: dashboard,
  page: () => const DashboardScreen(),
  transition: Transition.fadeIn,
  middlewares: [AuthMiddleware()],
),
GetPage(
  name: profile,
  page: () => const ProfileScreen(),
  transition: Transition.fadeIn,
  middlewares: [AuthMiddleware()],
),
```

Recomendacion de navegacion inicial post-login:
- Mantener `/home` como hub rapido o redirigirlo a `/dashboard`.

---

## 3. Dashboard principal

Archivo base: `lib/screens/dashboard/dashboard_screen.dart`

### Funcionalidad actual

- Carga de tramites del usuario con `TramitesSeguimientoService.obtenerMisTramites()`.
- Estadisticas:
  - total
  - en_progreso (incluye `activo` y `en_progreso`)
  - completado
  - archivado
- Lista de tramites recientes.
- Acciones rapidas a:
  - `/tramites`
  - `/mis-tramites`
  - `/tramite-seguimiento` (con `arguments: tramite.id`)

### Verificaciones clave

- El endpoint `/workflow/mis-tramites` responde 200.
- `authService.getHeaders()` envia `Authorization: Bearer <token>`.
- Los estados del backend coinciden con el mapeo del frontend (`activo`, `en_progreso`, `completado`, `archivado`, `rechazado`).

---

## 4. Perfil de usuario

Archivo base: `lib/screens/profile/profile_screen.dart`

### Funcionalidad actual

- Lectura reactiva de `authService.usuarioActual` con `Obx`.
- Visualizacion de datos del usuario (nombre, email, rol, estado, id).
- Modo de edicion local (sin persistencia backend, reservado para Ciclo 2).
- Cierre de sesion desde la misma pantalla.

### Criterio de cierre G5F para perfil

- Debe ser accesible por ruta protegida (`/profile`).
- Debe mostrar datos del usuario autenticado.
- Debe permitir logout y regresar a `/login`.

---

## 5. Layout principal (equivalente Flutter de navbar + sidebar)

En Flutter no existe `AppLayoutComponent` como en Angular. El equivalente recomendado es:

- `Scaffold`
- `AppBar`
- `Drawer` (menu lateral)
- `BottomNavigationBar` (opcional)

Implementacion sugerida para este proyecto:
- Mantener `HomeScreen` como punto de entrada autenticado.
- Agregar `Drawer` en `HomeScreen` con accesos a:
  - Dashboard (`/dashboard`)
  - Explorar Tramites (`/tramites`)
  - Mis Tramites (`/mis-tramites`)
  - Perfil (`/profile`)
  - Logout

---

## 6. Flujo recomendado de navegacion

1. Usuario inicia sesion en `/login`.
2. Si login exitoso, navegar a `/dashboard` (o `/home` si se mantiene como hub).
3. Desde dashboard:
   - Ver resumen
   - Ir a tramites
   - Ir a seguimiento
4. Desde menu:
   - Ir a perfil
   - Cerrar sesion

---

## 7. Ajustes rapidos sugeridos (codigo)

### 7.1 Login: redirigir a dashboard

En `lib/screens/auth/login_screen.dart`, cambiar:

```dart
Get.offNamed('/home');
```

por:

```dart
Get.offNamed('/dashboard');
```

### 7.2 Home como fallback

Si prefieres mantener `HomeScreen`, deja botones a dashboard/perfil y tramites.

---

## 8. Checklist de implementacion - Guia 5F

- [ ] Ruta `/dashboard` agregada y protegida.
- [ ] Ruta `/profile` agregada y protegida.
- [ ] Login redirige al flujo principal deseado (`/dashboard` o `/home`).
- [ ] Dashboard muestra estadisticas y tramites recientes reales.
- [ ] Perfil muestra usuario autenticado y permite logout.
- [ ] Navegacion entre pantallas sin errores de rutas.
- [ ] Prueba responsive en Android/iOS/Web.

---

## 9. Pruebas finales del Ciclo 1

### 9.1 Autenticacion (G1F)

- [ ] Registro de cliente exitoso.
- [ ] Login exitoso y fallido.
- [ ] Token persistido en `shared_preferences`.
- [ ] Rutas protegidas bloquean acceso sin token.

### 9.2 Exploracion (G2F)

- [ ] Listado de politicas/tramites disponibles.
- [ ] Filtros y busqueda funcionales.
- [ ] Navegacion a detalle.

### 9.3 Envio (G3F)

- [ ] Formulario dinamico carga correctamente.
- [ ] Validaciones de campos.
- [ ] Envio exitoso y retorno de codigo.

### 9.4 Seguimiento (G4F)

- [ ] `MisTramitesScreen` carga datos.
- [ ] `TramiteSeguimientoScreen` muestra estado, progreso e historial.
- [ ] Navegacion por `arguments` con `tramiteId`.

### 9.5 Dashboard y cierre (G5F)

- [ ] Dashboard operativo con datos reales.
- [ ] Perfil operativo en ruta protegida.
- [ ] Logout limpia sesion y redirige a login.

---

## 10. Comandos de verificacion

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Si `flutter test` falla por pruebas desactualizadas de plantilla, ajustar `test/widget_test.dart` al flujo real de la app.

---

## 11. Resumen del Ciclo 1 (Flutter)

| Guia | Objetivo | Estado en este repo |
|------|----------|---------------------|
| G1F | Autenticacion JWT | Implementado |
| G2F | Exploracion de Tramites | Implementado |
| G3F | Envio de Tramites | Implementado |
| G4F | Seguimiento de Tramites | Implementado |
| G5F | Dashboard + Perfil + cierre | Parcial (faltan rutas e integracion final) |

Estado general:
- Base funcional de Ciclo 1 disponible.
- Para cerrar G5F falta integrar rutas dashboard/perfil y validar flujo completo E2E.

---

## 12. Proximos pasos (Ciclo 2)

- Notificaciones en tiempo real.
- Edicion de perfil persistente en backend.
- Recuperacion de contrasena.
- Mejoras UX/UI y accesibilidad.
- Pruebas automatizadas por modulo.
