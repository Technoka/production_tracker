# 🎯 ROADMAP COMPLETO: GESTIÓN DE ESTADOS DE PRODUCTOS DE LOTE

## 📋 ANÁLISIS DE LA SITUACIÓN ACTUAL

### ✅ Ya Implementado (Backend)
- ✅ **Modelos completos**:
  - `ProductStatusModel`: Estados personalizables con validaciones
  - `StatusTransitionModel`: Transiciones con validaciones y lógica condicional
  - `ValidationConfigModel`: 7 tipos de validación configurables
  - `ConditionalLogic` y `ConditionalAction`: Lógica de negocio avanzada

- ✅ **Servicios funcionales**:
  - `ProductStatusService`: CRUD completo de estados
  - `StatusTransitionService`: Gestión de transiciones y validaciones
  - `ProductionBatchService`: Integración con validaciones de transición

- ✅ **Base de datos inicializada**:
  - Colección `organizations/{orgId}/product_statuses` con 5 estados por defecto
  - Colección `organizations/{orgId}/status_transitions` con transiciones predeterminadas
  - Estados del sistema: pending, hold, cao, control, ok

### ❌ Falta Implementar (Frontend/UI)
1. ❌ **Pantalla de gestión de estados** (crear, editar, eliminar, reordenar)
2. ❌ **Pantalla de gestión de transiciones** (configurar validaciones y permisos)
3. ❌ **Diálogos de validación** para cada tipo de transición
4. ❌ **Integración en Kanban** (drag & drop con validaciones)
5. ❌ **Modificación de batch_product_detail_screen** con estados dinámicos
6. ❌ **Sistema de estados en Kanban** (columnas por estado en lugar de fase)
7. ❌ **Internacionalización** de estados personalizados

---

## 🗺️ FASES DE IMPLEMENTACIÓN

### 📦 FASE 1: GESTIÓN DE ESTADOS (CRUD UI)
**Duración estimada: 3-4 días**

#### Objetivo
Crear interfaz completa para que administradores gestionen estados de productos.

#### 🎨 Pantallas a crear

##### 1.1. `/lib/screens/organization/manage_product_statuses_screen.dart`
```dart
// Pantalla principal de gestión de estados
// Features:
- Lista de todos los estados (activos e inactivos)
- Drag & drop para reordenar
- Botón crear nuevo estado
- Toggle activar/desactivar
- Editar/eliminar (solo estados custom)
- Badges para estados del sistema (no editables)
- Stream en tiempo real
```

**Componentes UI**:
- AppBar con título y botón "Crear Estado"
- `ReorderableListView` para drag & drop
- Card por cada estado con:
  - Color indicator (círculo con el color)
  - Icono del estado
  - Nombre y descripción
  - Badge "Sistema" si `isSystem == true`
  - Switch para activar/desactivar
  - IconButtons: editar, eliminar
- FloatingActionButton para crear nuevo

**Flujo de datos**:
```dart
StreamBuilder<List<ProductStatusModel>>(
  stream: productStatusService.watchStatuses(organizationId),
  builder: (context, snapshot) {
    // Renderizar lista reordenable
  }
)
```

##### 1.2. `/lib/screens/organization/create_edit_status_dialog.dart`
```dart
// Diálogo para crear/editar estados
// Features:
- TextField: Nombre del estado (validación: no vacío, único)
- TextField: Descripción (opcional)
- ColorPicker: Selector de color (validación: hex válido)
- IconPicker: Selector de icono Material Icons
- Vista previa del estado
- Validación en tiempo real
- Guardar/Cancelar
```

**Validaciones**:
- Nombre obligatorio (min 3 caracteres)
- Color en formato #RRGGBB
- Nombre único dentro de la organización
- No editar estados del sistema

##### 1.3. `/lib/widgets/status/status_preview_card.dart`
```dart
// Widget reutilizable de vista previa
// Shows:
- Color circle
- Icon
- Name & description
- Usage: en diálogo de creación, lista de estados
```

#### 🔧 Servicios a modificar

**`ProductStatusService`**: Ya está completo, solo verificar:
- ✅ `createStatus()` - Funciona
- ✅ `updateStatus()` - Funciona  
- ✅ `deleteStatus()` - Funciona
- ✅ `reorderStatuses()` - Funciona
- ⚠️ **AÑADIR**: Validación que no haya productos usando el estado antes de eliminar

```dart
// Nuevo método en ProductStatusService
Future<bool> canDeleteStatus(String organizationId, String statusId) async {
  // Consultar si hay productos con este statusId
  final productsSnapshot = await _firestore
    .collectionGroup('products')
    .where('organizationId', isEqualTo: organizationId)
    .where('statusId', isEqualTo: statusId)
    .limit(1)
    .get();
  
  return productsSnapshot.docs.isEmpty;
}
```

#### 🔐 Permisos requeridos
```dart
// En permission_registry_model.dart - AÑADIR si no existe:
'organization': {
  'manageProductStatuses': boolean, // Para CRUD de estados
}
```

#### 📱 Navegación
- Desde `OrganizationSettingsScreen` → nueva opción "Gestionar Estados"
- O desde `ManagePhasesScreen` como opción paralela

#### 🌐 Traducciones necesarias (app_es.arb / app_en.arb)
```json
"manageProductStatuses": "Gestionar Estados de Productos",
"createStatus": "Crear Estado",
"editStatus": "Editar Estado",
"deleteStatus": "Eliminar Estado",
"statusName": "Nombre del Estado",
"statusDescription": "Descripción",
"statusColor": "Color",
"statusIcon": "Icono",
"statusPreview": "Vista Previa",
"systemStatus": "Estado del Sistema",
"customStatus": "Estado Personalizado",
"activeStatus": "Estado Activo",
"inactiveStatus": "Estado Inactivo",
"reorderStatuses": "Reordenar Estados",
"deleteStatusConfirm": "¿Eliminar este estado?",
"deleteStatusWarning": "Los productos con este estado no podrán continuar",
"statusInUse": "Este estado está en uso y no puede eliminarse",
"statusNameRequired": "El nombre es obligatorio",
"statusNameExists": "Ya existe un estado con este nombre",
"statusColorInvalid": "Color inválido (use formato #RRGGBB)",
```

---

### 🔄 FASE 2: GESTIÓN DE TRANSICIONES
**Duración estimada: 4-5 días**

#### Objetivo
Crear interfaz para configurar transiciones entre estados con validaciones y permisos.

#### 🎨 Pantallas a crear

##### 2.1. `/lib/screens/organization/manage_status_transitions_screen.dart`
```dart
// Pantalla principal de transiciones
// Features:
- Vista de matriz de transiciones (desde → hacia)
- Filtro por estado origen
- Lista de todas las transiciones configuradas
- Crear nueva transición
- Editar/eliminar transiciones existentes
- Visualización de validaciones configuradas
- Stream en tiempo real
```

