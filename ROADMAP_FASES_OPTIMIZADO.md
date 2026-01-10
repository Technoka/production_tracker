# Roadmap de Implementación - Fases 5-15 (Optimizado)

## ✅ Completado (Fases 1-4)

- ✅ **FASE 1**: Autenticación y Organizaciones
- ✅ **FASE 2**: Gestión de Clientes y Proyectos
- ✅ **FASE 3**: Catálogo y Productos
- ✅ **FASE 4**: Fases de Producción

---

## 🚀 FASE 5: SLA, ALERTAS Y MÉTRICAS BÁSICAS
**Prioridad: ALTA** | **Duración: 1-2 semanas**

### Objetivos:
Implementar sistema de alertas automáticas y métricas de rendimiento.

### Funcionalidades:
1. **Configuración de SLA por fase**
   - Tiempo máximo permitido por fase
   - Umbral de advertencia (80% del tiempo)
   - Límites WIP (Work In Progress) por fase

2. **Detección automática de retrasos**
   - Cloud Function que corre cada hora
   - Detecta productos/proyectos fuera de SLA
   - Crea alertas en `sla_alerts/`
   - Marca productos como `isDelayed: true`

3. **Dashboard de métricas básicas**
   - Proyectos activos vs completados
   - Productos por fase (distribución)
   - Tiempo promedio por fase
   - Lista de proyectos retrasados
   - Gráfico de tendencia semanal/mensual

4. **Indicadores visuales**
   - Badges rojos en productos retrasados
   - Contador de alertas en navbar
   - Panel lateral de alertas activas

### Archivos a crear:
- `lib/models/sla_alert_model.dart`
- `lib/services/sla_service.dart`
- `lib/services/analytics_service.dart`
- `lib/screens/dashboard/metrics_dashboard_screen.dart`
- `lib/widgets/sla_alert_badge.dart`
- `functions/src/sla-monitor.ts` (Cloud Function)

### Base de datos:
- Colección `sla_alerts/`
- Campos en `phases/`: `maxDurationHours`, `warningThresholdPercent`
- Campos en `projects/`: `isDelayed`, `delayHours`

---

## 🎨 FASE 6: TABLERO KANBAN DRAG & DROP
**Prioridad: ALTA** | **Duración: 2 semanas**

### Objetivos:
Vista Kanban profesional con drag & drop para mover productos entre fases.

### Funcionalidades:
1. **Tablero Kanban visual**
   - Columnas por fase de producción
   - Tarjetas de productos arrastrables
   - Límites WIP visibles por columna
   - Colores y códigos visuales

2. **Drag & Drop funcional**
   - Mover productos entre fases
   - Validación de permisos (operarios solo sus fases)
   - Actualización automática de `phaseProgress`
   - Animaciones suaves

3. **Filtros y búsqueda**
   - Por cliente
   - Por proyecto
   - Por urgencia/prioridad
   - Por rango de fechas
   - Por estado de retraso

4. **Información en tarjetas**
   - Nombre del producto
   - Cliente y proyecto
   - Cantidad
   - Días en fase actual
   - Indicador de urgencia
   - Mini-indicador de progreso total

5. **Vista swimlane** (opcional)
   - Agrupar por proyecto
   - Agrupar por cliente
   - Agrupar por prioridad

### Archivos a crear:
- `lib/screens/kanban/kanban_board_screen.dart`
- `lib/widgets/kanban/kanban_column.dart`
- `lib/widgets/kanban/product_card.dart`
- `lib/widgets/kanban/kanban_filter_bar.dart`
- `lib/services/kanban_service.dart`

### Dependencias:
```yaml
dependencies:
  flutter_draggable_gridview: ^1.0.0  # O similar
  # O implementar custom con Draggable/DragTarget
```

---

## 💬 FASE 7: SISTEMA DE MENSAJERÍA Y CHAT
**Prioridad: ALTA** | **Duración: 2-3 semanas**

### Objetivos:
Chat completo por proyecto con línea de tiempo y eventos automáticos.

### Funcionalidades:
1. **Chat por lote**
   - Mensajes de texto
   - Menciones @usuario
   - Adjuntar archivos (fotos, PDFs)
   - Emojis y reacciones
   - Editar/eliminar mensajes
   - Threads (responder a mensajes)

2. **Eventos automáticos del sistema**
   - "Lote creado"
   - "Fase X completada"
   - "Producto movido a fase Y"
   - "Retraso detectado en producto Z"
   - "Factura emitida"
   - "Pago recibido"

