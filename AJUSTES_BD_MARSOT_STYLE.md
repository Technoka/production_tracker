# Ajustes Base de Datos para Funcionalidad Estilo Marsot

## 🎯 Cambios Necesarios en la Estructura Existente

### 1. **Ajustes en `/organizations/{orgId}/phases/`**

```dart
// AÑADIR campos:
{
  ...campos existentes,
  
  // Para SLA y alertas automáticas
  maxDurationHours: number,        // Tiempo máximo permitido (SLA)
  warningThresholdPercent: number, // % para alerta temprana (ej: 80%)
  
  // Para Kanban visual
  color: string,                   // Color de la columna
  icon: string,                    // Icono de la fase
  wip_limit: number,               // Límite Work-In-Progress (Kanban)
  
  // Para métricas
  averageDurationHours: number,    // Calculado de históricos
  minDurationHours: number,
  maxDurationHours: number,
}
```

### 2. **Ajustes en `/organizations/{orgId}/projects/`**

```dart
// AÑADIR campos:
{
  ...campos existentes,
  
  // SLA y urgencia
  totalSlaHours: number,           // SLA total del proyecto
  expectedCompletionDate: timestamp,
  isDelayed: boolean,              // Flag rápido para queries
  delayHours: number,              // Horas de retraso acumuladas
  
  // Prioridad Kanban
  priority: number,                // 1-5 (1=máxima)
  urgencyLevel: string,            // "low", "medium", "high", "critical"
  
  // Facturación
  invoiceStatus: string,           // "pending", "issued", "paid", "overdue"
  invoiceId: string,               // ID de Holded
  totalAmount: number,
  paidAmount: number,
  paymentDueDate: timestamp,
  
  // Métricas internas
  startedAt: timestamp,            // Cuándo empezó producción real
  actualCompletionDate: timestamp,
  leadTimeHours: number,           // Tiempo real tomado
}
```

### 3. **Ajustes en `/organizations/{orgId}/projects/{projectId}/products/`**

```dart
// AÑADIR campos:
{
  ...campos existentes,
  
  // SLA por producto
  expectedDuration: number,        // Horas esperadas
  actualDuration: number,          // Horas reales
  isBlocked: boolean,              // Flag de bloqueo
  blockReason: string,             // Motivo del bloqueo
  
  // Kanban
  kanbanPosition: number,          // Orden en la columna
  swimlane: string,                // Para agrupar en Kanban
  
  // Control de calidad
  qualityStatus: string,           // "pending", "approved", "rejected"
  qualityNotes: string,
  qualityCheckedBy: string,
  qualityCheckedAt: timestamp,
}
```

### 4. **NUEVA Colección: `/organizations/{orgId}/projects/{projectId}/messages/`**

```dart
{
  id: string,
  type: string,                    // "user_message", "system_event", "status_change"
  content: string,                 // Texto del mensaje
  
  // Autor
  authorId: string,
  authorName: string,
  authorRole: string,
  authorAvatar: string,
  
  // Sistema
  isSystemGenerated: boolean,
  eventType: string,               // "phase_completed", "delay_detected", etc.
  
  // Interacción
  mentions: [userId],              // Usuarios mencionados
  attachments: [{
    name: string,
    url: string,
    type: string,
    size: number,
  }],
  reactions: [{                    // Emojis
    emoji: string,
    userId: string,
    userName: string,
  }],
  
  // Metadata
  isInternal: boolean,             // Solo equipo interno
  isPinned: boolean,               // Mensaje destacado
  
  // Thread
  parentMessageId: string,         // Para respuestas
  threadCount: number,             // Nº de respuestas
  
  // Timestamps
  createdAt: timestamp,
  updatedAt: timestamp,
  editedAt: timestamp,
  
  // Estado
  readBy: [userId],                // Quién lo leyó
  deliveredTo: [userId],
}
```

### 5. **NUEVA Colección: `/organizations/{orgId}/inbox/`**

Bandeja unificada de conversaciones:

