# Reconfiguración del Mobile (Flutter)

> Guía operativa para reconectar la app móvil Flutter al PC cuando el teléfono se desconecta del USB o falla la conexión con el backend.
>
> **Audiencia:** otra IA o desarrollador que retoma el trabajo sin contexto previo.

---

## 1. Estado de referencia (lo que normalmente está montado)

| Cosa | Valor |
|------|-------|
| Proyecto Flutter | `C:\Users\Isael Ortiz\Documents\1PSW1 - copia\mobile` |
| Dispositivo físico | Xiaomi Redmi (modelo `2201116TG`, Android 13) |
| Serial ADB | `RS5LDM4PFIUO8LAE` |
| Backend (Spring Boot) | `http://localhost:8080` en la PC |
| URL configurada en `lib/config/environment.dart` | `http://localhost:8080/api` |
| Modo de conexión esperado | USB con `adb reverse` activo |

---

## 2. Diagnóstico rápido (qué chequear primero)

Ejecuta estos 3 comandos en PowerShell en este orden:

```powershell
adb devices
flutter devices
curl http://localhost:8080/api/health
```

Resultado esperado:
1. `adb devices` debe listar un dispositivo con estado `device` (no `unauthorized` ni `offline`).
2. `flutter devices` debe incluir el modelo del teléfono (`2201116TG (mobile) • RS5LDM4PFIUO8LAE • android-arm64`).
3. `curl ... /api/health` debe devolver código 200 con un JSON (`{"status":"UP"}` o similar).

Si alguno falla, busca el caso correspondiente abajo.

---

## 3. Casos comunes

### Caso A — `adb devices` no muestra nada

Significa que el USB no está conectado o no está autorizado para depuración.

**Pasos:**
1. Desconecta y vuelve a conectar el cable USB.
2. En el teléfono, baja la barra de notificaciones → verifica el modo USB. Debe estar en **"Transferencia de archivos (MTP)"** o **"Sin transferencia de datos"**. NO en "Solo carga" porque eso desactiva ADB en algunos Xiaomi.
3. En el teléfono, abre **Ajustes → Opciones del desarrollador**, confirma que está activo:
   - ✅ Depuración USB
   - ✅ Instalar vía USB (Xiaomi-específico)
   - ✅ Depuración USB (Configuración de seguridad) (Xiaomi-específico, requiere tarjeta SIM)
4. Vuelve a ejecutar `adb devices`. Debería aparecer.
5. Si aparece como `unauthorized`, mira la pantalla del teléfono: hay un diálogo *"Permitir depuración USB"* — marca "Permitir siempre desde este equipo" y acepta.

Si `adb` no se encuentra como comando, está en `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`. Agrega esa carpeta al PATH o invoca con la ruta completa.

### Caso B — `adb devices` muestra el dispositivo pero `flutter devices` no

Reinicia el daemon de ADB:

```powershell
adb kill-server
adb start-server
adb devices
flutter devices
```

Si sigue sin aparecer en `flutter devices` pero sí en `adb devices`, ejecuta `flutter doctor -v` y revisa que la sección "Android toolchain" no muestre errores.

### Caso C — La app arranca pero TODAS las llamadas HTTP fallan con `TimeoutException`

El teléfono no puede alcanzar al backend. Hay que decidir qué URL usar en `lib/config/environment.dart` según cómo está el teléfono conectado al PC:

| Conexión | Valor de `apiUrl` | Pre-requisito |
|----------|-------------------|----------------|
| **USB con `adb reverse` activo** (recomendado) | `http://localhost:8080/api` | Ejecutar `adb reverse tcp:8080 tcp:8080` después de cada reconexión USB |
| Misma WiFi que el PC | `http://<IP-LAN-del-PC>:8080/api` | Obtener IP con `ipconfig`. El firewall de Windows debe permitir el puerto 8080 entrante |
| Mobile Hotspot del PC (Windows) | `http://192.168.137.1:8080/api` | El PC comparte conexión vía Hotspot |
| Emulador Android (AVD) | `http://10.0.2.2:8080/api` | Solo emulador, no dispositivo físico |
| Producción | `http://44.213.74.152:8080/api` | El backend EC2 debe estar arriba |

**Si está conectado por USB, la opción más simple es `adb reverse`:**

```powershell
adb reverse tcp:8080 tcp:8080
adb reverse --list   # confirma que aparece "tcp:8080 tcp:8080"
```

Esto hace que cuando la app pida `localhost:8080`, ADB redirige a `localhost:8080` del PC. **Se pierde con cada desconexión USB**; hay que volver a ejecutarlo.

Si en su lugar quieres conectar por IP LAN, edita [`lib/config/environment.dart`](lib/config/environment.dart):

```dart
class Environment {
  static const String apiUrl = 'http://192.168.X.X:8080/api';  // ← IP de la PC
  static const bool isProduction = false;
}
```

Para obtener la IP del PC:
```powershell
ipconfig | findstr IPv4
```

### Caso D — Quiero pasar a conexión WiFi (sin cable USB)

Una vez funcionando por USB, se puede cortar el cable y seguir trabajando por WiFi:

```powershell
adb tcpip 5555
adb connect 192.168.X.X:5555    # IP del teléfono en la WiFi (no del PC)
adb devices                      # ahora debe aparecer la IP:5555
```