3. **Mensajes internos vs cliente**
   - Flag `isInternal` para mensajes privados
   - Clientes solo ven mensajes públicos
   - Equipo ve todo

4. **Notificaciones en tiempo real**
   - Badge con contador de no leídos
   - Sonido/vibración en mensajes nuevos
   - Push notifications (opcional)

5. **Estado de lectura**
   - Marca de "visto" por usuario
   - Indicador "está escribiendo..."

### Archivos a crear:
- `lib/models/message_model.dart`
- `lib/services/message_service.dart`
- `lib/screens/chat/batch_chat_screen.dart`
- `lib/widgets/chat/message_bubble.dart`
- `lib/widgets/chat/message_input.dart`
- `lib/widgets/chat/system_event_card.dart`
- `lib/services/notification_service.dart`

### Base de datos:
- Colección `/organizations/{organizationId}/production_batches/{batchId}/messages/`

---

## 📥 FASE 8: BANDEJA DE ENTRADA UNIFICADA
**Prioridad: MEDIA** | **Duración: 1 semana**

### Objetivos:
Inbox central que consolida todas las conversaciones.

### Funcionalidades:
1. **Vista de inbox**
   - Lista de todas las conversaciones
   - Ordenadas por última actividad
   - Contador de mensajes no leídos
   - Estado (abierto, resuelto, archivado)

2. **Filtros**
   - Por cliente
   - Por proyecto
   - Por producto
   - Por estado
   - Por prioridad
   - Solo no leídos
   - Asignadas a mí

3. **Acciones rápidas**
   - Marcar como leído/no leído
   - Archivar conversación
   - Asignar a usuario
   - Cambiar prioridad
   - Resolver/abrir

4. **Preferencias de inbox**
   - Layout (lista/tarjetas)
   - Auto-archivar resueltos
   - Marcar como leído al abrir

### Archivos a crear:
- `lib/screens/inbox/inbox_screen.dart`
- `lib/models/inbox_conversation_model.dart`
- `lib/services/inbox_service.dart`
- `lib/widgets/inbox/conversation_card.dart`
- `lib/screens/settings/inbox_preferences_screen.dart`

### Base de datos:
- Colección `inbox/`
- Colección `users/{userId}/inbox_preferences/`

---

## 🔔 FASE 9: NOTIFICACIONES PUSH Y EMAIL
**Prioridad: MEDIA** | **Duración: 1-2 semanas**

### Objetivos:
Sistema completo de notificaciones multi-canal.

### Funcionalidades:
1. **Notificaciones in-app**
   - Panel lateral deslizable
   - Lista de notificaciones recientes
   - Contador en navbar
   - Marcar como leída
   - Ir al elemento relacionado

2. **Push notifications**
   - Firebase Cloud Messaging (FCM)
   - Notificaciones para móviles iOS/Android
   - Notificaciones web (PWA)

3. **Email notifications**
   - SendGrid o similar
   - Templates HTML personalizados
   - Resumen diario/semanal opcional

4. **Configuración por usuario**
   - Activar/desactivar por canal
   - Frecuencia (instantáneo, horario, diario)
   - Horas de silencio
   - Tipos de notificación

5. **Tipos de notificaciones**
   - Nuevo mensaje/mención
   - Cambio de estado
   - Alerta SLA
   - Factura emitida
   - Pago recibido
   - Asignación a proyecto

### Archivos a crear:
- `lib/models/notification_model.dart`
- `lib/services/notification_service.dart`
- `lib/screens/notifications/notifications_screen.dart`
- `lib/widgets/notification_card.dart`
- `lib/screens/settings/notification_preferences_screen.dart`
- `functions/src/send-notifications.ts` (Cloud Function)

### Integraciones:
- Firebase Cloud Messaging
- SendGrid API

---

## 💰 FASE 10: FACTURACIÓN Y HOLDED
**Prioridad: ALTA** | **Duración: 2 semanas**

### Objetivos:
Integración completa con Holded para facturación electrónica.

### Funcionalidades:
1. **Crear facturas desde proyecto**
   - Botón "Generar factura"
   - Calcula total del proyecto
   - Crea factura en Holded via API
   - Guarda referencia local

2. **Sincronización con Holded**
   - Importar facturas existentes
   - Actualizar estados
   - Webhook para cambios en Holded
   - Sync bidireccional

3. **Gestión de facturas**
   - Lista de facturas por proyecto/cliente
   - Descargar PDF
   - Ver detalles
   - Estados (pendiente, pagada, vencida)

4. **Dashboard financiero**
   - Total facturado
   - Total cobrado
   - Pendiente de cobro
   - Facturas vencidas

