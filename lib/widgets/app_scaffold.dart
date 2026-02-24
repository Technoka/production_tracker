// lib/widgets/app_scaffold.dart
//
// =============================================================================
// APP SCAFFOLD — Widget envolvente centralizado para todas las pantallas
//               principales de la app.
//
// Gestiona automáticamente:
//   • Drawer fijo a la izquierda en desktop (>= DESKTOP_MIN_SCREEN_WIDTH)
//   • Drawer flotante (hamburger) en móvil / pantallas pequeñas
//   • BottomNavigationBar solo en móvil
//   • AppBar con logo/nombre de organización y badge de notificaciones
//
// USO BÁSICO:
//   return AppScaffold(
//     currentIndex: AppNavIndex.production,   // ← qué pestaña está activa
//     title: l10n.production,                 // ← título de la pantalla (AppBar)
//     body: MiContenido(),
//   );
//
// OPCIONES AVANZADAS:
//   • floatingActionButton  → FAB propio de la pantalla
//   • actions               → Iconos adicionales en el AppBar
//   • showAppBar            → Mostrar el AppBar (por defecto true)
//   • showOrgTitleInAppBar  → Mostrar logo+nombre org en AppBar (por defecto true)
//   • resizeToAvoidBottomInset → para pantallas con teclado
//
// AÑADIR UNA NUEVA SECCIÓN AL MENÚ:
//   1. Añade un valor a `AppNavIndex`.
//   2. Añade la entrada en `_AppDrawerContent._buildItems()`.
//   3. Añade el BottomNavigationBarItem en `_AppBottomNavBar._buildItems()`.
//   4. Actualiza `_AppBottomNavBar._navigate()` con la nueva ruta.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/user_model.dart';
import '../providers/initialization_provider.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../utils/ui_constants.dart';
import '../widgets/notification_badge.dart';

// Screens — importadas para la navegación
import '../screens/home_screen.dart';
import '../screens/production/production_screen.dart';
import '../screens/management/management_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/organization/organization_home_screen.dart';

// =============================================================================
// ENUM: Índice de pantalla activa
// =============================================================================

/// Identifica la sección activa de la app.
/// Úsalo en `AppScaffold(currentIndex: AppNavIndex.xxx)`.
enum AppNavIndex {
  home, // 0
  production, // 1
  management, // 2
  profile, // 3
  organization, // 4 — visible en drawer pero no en bottom nav
}

// =============================================================================
// APP SCAFFOLD
// =============================================================================

class AppScaffold extends StatelessWidget {
  /// Sección activa (resalta el ítem correcto en drawer y bottom nav).
  final AppNavIndex currentIndex;

  /// Título de la pantalla mostrado en el AppBar cuando no hay logo de org.
  final String title;

  /// Contenido principal de la pantalla.
  final Widget body;

  /// FAB opcional — se pasa directamente al Scaffold subyacente.
  final Widget? floatingActionButton;

  /// Acciones adicionales en el AppBar (además del NotificationBadge).
  final List<Widget>? actions;

  /// Mostrar AppBar. Por defecto true.
  final bool showAppBar;

  /// Mostrar logo y nombre de organización en el AppBar. Por defecto true.
  final bool showOrgTitleInAppBar;

  /// Forwarded al Scaffold para pantallas con teclado. Por defecto true.
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.showAppBar = true,
    this.showOrgTitleInAppBar = true,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >=
        UIConstants.DESKTOP_MIN_SCREEN_WIDTH;
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: showAppBar ? _buildAppBar(context, isDesktop) : null,

