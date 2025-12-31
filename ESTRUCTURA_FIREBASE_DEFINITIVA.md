# Estructura Firestore Definitiva - Todas las Fases

## 🎯 Estructura Completa y Optimizada

```
firestore/
│
├── users/                                    # ✅ GLOBAL (Autenticación y perfil)
│   └── {userId}/
│       ├── email: string
│       ├── name: string
│       ├── photoURL: string
│       ├── organizationId: string            # Referencia a organización
│       ├── role: string                      # Rol en la organización
│       ├── createdAt: timestamp
│       │
│       ├── preferences/                      # ⭐ FASE 12: Personalización
│       │   ├── theme: "light" | "dark"
│       │   ├── language: "es" | "en"
│       │   ├── defaultView: string
│       │   └── emailNotifications: boolean
│       │
│       └── notifications/                    # ⭐ FASE 7: Notificaciones
│           └── {notificationId}/
│               ├── type: string
│               ├── title: string
│               ├── message: string
│               ├── read: boolean
│               ├── link: string
│               ├── createdAt: timestamp
│               └── relatedData: map
│
└── organizations/                            # ✅ POR ORGANIZACIÓN
    └── {orgId}/
        ├── name: string
        ├── description: string
        ├── ownerId: string
        ├── logoURL: string
        ├── createdAt: timestamp
        ├── settings: map                     # ⭐ FASE 12: Configuración global
        │
        ├── members/                          # ✅ FASE 1: Miembros
        │   └── {userId}/
        │       ├── role: string
        │       ├── joinedAt: timestamp
        │       ├── permissions: array
        │       └── isActive: boolean
        │
        ├── invitations/                      # ✅ FASE 1: Invitaciones
        │   └── {invitationId}/
        │
        ├── phases/                           # ✅ FASE 4: Fases de producción
        │   └── {phaseId}/
        │       ├── name: string
        │       ├── order: number
        │       ├── isActive: boolean
        │       ├── description: string
        │       ├── estimatedDuration: number # ⭐ FASE 11: Para reportes de tiempo
        │       └── color: string             # ⭐ FASE 5: Para visualización Kanban
        │
        ├── phaseAssignments/                 # ✅ FASE 4: Asignación de operarios
        │   └── {userId}/
        │       └── phases: [phaseId1, ...]
        │
        ├── clients/                          # ✅ FASE 2: Clientes
        │   └── {clientId}/
        │       ├── name: string
        │       ├── email: string
        │       ├── company: string
        │       ├── phone: string
        │       ├── address: string
        │       ├── notes: string
        │       ├── userId: string            # ⭐ FASE 8: Link a cuenta de usuario si tiene acceso
        │       └── createdAt: timestamp
        │
        ├── product_catalog/                  # ✅ FASE 3: Catálogo de productos
        │   └── {catalogProductId}/
        │       ├── name: string
        │       ├── reference: string
        │       ├── description: string
        │       ├── imageUrls: array
        │       ├── basePrice: number
        │       ├── usageCount: number
        │       ├── materials: array          # ⭐ FASE 9: Materiales predefinidos
        │       └── createdAt: timestamp
        │
        ├── materials/                        # ⭐ FASE 9: Inventario de materiales
        │   └── {materialId}/
        │       ├── name: string
        │       ├── type: string              # "leather", "hardware", "thread", etc.
        │       ├── color: string
        │       ├── supplier: string
        │       ├── stockLevel: number
        │       ├── minStockLevel: number     # Para alertas automáticas
        │       ├── unit: string              # "meters", "pieces", etc.
        │       ├── costPerUnit: number
        │       └── lastRestockDate: timestamp
        │
        ├── projects/                         # ✅ FASE 2: Proyectos
        │   └── {projectId}/
        │       ├── name: string
        │       ├── clientId: string
        │       ├── description: string
        │       ├── status: string
        │       ├── estimatedDeliveryDate: timestamp
        │       ├── actualDeliveryDate: timestamp
        │       ├── assignedMembers: [userId1, userId2]
        │       ├── priority: string          # ⭐ FASE 5: "high", "medium", "low"
        │       ├── tags: array               # ⭐ FASE 12: Para búsqueda avanzada
        │       ├── createdBy: string
        │       ├── createdAt: timestamp
        │       ├── updatedAt: timestamp
        │       │
        │       ├── products/                 # ✅ FASE 3: Productos del proyecto
        │       │   └── {productId}/
        │       │       ├── catalogProductId: string
        │       │       ├── catalogProductName: string
        │       │       ├── catalogProductReference: string
        │       │       ├── quantity: number
        │       │       ├── unitPrice: number
        │       │       ├── totalPrice: number
        │       │       ├── status: string
        │       │       ├── customization: map
        │       │       ├── notes: string
        │       │       ├── materialStatus: string  # ⭐ FASE 9: "available", "pending", "missing"
        │       │       ├── urgencyLevel: number    # ⭐ FASE 5: Para ordenar en Kanban
        │       │       ├── createdBy: string
        │       │       ├── createdAt: timestamp
        │       │       ├── updatedAt: timestamp
        │       │       │
        │       │       ├── phaseProgress/    # ✅ FASE 4: Progreso de fases
        │       │       │   └── {phaseId}/
        │       │       │       ├── phaseId: string
        │       │       │       ├── phaseName: string
        │       │       │       ├── phaseOrder: number
        │       │       │       ├── status: string
        │       │       │       ├── startedAt: timestamp
        │       │       │       ├── completedAt: timestamp
        │       │       │       ├── startedByUserId: string
        │       │       │       ├── startedByUserName: string
        │       │       │       ├── completedByUserId: string
        │       │       │       ├── completedByUserName: string
        │       │       │       ├── notes: string
        │       │       │       └── createdAt: timestamp
        │       │       │
        │       │       ├── materials/        # ⭐ FASE 9: Materiales por producto
        │       │       │   └── {materialId}/
        │       │       │       ├── materialId: string
        │       │       │       ├── materialName: string
        │       │       │       ├── quantity: number
        │       │       │       ├── unit: string
        │       │       │       ├── status: string  # "reserved", "used", "pending"
        │       │       │       └── assignedAt: timestamp
        │       │       │
        │       │       ├── photos/           # ⭐ FASE 10: Fotos del producto
        │       │       │   └── {photoId}/
        │       │       │       ├── url: string
        │       │       │       ├── thumbnailUrl: string
        │       │       │       ├── phaseId: string      # En qué fase se tomó
        │       │       │       ├── uploadedBy: string
        │       │       │       ├── uploadedAt: timestamp
        │       │       │       ├── caption: string
        │       │       │       └── type: string  # "progress", "final", "reference"
        │       │       │
        │       │       └── comments/         # ⭐ FASE 6: Comentarios por producto
        │       │           └── {commentId}/
        │       │               ├── text: string
        │       │               ├── authorId: string
        │       │               ├── authorName: string
        │       │               ├── mentions: [userId1, userId2]
        │       │               ├── isInternal: boolean  # true = solo equipo
        │       │               ├── createdAt: timestamp
        │       │               └── edited: boolean
        │       │
        │       ├── comments/                 # ⭐ FASE 6: Comentarios del proyecto
        │       │   └── {commentId}/
        │       │       ├── text: string
        │       │       ├── authorId: string
        │       │       ├── authorName: string
        │       │       ├── mentions: [userId1]
        │       │       ├── isInternal: boolean
        │       │       ├── createdAt: timestamp
        │       │       └── edited: boolean
        │       │
        │       ├── files/                    # ⭐ FASE 10: Archivos del proyecto
        │       │   └── {fileId}/
        │       │       ├── name: string
        │       │       ├── url: string
        │       │       ├── type: string      # "design", "contract", "specification"
        │       │       ├── mimeType: string
        │       │       ├── size: number
        │       │       ├── uploadedBy: string
        │       │       └── uploadedAt: timestamp
        │       │
        │       ├── notes/                    # ⭐ FASE 6: Notas del proyecto
        │       │   └── {noteId}/
        │       │       ├── title: string
        │       │       ├── content: string
        │       │       ├── type: string      # "general", "incident", "special_detail"
        │       │       ├── createdBy: string
        │       │       ├── createdAt: timestamp
        │       │       └── updatedAt: timestamp
        │       │
        │       └── auditLog/                 # ⭐ FASE 11: Histórico de cambios
        │           └── {logId}/
        │               ├── action: string    # "status_change", "phase_update", etc.
        │               ├── entityType: string # "project", "product", "phase"
        │               ├── entityId: string
        │               ├── userId: string
        │               ├── userName: string
        │               ├── oldValue: map
        │               ├── newValue: map
        │               ├── timestamp: timestamp
        │               └── description: string
        │
        ├── reports/                          # ⭐ FASE 11: Reportes generados
        │   └── {reportId}/
        │       ├── type: string              # "productivity", "delays", "completed"
        │       ├── period: map               # { start, end }
        │       ├── data: map                 # Datos del reporte
        │       ├── generatedBy: string
        │       ├── generatedAt: timestamp
        │       └── pdfUrl: string            # Link al PDF en Storage
        │
        └── analytics/                        # ⭐ FASE 5 & 11: Estadísticas agregadas
            ├── daily/
            │   └── {date}/                   # YYYY-MM-DD
            │       ├── productsCompleted: number
            │       ├── phasesCompleted: number
            │       ├── activeProjects: number
            │       └── productivity: map
            │
            └── monthly/
                └── {month}/                  # YYYY-MM
                    ├── productsCompleted: number
                    ├── projectsCompleted: number
                    ├── averageTimePerPhase: map
                    └── revenue: number
```