### Archivos a crear:
- `lib/models/invoice_model.dart`
- `lib/services/holded_service.dart`
- `lib/services/invoice_service.dart`
- `lib/screens/invoices/invoices_list_screen.dart`
- `lib/screens/invoices/invoice_detail_screen.dart`
- `lib/screens/dashboard/financial_dashboard_screen.dart`
- `functions/src/holded-webhook.ts` (Cloud Function)

### Base de datos:
- Colección `invoices/`

### Integraciones:
- Holded API

---

## 💳 FASE 11: PAGOS ONLINE (STRIPE/REDSYS)
**Prioridad: MEDIA** | **Duración: 2 semanas**

### Objetivos:
Pasarela de pagos integrada para clientes.

### Funcionalidades:
1. **Integración Stripe**
   - Payment Intents API
   - Checkout hosted
   - Webhooks para confirmación
   - Guardar métodos de pago

2. **Integración Redsys** (opcional)
   - TPV virtual
   - Pasarela española
   - Confirmación de pagos

3. **Proceso de pago**
   - Desde detalle de factura
   - Seleccionar método
   - Procesar pago
   - Actualizar estado
   - Enviar confirmación

4. **Gestión de pagos**
   - Historial de pagos
   - Reembolsos
   - Pagos parciales
   - Recibos

### Archivos a crear:
- `lib/models/payment_model.dart`
- `lib/services/stripe_service.dart`
- `lib/services/redsys_service.dart`
- `lib/screens/payments/payment_screen.dart`
- `lib/screens/payments/payment_success_screen.dart`
- `lib/screens/payments/payments_list_screen.dart`
- `functions/src/stripe-webhook.ts` (Cloud Function)

### Base de datos:
- Colección `payments/`

### Integraciones:
- Stripe API
- Redsys (opcional)

---

## 👤 FASE 12: PORTAL DEL CLIENTE
**Prioridad: ALTA** | **Duración: 2 semanas**

### Objetivos:
Vista simplificada para clientes con acceso restringido.

### Funcionalidades:
1. **Dashboard cliente**
   - Mis proyectos activos
   - Estado visual simplificado
   - Fechas de entrega
   - Últimos mensajes

2. **Vista de proyecto (cliente)**
   - Info básica del proyecto
   - Lista de productos
   - Estado general (% completado)
   - Chat con Marsot
   - Galería de fotos
   - Descargar facturas

3. **Crear nuevo pedido**
   - Elegir productos del catálogo aprobado
   - Definir cantidades
   - Fecha objetivo
   - Adjuntar referencias
   - Enviar a aprobación

4. **Notificaciones cliente**
   - Pedido aprobado
   - Fase completada
   - Producto listo
   - Factura disponible

### Archivos a crear:
- `lib/screens/client/client_dashboard.dart`
- `lib/screens/client/client_project_view.dart`
- `lib/screens/client/create_order_screen.dart`
- `lib/widgets/client/simplified_progress.dart`

---

## 📊 FASE 13: REPORTES Y ANALYTICS AVANZADOS
**Prioridad: MEDIA** | **Duración: 2 semanas**

### Objetivos:
Reportes detallados y exportación de datos.

### Funcionalidades:
1. **Reportes predefinidos**
   - Proyectos completados (período)
   - Productividad por fase
   - Tiempos promedio
   - Proyectos retrasados
   - Ingresos por cliente/mes

2. **Generación de PDF**
   - Librería pdf
   - Templates profesionales
   - Gráficos incluidos
   - Logo y branding

3. **Exportación CSV**
   - Proyectos
   - Productos
   - Facturas
   - Pagos

4. **Analytics agregados**
   - Cloud Functions que calculan métricas diarias/mensuales
   - Guardan en `analytics/`
   - Dashboard consume datos pre-calculados

### Archivos a crear:
- `lib/services/report_service.dart`
- `lib/screens/reports/reports_screen.dart`
- `lib/screens/reports/report_viewer_screen.dart`
- `lib/utils/pdf_generator.dart`
- `functions/src/calculate-analytics.ts` (Cloud Function scheduled)

### Base de datos:
- Colección `reports/`
- Colección `analytics/`

---

## 📁 FASE 14: GESTIÓN DE ARCHIVOS Y GALERÍA
**Prioridad: MEDIA** | **Duración: 1-2 semanas**

### Objetivos:
Sistema completo de archivos y fotos.

### Funcionalidades:
1. **Subida de archivos**
   - Por proyecto (diseños, contratos)
   - Por producto (fotos progreso, finales)
   - Múltiples archivos simultáneos
   - Preview de imágenes
   - Límite de tamaño

