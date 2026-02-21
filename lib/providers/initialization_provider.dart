import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_produccion/models/user_model.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../services/organization_member_service.dart';
import '../services/organization_service.dart';
import '../services/organization_settings_service.dart';
import '../services/production_batch_service.dart';
import '../services/phase_service.dart';
import '../services/product_status_service.dart';
import '../services/client_service.dart';
import '../services/product_catalog_service.dart';
import '../services/project_service.dart';
import '../providers/production_data_provider.dart';

class InitializationProvider extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isInitializing = false;

  String? _cachedRoleName;
  String? _cachedOrgName;
  String? _cachedOrgLogoUrl;

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;

  String? get cachedRoleName => _cachedRoleName;
  String? get cachedOrgName => _cachedOrgName;
  String? get cachedOrgLogoUrl => _cachedOrgLogoUrl;

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    notifyListeners();

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // ── CAMBIO: si currentUserData es null pero hay un usuario autenticado,
      // esperarlo antes de continuar (caso web al recargar)
      UserModel? user = authService.currentUserData;
      if (user == null && authService.currentUser != null) {
        user = await authService.getUserData(); // carga desde Firestore
      }

      if (user == null || user.organizationId == null) {
        _isInitializing = false;
        notifyListeners();
        return;
      }

      // Cargar permisos
      final permissionService =
          Provider.of<PermissionService>(context, listen: false);
      await permissionService.loadCurrentUserPermissions(
        userId: user.uid,
        organizationId: user.organizationId!,
      );

      // Cargar datos del miembro (rol)
      final memberService =
          Provider.of<OrganizationMemberService>(context, listen: false);
      final memberData = await memberService.getCurrentMember(
        user.organizationId!,
        user.uid,
      );
      _cachedRoleName = memberData?.member.roleName ?? 'User?';

      // Cargar datos de la organización (nombre y logo)
      final organizationService =
          Provider.of<OrganizationService>(context, listen: false);
      final settingsService =
          Provider.of<OrganizationSettingsService>(context, listen: false);

      final orgData =
          await organizationService.getOrganization(user.organizationId!);
      final orgSettings =
          await settingsService.getOrganizationSettings(user.organizationId!);

      _cachedOrgName = orgData?.name;
      _cachedOrgLogoUrl = orgSettings?.branding.logoUrl;

      // print(
      //     '👤 Loading permissions for: ${FirebaseAuth.instance.currentUser?.uid ?? "NULL"}');
      // print('⏱️ Timestamp: ${DateTime.now().millisecondsSinceEpoch}');

      // Inicializar ProductionDataProvider
      final productionDataProvider =
          Provider.of<ProductionDataProvider>(context, listen: false);
      await productionDataProvider.initialize(
        organizationId: user.organizationId!,
        userId: user.uid,
        batchService:
            Provider.of<ProductionBatchService>(context, listen: false),
        phaseService: Provider.of<PhaseService>(context, listen: false),
        statusService:
            Provider.of<ProductStatusService>(context, listen: false),
        clientService: Provider.of<ClientService>(context, listen: false),
        catalogService:
            Provider.of<ProductCatalogService>(context, listen: false),
        projectService: Provider.of<ProjectService>(context, listen: false),
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Error during initialization: $e');
      _isInitialized = true; // Marcar como inicializado aunque falle
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> refresh(BuildContext context) async {
    // Para el pull-to-refresh, solo recargar datos, no el cache de UI
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUserData;

      if (user == null || user.organizationId == null) return;

      final permissionService =
          Provider.of<PermissionService>(context, listen: false);
      await permissionService.loadCurrentUserPermissions(
        userId: user.uid,
        organizationId: user.organizationId!,
      );

      final productionDataProvider =
          Provider.of<ProductionDataProvider>(context, listen: false);
      await productionDataProvider.initialize(
        organizationId: user.organizationId!,
        userId: user.uid,
        batchService:
            Provider.of<ProductionBatchService>(context, listen: false),
        phaseService: Provider.of<PhaseService>(context, listen: false),
        statusService:
            Provider.of<ProductStatusService>(context, listen: false),
        clientService: Provider.of<ClientService>(context, listen: false),
        catalogService:
            Provider.of<ProductCatalogService>(context, listen: false),
        projectService: Provider.of<ProjectService>(context, listen: false),
      );
    } catch (e) {
      debugPrint('❌ Error during refresh: $e');
    }
  }

  void reset() {
    _isInitialized = false;
    _isInitializing = false;
    _cachedRoleName = null;
    _cachedOrgName = null;
    _cachedOrgLogoUrl = null;
    notifyListeners();
  }
}