---

## 🔄 Cambios Respecto a la Estructura Inicial

### ✅ Mantener como está:
1. `/users` en la raíz (autenticación global)
2. Todo lo demás dentro de `/organizations/{orgId}`
3. Estructura de proyectos y productos

### ⭐ Añadir ahora (preparación para fases futuras):

#### 1. En `/users/{userId}`:
```dart
preferences/     // FASE 12
notifications/   // FASE 7
```

#### 2. En `/organizations/{orgId}`:
```dart
materials/       // FASE 9
reports/         // FASE 11
analytics/       // FASE 5 & 11
```

#### 3. En `/projects/{projectId}/products/{productId}`:
```dart
materials/       // FASE 9
photos/          // FASE 10
comments/        // FASE 6
```

#### 4. En `/projects/{projectId}`:
```dart
comments/        // FASE 6
files/           // FASE 10
notes/           // FASE 6
auditLog/        // FASE 11
```

---

## 📋 Campos Adicionales a Añadir

### En `phases`:
```dart
estimatedDuration: number  // Para reportes de tiempo
color: string              // Para visualización Kanban
```

### En `projects`:
```dart
priority: string           // "high", "medium", "low"
tags: array               // Para búsqueda avanzada
```

### En `products`:
```dart
materialStatus: string    // "available", "pending", "missing"
urgencyLevel: number      // Para ordenar en Kanban (0-10)
```