2. **Firebase Storage**
   - Estructura organizada
   - `organizations/{orgId}/projects/{projectId}/files/`
   - `organizations/{orgId}/projects/{projectId}/products/{productId}/photos/`

3. **Galería de fotos**
   - Vista grid/lista
   - Filtrar por fase
   - Filtrar por tipo
   - Lightbox para ampliar
   - Descargar

4. **Gestión de archivos**
   - Renombrar
   - Eliminar (solo admins)
   - Compartir link
   - Metadata (quién subió, cuándo)

### Archivos a crear:
- `lib/models/file_model.dart`
- `lib/models/photo_model.dart`
- `lib/services/file_service.dart`
- `lib/screens/files/files_screen.dart`
- `lib/screens/photos/photo_gallery_screen.dart`
- `lib/widgets/file_uploader.dart`
- `lib/widgets/photo_grid.dart`

### Base de datos:
- Colección `projects/{projectId}/files/`
- Colección `products/{productId}/photos/`

---

## 🎨 FASE 15: UX/UI AVANZADO Y PERSONALIZACIÓN
**Prioridad: BAJA** | **Duración: 1-2 semanas**

### Objetivos:
Mejorar experiencia de usuario y personalización.

### Funcionalidades:
1. **Tema oscuro**
   - Toggle light/dark
   - Guardar preferencia
   - Transición suave

2. **Personalización**
   - Avatar personalizado
   - Color de acento
   - Tamaño de fuente
   - Vista preferida (Kanban/Lista)

3. **Búsqueda global**
   - Buscar en todo (proyectos, clientes, productos)
   - Resultados agrupados por tipo
   - Búsqueda avanzada con filtros

4. **Atajos de teclado**
   - Navegación rápida
   - Crear nuevo (Ctrl+N)
   - Búsqueda (Ctrl+K)

5. **Onboarding**
   - Tutorial inicial por rol
   - Tooltips contextuales
   - Centro de ayuda
   - Videos tutoriales

6. **Internacionalización**
   - Español
   - Inglés
   - Fácil añadir idiomas

### Archivos a crear:
- `lib/theme/dark_theme.dart`
- `lib/screens/settings/appearance_screen.dart`
- `lib/screens/search/global_search_screen.dart`
- `lib/screens/onboarding/onboarding_screen.dart`
- `lib/l10n/` (carpeta de traducciones)

---

## 📅 Timeline Estimado

| Fase | Duración | Acumulado | Prioridad |
|------|----------|-----------|-----------|
| FASE 5: SLA y Alertas | 1-2 sem | 2 sem | ALTA |
| FASE 6: Kanban | 2 sem | 4 sem | ALTA |
| FASE 7: Chat | 2-3 sem | 7 sem | ALTA |
| FASE 8: Inbox | 1 sem | 8 sem | MEDIA |
| FASE 9: Notificaciones | 1-2 sem | 10 sem | MEDIA |
| FASE 10: Holded | 2 sem | 12 sem | ALTA |
| FASE 11: Pagos | 2 sem | 14 sem | MEDIA |
| FASE 12: Portal Cliente | 2 sem | 16 sem | ALTA |
| FASE 13: Reportes | 2 sem | 18 sem | MEDIA |
| FASE 14: Archivos | 1-2 sem | 20 sem | MEDIA |
| FASE 15: UX Avanzado | 1-2 sem | 22 sem | BAJA |

**Total: ~5-6 meses** (trabajando full-time)

---

## 🎯 Orden Recomendado de Implementación

### Grupo 1 - Core Crítico (Primero):
1. FASE 5: SLA y Alertas
2. FASE 6: Kanban
3. FASE 7: Chat

### Grupo 2 - Financiero (Segundo):
4. FASE 10: Holded
5. FASE 11: Pagos

### Grupo 3 - Cliente (Tercero):
6. FASE 12: Portal Cliente
7. FASE 8: Inbox
8. FASE 9: Notificaciones

### Grupo 4 - Analytics (Cuarto):
9. FASE 13: Reportes
10. FASE 14: Archivos

### Grupo 5 - Polish (Último):
11. FASE 15: UX Avanzado

---

## ✅ Ventajas de este Roadmap

1. **Sin refactorización** - Cada fase construye sobre la anterior
2. **Lógico** - Agrupado por funcionalidad relacionada
3. **Testeable** - Cada fase es completa y funcional
4. **Flexible** - Puedes cambiar el orden si lo necesitas
5. **Priorizado** - Las fases críticas primero
6. **Realista** - Tiempos estimados alcanzables