```dart
{
  id: string,
  
  // Referencia
  entityType: string,              // "project", "product", "general"
  entityId: string,                // ID del proyecto/producto
  entityName: string,              // Nombre para mostrar
  
  // Estado
  status: string,                  // "open", "resolved", "archived"
  priority: string,                // "low", "medium", "high", "urgent"
  
  // Participantes
  participants: [userId],
  assignedTo: string,              // Usuario asignado a responder
  
  // Mensajes
  lastMessageId: string,
  lastMessageText: string,
  lastMessageAt: timestamp,
  lastMessageBy: string,
  
  // Contadores
  unreadCount: number,
  totalMessages: number,
  
  // Cliente
  clientId: string,
  clientName: string,
  
  // Metadata
  tags: [string],
  createdAt: timestamp,
  updatedAt: timestamp,
}
```

### 6. **NUEVA Colección: `/organizations/{orgId}/invoices/`**

```dart
{
  id: string,
  
  // Referencia
  projectId: string,
  projectName: string,
  clientId: string,
  clientName: string,
  
  // Holded Integration
  holdedInvoiceId: string,         // ID en Holded
  holdedDocumentNumber: string,    // Número de factura
  holdedStatus: string,            // Estado en Holded
  holdedPdfUrl: string,
  
  // Datos financieros
  subtotal: number,
  tax: number,
  taxRate: number,
  total: number,
  currency: string,                // "EUR", "USD"
  
  // Items
  items: [{
    productId: string,
    description: string,
    quantity: number,
    unitPrice: number,
    total: number,
  }],
  
  // Fechas
  issueDate: timestamp,
  dueDate: timestamp,
  paidDate: timestamp,
  
  // Estado de pago
  paymentStatus: string,           // "pending", "partial", "paid", "overdue"
  paidAmount: number,
  pendingAmount: number,
  
  // Método de pago
  paymentMethod: string,           // "stripe", "redsys", "transfer", "cash"
  paymentReference: string,        // Transaction ID
  
  // Stripe/Redsys
  stripePaymentIntentId: string,
  redsysOrderId: string,
  
  // Timestamps
  createdAt: timestamp,
  updatedAt: timestamp,
  syncedAt: timestamp,             // Última sync con Holded
}
```

### 7. **NUEVA Colección: `/organizations/{orgId}/sla_alerts/`**

```dart
{
  id: string,
  
  // Entidad afectada
  entityType: string,              // "project", "product", "phase"
  entityId: string,
  entityName: string,
  
  // Tipo de alerta
  alertType: string,               // "sla_exceeded", "sla_warning", "phase_blocked"
  severity: string,                // "warning", "critical"
  
  // Detalle
  currentValue: number,            // Horas actuales
  thresholdValue: number,          // Límite SLA
  deviationPercent: number,        // % de desviación
  
  // Estado
  status: string,                  // "active", "resolved", "acknowledged"
  acknowledgedBy: string,
  acknowledgedAt: timestamp,
  resolvedAt: timestamp,
  
  // Notificación
  notifiedUsers: [userId],
  notifiedAt: timestamp,
  
  // Metadata
  createdAt: timestamp,
  projectId: string,               // Para filtrado
  phaseId: string,
}
```

### 8. **NUEVA Colección: `/organizations/{orgId}/payments/`**

```dart
{
  id: string,
  
  // Referencias
  invoiceId: string,
  projectId: string,
  clientId: string,
  
  // Stripe
  stripePaymentIntentId: string,
  stripeChargeId: string,
  stripeCustomerId: string,
  
  // Redsys
  redsysOrderId: string,
  redsysAuthorizationCode: string,
  
  // Datos del pago
  amount: number,
  currency: string,
  status: string,                  // "pending", "processing", "succeeded", "failed"
  
  // Método
  paymentMethod: string,           // "card", "transfer", "cash"
  last4: string,                   // Últimos 4 dígitos tarjeta
  brand: string,                   // "visa", "mastercard"
  
  // Fechas
  createdAt: timestamp,
  processedAt: timestamp,
  
  // Metadata
  description: string,
  receiptUrl: string,
  failureReason: string,
}
```

### 9. **Ajustes en `/organizations/{orgId}/product_catalog/`**