**Layout sugerido**:
```
┌─────────────────────────────────────┐
│ Gestionar Transiciones      [+ Crear]│
├─────────────────────────────────────┤
│ Filtrar por estado origen: [Todos ▼]│
├─────────────────────────────────────┤
│ ┌───────────────────────────────┐   │
│ │ Pending → Hold                │   │
│ │ Validación: Simple            │   │
│ │ Roles: Admin, Manager     [⋮]│   │
│ └───────────────────────────────┘   │
│ ┌───────────────────────────────┐   │
│ │ Hold → CAO                    │   │
│ │ Validación: Cantidad + Texto  │   │
│ │ Roles: Admin, Quality   [⋮]  │   │
│ │ 🔔 Lógica: Si qty > 5 → Alert│   │
│ └───────────────────────────────┘   │
└─────────────────────────────────────┘
```

##### 2.2. `/lib/screens/organization/create_edit_transition_dialog.dart`
```dart
// Diálogo modal grande para configurar transición
// Steps (wizard multi-paso):

// PASO 1: Selección básica
- DropdownButton: Estado origen (fromStatusId)
- DropdownButton: Estado destino (toStatusId)
- Multi-select: Roles permitidos

// PASO 2: Tipo de validación
- Radio buttons con los 7 tipos:
  * Simple Approval
  * Text Required
  * Text Optional  
  * Quantity and Text
  * Checklist
  * Photo Required
  * Multi-Approval

// PASO 3: Configuración de validación (según tipo)
- Si Text: min/max length, placeholder, label
- Si Quantity: min/max value, placeholder, label
- Si Checklist: lista de items, ¿todos obligatorios?
- Si Photo: mínimo de fotos
- Si Multi-approval: mínimo de aprobadores

// PASO 4: Lógica condicional (opcional)
- Checkbox: "Añadir lógica condicional"
- Si activado:
  * Campo a evaluar (quantity, text length, etc)
  * Operador (>, <, ==, !=)
  * Valor de comparación
  * Acción si se cumple:
    - Bloquear transición (con mensaje)
    - Mostrar advertencia
    - Requerir aprobación adicional
    - Notificar roles

// PASO 5: Resumen y confirmación
- Vista previa de toda la configuración
- Botones: Guardar / Cancelar
```

**Componentes reutilizables**:
- `/lib/widgets/transitions/validation_type_selector.dart`
- `/lib/widgets/transitions/validation_config_form.dart`
- `/lib/widgets/transitions/conditional_logic_builder.dart`
- `/lib/widgets/transitions/transition_preview_card.dart`

##### 2.3. `/lib/widgets/transitions/transition_list_item.dart`
```dart
// Card expandible para mostrar una transición
// Compact view:
- Estado origen → Estado destino
- Icono de tipo de validación
- Lista de roles (chips)
- Badge si tiene lógica condicional

// Expanded view:
- Toda la configuración de validación
- Detalles de lógica condicional
- Botones: Editar, Eliminar, Duplicar
```

#### 🔧 Servicios a modificar

**`StatusTransitionService`**: Añadir métodos CRUD completos

```dart
// CREAR
Future<String?> createTransition({
  required String organizationId,
  required String fromStatusId,
  required String toStatusId,
  required ValidationType validationType,
  required ValidationConfigModel validationConfig,
  required List<String> allowedRoles,
  ConditionalLogic? conditionalLogic,
  String? createdBy,
}) async { ... }

// ACTUALIZAR
Future<bool> updateTransition({
  required String organizationId,
  required String transitionId,
  // ... campos opcionales para actualizar
}) async { ... }

// ELIMINAR
Future<bool> deleteTransition(
  String organizationId,
  String transitionId,
) async { ... }

// OBTENER transiciones desde un estado
Future<List<StatusTransitionModel>> getTransitionsFromStatus(
  String organizationId,
  String fromStatusId,
) async { ... }

// OBTENER transición específica
Future<StatusTransitionModel?> getTransition(
  String organizationId,
  String transitionId,
) async { ... }
```

#### 🔐 Permisos requeridos
```dart
'organization': {
  'manageStatusTransitions': boolean,
}
```

#### 🌐 Traducciones necesarias
```json
"manageStatusTransitions": "Gestionar Transiciones",
"createTransition": "Crear Transición",
"editTransition": "Editar Transición",
"deleteTransition": "Eliminar Transición",
"fromStatus": "Desde Estado",
"toStatus": "Hacia Estado",
"allowedRoles": "Roles Permitidos",
"validationType": "Tipo de Validación",
"validationConfig": "Configuración de Validación",
"conditionalLogic": "Lógica Condicional",
"addConditionalLogic": "Añadir Lógica Condicional",
"field": "Campo",
"operator": "Operador",
"value": "Valor",
"action": "Acción",
"blockTransition": "Bloquear Transición",
"showWarning": "Mostrar Advertencia",
"requireApproval": "Requerir Aprobación",
"notifyRoles": "Notificar Roles",
"transitionSummary": "Resumen de Transición",

// Tipos de validación
"simpleApproval": "Aprobación Simple",
"textRequired": "Texto Obligatorio",
"textOptional": "Texto Opcional",
"quantityAndText": "Cantidad y Texto",
"checklist": "Lista de Verificación",
"photoRequired": "Foto Obligatoria",
"multiApproval": "Aprobación Múltiple",

// Labels de configuración
"minLength": "Longitud Mínima",
"maxLength": "Longitud Máxima",
"minValue": "Valor Mínimo",
"maxValue": "Valor Máximo",
"placeholder": "Texto de Ejemplo",
"minPhotos": "Mínimo de Fotos",
"minApprovals": "Mínimo de Aprobaciones",
"checklistItems": "Items de Verificación",
"allItemsRequired": "Todos los Items Obligatorios",
```

---

### 🎯 FASE 3: DIÁLOGOS DE VALIDACIÓN DINÁMICOS
**Duración estimada: 5-6 días**

#### Objetivo
Crear sistema de diálogos que se adaptan al tipo de validación de cada transición.

#### 🎨 Componentes a crear

##### 3.1. `/lib/widgets/transitions/validation_dialog_manager.dart`
```dart
// Manager central que decide qué diálogo mostrar
class ValidationDialogManager {
  static Future<ValidationDataModel?> showValidationDialog({
    required BuildContext context,
    required StatusTransitionModel transition,
    required BatchProductModel product,
  }) async {
    switch (transition.validationType) {
      case ValidationType.simpleApproval:
        return await _showSimpleApprovalDialog(context, transition);
      
      case ValidationType.textRequired:
      case ValidationType.textOptional:
        return await _showTextDialog(context, transition);
      
      case ValidationType.quantityAndText:
        return await _showQuantityTextDialog(context, transition);
      
      case ValidationType.checklist:
        return await _showChecklistDialog(context, transition);
      
      case ValidationType.photoRequired:
        return await _showPhotoDialog(context, transition);
      
      case ValidationType.multiApproval:
        return await _showMultiApprovalDialog(context, transition);
    }
  }
}
```