      // ── Body ────────────────────────────────────────────────────────────────
      // En desktop: Row con drawer fijo + contenido.
      // En móvil:   solo el contenido (el drawer se abre con el botón de AppBar).
      body: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drawer fijo
                Container(
                  width: UIConstants.SIDE_DRAWER_WIDTH,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: _AppDrawerContent(
                    currentIndex: currentIndex,
                    isDesktop: true,
                  ),
                ),
                // Contenido
                Expanded(child: body),
              ],
            )
          : body,

      // ── Drawer flotante (solo móvil) ─────────────────────────────────────
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: _AppDrawerContent(
                currentIndex: currentIndex,
                isDesktop: false,
              ),
            ),

      // ── Bottom Nav Bar (solo móvil) ──────────────────────────────────────
      bottomNavigationBar: isDesktop
          ? null
          : (user != null
              ? _AppBottomNavBar(currentIndex: currentIndex, user: user)
              : null),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButton: floatingActionButton,
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDesktop) {
    final initProvider = Provider.of<InitializationProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    Widget titleWidget;

    if (showOrgTitleInAppBar && initProvider.cachedOrgName != null) {
      titleWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (initProvider.cachedOrgLogoUrl != null) ...[
            Container(
              constraints: const BoxConstraints(maxWidth: 120),
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: kToolbarHeight - 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  initProvider.cachedOrgLogoUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              initProvider.cachedOrgName!,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      titleWidget = Text(title.isNotEmpty ? title : l10n.appTitle);
    }

    return AppBar(
      title: titleWidget,
      // En desktop el drawer está fijo, no hay hamburger; en móvil sí.
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: !isDesktop,
      actions: [
        ...?actions,
        const NotificationBadge(),
        const SizedBox(width: 20)
      ],
    );
  }
}

// =============================================================================
// _APP DRAWER CONTENT — contenido del drawer (compartido entre fijo y flotante)
// =============================================================================

class _AppDrawerContent extends StatelessWidget {
  final AppNavIndex currentIndex;
  final bool isDesktop;

  const _AppDrawerContent({
    required this.currentIndex,
    required this.isDesktop,
  });

  /// Cierra el drawer flotante de móvil.
  /// En desktop no hace nada porque el drawer forma parte del body.
  void _closeDrawer(BuildContext context) {
    if (!isDesktop) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final permissionService = Provider.of<PermissionService>(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    final canAccessProduction =
        permissionService.canViewKanban || permissionService.canViewBatches;
    final canAccessManagement = permissionService.canViewProjects ||
        permissionService.canViewClients ||
        permissionService.canViewCatalog;
    final canViewReports = permissionService.canViewReports;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 15),

                // ── Home ──────────────────────────────────────────────────
                _DrawerItem(
                  icon: Icons.home,
                  label: l10n.home,
                  isSelected: currentIndex == AppNavIndex.home,
                  primaryColor: primaryColor,
                  onTap: () {
                    _closeDrawer(context);
                    if (currentIndex != AppNavIndex.home) {
                      Navigator.pushReplacement(
                        context,
                        _fadeRoute(const HomeScreen()),
                      );
                    }
                  },
                ),

                // ── Producción ────────────────────────────────────────────
                if (canAccessProduction)
                  _DrawerItem(
                    icon: Icons.precision_manufacturing,
                    label: l10n.production,
                    isSelected: currentIndex == AppNavIndex.production,
                    primaryColor: primaryColor,
                    onTap: () {
                      _closeDrawer(context);
                      if (currentIndex != AppNavIndex.production) {
                        Navigator.pushReplacement(
                          context,
                          _fadeRoute(const ProductionScreen()),
                        );
                      }
                    },
                  ),

                // ── Gestión ───────────────────────────────────────────────
                if (canAccessManagement)
                  _DrawerItem(
                    icon: Icons.manage_accounts,
                    label: l10n.management,
                    isSelected: currentIndex == AppNavIndex.management,
                    primaryColor: primaryColor,
                    onTap: () {
                      _closeDrawer(context);
                      if (currentIndex != AppNavIndex.management) {
                        Navigator.pushReplacement(
                          context,
                          _fadeRoute(const ManagementScreen()),
                        );
                      }
                    },
                  ),

                // ── Organización ──────────────────────────────────────────
                if (canViewReports)
                  _DrawerItem(
                    icon: Icons.business,
                    label: l10n.organization,
                    isSelected: currentIndex == AppNavIndex.organization,
                    primaryColor: primaryColor,
                    onTap: () {
                      _closeDrawer(context);
                      if (currentIndex != AppNavIndex.organization) {
                        Navigator.push(
                          context,
                          _fadeRoute(const OrganizationHomeScreen()),
                        );
                      }
                    },
                  ),

                const Divider(),

                // ── Perfil ────────────────────────────────────────────────
                _DrawerItem(
                  icon: Icons.person,
                  label: l10n.profile,
                  isSelected: currentIndex == AppNavIndex.profile,
                  primaryColor: primaryColor,
                  onTap: () {
                    _closeDrawer(context);
                    if (currentIndex != AppNavIndex.profile) {
                      Navigator.push(
                        context,
                        _fadeRoute(const ProfileScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // ── Versión ────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 10),
            child: Center(
              child: Text(
                'Version 0.10.0 - 23/2/25 - Alpha Test',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _DRAWER ITEM — ListTile reutilizable para el drawer
// =============================================================================

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: primaryColor, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      selected: isSelected,
      selectedColor: primaryColor,
      selectedTileColor: primaryColor.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}

// =============================================================================
// _APP BOTTOM NAV BAR — solo visible en móvil
// =============================================================================

class _AppBottomNavBar extends StatelessWidget {
  final AppNavIndex currentIndex;
  final UserModel user;

  const _AppBottomNavBar({
    required this.currentIndex,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final permissionService = Provider.of<PermissionService>(context);

    final canAccessProduction =
        permissionService.canViewKanban || permissionService.canViewBatches;
    final canAccessManagement = permissionService.canViewProjects ||
        permissionService.canViewClients ||
        permissionService.canViewCatalog;

    // Construir ítems y mapa de índice → AppNavIndex en paralelo
    final items = <BottomNavigationBarItem>[];
    final indexMap = <int, AppNavIndex>{};

    // Home — siempre visible
    indexMap[items.length] = AppNavIndex.home;
    items.add(BottomNavigationBarItem(
      icon: const Icon(Icons.home),
      label: l10n.home,
    ));

    if (canAccessProduction) {
      indexMap[items.length] = AppNavIndex.production;
      items.add(BottomNavigationBarItem(
        icon: const Icon(Icons.precision_manufacturing),
        label: l10n.production,
      ));
    }

    if (canAccessManagement) {
      indexMap[items.length] = AppNavIndex.management;
      items.add(BottomNavigationBarItem(
        icon: const Icon(Icons.manage_accounts),
        label: l10n.management,
      ));
    }

    // Perfil — siempre visible
    indexMap[items.length] = AppNavIndex.profile;
    items.add(BottomNavigationBarItem(
      icon: const Icon(Icons.person),
      label: l10n.profile,
    ));

    // No mostrar si hay menos de 3 ítems
    if (items.length < 3) return const SizedBox.shrink();

    // Calcular el índice numérico correspondiente al AppNavIndex activo
    final activeNumericIndex = indexMap.entries
        .firstWhere(
          (e) => e.value == currentIndex,
          orElse: () => const MapEntry(0, AppNavIndex.home),
        )
        .key;

    return BottomNavigationBar(
      currentIndex: activeNumericIndex.clamp(0, items.length - 1),
      onTap: (i) => _navigate(context, indexMap[i] ?? AppNavIndex.home),
      items: items,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 11,
    );
  }

  void _navigate(BuildContext context, AppNavIndex target) {
    if (target == currentIndex) return;

    Widget destination;
    switch (target) {
      case AppNavIndex.home:
        destination = const HomeScreen();
        break;
      case AppNavIndex.production:
        destination = const ProductionScreen();
        break;
      case AppNavIndex.management:
        destination = const ManagementScreen();
        break;
      case AppNavIndex.profile:
        destination = const ProfileScreen();
        break;
      case AppNavIndex.organization:
        destination = const OrganizationHomeScreen();
        break;
    }

    Navigator.pushReplacement(context, _fadeRoute(destination));
  }
}

// =============================================================================
// HELPER — transición de fade entre pantallas principales
// =============================================================================

PageRouteBuilder<T> _fadeRoute<T>(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 200),
  );
}