```dart
{
  ...campos existentes,
  
  // Aprobación
  approvalStatus: string,          // "pending", "approved", "rejected"
  approvedBy: string,
  approvedAt: timestamp,
  rejectionReason: string,
  
  // Cliente específico
  clientId: string,                // Producto solo para este cliente
  isPublic: boolean,               // Disponible para todos
  
  // Tiempo estimado
  estimatedProductionHours: number,
  
  // Precio por cliente
  clientPrices: [{
    clientId: string,
    unitPrice: number,
    minQuantity: number,
  }],
}
```

### 10. **NUEVA Colección: `/users/{userId}/inbox_preferences/`**

```dart
{
  // Notificaciones
  emailNotifications: boolean,
  pushNotifications: boolean,
  smsNotifications: boolean,
  
  // Frecuencia
  notificationFrequency: string,   // "instant", "hourly", "daily"
  quietHoursStart: string,         // "22:00"
  quietHoursEnd: string,           // "08:00"
  
  // Tipos
  notifyOnNewMessage: boolean,
  notifyOnStatusChange: boolean,
  notifyOnSlaAlert: boolean,
  notifyOnPayment: boolean,
  notifyOnMention: boolean,
  
  // Inbox
  inboxLayout: string,             // "list", "cards", "compact"
  autoArchiveResolved: boolean,
  markAsReadOnOpen: boolean,
}
```

---

## 🔄 Colecciones que NO necesitan cambios

✅ **users/** - Perfecto como está
✅ **organizations/** - Base correcta
✅ **organizations/{orgId}/members/** - Correcto
✅ **organizations/{orgId}/clients/** - Solo añadir `userId` para portal
✅ **organizations/{orgId}/phases/** - Solo ajustes menores
✅ **organizations/{orgId}/phaseAssignments/** - Correcto

---

## 📊 Índices Compuestos Adicionales Necesarios

```javascript
// Para Kanban drag & drop
organizations/{orgId}/projects/{projectId}/products
  - status (ASC), kanbanPosition (ASC)
  - phaseId (ASC), kanbanPosition (ASC)

// Para SLA y alertas
organizations/{orgId}/projects
  - isDelayed (ASC), priority (DESC)
  - urgencyLevel (ASC), estimatedDeliveryDate (ASC)

organizations/{orgId}/sla_alerts
  - status (ASC), severity (DESC), createdAt (DESC)

// Para inbox
organizations/{orgId}/inbox
  - status (ASC), priority (DESC), lastMessageAt (DESC)
  - assignedTo (ASC), status (ASC), lastMessageAt (DESC)
  - clientId (ASC), status (ASC)

// Para facturación
organizations/{orgId}/invoices
  - paymentStatus (ASC), dueDate (ASC)
  - clientId (ASC), issueDate (DESC)
  - projectId (ASC)

// Para mensajes
organizations/{orgId}/projects/{projectId}/messages
  - createdAt (DESC), isSystemGenerated (ASC)
  - authorId (ASC), createdAt (DESC)
```

---

## 🎯 Resumen de Cambios

### Colecciones Nuevas (6):
1. ✅ `messages/` - Chat completo con threads
2. ✅ `inbox/` - Bandeja unificada
3. ✅ `invoices/` - Facturación Holded
4. ✅ `payments/` - Pagos Stripe/Redsys
5. ✅ `sla_alerts/` - Alertas automáticas
6. ✅ `inbox_preferences/` - Preferencias usuario

### Colecciones Modificadas (4):
1. ⚠️ `phases/` - Añadir SLA y Kanban
2. ⚠️ `projects/` - Añadir facturación y SLA
3. ⚠️ `products/` - Añadir control calidad
4. ⚠️ `product_catalog/` - Añadir aprobación

### Colecciones Sin Cambios (6):
- `users/`, `organizations/`, `members/`, `clients/`, `phaseAssignments/`, `auditLog/`

---

## ✅ Ventajas de esta Estructura

1. **Compatible hacia atrás** - No rompe nada existente
2. **Escalable** - Soporta crecimiento
3. **Eficiente** - Queries optimizadas
4. **Segura** - Aislamiento por organización
5. **Flexible** - Fácil añadir features
6. **Integrable** - Preparada para Holded/Stripe/Redsys