##### 3.2. `/lib/widgets/transitions/simple_approval_dialog.dart`
```dart
// Diálogo más simple: solo confirmación
// UI:
- Título: "¿Confirmar transición {fromStatus} → {toStatus}?"
- Descripción: mostrar info del producto
- Botones: Cancelar / Confirmar
```

##### 3.3. `/lib/widgets/transitions/text_validation_dialog.dart`
```dart
// Diálogo con campo de texto
// UI según config:
- TextField con label de config.textLabel
- Placeholder de config.textPlaceholder
- Validación minLength/maxLength en tiempo real
- Contador de caracteres
- Botones: Cancelar / Confirmar
```

##### 3.4. `/lib/widgets/transitions/quantity_text_dialog.dart`
```dart
// Diálogo con cantidad + texto
// UI:
- TextField numérico para cantidad
  * Label: config.quantityLabel
  * Validación: config.quantityMin/Max
- TextField para descripción
  * Label: config.textLabel
  * Validación: config.textMinLength/MaxLength
- Si hay lógica condicional:
  * Evaluar en tiempo real
  * Mostrar warning/error según acción
- Botones: Cancelar / Confirmar
```

##### 3.5. `/lib/widgets/transitions/checklist_dialog.dart`
```dart
// Diálogo con lista de verificación
// UI:
- Lista de CheckboxListTile
- Por cada item en config.checklistItems:
  * Checkbox
  * Label del item
  * ¿Es obligatorio?
- Si config.allItemsRequired: validar todos marcados
- Sino: permitir enviar con algunos sin marcar
- Botones: Cancelar / Confirmar
```

##### 3.6. `/lib/widgets/transitions/photo_validation_dialog.dart`
```dart
// Diálogo para subir fotos
// UI:
- Botón "Tomar foto" (cámara)
- Botón "Elegir de galería"
- Grid de fotos seleccionadas (con X para eliminar)
- Contador: {currentCount} / {config.minPhotos} fotos
- Validación: mínimo de fotos alcanzado
- Subir a Firebase Storage al confirmar
- Botones: Cancelar / Confirmar (disabled si no cumple mínimo)
```

**Dependencias**:
```yaml
image_picker: ^1.0.7
firebase_storage: ^11.6.0
```

##### 3.7. `/lib/widgets/transitions/multi_approval_dialog.dart`
```dart
// Diálogo para aprobar con múltiples usuarios
// UI:
- Lista de usuarios que pueden aprobar
- CheckboxListTile por cada usuario
- Mínimo de aprobaciones: config.minApprovals
- Mostrar quién ya ha aprobado
- Validación: suficientes aprobaciones
- Botones: Cancelar / Guardar (disabled si no cumple)

// Backend:
- Guardar en ValidationDataModel.approvedBy: [userId1, userId2, ...]
- Si no cumple mínimo: guardar como "pendiente de aprobación"
```

#### 🔧 Lógica de evaluación condicional

**`/lib/services/conditional_logic_evaluator.dart`**
```dart
class ConditionalLogicEvaluator {
  /// Evalúa si se cumple la condición
  static bool evaluateCondition(
    ConditionalLogic logic,
    Map<String, dynamic> validationData,
  ) {
    final value = validationData[logic.field];
    
    switch (logic.operator) {
      case ConditionOperator.greaterThan:
        return (value as num) > (logic.value as num);
      
      case ConditionOperator.lessThan:
        return (value as num) < (logic.value as num);
      
      case ConditionOperator.equals:
        return value == logic.value;
      
      case ConditionOperator.notEquals:
        return value != logic.value;
      
      case ConditionOperator.contains:
        return (value as String).contains(logic.value as String);
    }
  }
  
  /// Ejecuta la acción configurada
  static Future<ConditionalActionResult> executeAction(
    ConditionalAction action,
    BuildContext context,
  ) async {
    switch (action.type) {
      case ConditionalActionType.blockTransition:
        return ConditionalActionResult(
          shouldBlock: true,
          message: action.parameters?['reason'] ?? 'Transición bloqueada',
        );
      
      case ConditionalActionType.showWarning:
        return ConditionalActionResult(
          shouldBlock: false,
          showWarning: true,
          message: action.parameters?['message'] ?? 'Advertencia',
        );
      
      case ConditionalActionType.requireApproval:
        return ConditionalActionResult(
          shouldBlock: false,
          requiresAdditionalApproval: true,
          requiredRoles: action.parameters?['requiredRoles'] ?? [],
        );
      
      case ConditionalActionType.requireAdditionalField:
        // Mostrar campo adicional dinámicamente
        return ConditionalActionResult(
          shouldBlock: false,
          additionalFieldRequired: action.parameters?['fieldName'],
        );
    }
  }
}

class ConditionalActionResult {
  final bool shouldBlock;
  final bool showWarning;
  final String? message;
  final bool requiresAdditionalApproval;
  final List<String> requiredRoles;
  final String? additionalFieldRequired;
  
  ConditionalActionResult({
    this.shouldBlock = false,
    this.showWarning = false,
    this.message,
    this.requiresAdditionalApproval = false,
    this.requiredRoles = const [],
    this.additionalFieldRequired,
  });
}
```

#### 🎯 Flujo de validación completo

```dart
// En batch_product_detail_screen.dart o kanban
Future<bool> _handleStatusTransition(
  BatchProductModel product,
  String toStatusId,
) async {
  // 1. Obtener transición configurada
  final transition = await _getTransitionConfig(
    product.statusId,
    toStatusId,
  );
  
  if (transition == null) {
    _showError('Transición no permitida');
    return false;
  }
  
  // 2. Validar permisos del usuario
  if (!_canUserExecuteTransition(transition)) {
    _showError('No tienes permisos para esta transición');
    return false;
  }
  
  // 3. Mostrar diálogo de validación
  final validationData = await ValidationDialogManager.showValidationDialog(
    context: context,
    transition: transition,
    product: product,
  );
  
  if (validationData == null) {
    return false; // Usuario canceló
  }
  
  // 4. Evaluar lógica condicional (si existe)
  if (transition.conditionalLogic != null) {
    final conditionMet = ConditionalLogicEvaluator.evaluateCondition(
      transition.conditionalLogic!,
      validationData.toMap(),
    );
    
    if (conditionMet) {
      final actionResult = await ConditionalLogicEvaluator.executeAction(
        transition.conditionalLogic!.action,
        context,
      );
      
      if (actionResult.shouldBlock) {
        _showError(actionResult.message ?? 'Transición bloqueada');
        return false;
      }
      
      if (actionResult.showWarning) {
        final proceed = await _showWarningDialog(actionResult.message!);
        if (!proceed) return false;
      }
      
      if (actionResult.requiresAdditionalApproval) {
        // Guardar como "pendiente de aprobación"
        await _saveAsPendingApproval(product, toStatusId, validationData);
        _showInfo('Transición requiere aprobación adicional');
        return true;
      }
    }
  }
  
  // 5. Ejecutar la transición
  final success = await _productionBatchService.updateProductStatus(
    organizationId: widget.organizationId,
    batchId: widget.batchId,
    productId: product.id,
    newStatusId: toStatusId,
    validationData: validationData,
    userId: _currentUser.uid,
  );
  
  if (success) {
    _showSuccess('Estado actualizado correctamente');
  } else {
    _showError('Error al actualizar estado');
  }
  
  return success;
}
```