### En `clients`:
```dart
userId: string            // Link a cuenta de usuario si tiene acceso portal
```

---

## 🎯 Ventajas de esta Estructura

### ✅ Escalabilidad
- Cada organización es independiente
- Fácil implementar multi-tenancy
- Los datos no se mezclan entre organizaciones

### ✅ Performance
- Consultas más eficientes (scope reducido)
- Índices más pequeños por organización
- Paginación más efectiva

### ✅ Seguridad
- Reglas de Firestore más simples y robustas
- Aislamiento natural entre organizaciones
- Fácil implementar RBAC por organización

### ✅ Flexibilidad
- Cada organización puede tener configuración única
- Fases personalizables por organización
- Reportes y analytics independientes

### ✅ Backup y Recuperación
- Fácil exportar datos de una organización
- Posible migración de organizaciones
- Rollback selectivo

---

## 🚀 Migración Inmediata vs Futura

### Migrar AHORA (Fases 1-4):
```
✅ /projects → /organizations/{orgId}/projects
✅ /clients → /organizations/{orgId}/clients
✅ /product_catalog → /organizations/{orgId}/product_catalog
✅ Crear /organizations/{orgId}/phases
✅ Crear /organizations/{orgId}/phaseAssignments
```

### Crear DESPUÉS (cuando implementes la fase):
```
⏳ /organizations/{orgId}/materials (FASE 9)
⏳ /organizations/{orgId}/reports (FASE 11)
⏳ /organizations/{orgId}/analytics (FASE 5 & 11)
⏳ /users/{userId}/preferences (FASE 12)
⏳ /users/{userId}/notifications (FASE 7)
⏳ Subcolecciones de comments, photos, files (FASES 6, 10)
```

