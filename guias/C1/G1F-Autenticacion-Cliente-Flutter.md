# Guía 1F — Autenticación JWT + Login/Registro Cliente (Flutter)

**Ciclo 1 · Sistema de Gestión de Trámites - Frontend (Flutter)**

> 🎯 **Objetivo:** Implementar pantalla de login y registro para clientes. Los clientes se autentican con JWT para acceder al sistema.

---

## 0. Requisitos

✅ Backend Ciclo 1 (G1-G5) compilando y ejecutándose en `http://localhost:8080`
✅ Flutter 3.11+ instalado
✅ Dart 3.11+ instalado
✅ pubspec.yaml con dependencias configuradas

---

## 1. Estructura de Carpetas Flutter

```
lib/
├── main.dart
├── config/
│   └── environment.dart
├── models/
│   ├── auth_model.dart
│   └── usuario_model.dart
├── services/
│   ├── auth_service.dart
│   ├── storage_service.dart
│   └── http_client.dart (opcional)
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   └── home/
│       └── home_screen.dart
├── routes/
│   └── app_routes.dart
├── middlewares/
│   └── auth_middleware.dart
└── widgets/
    └── (componentes reutilizables)
```

---

## 2. Dependencias Necesarias (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  
  # HTTP y Networking
  http: ^1.1.0
  
  # State Management y Navegación
  get: ^4.6.5
  
  # Almacenamiento local
  shared_preferences: ^2.2.0
  
  # Validación de formularios (opcional)
  form_validator: ^0.3.0
```

---

## 3. Modelos Dart (lib/models/)

### auth_model.dart
Define los modelos de LoginRequest, LoginResponse, RegisterRequest y RegisterResponse.

**Características:**
- Serialización a/desde JSON
- Tipado fuerte
- Validación básica

### usuario_model.dart
Define el modelo de Usuario.

**Características:**
- Método `copyWith()` para crear copias modificadas
- Serialización a/desde JSON

---

## 4. Configuración de Ambiente (lib/config/environment.dart)

```dart
class Environment {
  static const String apiUrl = 'http://localhost:8080/api';
  static const bool isProduction = false;
}
```

**Cambiar en producción** según sea necesario.

---

## 5. Servicio de Almacenamiento Local (lib/services/storage_service.dart)

Maneja:
- Guardar/obtener token JWT
- Guardar/obtener datos de usuario
- Limpiar storage (logout)
- Verificar si hay token

---

## 6. Servicio de Autenticación (lib/services/auth_service.dart)

Es un `GetxService` que proporciona:

### Métodos principales:
- `login(request)`: Autenticarse con email y contraseña
- `registrar(request)`: Registrar nuevo cliente
- `logout()`: Cerrar sesión
- `obtenerDatosUsuario()`: Obtener datos actuales del backend
- `getToken()`: Obtener token guardado
- `verificarAutenticacion()`: Verificar si está autenticado

### Observables (Rx):
- `usuarioActual`: Observable del usuario actual
- `isAuthenticated`: Observable del estado de autenticación

### Características:
- Manejo de errores HTTP
- Almacenamiento automático de tokens
- Restauración de sesión al inicializar
- Headers HTTP con token incluido

---

## 7. Pantallas de Autenticación

### LoginScreen (lib/screens/auth/login_screen.dart)

**Campos:**
- Email (validación de formato)
- Contraseña (mínimo 6 caracteres)

**Funcionalidades:**
- Validación en tiempo real con Form
- Mensaje de error si falla el login
- Botón "Registrarse" para navegar a registro
- Estado de carga durante petición HTTP

### RegisterScreen (lib/screens/auth/register_screen.dart)

**Campos:**
- Nombre (mínimo 3 caracteres)
- Email (validación de formato)
- Contraseña (mínimo 6 caracteres)
- Confirmar Contraseña (debe coincidir)

**Funcionalidades:**
- Validación de coincidencia de contraseñas
- Mensaje de éxito con redirección a login
- Botón "Inicia sesión" para navegar a login
- Estado de carga durante petición HTTP

---

## 8. HomeScreen (Pantalla Protegida)

Ejemplo de pantalla que requiere autenticación.

**Funcionalidades:**
- Muestra datos del usuario autenticado
- Botón de logout
- Protegida por AuthMiddleware
- Usa Obx para reactividad

---

## 9. Middleware de Autenticación (lib/middlewares/auth_middleware.dart)

Protege rutas que requieren autenticación.

**Uso:**
```dart
GetPage(
  name: '/home',
  page: () => const HomeScreen(),
  middlewares: [AuthMiddleware()],
)
```

---

## 10. Configuración de Rutas (lib/routes/app_routes.dart)

Define todas las rutas de la aplicación usando GetX:

```dart
static List<GetPage> pages = [
  GetPage(name: '/login', page: () => const LoginScreen()),
  GetPage(name: '/register', page: () => const RegisterScreen()),
  GetPage(
    name: '/home',
    page: () => const HomeScreen(),
    middlewares: [AuthMiddleware()],
  ),
];
```

---

## 11. Configuración Principal (lib/main.dart)

### Inicialización:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar StorageService
  final storageService = StorageService();
  await storageService.init();
  
  // Registrar servicios con GetX
  Get.put<StorageService>(storageService);
  Get.put<AuthService>(
    AuthService(storageService: storageService),
    permanent: true,
  );
  
  runApp(const MyApp());
}
```