---

### 📊 FASE 4: KANBAN CON ESTADOS (NO FASES)
**Duración estimada: 6-7 días**

#### Objetivo
Modificar el Kanban para que muestre columnas por estado de producto (no por fase) con drag & drop validado.

#### 🎨 Modificaciones a realizar

##### 4.1. Modificar `/lib/widgets/kanban/kanban_board_widget.dart`

**Cambio conceptual**: 
- ANTES: Columnas = Fases de producción (Corte, Skiving, etc)
- AHORA: Columnas = Estados de calidad (Pending, Hold, CAO, Control, OK)

```dart
class KanbanBoardWidget extends StatefulWidget {
  final String organizationId;
  final UserModel currentUser;
  final KanbanViewMode viewMode; // NEW: phases vs statuses
  
  // Añadir toggle para cambiar entre modos
  const KanbanBoardWidget({
    required this.organizationId,
    required this.currentUser,
    this.viewMode = KanbanViewMode.statuses, // Default: por estados
  });
}

enum KanbanViewMode {
  phases,   // Kanban por fases (legacy)
  statuses, // Kanban por estados (nuevo)
}
```

**Estructura de datos**:
```dart
// Stream de estados activos
Stream<List<ProductStatusModel>> _watchStatuses() {
  return Provider.of<ProductStatusService>(context, listen: false)
    .watchStatuses(widget.organizationId);
}

// Agrupar productos por estado
Map<String, List<BatchProductModel>> _groupProductsByStatus(
  List<BatchProductModel> products
) {
  final grouped = <String, List<BatchProductModel>>{};
  
  for (final product in products) {
    final statusId = product.statusId ?? 'pending';
    if (!grouped.containsKey(statusId)) {
      grouped[statusId] = [];
    }
    grouped[statusId]!.add(product);
  }
  
  return grouped;
}
```

**UI Layout**:
```dart
Widget build(BuildContext context) {
  return StreamBuilder<List<ProductStatusModel>>(
    stream: _watchStatuses(),
    builder: (context, statusSnapshot) {
      if (!statusSnapshot.hasData) return LoadingWidget();
      
      final statuses = statusSnapshot.data!;
      
      return StreamBuilder<List<BatchProductModel>>(
        stream: _watchProducts(),
        builder: (context, productSnapshot) {
          if (!productSnapshot.hasData) return LoadingWidget();
          
          final products = productSnapshot.data!;
          final groupedProducts = _groupProductsByStatus(products);
          
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: statuses.map((status) {
                return KanbanColumn(
                  status: status,
                  products: groupedProducts[status.id] ?? [],
                  onProductDropped: (product, newStatusId) => 
                    _handleProductDrop(product, newStatusId),
                );
              }).toList(),
            ),
          );
        },
      );
    },
  );
}
```

##### 4.2. Crear `/lib/widgets/kanban/kanban_column_status.dart`

```dart
class KanbanColumn extends StatelessWidget {
  final ProductStatusModel status;
  final List<BatchProductModel> products;
  final Function(BatchProductModel, String) onProductDropped;
  
  @override
  Widget build(BuildContext context) {
    return DragTarget<BatchProductModel>(
      onWillAccept: (product) {
        // Validar si la transición es permitida
        return _canDropProduct(product, status.id);
      },
      onAccept: (product) {
        onProductDropped(product, status.id);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 300,
          margin: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty 
              ? status.colorValue.withOpacity(0.1)
              : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: candidateData.isNotEmpty
                ? status.colorValue
                : Colors.grey.shade300,
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Header de la columna
              _buildColumnHeader(),
              
              // Lista de productos
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return DraggableProductCard(
                      product: products[index],
                      currentStatus: status,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildColumnHeader() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status.colorValue.withOpacity(0.1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: status.colorValue,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          
          // Icono
          Icon(
            IconData(
              int.parse(status.icon),
              fontFamily: 'MaterialIcons',
            ),
            color: status.colorValue,
            size: 20,
          ),
          SizedBox(width: 8),
          
          // Nombre
          Expanded(
            child: Text(
              status.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // Contador
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status.colorValue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              products.length.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  bool _canDropProduct(BatchProductModel product, String toStatusId) {
    // TODO: Consultar si existe transición permitida
    // y si el usuario tiene permisos
    return true; // Placeholder
  }
}
```

##### 4.3. Modificar `/lib/widgets/kanban/product_card.dart`

```dart
class DraggableProductCard extends StatelessWidget {
  final BatchProductModel product;
  final ProductStatusModel currentStatus;
  
  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<BatchProductModel>(
      data: product,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 280,
          child: _buildCardContent(isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardContent(),
      ),
      child: _buildCardContent(),
    );
  }
  
  Widget _buildCardContent({bool isDragging = false}) {
    return Card(
      elevation: isDragging ? 0 : 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del producto
            Text(
              product.catalogProductName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            
            // Info básica
            Row(
              children: [
                Icon(Icons.numbers, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('Cantidad: ${product.quantity}'),
              ],
            ),
            
            // Fase actual (si aplica)
            if (product.currentPhaseId != null)
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('Fase: ${product.currentPhaseName}'),
                ],
              ),
            
            // Estado actual (con color)
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentStatus.colorValue,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  currentStatus.name,
                  style: TextStyle(
                    color: currentStatus.colorValue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            // Urgencia (si aplica)
            if (product.isDelayed ?? false)
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '⚠️ RETRASADO',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

##### 4.4. Lógica de drop con validación

```dart
Future<void> _handleProductDrop(
  BatchProductModel product,
  String newStatusId,
) async {
  // 1. Validar que la transición existe
  final transitions = await _statusTransitionService
    .getTransitionsFromStatus(
      widget.organizationId,
      product.statusId ?? 'pending',
    );
  
  final transition = transitions.firstWhere(
    (t) => t.toStatusId == newStatusId,
    orElse: () => null,
  );
  
  if (transition == null) {
    _showError('Transición no permitida');
    return;
  }
  
  // 2. Validar permisos del usuario
  final hasPermission = await _validateUserPermission(transition);
  if (!hasPermission) {
    _showError('No tienes permisos para esta transición');
    return;
  }
  
  // 3. Mostrar diálogo de validación (si requiere)
  if (transition.validationType != ValidationType.simpleApproval) {
    final validationData = await ValidationDialogManager.showValidationDialog(
      context: context,
      transition: transition,
      product: product,
    );
    
    if (validationData == null) {
      return; // Usuario canceló
    }
    
    // 4. Ejecutar transición con validación
    await _executeTransitionWithValidation(
      product,
      newStatusId,
      validationData,
    );
  } else {
    // 5. Transición simple sin validación
    await _executeSimpleTransition(product, newStatusId);
  }
}

