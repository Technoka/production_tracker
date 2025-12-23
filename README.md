# Sistema de Gestión de Producción - Flutter + Firebase

## 📋 Requisitos Previos

- Flutter SDK (versión 3.0 o superior)
- Android Studio
- Visual Studio Code
- Cuenta de Firebase
- Git

---

## 🚀 Configuración Paso a Paso

### 1. Configuración de Firebase

#### 1.1 Crear Proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Agregar proyecto"
3. Nombre del proyecto: `gestion-produccion` (o el que prefieras)
4. Desactiva Google Analytics (opcional)
5. Haz clic en "Crear proyecto"

#### 1.2 Habilitar Authentication

1. En el menú lateral, ve a **Build → Authentication**
2. Haz clic en "Comenzar"
3. Habilita **"Correo electrónico/contraseña"**
4. Guarda los cambios

#### 1.3 Crear Firestore Database

1. En el menú lateral, ve a **Build → Firestore Database**
2. Haz clic en "Crear base de datos"
3. Selecciona **"Iniciar en modo de prueba"**
4. Elige la ubicación más cercana (ej: `us-central1`)
5. Haz clic en "Habilitar"

#### 1.4 Configurar Reglas de Seguridad

En la pestaña **"Reglas"** de Firestore, reemplaza el contenido con:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    match /projects/{projectId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'manufacturer';
      allow update, delete: if request.auth != null && 
                            get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'manufacturer';
    }
    
    match /products/{productId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'manufacturer';
      allow update, delete: if request.auth != null && 
                            get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'manufacturer';
    }
  }
}
```

Haz clic en **"Publicar"**.

---

### 2. Registrar App Android en Firebase

1. En la página principal de tu proyecto Firebase, haz clic en el ícono de **Android** (</> o robot)
2. Registra tu app:
   - **Nombre del paquete Android**: `com.tuempresa.gestionproduccion`
   - **Alias de la app**: Gestión Producción
   - **Certificado SHA-1**: (opcional, déjalo en blanco por ahora)
3. Haz clic en **"Registrar app"**
4. **IMPORTANTE**: Descarga el archivo `google-services.json`
5. Guarda este archivo en `android/app/google-services.json` (en tu proyecto Flutter)

---

### 3. Configurar Flutter con FlutterFire CLI (RECOMENDADO)

Esta es la forma más fácil de configurar Firebase:

#### 3.1 Instalar FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

#### 3.2 Configurar Firebase automáticamente

Desde la raíz de tu proyecto Flutter:

```bash
flutterfire configure
```

Esto creará automáticamente el archivo `lib/firebase_options.dart` con la configuración correcta para Android e iOS.

---

### 4. Configuración Manual (Alternativa)

Si prefieres configurar manualmente o FlutterFire CLI no funciona:

#### 4.1 Crear estructura de carpetas

```
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   ├── user_model.dart
│   ├── project_model.dart
│   └── product_model.dart
├── services/
│   ├── auth_service.dart
│   └── firestore_service.dart
└── screens/
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── home_screen.dart
    ├── manufacturer/
    │   ├── manufacturer_dashboard.dart
    │   ├── create_project_screen.dart
    │   ├── project_detail_screen.dart
    │   ├── create_product_screen.dart
    │   └── product_detail_screen.dart
    └── client/
        ├── client_dashboard.dart
        ├── client_project_detail.dart
        └── client_product_detail.dart