### Configuración de GetMaterialApp:

```dart
GetMaterialApp(
  title: 'Sistema de Gestión de Trámites',
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    useMaterial3: true,
  ),
  initialRoute: AppRoutes.login,
  getPages: AppRoutes.pages,
  debugShowCheckedModeBanner: false,
)
```

---

## 12. Flujo de Autenticación

### Login:
1. Usuario ingresa email y contraseña
2. Se valida el formulario
3. Se envía solicitud POST a `/api/auth/login`
4. Si es exitoso:
   - Token se guarda en `shared_preferences`
   - Datos de usuario se guardan localmente
   - Se navega a `/home`
5. Si falla, se muestra mensaje de error

### Registro:
1. Usuario completa formulario
2. Se valida coincidencia de contraseñas
3. Se envía solicitud POST a `/api/auth/register-cliente`
4. Si es exitoso, se muestra mensaje y se redirige a login
5. Si falla, se muestra mensaje de error

### Restauración de Sesión:
1. Al iniciar la app, AuthService intenta restaurar sesión
2. Si hay token guardado, obtiene datos del usuario
3. Si las credenciales no son válidas (401), se limpia y se va a login

### Acceso a Rutas Protegidas:
1. AuthMiddleware verifica si está autenticado
2. Si no, redirige a `/login`
3. Si sí, permite acceso a la pantalla

---

## 13. Endpoints Utilizados

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login con email y contraseña |
| POST | `/api/auth/register-cliente` | Registrar nuevo cliente |
| GET | `/api/usuarios/me` | Obtener datos del usuario actual (requiere token) |

---

## 14. Acceso a Servicios desde Widgets

### Con GetX:
```dart
// En un widget
final authService = Get.find<AuthService>();

// Acceder a observables (reactivo)
Obx(() {
  final usuario = authService.usuarioActual.value;
  return Text(usuario?.nombre ?? '');
})

// Acceder a valores simples
final token = authService.getToken();
```

---

## 15. Datos de Prueba (MockData)

Para facilitar el desarrollo y testing, se proporciona un archivo `lib/mock/mock_data.dart` con datos de prueba precargados.

### Clientes de Prueba Disponibles:

```dart
/// Cliente
MockData.clienteTest
{
  'email': 'cliente@cre.bo',
  'password': 'cliente12345',
  'nombre': 'Juan',
  'apellido': 'Pérez',
  'tipo': 'cliente',
  'rol': 'Cliente',
}

/// Funcionario (para próximas guías)
MockData.funcionarioTest
{
  'email': 'funcionario@cre.bo',
  'password': 'funcionario12345',
  'nombre': 'María',
  'apellido': 'García',
  'tipo': 'funcionario',
  'rol': 'Funcionario',
}

/// Administrador (para próximas guías)
MockData.administradorTest
{
  'email': 'admin@cre.bo',
  'password': 'admin12345',
  'nombre': 'Carlos',
  'apellido': 'López',
  'tipo': 'administrador',
  'rol': 'Administrador',
}
```