---

## 📊 Índices Compuestos Necesarios

Para Firestore, necesitarás crear estos índices:

```javascript
// FASE 4: Fases
organizations/{orgId}/projects/{projectId}/products/{productId}/phaseProgress
  - phaseOrder (ASC), status (ASC)

// FASE 5: Kanban/Dashboard
organizations/{orgId}/projects
  - status (ASC), estimatedDeliveryDate (ASC)
  - priority (DESC), createdAt (DESC)

organizations/{orgId}/projects/{projectId}/products
  - status (ASC), urgencyLevel (DESC)

// FASE 9: Materiales
organizations/{orgId}/materials
  - type (ASC), stockLevel (ASC)

// FASE 11: Reportes
organizations/{orgId}/projects/{projectId}/auditLog
  - entityType (ASC), timestamp (DESC)
  - userId (ASC), timestamp (DESC)
```

---

## 🔐 Reglas de Seguridad Actualizadas

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ========== FUNCIONES HELPER ==========
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    function getUserRole(orgId) {
      return get(/databases/$(database)/documents/organizations/$(orgId)/members/$(request.auth.uid)).data.role;
    }
    
    function isOrgMember(orgId) {
      return exists(/databases/$(database)/documents/organizations/$(orgId)/members/$(request.auth.uid));
    }
    
    function isOrgOwner(orgId) {
      return get(/databases/$(database)/documents/organizations/$(orgId)).data.ownerId == request.auth.uid;
    }
    
    function hasRole(orgId, roles) {
      return getUserRole(orgId) in roles;
    }
    
    // ========== USERS (ROOT) ==========
    
    match /users/{userId} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow write: if isAuthenticated() && request.auth.uid == userId;
      
      match /preferences/{docId} {
        allow read, write: if isAuthenticated() && request.auth.uid == userId;
      }
      
      match /notifications/{notificationId} {
        allow read: if isAuthenticated() && request.auth.uid == userId;
        allow write: if isAuthenticated() && request.auth.uid == userId;
        allow create: if isAuthenticated(); // Otros usuarios pueden crear notificaciones
      }
    }
    
    // ========== ORGANIZATIONS ==========
    
    match /organizations/{orgId} {
      allow read: if isAuthenticated() && isOrgMember(orgId);
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (isOrgOwner(orgId) || hasRole(orgId, ['admin']));
      allow delete: if isAuthenticated() && isOrgOwner(orgId);
      
      // Members
      match /members/{memberId} {
        allow read: if isAuthenticated() && isOrgMember(orgId);
        allow write: if isAuthenticated() && (isOrgOwner(orgId) || hasRole(orgId, ['admin']));
      }
      
      // Phases
      match /phases/{phaseId} {
        allow read: if isAuthenticated() && isOrgMember(orgId);
        allow write: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager']);
      }
      
      // Phase Assignments
      match /phaseAssignments/{userId} {
        allow read: if isAuthenticated() && (request.auth.uid == userId || hasRole(orgId, ['admin', 'production_manager']));
        allow write: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager']);
      }
      
      // Clients
      match /clients/{clientId} {
        allow read: if isAuthenticated() && isOrgMember(orgId);
        allow write: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager']);
      }
      
      // Product Catalog
      match /product_catalog/{catalogId} {
        allow read: if isAuthenticated() && isOrgMember(orgId);
        allow write: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager']);
      }
      
      // Materials (FASE 9)
      match /materials/{materialId} {
        allow read: if isAuthenticated() && isOrgMember(orgId);
        allow write: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager', 'operator']);
      }
      
      // Projects
      match /projects/{projectId} {
        allow read: if isAuthenticated() && isOrgMember(orgId);
        allow create: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager']);
        allow update: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager', 'operator']);
        allow delete: if isAuthenticated() && hasRole(orgId, ['admin']);
        
        // Products
        match /products/{productId} {
          allow read: if isAuthenticated() && isOrgMember(orgId);
          allow write: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager', 'operator']);
          
          // Phase Progress
          match /phaseProgress/{progressId} {
            allow read: if isAuthenticated() && isOrgMember(orgId);
            allow write: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager', 'operator']);
          }
          
          // Materials (FASE 9)
          match /materials/{materialId} {
            allow read: if isAuthenticated() && isOrgMember(orgId);
            allow write: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager', 'operator']);
          }
          
          // Photos (FASE 10)
          match /photos/{photoId} {
            allow read: if isAuthenticated() && isOrgMember(orgId);
            allow create: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager', 'operator']);
            allow delete: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager']);
          }
          
          // Comments (FASE 6)
          match /comments/{commentId} {
            allow read: if isAuthenticated() && (
              isOrgMember(orgId) || 
              (resource.data.isInternal == false && getUserData().role == 'client')
            );
            allow create: if isAuthenticated() && isOrgMember(orgId);
            allow update: if isAuthenticated() && request.auth.uid == resource.data.authorId;
            allow delete: if isAuthenticated() && (
              request.auth.uid == resource.data.authorId || 
              hasRole(orgId, ['admin', 'production_manager'])
            );
          }
        }
        
        // Project Comments (FASE 6)
        match /comments/{commentId} {
          allow read: if isAuthenticated() && isOrgMember(orgId);
          allow create: if isAuthenticated() && isOrgMember(orgId);
          allow update: if isAuthenticated() && request.auth.uid == resource.data.authorId;
          allow delete: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager']);
        }
        
        // Project Files (FASE 10)
        match /files/{fileId} {
          allow read: if isAuthenticated() && isOrgMember(orgId);
          allow create: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager']);
          allow delete: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager']);
        }
        
        // Project Notes (FASE 6)
        match /notes/{noteId} {
          allow read: if isAuthenticated() && isOrgMember(orgId);
          allow write: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager', 'operator']);
        }
        
        // Audit Log (FASE 11)
        match /auditLog/{logId} {
          allow read: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager']);
          allow create: if isAuthenticated(); // Sistema crea automáticamente
        }
      }
      
      // Reports (FASE 11)
      match /reports/{reportId} {
        allow read: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager', 'contable']);
        allow create: if isAuthenticated() && hasRole(orgId, ['admin', 'production_manager']);
        allow delete: if isAuthenticated() && hasRole(orgId, ['admin']);
      }
      
      // Analytics (FASE 5 & 11)
      match /analytics/{type}/{docId} {
        allow read: if isAuthenticated() && isOrgMember(orgId);
        allow write: if false; // Solo Cloud Functions pueden escribir
      }
    }
  }
}
```

---

## ✅ Conclusión

**La estructura propuesta ES LA CORRECTA** para implementar todas las fases futuras.

### Acción Inmediata:
1. ✅ Migra los datos como te indiqué (projects, clients, catalog)
2. ✅ Actualiza los 3 servicios principales
3. ✅ Prueba que todo funcione con las fases 1-4

### Preparación Futura:
- No necesitas crear las colecciones futuras ahora
- La estructura soporta todas las fases sin problemas
- Solo añade las subcolecciones cuando implementes cada fase

**Esta estructura te ahorrará meses de refactorización futura** 🎯