```

#### 4.2 Actualizar `lib/firebase_options.dart`

Reemplaza los valores placeholder con los valores reales de tu proyecto Firebase (puedes encontrarlos en la configuración del proyecto en Firebase Console).

---

### 5. Instalar Dependencias

Desde la terminal, en la raíz del proyecto:

```bash
flutter pub get
```

---

### 6. Configuración de Android

#### 6.1 Verificar `android/app/build.gradle`

Asegúrate de que el archivo esté configurado correctamente (ya proporcionado en los artefactos).

#### 6.2 Verificar `android/build.gradle`

Asegúrate de que el archivo esté configurado correctamente (ya proporcionado en los artefactos).

#### 6.3 Colocar `google-services.json`

Asegúrate de que el archivo `google-services.json` descargado de Firebase esté en:
```
android/app/google-services.json
```

---

### 7. Ejecutar la Aplicación

#### 7.1 Abrir Emulador de Android

Abre Android Studio y lanza un emulador Android (AVD).

#### 7.2 Ejecutar desde VSCode

```bash
flutter run
```

O presiona `F5` en VSCode.

---

## 🎯 Funcionalidades Implementadas

### Para Fabricantes:
- ✅ Registro y login con correo/contraseña
- ✅ Crear proyectos y asignar clientes
- ✅ Ver lista de proyectos
- ✅ Cambiar estado de proyectos
- ✅ Crear productos dentro de proyectos
- ✅ Ver detalles de productos
- ✅ Cambiar etapas de productos
- ✅ Ver historial de etapas

### Para Clientes:
- ✅ Registro y login con correo/contraseña
- ✅ Ver proyectos asignados (solo lectura)
- ✅ Ver productos en tiempo real
- ✅ Ver estado actual y progreso
- ✅ Ver historial de etapas completo
- ✅ Visualización de porcentaje de completado

---

## 📱 Flujo de Uso

### Primera vez (Fabricante):

1. **Registrarse** como fabricante
2. **Crear un proyecto** con nombre, descripción y cliente asignado
3. **Añadir productos** al proyecto con sus detalles
4. **Actualizar etapas** conforme avanza la producción

### Primera vez (Cliente):

1. **Registrarse** como cliente
2. **Esperar** a que un fabricante te asigne a un proyecto
3. **Ver en tiempo real** el estado de tus productos
4. **Consultar historial** de etapas

---

## 🔧 Solución de Problemas Comunes

### Error: "google-services.json not found"
**Solución**: Asegúrate de haber descargado el archivo desde Firebase Console y colocarlo en `android/app/google-services.json`

### Error de compilación en Android
**Solución**: 
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: "Failed to connect to Firebase"
**Solución**: Verifica que `lib/firebase_options.dart` tenga los valores correctos de tu proyecto Firebase.

### Error: "Permission denied" al crear proyecto/producto
**Solución**: Verifica que las reglas de seguridad en Firestore estén configuradas correctamente.

---

## 📊 Estructura de Base de Datos (Firestore)

### Colección: `users`
```
users/{userId}
  - uid: string
  - email: string
  - name: string
  - role: string ('manufacturer' | 'client')
  - createdAt: timestamp
```

### Colección: `projects`
```
projects/{projectId}
  - id: string
  - name: string
  - description: string
  - manufacturerId: string
  - clientId: string
  - status: string
  - createdAt: timestamp
  - updatedAt: timestamp
```

### Colección: `products`
```
products/{productId}
  - id: string
  - projectId: string
  - name: string
  - description: string
  - quantity: number
  - currentStage: string
  - batchNumber: string
  - stages: array
    - name: string
    - status: string
    - startedAt: timestamp
    - completedAt: timestamp (optional)
    - notes: string (optional)
  - createdAt: timestamp
  - updatedAt: timestamp
```

---

## 🔐 Seguridad

- Las contraseñas se manejan de forma segura con Firebase Authentication
- Las reglas de Firestore aseguran que:
  - Solo fabricantes pueden crear/editar proyectos y productos
  - Los clientes solo pueden leer datos
  - Cada usuario solo puede modificar sus propios datos

---

## 📝 Próximos Pasos (Sugerencias)

1. **Notificaciones Push**: Implementar con Firebase Cloud Messaging
2. **Imágenes de productos**: Agregar Firebase Storage
3. **Chat**: Comunicación entre fabricante y cliente
4. **Exportar reportes**: Generar PDFs con el estado de producción
5. **Dashboard analítico**: Gráficos de progreso y estadísticas
6. **Búsqueda avanzada**: Filtros y ordenamiento de productos

---

## 🆘 Soporte

Si encuentras algún problema durante la configuración, verifica:
1. ✅ Firebase está correctamente configurado
2. ✅ `google-services.json` está en la ubicación correcta
3. ✅ Todas las dependencias están instaladas
4. ✅ El emulador de Android está funcionando

---

¡Buena suerte con tu proyecto! 🚀