Future<bool> _validateUserPermission(
  StatusTransitionModel transition,
) async {
  final userRole = widget.currentUser.role;
  return transition.allowedRoles.contains(userRole);
}

void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}
```

#### 🔄 Toggle entre vistas (Fases vs Estados)

Añadir en la UI del Kanban:
```dart
Row(
  children: [
    Text('Vista: '),
    SegmentedButton<KanbanViewMode>(
      segments: [
        ButtonSegment(
          value: KanbanViewMode.phases,
          label: Text('Por Fases'),
          icon: Icon(Icons.view_column),
        ),
        ButtonSegment(
          value: KanbanViewMode.statuses,
          label: Text('Por Estados'),
          icon: Icon(Icons.label),
        ),
      ],
      selected: {_currentViewMode},
      onSelectionChanged: (Set<KanbanViewMode> newSelection) {
        setState(() {
          _currentViewMode = newSelection.first;
        });
      },
    ),
  ],
)
```

---

### 🛠️ FASE 5: MODIFICAR BATCH_PRODUCT_DETAIL_SCREEN
**Duración estimada: 3-4 días**

#### Objetivo
Reemplazar botones hardcoded por sistema dinámico basado en transiciones configuradas.

#### 🎨 Modificaciones

##### 5.1. Modificar sección de "Acciones" en `batch_product_detail_screen.dart`

**ANTES (hardcoded)**:
```dart
// Botones fijos según estado actual
if (product.isPending) {
  ElevatedButton('Enviar a Hold', ...);
}
if (product.isHold) {
  ElevatedButton('Aprobar → OK', ...);
  ElevatedButton('Rechazar → CAO', ...);
}
// ... etc
```

**DESPUÉS (dinámico)**:
```dart
// Cargar transiciones disponibles desde el estado actual
StreamBuilder<List<StatusTransitionModel>>(
  stream: _watchAvailableTransitions(product.statusId),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return LoadingWidget();
    
    final transitions = snapshot.data!;
    
    // Filtrar transiciones que el usuario puede ejecutar
    final allowedTransitions = transitions.where((t) {
      return _canUserExecuteTransition(t);
    }).toList();
    
    if (allowedTransitions.isEmpty) {
      return Text('No hay acciones disponibles');
    }
    
    return Column(
      children: allowedTransitions.map((transition) {
        return _buildTransitionButton(transition, product);
      }).toList(),
    );
  },
)
```

##### 5.2. Crear botones dinámicos

```dart
Widget _buildTransitionButton(
  StatusTransitionModel transition,
  BatchProductModel product,
) {
  // Determinar color según estado destino
  final toStatus = _getStatusById(transition.toStatusId);
  
  return Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(_getValidationIcon(transition.validationType)),
        label: Text(
          'Mover a ${transition.toStatusName}',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: toStatus?.colorValue ?? Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => _handleTransition(transition, product),
      ),
    ),
  );
}

IconData _getValidationIcon(ValidationType type) {
  switch (type) {
    case ValidationType.simpleApproval:
      return Icons.check_circle;
    case ValidationType.textRequired:
      return Icons.edit;
    case ValidationType.quantityAndText:
      return Icons.format_list_numbered;
    case ValidationType.checklist:
      return Icons.checklist;
    case ValidationType.photoRequired:
      return Icons.camera_alt;
    case ValidationType.multiApproval:
      return Icons.people;
    default:
      return Icons.arrow_forward;
  }
}

