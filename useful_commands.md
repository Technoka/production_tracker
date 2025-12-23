# Comandos Útiles para el Desarrollo

## 🚀 Comandos de Inicio Rápido

### Crear y configurar el proyecto desde cero

```bash
# 1. Crear el proyecto Flutter
flutter create gestion_produccion
cd gestion_produccion

# 2. Instalar FlutterFire CLI (solo una vez)
dart pub global activate flutterfire_cli

# 3. Configurar Firebase automáticamente
flutterfire configure

# 4. Instalar dependencias
flutter pub get

# 5. Ejecutar la aplicación
flutter run
```

---

## 📦 Gestión de Dependencias

```bash
# Instalar dependencias del pubspec.yaml
flutter pub get

# Actualizar dependencias
flutter pub upgrade

# Ver dependencias desactualizadas
flutter pub outdated

# Limpiar caché de dependencias
flutter pub cache repair
```

---

## 🏗️ Comandos de Build

```bash
# Limpiar proyecto
flutter clean

# Compilar para Android (Debug)
flutter build apk --debug

# Compilar para Android (Release)
flutter build apk --release

# Compilar para Android (Split por arquitectura)
flutter build apk --split-per-abi

# Ver información del proyecto
flutter doctor -v
```

---

## 📱 Ejecutar en Dispositivos

```bash
# Ver dispositivos conectados
flutter devices

# Ejecutar en dispositivo específico
flutter run -d <device_id>

# Ejecutar en modo release
flutter run --release

# Hot reload (mientras la app está corriendo)
# Presiona 'r' en la terminal

# Hot restart (mientras la app está corriendo)
# Presiona 'R' en la terminal
```

---

## 🔍 Debugging

```bash
# Ejecutar con verbose logging
flutter run --verbose

# Ver logs en tiempo real
flutter logs

# Analizar el proyecto
flutter analyze

# Ejecutar tests
flutter test
```

---

## 🛠️ Android Específico

```bash
# Limpiar build de Android
cd android
./gradlew clean
cd ..

# Verificar problemas de Android
cd android
./gradlew assembleDebug
cd ..

# Ver logs de Android
adb logcat | grep flutter
```

---

## 🔥 Firebase

```bash
# Reconfigurar Firebase
flutterfire configure

# Ver configuración actual de Firebase
cat lib/firebase_options.dart

# Actualizar reglas de seguridad (desde firebase console)
# No hay comando CLI directo, usar Firebase Console
```

---

## 📊 Análisis de Código

```bash
# Formatear código
flutter format .

# Análisis estático
flutter analyze

# Verificar problemas comunes
dart fix --apply
```

---

## 🐛 Solución de Problemas

```bash
# Cuando nada funciona - limpieza completa
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run

# Resetear Flutter
flutter clean
rm -rf .dart_tool
rm -rf build
rm pubspec.lock
flutter pub get

# Verificar instalación de Flutter
flutter doctor

# Reparar Flutter
flutter doctor --android-licenses
```

---

## 📝 Git

```bash
# Inicializar repositorio
git init
git add .
git commit -m "Initial commit"

# Conectar con GitHub
git remote add origin https://github.com/tuusuario/gestion_produccion.git
git branch -M main
git push -u origin main

# Crear .gitignore para Flutter
# (Ya viene incluido con flutter create)

# Actualizar repositorio
git add .
git commit -m "Descripción del cambio"
git push
```

---

## 🔄 Actualización de la App

```bash
# Verificar versión actual
grep 'version:' pubspec.yaml

# Incrementar versión (manualmente en pubspec.yaml)
# version: 1.0.0+1  ->  version: 1.1.0+2

# Compilar nueva versión
flutter build apk --release
```

---

## 📱 Gestión de Emuladores

```bash
# Ver emuladores disponibles
flutter emulators

# Crear nuevo emulador AVD
# (Usar Android Studio > AVD Manager)

# Iniciar emulador desde línea de comandos
flutter emulators --launch <emulator_id>
```

---

## 🎯 Atajos de VSCode

### Durante la ejecución:
- `r` - Hot reload
- `R` - Hot restart
- `q` - Quit
- `h` - Ayuda
- `s` - Tomar screenshot
- `w` - Ver widget tree

### En VSCode:
- `F5` - Iniciar debugging
- `Shift + F5` - Detener debugging
- `Ctrl + F5` - Ejecutar sin debugging

---

## 📊 Rendimiento

```bash
# Ejecutar con modo profile
flutter run --profile

# Compilar con optimizaciones
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Analizar tamaño del APK
flutter build apk --analyze-size
```

---

## 🔧 Mantenimiento Regular

```bash
# Actualizar Flutter
flutter upgrade

# Actualizar dependencias
flutter pub upgrade

# Limpiar proyecto
flutter clean

# Verificar salud del proyecto
flutter doctor
flutter analyze

# Actualizar Firebase
flutterfire configure
```

---

## 💡 Tips Útiles

### Acelerar compilación en Android:
Agregar en `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx4096m
org.gradle.parallel=true
org.gradle.daemon=true
org.gradle.configureondemand=true
```

### Ver cambios en tiempo real:
- Usa Hot Reload (`r`) para cambios de UI
- Usa Hot Restart (`R`) para cambios de lógica

### Debugging efectivo:
- Usa `print()` para debugging básico
- Usa `debugPrint()` para debugging en producción
- Usa breakpoints en VSCode

---

## 🚨 Comandos de Emergencia

```bash
# Cuando todo falla:
flutter clean
flutter pub cache repair
flutter pub get
cd android
./gradlew clean
cd ..
rm -rf build
flutter run

# Si persisten los errores de Firebase:
rm lib/firebase_options.dart
flutterfire configure
flutter pub get
flutter run
```

---

## 📚 Recursos Adicionales

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire](https://firebase.flutter.dev/)
- [Pub.dev](https://pub.dev/) - Paquetes de Flutter