### Usar Datos de Prueba en la App:

En las pantallas de **Login** y **Registro**, hay un botón **"Usar datos de prueba"** que rellena automáticamente los formularios con los datos del cliente.

**Ejemplo en LoginScreen:**
```dart
void _fillMockData() {
  _emailController.text = MockData.clienteTest['email'];
  _passwordController.text = MockData.clienteTest['password'];
}
```

---

## 16. Checklist de Implementación

- [x] Actualizar pubspec.yaml con dependencias
- [x] Crear estructura de carpetas
- [x] Crear modelos Dart (auth_model.dart, usuario_model.dart)
- [x] Crear configuración de ambiente (environment.dart)
- [x] Implementar StorageService
- [x] Implementar AuthService como GetxService
- [x] Crear AuthMiddleware
- [x] Crear LoginScreen
- [x] Crear RegisterScreen
- [x] Crear HomeScreen (ejemplo)
- [x] Configurar rutas con AppRoutes
- [x] Actualizar main.dart

### Siguientes Pasos:
- [ ] Ejecutar `flutter pub get` para descargar dependencias
- [ ] Ejecutar `flutter run` para probar
- [ ] Verificar que el login funciona
- [ ] Verificar que el registro funciona
- [ ] Verificar que el token se guarda en shared_preferences
- [ ] Implementar G2F: Exploración de trámites disponibles

---

## 17. Notas Importantes

⚠️ **Seguridad:**
- El token se guarda en SharedPreferences. Para mayor seguridad en producción, considera usar métodos más seguros como Android Keystore o Keychain en iOS.
- La URL del backend está hardcodeada. En producción, considera usar variables de entorno.
- Nunca expongas credenciales en el código.

📝 **Debugging:**
- Para ver peticiones HTTP, añade un http.Client custom con logging
- Usa `Get.log()` para debug en GetX
- Inspecciona SharedPreferences con `flutter pub global activate shared_preferences_cli`

🔄 **Hot Reload:**
- El Hot Reload funciona bien con Flutter
- El Hot Restart reinicia la app pero mantiene las preferencias guardadas
- Para limpiar SharedPreferences en desarrollo, elimina la app y reinstala

---

## 18. Diferencias con Angular

| Aspecto | Angular | Flutter |
|--------|---------|---------|
| **State Management** | RxJS Observables + Subjects | GetX Rx + Obx |
| **Almacenamiento** | localStorage nativo | shared_preferences |
| **HTTP** | HttpClient de Angular | http package |
| **Validación** | Validators de Angular | Validadores customizados |
| **Navegación** | Router Angular | GetX Get.to/Get.offNamed |
| **Inyección** | Angular DI | GetX Get.put |
| **Formularios** | Reactive Forms | Form con GlobalKey |
| **Middleware** | HTTP Interceptors | GetX Middlewares |

---

## 19. Comandos Útiles

```bash
# Descargar dependencias
flutter pub get

# Ejecutar app
flutter run

# Release build
flutter build apk      # Android
flutter build ipa      # iOS
flutter build web      # Web

# Limpiar cache
flutter clean

# Ver estructura del proyecto
tree lib -L 3
```

---

## 20. Referencia Rápida de GetX

```dart
// Obtener un servicio
final authService = Get.find<AuthService>();

// Navegar
Get.to(() => const MyScreen());
Get.toNamed('/ruta');
Get.off(() => const MyScreen());
Get.offNamed('/ruta');

// Observables
Obx(() => Text(authService.usuarioActual.value?.nombre ?? ''))

// Dialogs
Get.defaultDialog(title: 'Confirmar', middleText: '¿Estás seguro?');

// Snackbars
Get.snackbar('Éxito', 'Operación completada');
```

---

¡Implementación completada! 🚀