Future<void> _handleTransition(
  StatusTransitionModel transition,
  BatchProductModel product,
) async {
  // Usar el flujo de validación de la Fase 3
  final success = await _handleStatusTransition(
    product,
    transition.toStatusId,
  );
  
  if (success) {
    // Actualizar UI o navegar
  }
}
```

##### 5.3. Modificar tarjeta de "Estado Actual"

```dart
Widget _buildStatusCard(BatchProductModel product) {
  return FutureBuilder<ProductStatusModel?>(
    future: _getProductStatus(product.statusId),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return LoadingWidget();
      
      final status = snapshot.data!;
      
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estado Actual',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              
              Row(
                children: [
                  // Color indicator
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: status.colorValue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  
                  // Icono
                  Icon(
                    IconData(
                      int.parse(status.icon),
                      fontFamily: 'MaterialIcons',
                    ),
                    color: status.colorValue,
                  ),
                  SizedBox(width: 8),
                  
                  // Nombre
                  Text(
                    status.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: status.colorValue,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              Text(
                status.description,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              
              // Mostrar historial si hay
              if (product.statusHistory?.isNotEmpty ?? false) ...[
                SizedBox(height: 16),
                Divider(),
                _buildStatusHistory(product.statusHistory!),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildStatusHistory(List<StatusHistoryEntry> history) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Historial de Estados',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      SizedBox(height: 8),
      
      ...history.reversed.take(5).map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.fromStatusName} → ${entry.toStatusName}',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${entry.changedBy} - ${_formatDate(entry.timestamp)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (entry.validationData != null)
                      Text(
                        'Con validación',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      
      if (history.length > 5)
        TextButton(
          onPressed: () => _showFullHistory(history),
          child: Text('Ver historial completo'),
        ),
    ],
  );
}
```

---

### 🔐 FASE 6: VALIDACIONES Y PERMISOS
**Duración estimada: 2-3 días**

#### Objetivo
Asegurar que todas las operaciones validen permisos correctamente.

#### 🎯 Validaciones necesarias

##### 6.1. Validación en UI (frontend)

```dart
// En cada widget que permita cambio de estado
Future<bool> _canUserExecuteTransition(
  StatusTransitionModel transition,
) async {
  final memberService = Provider.of<OrganizationMemberService>(context);
  final user = widget.currentUser;
  
  // 1. Verificar si el rol del usuario está en allowedRoles
  if (!transition.allowedRoles.contains(user.role)) {
    return false;
  }
  
  // 2. Si hay permiso específico requerido, validarlo
  if (transition.requiresPermission != null) {
    final hasPermission = await memberService.hasPermission(
      user.organizationId!,
      user.uid,
      transition.requiresPermission!,
    );
    return hasPermission;
  }
  
  return true;
}
```

##### 6.2. Validación en Service (backend logic)

Modificar `ProductionBatchService.updateProductStatus()`:

```dart
Future<bool> updateProductStatus({
  required String organizationId,
  required String batchId,
  required String productId,
  required String newStatusId,
  ValidationDataModel? validationData,
  required String userId,
}) async {
  try {
    // 1. Obtener producto actual
    final product = await _getProduct(organizationId, batchId, productId);
    if (product == null) return false;
    
    // 2. Obtener transición
    final transition = await _statusTransitionService.getTransition(
      organizationId,
      product.statusId ?? 'pending',
      newStatusId,
    );
    
    if (transition == null) {
      throw Exception('Transición no permitida');
    }
    
    // 3. Validar permisos del usuario
    final member = await _memberService.getMember(organizationId, userId);
    if (member == null || !transition.allowedRoles.contains(member.roleId)) {
      throw Exception('Sin permisos para esta transición');
    }
    
    // 4. Validar datos de validación (si se requieren)
    if (transition.validationType != ValidationType.simpleApproval) {
      if (validationData == null) {
        throw Exception('Se requieren datos de validación');
      }
      
      final validationError = _validateTransitionData(
        validationType: transition.validationType,
        config: transition.validationConfig,
        data: validationData.toMap(),
      );
      
      if (validationError != null) {
        throw Exception(validationError);
      }
    }
    
    // 5. Evaluar lógica condicional
    if (transition.conditionalLogic != null && validationData != null) {
      final shouldBlock = await _evaluateConditionalLogic(
        transition.conditionalLogic!,
        validationData.toMap(),
      );
      
      if (shouldBlock) {
        throw Exception('Transición bloqueada por reglas de negocio');
      }
    }
    
    // 6. Actualizar producto en Firestore
    final statusHistory = [
      ...product.statusHistory ?? [],
      StatusHistoryEntry(
        fromStatusId: product.statusId ?? 'pending',
        toStatusId: newStatusId,
        fromStatusName: product.statusName ?? 'Pendiente',
        toStatusName: await _getStatusName(organizationId, newStatusId),
        changedBy: userId,
        changedByName: await _getUserName(userId),
        timestamp: DateTime.now(),
        validationData: validationData,
      ),
    ];
    
    await _firestore
      .collection('organizations')
      .doc(organizationId)
      .collection('production_batches')
      .doc(batchId)
      .collection('products')
      .doc(productId)
      .update({
        'statusId': newStatusId,
        'statusName': await _getStatusName(organizationId, newStatusId),
        'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    
    return true;
  } catch (e) {
    debugPrint('Error updating product status: $e');
    return false;
  }
}
```

##### 6.3. Reglas de Firestore Security

Añadir a `firestore.rules`:

```javascript
// Validar transiciones de estado de productos
match /organizations/{orgId}/production_batches/{batchId}/products/{productId} {
  allow read: if isOrgMember(orgId);
  
  allow update: if isOrgMember(orgId) 
    && canExecuteStatusTransition(
      orgId,
      resource.data.statusId, 
      request.resource.data.statusId
    );
}

// Función helper para validar transiciones
function canExecuteStatusTransition(orgId, fromStatusId, toStatusId) {
  let member = get(/databases/$(database)/documents/organizations/$(orgId)/members/$(request.auth.uid));
  let transition = getTransitionDoc(orgId, fromStatusId, toStatusId);
  
  return transition != null 
    && transition.data.allowedRoles.hasAny([member.data.roleId]);
}

function getTransitionDoc(orgId, fromStatusId, toStatusId) {
  return getAfter(/databases/$(database)/documents/organizations/$(orgId)/status_transitions)
    .data
    .where(t => t.fromStatusId == fromStatusId && t.toStatusId == toStatusId)[0];
}
```

---

### 🌐 FASE 7: INTERNACIONALIZACIÓN
**Duración estimada: 2 días**

#### Objetivo
Añadir traducciones para todos los nuevos textos de estados y transiciones.

#### 📝 Archivos a modificar

##### Añadir a `app_es.arb`:
```json
{
  "manageProductStatuses": "Gestionar Estados de Productos",
  "manageStatusTransitions": "Gestionar Transiciones",
  "createStatus": "Crear Estado",
  "editStatus": "Editar Estado",
  "deleteStatus": "Eliminar Estado",
  "createTransition": "Crear Transición",
  "editTransition": "Editar Transición",
  "deleteTransition": "Eliminar Transición",
  
  "statusName": "Nombre del Estado",
  "statusDescription": "Descripción",
  "statusColor": "Color",
  "statusIcon": "Icono",
  "statusPreview": "Vista Previa",
  "statusActive": "Estado Activo",
  "statusInactive": "Estado Inactivo",
  
  "fromStatus": "Desde Estado",
  "toStatus": "Hacia Estado",
  "allowedRoles": "Roles Permitidos",
  "validationType": "Tipo de Validación",
  "validationConfig": "Configuración",
  "conditionalLogic": "Lógica Condicional",
  
  "simpleApproval": "Aprobación Simple",
  "textRequired": "Texto Obligatorio",
  "textOptional": "Texto Opcional",
  "quantityAndText": "Cantidad y Texto",
  "checklist": "Lista de Verificación",
  "photoRequired": "Foto Obligatoria",
  "multiApproval": "Aprobación Múltiple",
  
  "confirmTransition": "¿Confirmar transición?",
  "transitionFrom": "Desde",
  "transitionTo": "Hacia",
  "enterDescription": "Ingrese descripción",
  "enterQuantity": "Ingrese cantidad",
  "selectItems": "Seleccione items",
  "uploadPhotos": "Subir fotos",
  "requiresApprovals": "Requiere aprobaciones",
  
  "statusHistory": "Historial de Estados",
  "changedBy": "Cambiado por",
  "changedAt": "Fecha",
  "withValidation": "Con validación",
  "viewFullHistory": "Ver historial completo",
  
  "transitionNotAllowed": "Transición no permitida",
  "noPermissionForTransition": "No tienes permisos para esta transición",
  "validationRequired": "Se requiere validación",
  "transitionBlocked": "Transición bloqueada",
  "statusUpdatedSuccess": "Estado actualizado correctamente",
  "statusUpdateError": "Error al actualizar estado"
}
```

##### Añadir a `app_en.arb`:
```json
{
  "manageProductStatuses": "Manage Product Statuses",
  "manageStatusTransitions": "Manage Transitions",
  "createStatus": "Create Status",
  "editStatus": "Edit Status",
  "deleteStatus": "Delete Status",
  "createTransition": "Create Transition",
  "editTransition": "Edit Transition",
  "deleteTransition": "Delete Transition",
  
  "statusName": "Status Name",
  "statusDescription": "Description",
  "statusColor": "Color",
  "statusIcon": "Icon",
  "statusPreview": "Preview",
  "statusActive": "Active Status",
  "statusInactive": "Inactive Status",
  
  "fromStatus": "From Status",
  "toStatus": "To Status",
  "allowedRoles": "Allowed Roles",
  "validationType": "Validation Type",
  "validationConfig": "Configuration",
  "conditionalLogic": "Conditional Logic",
  
  "simpleApproval": "Simple Approval",
  "textRequired": "Text Required",
  "textOptional": "Optional Text",
  "quantityAndText": "Quantity and Text",
  "checklist": "Checklist",
  "photoRequired": "Photo Required",
  "multiApproval": "Multi-Approval",
  
  "confirmTransition": "Confirm transition?",
  "transitionFrom": "From",
  "transitionTo": "To",
  "enterDescription": "Enter description",
  "enterQuantity": "Enter quantity",
  "selectItems": "Select items",
  "uploadPhotos": "Upload photos",
  "requiresApprovals": "Requires approvals",
  
  "statusHistory": "Status History",
  "changedBy": "Changed by",
  "changedAt": "Date",
  "withValidation": "With validation",
  "viewFullHistory": "View full history",
  
  "transitionNotAllowed": "Transition not allowed",
  "noPermissionForTransition": "No permission for this transition",
  "validationRequired": "Validation required",
  "transitionBlocked": "Transition blocked",
  "statusUpdatedSuccess": "Status updated successfully",
  "statusUpdateError": "Error updating status"
}
```

---

## 🗄️ CAMBIOS EN BASE DE DATOS

### ✅ Ya existe (no tocar):
- `organizations/{orgId}/product_statuses`
- `organizations/{orgId}/status_transitions`

### ⚠️ Índices compuestos necesarios:

Crear en Firebase Console:

```
Collection: organizations/{orgId}/product_statuses
Fields: isActive (Ascending), order (Ascending)

Collection: organizations/{orgId}/status_transitions
Fields: fromStatusId (Ascending), isActive (Ascending)

Collection: organizations/{orgId}/production_batches/{batchId}/products
Fields: statusId (Ascending), updatedAt (Descending)
```

### 📊 Migración de datos existentes

Si ya hay productos con estados legacy (strings en lugar de IDs):

```dart
// Script de migración (ejecutar una vez)
Future<void> migrateProductStatuses(String organizationId) async {
  final batches = await _firestore
    .collection('organizations')
    .doc(organizationId)
    .collection('production_batches')
    .get();
  
  for (final batchDoc in batches.docs) {
    final products = await batchDoc.reference
      .collection('products')
      .get();
    
    final batch = _firestore.batch();
    
    for (final productDoc in products.docs) {
      final data = productDoc.data();
      final legacyStatus = data['productStatus'] as String?;
      
      // Mapear status legacy a nuevos IDs
      String? newStatusId;
      switch (legacyStatus) {
        case 'pending':
          newStatusId = 'pending';
          break;
        case 'hold':
          newStatusId = 'hold';
          break;
        case 'cao':
          newStatusId = 'cao';
          break;
        case 'control':
          newStatusId = 'control';
          break;
        case 'ok':
          newStatusId = 'ok';
          break;
        default:
          newStatusId = 'pending';
      }
      
      batch.update(productDoc.reference, {
        'statusId': newStatusId,
        'statusName': _getStatusName(newStatusId),
        // Mantener productStatus por compatibilidad
        'productStatus': legacyStatus ?? 'pending',
      });
    }
    
    await batch.commit();
  }
}
```

---

## 📦 DEPENDENCIAS ADICIONALES

Añadir a `pubspec.yaml`:

```yaml
dependencies:
  # Para selección de colores
  flutter_colorpicker: ^1.0.3
  
  # Para selección de iconos
  flutter_iconpicker: ^3.2.4
  
  # Para drag & drop en Kanban
  # (opcional si se implementa custom)
  flutter_reorderable_list: ^1.3.1
  
  # Para subir fotos
  image_picker: ^1.0.7
  
  # Para storage de fotos
  firebase_storage: ^11.6.0
  
  # Para comprimir imágenes antes de subir
  image: ^4.1.7
  flutter_image_compress: ^2.1.0
```

---

## 🧪 TESTING Y VALIDACIÓN

### Test checklist:

#### Gestión de Estados
- [ ] Crear estado personalizado
- [ ] Editar estado personalizado
- [ ] Eliminar estado (sin productos asociados)
- [ ] Intentar eliminar estado con productos (debe fallar)
- [ ] Reordenar estados (drag & drop)
- [ ] Activar/desactivar estado
- [ ] Estados del sistema no editables
- [ ] Validación de color (#RRGGBB)
- [ ] Nombres únicos

#### Gestión de Transiciones
- [ ] Crear transición simple
- [ ] Crear transición con validación de texto
- [ ] Crear transición con cantidad + texto
- [ ] Crear transición con checklist
- [ ] Crear transición con fotos
- [ ] Crear transición con multi-aprobación
- [ ] Configurar lógica condicional
- [ ] Editar transición existente
- [ ] Eliminar transición
- [ ] Validación de permisos por rol

#### Kanban
- [ ] Vista por estados funciona
- [ ] Drag & drop valida transiciones
- [ ] Diálogo correcto según tipo de validación
- [ ] Lógica condicional se evalúa
- [ ] Permisos se validan
- [ ] Contador de productos por estado
- [ ] Filtros funcionan
- [ ] Toggle entre fases y estados

#### Batch Product Detail
- [ ] Muestra estado actual con color/icono
- [ ] Botones dinámicos según transiciones disponibles
- [ ] Solo muestra transiciones permitidas
- [ ] Historial de estados visible
- [ ] Validaciones funcionan

#### Permisos
- [ ] Admin puede todo
- [ ] Manager puede crear/editar estados
- [ ] Operator solo ve transiciones permitidas
- [ ] Client no puede cambiar estados
- [ ] Firestore rules bloquean acceso no autorizado

---

## 📋 RESUMEN DE ARCHIVOS A CREAR/MODIFICAR

### ✨ Nuevos archivos (25):

#### Pantallas (6):
1. `/lib/screens/organization/manage_product_statuses_screen.dart`
2. `/lib/screens/organization/create_edit_status_dialog.dart`
3. `/lib/screens/organization/manage_status_transitions_screen.dart`
4. `/lib/screens/organization/create_edit_transition_dialog.dart`
5. `/lib/screens/organization/transition_summary_screen.dart`
6. `/lib/screens/organization/status_history_screen.dart`

#### Widgets de estados (3):
7. `/lib/widgets/status/status_preview_card.dart`
8. `/lib/widgets/status/status_list_item.dart`
9. `/lib/widgets/status/status_color_picker.dart`

#### Widgets de transiciones (4):
10. `/lib/widgets/transitions/transition_list_item.dart`
11. `/lib/widgets/transitions/validation_type_selector.dart`
12. `/lib/widgets/transitions/validation_config_form.dart`
13. `/lib/widgets/transitions/conditional_logic_builder.dart`

#### Diálogos de validación (7):
14. `/lib/widgets/transitions/validation_dialog_manager.dart`
15. `/lib/widgets/transitions/simple_approval_dialog.dart`
16. `/lib/widgets/transitions/text_validation_dialog.dart`
17. `/lib/widgets/transitions/quantity_text_dialog.dart`
18. `/lib/widgets/transitions/checklist_dialog.dart`
19. `/lib/widgets/transitions/photo_validation_dialog.dart`
20. `/lib/widgets/transitions/multi_approval_dialog.dart`

#### Widgets de Kanban (2):
21. `/lib/widgets/kanban/kanban_column_status.dart`
22. `/lib/widgets/kanban/draggable_product_card.dart`

#### Servicios (3):
23. `/lib/services/conditional_logic_evaluator.dart`
24. `/lib/services/photo_upload_service.dart`
25. `/lib/services/status_migration_service.dart`

### 🔧 Archivos a modificar (10):
1. `/lib/services/product_status_service.dart` - Añadir `canDeleteStatus()`
2. `/lib/services/status_transition_service.dart` - Añadir métodos CRUD
3. `/lib/services/production_batch_service.dart` - Mejorar validaciones
4. `/lib/widgets/kanban/kanban_board_widget.dart` - Soporte para estados
5. `/lib/screens/production/batch_product_detail_screen.dart` - Botones dinámicos
6. `/lib/screens/organization/organization_settings_screen.dart` - Añadir enlaces
7. `/lib/models/batch_product_model.dart` - Asegurar campos de estado
8. `/lib/l10n/app_es.arb` - Traducciones ES
9. `/lib/l10n/app_en.arb` - Traducciones EN
10. `/lib/utils/permission_registry_model.dart` - Nuevos permisos

---

## ⏱️ ESTIMACIÓN TOTAL

| Fase | Descripción | Días | Acumulado |
|------|-------------|------|-----------|
| 1 | Gestión de Estados (CRUD UI) | 3-4 | 4 |
| 2 | Gestión de Transiciones | 4-5 | 9 |
| 3 | Diálogos de Validación | 5-6 | 15 |
| 4 | Kanban con Estados | 6-7 | 22 |
| 5 | Modificar Detail Screen | 3-4 | 26 |
| 6 | Validaciones y Permisos | 2-3 | 29 |
| 7 | Internacionalización | 2 | 31 |
| **TESTING** | Pruebas integrales | 3-4 | **35** |

**⏱️ Total estimado: 31-35 días hábiles (6-7 semanas)**

---

## 🚀 ORDEN DE IMPLEMENTACIÓN RECOMENDADO

### Semana 1-2: Backend primero
1. Completar servicios (StatusTransitionService CRUD)
2. Añadir validaciones en ProductionBatchService
3. Testing de servicios

### Semana 3: UI de gestión
4. Pantallas de gestión de estados
5. Pantallas de gestión de transiciones
6. Testing de CRUD

### Semana 4-5: Diálogos y validaciones
7. Crear todos los diálogos de validación
8. Implementar ConditionalLogicEvaluator
9. Testing de flujos de validación

### Semana 6: Kanban
10. Modificar Kanban para estados
11. Drag & drop con validaciones
12. Testing de Kanban

### Semana 7: Finalización
13. Modificar batch_product_detail_screen
14. Internacionalización
15. Testing integral
16. Documentación

---

## 🎯 PRIORIDADES SI HAY LIMITACIONES DE TIEMPO

### Mínimo viable (2 semanas):
- ✅ Fase 1: Gestión de Estados (CRUD básico)
- ✅ Fase 3: Diálogo simple approval
- ✅ Fase 5: Botones dinámicos en detail screen
- ✅ Validaciones básicas de permisos

### Ideal (4 semanas):
- ✅ Todo lo del mínimo viable
- ✅ Fase 2: Gestión de Transiciones
- ✅ Fase 3: Todos los diálogos de validación
- ✅ Fase 6: Validaciones completas

### Completo (6-7 semanas):
- ✅ Todo incluido
- ✅ Fase 4: Kanban con estados
- ✅ Lógica condicional completa
- ✅ Testing exhaustivo
- ✅ Documentación completa

---

## 📚 NOTAS FINALES

### Buenas prácticas:
1. **Siempre validar permisos** en UI y backend
2. **Mantener compatibilidad** con datos legacy durante migración
3. **Testing progresivo** después de cada fase
4. **Commits frecuentes** con mensajes descriptivos
5. **Documentar** cambios importantes en README

### Posibles mejoras futuras:
- [ ] Exportar/importar configuración de estados entre organizaciones
- [ ] Templates de transiciones predefinidos
- [ ] Analytics de tiempo por estado
- [ ] Notificaciones automáticas en transiciones críticas
- [ ] Aprobaciones vía email/notificación push
- [ ] Firma digital en aprobaciones
- [ ] Adjuntar PDFs en transiciones
- [ ] Comentarios en cada transición

### Consideraciones de performance:
- **Índices compuestos**: Críticos para queries eficientes
- **Paginación**: En historial de estados si hay muchos registros
- **Cache**: Guardar estados/transiciones en memoria
- **Optimistic updates**: Actualizar UI antes de confirmar en backend

---

## ✅ CHECKLIST FINAL

Antes de considerar completa la implementación:

- [ ] Todos los servicios tienen manejo de errores
- [ ] Todos los diálogos validan entrada del usuario
- [ ] Permisos validados en UI y backend
- [ ] Firestore rules actualizadas
- [ ] Índices compuestos creados
- [ ] Traducciones en ES e EN completas
- [ ] Migración de datos legacy probada
- [ ] Testing manual de todos los flujos
- [ ] Documentación actualizada
- [ ] README con instrucciones de uso
- [ ] No hay console.log/debugPrint innecesarios
- [ ] Código formateado con `flutter format`
- [ ] Sin warnings en compilación
- [ ] Performance aceptable en dispositivos low-end

---

**🎉 ¡Fin del Roadmap!**

Este roadmap cubre la implementación completa del sistema de gestión de estados de productos de lote, desde el CRUD básico hasta la integración avanzada en el Kanban con validaciones y lógica condicional.