Para saber la IP del teléfono: Ajustes → Acerca del teléfono → Estado → Dirección IP.

Después de conectar por WiFi, en `environment.dart` usa la IP LAN del **PC**, no de localhost (porque `adb reverse` no funciona sobre TCP).

### Caso E — `adb reverse` falla con "more than one device/emulator"

Especifica el serial:

```powershell
adb -s RS5LDM4PFIUO8LAE reverse tcp:8080 tcp:8080
```

### Caso F — App muestra el primer error "Network error" pero después funciona

Es el bug conocido del `NetworkController` que se dispara antes de que MaterialApp esté montado. Ya está mitigado en `lib/controllers/network_controller.dart` (el primer chequeo es silencioso). Si reaparece tras un cambio, verifica que la primera llamada a `_updateStatus` setea `_bootstrapped = true` y retorna sin mostrar `Get.snackbar`.

---

## 4. Comandos de uso diario

### Arrancar la app

```powershell
cd "C:\Users\Isael Ortiz\Documents\1PSW1 - copia\mobile"
adb reverse tcp:8080 tcp:8080    # solo si conectaste el USB hace poco
flutter run
```

Cuando la consola muestre el menú interactivo:
- `r` → hot reload (rápido, recoge cambios en código Dart)
- `R` → hot restart (reinicia el estado, recoge cambios estructurales)
- `q` → cerrar la app

> ⚠️ Si cambias `pubspec.yaml`, `main.dart`, o agregas un paquete nativo, hay que **detener (`q`) y volver a `flutter run`** — el hot restart no es suficiente.

### Reinstalar limpio (cuando el comportamiento es muy raro)

```powershell
flutter clean
flutter pub get
adb uninstall com.example.mobile   # opcional, borra datos persistidos en el teléfono
flutter run
```

### Verificar logs en vivo del teléfono (sin Flutter)

```powershell
adb logcat -s flutter
```

### Asegurar que el backend está arriba

```powershell
curl http://localhost:8080/api/health
docker compose -f "C:\Users\Isael Ortiz\Documents\1PSW1 - copia\Backend\docker-compose.yml" ps
```

Si la base de datos no responde:
```powershell
docker compose -f "C:\Users\Isael Ortiz\Documents\1PSW1 - copia\Backend\docker-compose.yml" up -d
```

---

## 5. Checklist mínimo cuando se cae todo

Si entras al proyecto y nada funciona, haz esto en orden:

1. `docker desktop` → arrancar Docker Desktop manualmente si no está corriendo (búsqueda en menú inicio).
2. `docker compose -f "...\Backend\docker-compose.yml" up -d` — arranca MongoDB.
3. En `Backend\`, `.\gradlew.bat bootRun` — arranca Spring Boot. Espera el mensaje `Started DemoApplication in X.X seconds`.
4. Conecta el teléfono por USB. Autoriza depuración si aparece el diálogo.
5. `adb devices` — confirma que aparece como `device`.
6. `adb reverse tcp:8080 tcp:8080` — redirige `localhost` del teléfono al PC.
7. `cd "C:\Users\Isael Ortiz\Documents\1PSW1 - copia\mobile"`
8. `flutter run` — arranca la app.

---

## 6. Credenciales de prueba sembradas (no cambies sin avisar)

Las credenciales del seed están en `Backend/src/main/java/com/example/demo/config/seeders/UsuarioSeeder.java`. Las más usadas para pruebas mobile:

| Email | Rol |
|-------|-----|
| `cliente@cre.bo` | Cliente (app móvil) |
| `cliente2@cre.bo` | Cliente |
| `cliente3@cre.bo` | Cliente |
| `funcionario@cre.bo` | Funcionario (web) |
| `admin@cre.bo` | Administrador (web) |

Password por defecto: el que sea que defina el seeder (verificar en el archivo si dudas). En `application.yml`, `app.seed.reset: true` significa que MongoDB se reinicia con cada arranque del backend.

---

## 7. Problemas conocidos a vigilar

- **`RenderFlex overflowed by X pixels`**: revisa que los `Text` largos dentro de un `Row` estén envueltos en `Expanded` con `overflow: TextOverflow.ellipsis`.
- **`Null check operator used on a null value` en `NetworkController`**: ya mitigado con `_bootstrapped` flag — si reaparece, garantiza que el primer `_updateStatus` no llame `Get.snackbar`.
- **TimeoutException 10s en cada request**: el teléfono no llega al backend. Aplicar Caso C.
- **El log de `flutter run` parece mostrar el bug arreglado**: el log se acumula entre hot restarts. Para validar de verdad, presiona `q`, vuelve a `flutter run`, reproduce y mira solo los logs nuevos.

---

## 8. Estado al cierre de esta sesión (referencia histórica)

| Componente | Estado |
|-----------|--------|
| Backend Spring Boot | arranca con `gradlew bootRun`, puerto 8080 |
| MongoDB (Docker) | container `tramites_mongodb` |
| Mongo Express | http://localhost:8081 |
| App Flutter | corre en USB con `adb reverse tcp:8080 tcp:8080` |
| Login que el usuario está probando | `cliente@cre.bo` |
| Fix abierto | overflows de `Row` en `tramite_seguimiento_screen.dart` (líneas 161, 248, 559) — todos con `Expanded + ellipsis` |
