// lib/widgets/access_control_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/organization_member_model.dart';
import '../models/role_model.dart';
import '../models/permission_model.dart';
import '../services/organization_service.dart';
import '../services/permission_service.dart';
import '../l10n/app_localizations.dart';

class AccessControlWidget extends StatefulWidget {
  final String organizationId;
  final String currentUserId;
  final List<String> selectedMembers;
  final Function(List<String>) onMembersChanged;
  final bool readOnly;
  final bool showTitle;
  final String? customTitle;
  final String? customDescription;
  final String resourceType;
  final String? clientId; // Para filtrar miembros del cliente

  const AccessControlWidget({
    super.key,
    required this.organizationId,
    required this.currentUserId,
    required this.selectedMembers,
    required this.onMembersChanged,
    this.readOnly = false,
    this.showTitle = true,
    this.customTitle,
    this.customDescription,
    this.resourceType = 'project',
    this.clientId,
  });

  @override
  State<AccessControlWidget> createState() => _AccessControlWidgetState();
}

class _AccessControlWidgetState extends State<AccessControlWidget> {
  late ValueNotifier<List<String>> _selectedMembersNotifier;

  // Cache para evitar parpadeo
  List<OrganizationMemberWithUser>? _cachedAutoAccessMembers;
  List<OrganizationMemberWithUser>? _cachedSelectableMembers;
  bool _isLoadingCache = true;

  // Control de expansión
  bool _isAutoAccessExpanded = false;

  // Búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedMembersNotifier = ValueNotifier(List.from(widget.selectedMembers));
    _loadMembersCache();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectedMembersNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AccessControlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMembers != widget.selectedMembers) {
      _selectedMembersNotifier.value = List.from(widget.selectedMembers);
    }
  }

  Future<void> _loadMembersCache() async {
    if (!mounted) return;

    try {
      final permissionService =
          Provider.of<PermissionService>(context, listen: false);

      // Cargar en paralelo
      final results = await Future.wait([
        _getMembersWithAutoAccess(permissionService),
        _getSelectableMembers(permissionService),
      ]);

      if (mounted) {
        setState(() {
          _cachedAutoAccessMembers = results[0];
          _cachedSelectableMembers = results[1];
          _isLoadingCache = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading members cache: $e');
      if (mounted) {
        setState(() => _isLoadingCache = false);
      }
    }
  }

  void _toggleMember(String memberId) {
    if (widget.readOnly) return;

    // 1. Obtenemos la lista actual
    final currentList = List<String>.from(_selectedMembersNotifier.value);

    // 2. Modificamos la copia
    if (currentList.contains(memberId)) {
      currentList.remove(memberId);
    } else {
      currentList.add(memberId);
    }

    // 3. Actualizamos el notificador (esto solo reconstruirá los widgets que escuchen)
    _selectedMembersNotifier.value = currentList;

    // 4. Notificamos al padre
    widget.onMembersChanged(currentList);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoadingCache) {
      return _buildLoadingSkeleton();
    }

    final autoAccessMembers = _cachedAutoAccessMembers ?? [];
    final selectableMembers = _cachedSelectableMembers ?? [];

    // Filtrar por búsqueda
    final filteredMembers = _searchQuery.isEmpty
        ? selectableMembers
        : selectableMembers.where((member) {
            final query = _searchQuery.toLowerCase();
            return member.userName.toLowerCase().contains(query) ||
                member.userEmail.toLowerCase().contains(query) ||
                member.roleName.toLowerCase().contains(query);
          }).toList();

    // Contar miembros por tipo
    final generalAccessCount =
        autoAccessMembers.where((m) => m.member.clientId == null).length;
    final clientAccessCount = autoAccessMembers
        .where((m) => m.member.clientId == widget.clientId)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security_outlined,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customTitle ?? l10n.accessControl,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.customDescription ?? l10n.accessControlDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Sección de Acceso Automático (colapsable)
        if (autoAccessMembers.isNotEmpty) ...[
          _buildAutoAccessCard(
            context,
            l10n,
            autoAccessMembers,
            generalAccessCount,
            clientAccessCount,
          ),
          const SizedBox(height: 16),
        ],

        // Sección de Asignar Miembros
        if (!widget.readOnly)
          _buildAssignMembersCard(
            context,
            l10n,
            filteredMembers,
          ),
      ],
    );
  }

  Widget _buildAutoAccessCard(
    BuildContext context,
    AppLocalizations l10n,
    List<OrganizationMemberWithUser> autoAccessMembers,
    int generalCount,
    int clientCount,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isAutoAccessExpanded = !_isAutoAccessExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'ACCESO AUTOMÁTICO: ${autoAccessMembers.length} miembros',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Estos miembros tienen acceso por:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (generalCount > 0)
                                Text(
                                  '• Permisos generales ($generalCount)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              if (clientCount > 0)
                                Text(
                                  '• Pertenencia al cliente ($clientCount)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isAutoAccessExpanded = !_isAutoAccessExpanded;
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isAutoAccessExpanded
                                    ? 'Ocultar detalles'
                                    : 'Ver detalles',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isAutoAccessExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 16,
                                color: Colors.blue.shade800,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido expandible
          if (_isAutoAccessExpanded) ...[
            Divider(height: 1, color: Colors.blue.shade200),
            _buildAutoAccessDetails(context, autoAccessMembers),
          ],
        ],
      ),
    );
  }

  Widget _buildAutoAccessDetails(
    BuildContext context,
    List<OrganizationMemberWithUser> members,
  ) {
    final generalMembers =
        members.where((m) => m.member.clientId == null).toList();
    final clientMembers =
        members.where((m) => m.member.clientId == widget.clientId).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (generalMembers.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Por Permisos Generales',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...generalMembers.map((member) => _buildMemberTile(member, true)),
            const SizedBox(height: 16),
          ],
          if (clientMembers.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Del Cliente',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...clientMembers.map((member) => _buildMemberTile(member, true)),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignMembersCard(
    BuildContext context,
    AppLocalizations l10n,
    List<OrganizationMemberWithUser> selectableMembers,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_add,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ASIGNAR MIEMBROS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ValueListenableBuilder<List<String>>(
                  valueListenable: _selectedMembersNotifier,
                  builder: (context, selectedList, _) {
                    // CAMBIAR: Contar solo los seleccionados que están en selectableMembers
                    final selectableMemberIds =
                        selectableMembers.map((m) => m.userId).toSet();
                    final validSelectedCount = selectedList
                        .where((id) => selectableMemberIds.contains(id))
                        .length;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: validSelectedCount > 0
                            ? Colors.green.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            validSelectedCount > 0
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 12,
                            color: validSelectedCount > 0
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$validSelectedCount / ${selectableMembers.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: validSelectedCount > 0
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Buscador
          if (selectableMembers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar miembro...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade400),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

          // Lista de miembros
          if (selectableMembers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${l10n.allMembersHaveAutoAccess}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (selectableMembers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${selectableMembers.length} disponibles para asignar',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...selectableMembers
                .map((member) => _buildMemberTile(member, false)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberTile(
      OrganizationMemberWithUser member, bool isAutoAccess) {
    final isMe = member.userId == widget.currentUserId;
    return ValueListenableBuilder<List<String>>(
        valueListenable: _selectedMembersNotifier,
        builder: (context, selectedList, child) {
          // Calculamos isSelected dentro del builder
          final isSelected = selectedList.contains(member.userId);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isAutoAccess || widget.readOnly
                  ? null
                  : () => _toggleMember(member.userId),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected && !isAutoAccess
                      ? Colors.green.shade50
                      : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (!isAutoAccess)
                      Checkbox(
                        value: isSelected,
                        onChanged: widget.readOnly
                            ? null
                            : (value) => _toggleMember(member.userId),
                        activeColor: Colors.green,
                      ),

                    // Avatar
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          _parseColor(member.roleColor).withOpacity(0.2),
                      backgroundImage: member.userPhotoUrl != null
                          ? NetworkImage(member.userPhotoUrl!)
                          : null,
                      child: member.userPhotoUrl == null
                          ? Text(
                              member.userName.isNotEmpty
                                  ? member.userName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _parseColor(member.roleColor),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  member.userName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Tú',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.userEmail,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Badge de rol con color
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _parseColor(member.roleColor).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _parseColor(member.roleColor).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _parseColor(member.roleColor),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            member.roleName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _parseColor(member.roleColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  // ==================== MÉTODOS DE OBTENCIÓN DE DATOS ====================

  Future<List<OrganizationMemberWithUser>> _getMembersWithAutoAccess(
    PermissionService permissionService,
  ) async {
    try {
      final organizationService =
          Provider.of<OrganizationService>(context, listen: false);

      final org =
          await organizationService.getOrganization(widget.organizationId);
      if (org == null) return [];

      final membersWithRoles = await _getOrganizationMembersWithRoles(context);
      final autoAccessMembers = <OrganizationMemberWithUser>[];

      for (final memberWithRole in membersWithRoles) {
        // Owner siempre tiene acceso
        if (memberWithRole.userId == org.ownerId) {
          autoAccessMembers.add(memberWithRole);
          continue;
        }

        // Miembros del mismo cliente
        if (widget.clientId != null &&
            memberWithRole.member.clientId == widget.clientId) {
          autoAccessMembers.add(memberWithRole);
          continue;
        }

        // Verificar permisos del rol
        final roleDoc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(widget.organizationId)
            .collection('roles')
            .doc(memberWithRole.member.roleId)
            .get();

        if (!roleDoc.exists) continue;

        final role = RoleModel.fromMap(roleDoc.data()!, docId: roleDoc.id);
        final permissions = memberWithRole.member.getEffectivePermissions(role);

        // Admin o con scope all en projects
        if (memberWithRole.member.roleId == 'admin' ||
            permissions.viewProjectsScope == PermissionScope.all) {
          autoAccessMembers.add(memberWithRole);
        }
      }

      return autoAccessMembers;
    } catch (e) {
      debugPrint('Error getting auto-access members: $e');
      return [];
    }
  }

  Future<List<OrganizationMemberWithUser>> _getSelectableMembers(
    PermissionService permissionService,
  ) async {
    try {
      final allMembers = await _getOrganizationMembersWithRoles(context);
      final autoAccessMembers =
          await _getMembersWithAutoAccess(permissionService);

      // Filtrar: solo los que NO tienen acceso automático Y NO son clientes de otros clientes
      final selectableMembers = allMembers.where((member) {
        // Excluir si tiene acceso automático
        if (autoAccessMembers.any((auto) => auto.userId == member.userId)) {
          return false;
        }

        // AGREGAR: Excluir si es un cliente de otro cliente
        // (solo incluir si no tiene clientId o si es del mismo cliente)
        if (member.member.clientId != null &&
            member.member.clientId != widget.clientId) {
          return false;
        }

        return true;
      }).toList();

      return selectableMembers;
    } catch (e) {
      debugPrint('Error getting selectable members: $e');
      return [];
    }
  }

  Future<List<OrganizationMemberWithUser>> _getOrganizationMembersWithRoles(
    BuildContext context,
  ) async {
    try {
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('members')
          .where('isActive', isEqualTo: true)
          .get();

      final membersWithRoles = <OrganizationMemberWithUser>[];

      for (final memberDoc in membersSnapshot.docs) {
        try {
          final member = OrganizationMemberModel.fromMap(
            memberDoc.data(),
            docId: memberDoc.id,
          );

          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(member.userId)
              .get();

          if (!userDoc.exists) continue;

          final user = UserModel.fromMap(userDoc.data()!);

          membersWithRoles.add(OrganizationMemberWithUser(
            member: member,
            userName: user.name,
            userEmail: user.email,
            userPhotoUrl: user.photoURL,
          ));
        } catch (e) {
          debugPrint('Error loading member: $e');
          continue;
        }
      }

      return membersWithRoles;
    } catch (e) {
      debugPrint('Error getting organization members: $e');
      return [];
    }
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.grey;
    }

    try {
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
