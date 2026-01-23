# 📁 Lista de Archivos del Proyecto - Production Tracker

## 📂 l10n/ (Internacionalización)
- **app_en.arb** - Traducciones en inglés
- **app_es.arb** - Traducciones en español
- **app_localizations_en.dart** - Localizaciones generadas inglés
- **app_localizations_es.dart** - Localizaciones generadas español
- **app_localizations.dart** - Clase base de localizaciones

---

## 📂 models/ (Modelos de datos)
- **batch_product_model.dart** - Producto dentro de un lote de producción
- **client_model.dart** - Clientes de la organización
- **message_model.dart** - Mensajes del chat/comunicación
- **organization_member_model.dart** - Miembros de la organización con roles
- **organization_model.dart** - Organizaciones/empresas
- **organization_settings_model.dart** - Configuración de organización (tema, logo)
- **permission_model.dart** - Permisos del sistema RBAC
- **permission_override_model.dart** - Sobreescrituras de permisos por usuario
- **permission_registry_model.dart** - Registro histórico de cambios de permisos
- **phase_model.dart** - Fases de producción (Corte, Skiving, etc.)
- **product_catalog_model.dart** - Catálogo de productos
- **product_status_model.dart** - Estados de calidad de productos
- **production_batch_model.dart** - Lotes de producción
- **project_model.dart** - Proyectos
- **release_note_model.dart** - Notas de versión/releases
- **role_model.dart** - Roles del sistema (Admin, Manager, etc.)
- **sla_alert_model.dart** - Alertas de SLA/plazos
- **status_transition_model.dart** - Transiciones de estados permitidas
- **user_model.dart** - Usuarios del sistema
- **validation_config_model.dart** - Configuraciones de validación

---

## 📂 providers/ (Gestores de estado)
- **locale_provider.dart** - Gestión del idioma de la app
- **theme_provider.dart** - Gestión del tema (claro/oscuro)

---

## 📂 screens/ (Pantallas de la aplicación)

### 📂 auth/ (Autenticación)
- **login_screen.dart** - Pantalla de inicio de sesión
- **password_reset_screen.dart** - Recuperación de contraseña
- **register_screen.dart** - Registro de nuevos usuarios

### 📂 catalog/ (Catálogo de productos)
- **create_product_catalog_screen.dart** - Crear producto en catálogo
- **edit_product_catalog_screen.dart** - Editar producto del catálogo
- **product_catalog_detail_screen.dart** - Detalle de producto del catálogo
- **product_catalog_screen.dart** - Lista de productos del catálogo

### 📂 chat/ (Mensajería)
- **chat_screen.dart** - Pantalla de chat/mensajes

### 📂 clients/ (Gestión de clientes)
- **client_detail_screen.dart** - Detalle de un cliente
- **create_client_screen.dart** - Crear nuevo cliente
- **edit_client_screen.dart** - Editar cliente existente

### 📂 dashboard/
- **metrics_dashboard_screen.dart** - Dashboard con métricas y KPIs

### 📂 management/ (Gestión)
- **management_folders_view.dart** - Vista de carpetas de gestión
- **management_screen.dart** - Pantalla principal de gestión

### 📂 organization/ (Organización)
- **assign_phases_screen.dart** - Asignar fases a productos
- **create_organization_screen.dart** - Crear nueva organización
- **invite_member_screen.dart** - Invitar miembros a organización
- **join_organization_screen.dart** - Unirse a organización
- **manage_phases_screen.dart** - Gestionar fases de producción
- **member_permissions_screen.dart** - Permisos de miembros
- **organization_detail_screen.dart** - Detalle de organización
- **organization_home_screen.dart** - Home de organización
- **organization_members_screen.dart** - Lista de miembros
- **organization_settings_screen.dart** - Configuración de organización
- **pending_invitations_screen.dart** - Invitaciones pendientes

### 📂 phases/ (Fases)
- **manage_phases_screen.dart** - Gestionar fases de producción
- **phase_editor_screen.dart** - Editor de fases

### 📂 production/ (Producción)
- **add_product_to_batch_screen.dart** - Añadir producto a lote
- **batch_product_detail_screen.dart** - Detalle de producto en lote
- **create_production_batch_screen.dart** - Crear lote de producción
- **production_batch_detail_screen.dart** - Detalle de lote de producción
- **production_screen.dart** - Pantalla principal de producción (con vistas: lotes, productos, kanban)

### 📂 profile/ (Perfil de usuario)
- **change_password_screen.dart** - Cambiar contraseña
- **edit_profile_screen.dart** - Editar perfil de usuario
- **profile_screen.dart** - Ver perfil de usuario
- **user_preferences_screen.dart** - Preferencias de usuario

