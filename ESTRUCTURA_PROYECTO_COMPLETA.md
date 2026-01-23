## 🔥 ESTRUCTURA DE FIREBASE

### Colecciones Principales

```
/users/{userId}
  - Perfil de usuario
  - email, name, photoUrl, createdAt

/organizations/{orgId}
  - Información de organización
  - name, ownerId, settings, createdAt
  
  /organizations/{orgId}/members/{userId}
    - Miembros de la organización
    - roleId, roleName, permissionOverrides, assignedPhases
  
  /organizations/{orgId}/roles/{roleId}
    - Roles personalizados
    - name, color, permissions, isSystem
  
  /organizations/{orgId}/product_statuses/{statusId}
    - Estados personalizables
    - name, color, icon, order, isSystem
  
  /organizations/{orgId}/status_transitions/{transitionId}
    - Transiciones entre estados
    - fromStatusId, toStatusId, validationType, allowedRoles
  
  /organizations/{orgId}/clients/{clientId}
    - Clientes
    - name, company, email, specialPermissions
  
  /organizations/{orgId}/projects/{projectId}
    - Proyectos
    - name, clientId, status, dates
  
  /organizations/{orgId}/product_catalog/{productId}
    - Catálogo de productos
    - name, family, basePrice, reference
  
  /organizations/{orgId}/phases/{phaseId}
    - Fases de producción
    - name, order, estimatedDuration
  
  /organizations/{orgId}/production_batches/{batchId}
    - Lotes de producción
    - batchNumber, projectId, status
    
    /production_batches/{batchId}/products/{productId}
      - Productos dentro del lote
      - statusId, statusName, statusHistory, phaseProgress
```

---

## 📊 CARACTERÍSTICAS IMPLEMENTADAS (Fases 1-4)

### ✅ FASE 1: Autenticación y Organizaciones
- Sistema de usuarios con Firebase Auth
- Multi-organización (multi-tenancy)
- Invitaciones y códigos de acceso

### ✅ FASE 2: Gestión de Clientes y Proyectos
- CRUD completo de clientes
- CRUD completo de proyectos
- Relación cliente-proyecto

### ✅ FASE 3: Catálogo de Productos
- CRUD de productos del catálogo
- Familias de productos
- Precios base

### ✅ FASE 4: Fases de Producción
- CRUD de fases personalizables
- Orden y duración estimada
- Asignación de operarios a fases

### 🔄 FASE 5: Sistema RBAC (En Progreso)
- Roles personalizables con permisos
- Permission overrides por usuario
- Estados de producto personalizables
- Transiciones con validaciones
- Lógica condicional (aprobaciones, alertas)
- Integration en production_batch_service

---

## 🎯 FUNCIONALIDADES PENDIENTES (Fases 6-15)

### FASE 6: Tablero Kanban (Parcialmente implementado)
- Drag & drop funcional
- Filtros avanzados
- Vista por swimlanes

### FASE 7: Sistema de Mensajería
- Chat por proyecto/lote
- Eventos del sistema
- Notificaciones en tiempo real

### FASE 8: Bandeja de Entrada
- Inbox unificado
- Conversaciones agrupadas

### FASE 9: Notificaciones Push
- FCM para móviles
- Email notifications
- Configuración por usuario

### FASE 10: Facturación y Holded
- Integración con Holded API
- Generación de facturas
- Control de pagos

### FASE 11: Gestión de Materiales
- Inventario de materiales
- Stock y proveedores
- Asignación a productos

### FASE 12: Portal del Cliente
- Dashboard simplificado
- Crear pedidos con aprobación
- Ver progreso

### FASE 13: Reportes Avanzados
- Reportes predefinidos
- Exportación PDF/CSV
- Analytics agregados

### FASE 14: Gestión de Archivos
- Subida de archivos
- Firebase Storage
- Galería de fotos

### FASE 15: UX/UI Avanzado
- Tema oscuro
- Búsqueda global
- Atajos de teclado
- Onboarding

---

## 🔑 CONCEPTOS CLAVE DEL SISTEMA

### Sistema RBAC (Role-Based Access Control)
- **Roles Base**: Contienen permisos por defecto (admin, operator, client, etc.)
- **Permission Overrides**: Permisos específicos que sobrescriben los del rol
- **Módulos**: Áreas funcionales (batches, products, projects, kanban)
- **Acciones**: Operaciones sobre módulos (view, create, edit, delete)
- **Scopes**: Alcance de permisos (all, assigned, none)

### Estados de Producto Personalizables
- **Estados del Sistema**: pending, hold, cao, control, ok (no editables)
- **Estados Personalizados**: Creados por cada organización
- **Historial**: Registro completo de cambios de estado con validación

### Transiciones con Validaciones
- **Tipos de Validación**: simple, texto, cantidad+texto, checklist, fotos, multi-aprobación
- **Lógica Condicional**: Reglas que se evalúan (ej: si defectos > 5, requiere aprobación)
- **Acciones Condicionales**: blockTransition, showWarning, requireApproval, notifyRoles

### Multi-Tenancy
- Todos los datos aislados por `organizationId`
- Cada organización es independiente
- Configuración personalizable por organización

---

## 📝 NOTAS IMPORTANTES

### Compatibilidad Legacy
- Algunos modelos mantienen campos legacy para migración gradual
- `productStatus` (string) convive con `statusId` (referencia)
- `role` (string) convive con `roleId` (referencia)

### Optimización Firebase
- Uso de streams para datos en tiempo real
- Batch writes para operaciones múltiples
- Índices compuestos necesarios (ver documentación)
- Consultas optimizadas con `limit()`

### Seguridad
- Todas las operaciones validan permisos efectivos (rol + overrides)
- Reglas de Firestore por implementar (ver ESTRUCTURA_FIREBASE_DEFINITIVA.md)
- Validación tanto en cliente como en servidor (futuras Cloud Functions)

### Internacionalización
- Soporte para español e inglés
- Archivos .arb para traducciones
- Preparado para añadir más idiomas

