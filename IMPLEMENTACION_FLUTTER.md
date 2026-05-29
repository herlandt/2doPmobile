# 📱 Implementación de Autenticación JWT en Flutter

## ✅ Resumen de Implementación

Se ha adaptado la Guía G1F de Angular a **Flutter**, implementando un sistema completo de autenticación JWT con login y registro de clientes.

---

## 📁 Archivos Creados

### Configuración
- `lib/config/environment.dart` - URLs de API y configuración

### Modelos
- `lib/models/auth_model.dart` - LoginRequest, LoginResponse, RegisterRequest, RegisterResponse
- `lib/models/usuario_model.dart` - Modelo de Usuario

### Servicios
- `lib/services/auth_service.dart` - Servicio principal de autenticación (GetxService)
- `lib/services/storage_service.dart` - Almacenamiento local con SharedPreferences
- `lib/services/http_client_service.dart` - Cliente HTTP con headers automáticos

### Pantallas
- `lib/screens/auth/login_screen.dart` - Pantalla de login
- `lib/screens/auth/register_screen.dart` - Pantalla de registro
- `lib/screens/home/home_screen.dart` - Pantalla protegida de ejemplo

### Rutas y Middleware
- `lib/routes/app_routes.dart` - Configuración de rutas con GetX
- `lib/middlewares/auth_middleware.dart` - Middleware de protección de rutas

### Archivos Modificados
- `lib/main.dart` - Punto de entrada con inicialización de servicios
- `pubspec.yaml` - Dependencias necesarias (http, get, shared_preferences)

### Documentación
- `guias/C1/G1F-Autenticacion-Cliente-Flutter.md` - Guía completa adaptada a Flutter

---

## 🚀 Cómo Empezar

### 1. Descargar Dependencias
```bash
cd mobile
flutter pub get
```

### 2. Ejecutar la App
```bash
flutter run
```

### 3. Probar
- **Login**: Usa las credenciales de un usuario registrado en el backend
- **Registro**: Crea una nueva cuenta
- **Token**: Se guarda automáticamente en SharedPreferences
- **Protección**: La ruta `/home` está protegida por AuthMiddleware

---

## 🔑 Características Principales

### ✨ AuthService (GetxService)
- Login y registro de usuarios
- Manejo automático de tokens JWT
- Observables reactivos (usuarioActual, isAuthenticated)
- Restauración de sesión al iniciar
- Métodos para obtener token y verificar autenticación

### 💾 StorageService
- Almacenamiento seguro con SharedPreferences
- Métodos para guardar/obtener token y datos de usuario
- Método clear() para logout

### 🛣️ Rutas con GetX
- Navegación simple con Get.to() y Get.toNamed()
- Middlewares para proteger rutas
- Transiciones suaves (fadeIn)

### 📱 Pantallas
- **LoginScreen**: Validación de email y contraseña
- **RegisterScreen**: Validación de nombre, email y confirmación de contraseña
- **HomeScreen**: Ejemplo de pantalla protegida que muestra datos del usuario

---

## 🔄 Flujo de Autenticación

```
┌─────────────┐
│   Login     │
│  Screen     │
└──────┬──────┘
       │ Valida formulario
       │ Llama authService.login()
       ▼
┌─────────────┐
│   Backend   │ POST /api/auth/login
│   (JWT)     │◄────────────────────────
└──────┬──────┘
       │ Token + Usuario
       ▼
┌─────────────┐
│ Storage     │ Guarda token y datos
│ Service     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Home       │ Pantalla protegida
│  Screen     │ (con AuthMiddleware)
└─────────────┘
```

---

## 🔐 Seguridad

- Token JWT almacenado en SharedPreferences
- Headers HTTP incluyen token automáticamente (Bearer)
- Invalidación de sesión en respuesta 401 (token expirado)
- Middleware protege rutas autenticadas
- Validación de formularios en el cliente

---

## 📦 Dependencias Utilizadas

| Paquete | Versión | Uso |
|---------|---------|-----|
| `get` | ^4.6.5 | State management, navegación, inyección |
| `http` | ^1.1.0 | Peticiones HTTP |
| `shared_preferences` | ^2.2.0 | Almacenamiento local |
| `form_validator` | ^0.3.0 | Validación de formularios (opcional) |

---

## 🎯 Endpoints del Backend

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login con email y contraseña |
| POST | `/api/auth/register-cliente` | Registrar nuevo cliente |
| GET | `/api/usuarios/me` | Obtener datos del usuario autenticado |

---

## 📝 Próximos Pasos

Las siguientes guías continuarán con:
- G2F: Exploración de trámites disponibles
- G3F: Envío de nuevos trámites
- G4F: Seguimiento de estado
- G5F: UI principal y navegación

---

## 💡 Comparación Angular vs Flutter

### Autenticación en Angular
```typescript
// Angular
this.http.post('/api/auth/login', request)
  .pipe(tap(response => localStorage.setItem('token', response.token)))
```

### Autenticación en Flutter
```dart
// Flutter
final response = await http.post(Uri.parse(url), body: jsonEncode(request));
await storageService.saveToken(loginResponse.token);
```

### Diferencias Clave

| Aspecto | Angular | Flutter |
|---------|---------|---------|
| **Navegación** | Angular Router | GetX Get.to/GetPage |
| **Storage** | localStorage | SharedPreferences |
| **Observables** | RxJS | GetX Rx/Obx |
| **Interceptores** | HttpInterceptor | HttpClientService custom |
| **Inyección** | ng inject | GetX Get.put |

---

## 🐛 Troubleshooting

### Token no se guarda
- Verificar que `StorageService.init()` se llamó en main.dart
- Revisar permisos en Android (AndroidManifest.xml)

### Las rutas protegidas no funcionan
- Verificar que AuthMiddleware está registrado en la ruta
- Asegurar que `verificarAutenticacion()` retorna true

### El backend retorna 401
- El token puede estar expirado
- Las credenciales pueden ser inválidas
- El endpoint puede requerir autenticación y no tiene token

### Hot reload no funciona bien
- Usa `flutter run -v` para debug
- Intenta hot restart en lugar de hot reload
- Limpia con `flutter clean`

---

## 📚 Recursos Útiles

- [Documentación de GetX](https://github.com/jonataslaw/getx/blob/master/README.es.md)
- [http package](https://pub.dev/packages/http)
- [shared_preferences](https://pub.dev/packages/shared_preferences)
- [Flutter Docs](https://docs.flutter.dev)

---

¡Implementación completa! ✨ Continúa con las guías G2F, G3F, G4F y G5F.