### 📂 projects/ (Proyectos)
- **create_project_screen.dart** - Crear nuevo proyecto
- **edit_project_screen.dart** - Editar proyecto existente
- **project_detail_screen.dart** - Detalle de proyecto (con tabs: detalles, productos)

- **home_screen.dart** - Pantalla home principal
---

## 📂 services/ (Lógica de negocio)
- **analytics_service.dart** - Servicio de analytics y métricas
- **auth_service.dart** - Autenticación de usuarios
- **client_service.dart** - Gestión de clientes
- **kanban_service.dart** - Lógica del tablero Kanban
- **message_service.dart** - Mensajería y chat
- **organization_member_service.dart** - Gestión de miembros de organización
- **organization_service.dart** - Gestión de organizaciones
- **organization_settings_service.dart** - Configuración de organización
- **permission_service.dart** - Sistema de permisos RBAC
- **phase_service.dart** - Gestión de fases de producción
- **product_catalog_service.dart** - Catálogo de productos
- **product_status_service.dart** - Estados de productos
- **production_batch_service.dart** - Lotes de producción
- **project_service.dart** - Gestión de proyectos
- **role_service.dart** - Gestión de roles
- **sla_service.dart** - Gestión de SLAs y alertas
- **status_transition_service.dart** - Transiciones de estados
- **update_service.dart** - Servicio de actualizaciones
- **user_preferences_service.dart** - Preferencias de usuario

---

## 📂 utils/ (Utilidades)
- **filter_utils.dart** - Widgets y utilidades para filtros reutilizables
- **management_view_types.dart** - Tipos de vistas de gestión
- **message_events_helper.dart** - Helper para eventos de mensajes
- **permission_utils.dart** - Utilidades para permisos
- **phase_utils.dart** - Utilidades para fases
- **role_utils.dart** - Utilidades para roles

---

## 📂 widgets/ (Widgets reutilizables)

### 📂 analytics/
- **kpi_card.dart** - Tarjeta de KPI para dashboard

### 📂 chat/
- **chat_button.dart** - Botón flotante de chat
- **message_bubble_widget.dart** - Burbuja de mensaje
- **message_input_widget.dart** - Input para escribir mensajes
- **message_search_delegate.dart** - Búsqueda de mensajes

### 📂 kanban/
- **draggable_product_card.dart** - Tarjeta arrastrable para Kanban
- **kanban_board_widget.dart** - Tablero Kanban completo

### 📂 management/
- **client_folder_card.dart** - Card de carpeta de cliente
- **product_family_folder_card.dart** - Card de familia de productos
- **project_folder_card.dart** - Card de carpeta de proyecto

### 📂 sla/
- **sla_alert_badge.dart** - Badge de alerta SLA
- **sla_alerts_panel.dart** - Panel de alertas SLA
- **sla_status_indicator.dart** - Indicador de estado SLA

### 📂 Otros widgets/
- **access_control_widget.dart** - Control de acceso a proyectos/lotes
- **batch_card_widget.dart** - Card de lote de producción
- **bottom_nav_bar_widget.dart** - Barra de navegación inferior
- **common_refresh.dart** - Widget de refresh común
- **production_dashboard_widget.dart** - Dashboard de producción (home)
- **universal_loading_screen.dart** - Pantalla de carga universal
- **welcome_message_widget.dart** - Mensaje de bienvenida
- **whats_new_dialog.dart** - Diálogo "Qué hay de nuevo"

---

## 📂 Raíz del proyecto
- **firebase_options.dart** - Configuración de Firebase
- **main.dart** - Punto de entrada de la aplicación

---

## 📊 Resumen
- **Total de archivos**: ~120+ archivos
- **Modelos**: ~20 archivos
- **Pantallas**: ~40 pantallas organizadas en 10 módulos
- **Servicios**: ~20 servicios
- **Widgets reutilizables**: ~25 widgets
- **Utilidades**: 6 archivos de utilidades
- **Idiomas soportados**: Español e Inglés

---

## 🏗️ Arquitectura
La aplicación sigue una arquitectura limpia con separación clara de responsabilidades:
- **Models**: Representación de datos
- **Services**: Lógica de negocio y comunicación con Firebase
- **Screens**: Interfaz de usuario (pantallas)
- **Widgets**: Componentes UI reutilizables
- **Utils**: Funciones y utilidades auxiliares
- **Providers**: Gestión de estado (idioma, tema)

## 🔥 Tecnologías
- **Flutter**: Framework principal
- **Firebase**: Backend (Firestore, Auth, Storage)
- **Provider**: Gestión de estado
- **Material Design**: Sistema de diseño
