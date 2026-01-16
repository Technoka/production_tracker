// lib/widgets/project_access_control_widget.dart

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
  final String? customTitle; // ← NUEVO
  final String? customDescription; // ← NUEVO
  final String resourceType; // ← NUEVO: 'project' o 'batch'

  const AccessControlWidget({
    super.key,
    required this.organizationId,
    required this.currentUserId,
    required this.selectedMembers,
    required this.onMembersChanged,
    this.readOnly = false,
    this.showTitle = true,
    this.customTitle, // ← NUEVO
    this.customDescription, // ← NUEVO
    this.resourceType = 'project', // ← NUEVO (default 'project')
  });

  @override
  State<AccessControlWidget> createState() => _AccessControlWidgetState();
}

class _AccessControlWidgetState extends State<AccessControlWidget> {
  late List<String> _internalSelectedMembers;

  @override
  void initState() {
    super.initState();
    _internalSelectedMembers = List.from(widget.selectedMembers);
  }

  @override
  void didUpdateWidget(AccessControlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMembers != widget.selectedMembers) {
      _internalSelectedMembers = List.from(widget.selectedMembers);
    }
  }

  void _toggleMember(String memberId) {
    if (widget.readOnly) return;

    setState(() {
      if (_internalSelectedMembers.contains(memberId)) {
        _internalSelectedMembers.remove(memberId);
      } else {
        _internalSelectedMembers.add(memberId);
      }
    });

    widget.onMembersChanged(_internalSelectedMembers);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final permissionService = Provider.of<PermissionService>(context);

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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.customDescription ?? l10n.accessControlDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Miembros con acceso automático
        FutureBuilder<List<OrganizationMemberWithUser>>(
          future: _getMembersWithAutoAccess(permissionService),
          builder: (context, autoAccessSnapshot) {
            if (autoAccessSnapshot.connectionState == ConnectionState.waiting) {
              return _buildAutoAccessSkeleton();
            }

            final autoAccessMembers = autoAccessSnapshot.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (autoAccessMembers.isNotEmpty) ...[
                  _buildAutoAccessSection(context, l10n, autoAccessMembers),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                ],

                // Asignar miembros manualmente
                _buildMemberSelectionSection(
                  context,
                  l10n,
                  autoAccessMembers,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAutoAccessSection(
    BuildContext context,
    AppLocalizations l10n,
    List<OrganizationMemberWithUser> autoAccessMembers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: Colors.blue.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.automaticAccess,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            children: autoAccessMembers.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;
              final isLast = index == autoAccessMembers.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              _parseColor(member.roleColor).withOpacity(0.2),
                          child: Text(
                            member.initials,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _parseColor(member.roleColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Nombre y email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.userName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                member.userEmail,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Badge de rol
                        _buildRoleBadge(
                          member.roleName,
                          _parseColor(member.roleColor),
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: Colors.blue.shade100,
                      indent: 52,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoAccessSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 200,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberSelectionSection(
    BuildContext context,
    AppLocalizations l10n,
    List<OrganizationMemberWithUser> autoAccessMembers,
  ) {
    final organizationService = Provider.of<OrganizationService>(context);
    final autoAccessIds = autoAccessMembers.map((m) => m.userId).toSet();

    return StreamBuilder<List<UserModel>>(
      stream:
          organizationService.watchOrganizationMembers(widget.organizationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMemberSelectionSkeleton();
        }

        // Filtrar miembros que NO tienen acceso automático
        final selectableMembers = (snapshot.data ?? [])
            .where((m) => !autoAccessIds.contains(m.uid))
            .toList();

        if (selectableMembers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              l10n.allMembersHaveAutoAccess,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_add_outlined,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.assignAdditionalMembers,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: selectableMembers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final member = entry.value;
                  final isMe = member.uid == widget.currentUserId;
                  final isSelected =
                      _internalSelectedMembers.contains(member.uid);
                  final isLast = index == selectableMembers.length - 1;

                  return Column(
                    children: [
                      FutureBuilder<Color>(
                        future: _getMemberRoleColor(member.uid),
                        builder: (context, colorSnapshot) {
                          final roleColor = colorSnapshot.data ?? Colors.blue;

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: widget.readOnly
                                ? null
                                : (value) {
                                    _toggleMember(member.uid);
                                  },
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    member.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      l10n.you,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    member.email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildRoleBadge(
                                  member.roleDisplayName,
                                  roleColor,
                                  compact: true,
                                ),
                              ],
                            ),
                            secondary: CircleAvatar(
                              radius: 18,
                              backgroundColor: isMe
                                  ? Colors.blue.shade100
                                  : roleColor.withOpacity(0.2),
                              child: Icon(
                                isMe ? Icons.account_circle : Icons.person,
                                color: isMe ? Colors.blue.shade700 : roleColor,
                                size: 20,
                              ),
                            ),
                            activeColor: Theme.of(context).primaryColor,
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        },
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                          indent: 68,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberSelectionSkeleton() {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 180,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRoleBadge(String roleName, Color color, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        roleName,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  Future<Color> _getMemberRoleColor(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('members')
          .doc(userId)
          .get();

      if (doc.exists) {
        final roleColor = doc.data()?['roleColor'] as String?;
        if (roleColor != null) {
          return _parseColor(roleColor);
        }
      }
    } catch (e) {
      debugPrint('Error getting role color: $e');
    }
    return Colors.blue;
  }

  /// Obtener miembros con acceso automático
  Future<List<OrganizationMemberWithUser>> _getMembersWithAutoAccess(
    PermissionService permissionService,
  ) async {
    try {
      // Obtener organización para saber quién es el owner
      final org = await _getOrganization(widget.organizationId);
      if (org == null) return [];

      // Obtener todos los miembros
      final organizationService =
          Provider.of<OrganizationService>(context, listen: false);
      final allMembers = await organizationService
          .watchOrganizationMembers(widget.organizationId)
          .first;

      final autoAccessMembers = <OrganizationMemberWithUser>[];

      for (final member in allMembers) {
        // Owner siempre tiene acceso
        if (member.uid == org['ownerId']) {
          final memberData = await _getMemberWithRole(member.uid);
          if (memberData != null) {
            autoAccessMembers.add(memberData);
            continue;
          }
        }

// Verificar si es admin o tiene scope all en projects/batches
        final memberData = await _getMemberWithRole(member.uid);

        if (memberData != null) {
          // Obtener el rol para verificar permisos
          final roleDoc = await FirebaseFirestore.instance
              .collection('organizations')
              .doc(widget.organizationId)
              .collection('roles')
              .doc(memberData.member.roleId)
              .get();

          if (!roleDoc.exists) continue;

          final role = RoleModel.fromMap(roleDoc.data()!, docId: roleDoc.id);
          final permissions = memberData.member.getEffectivePermissions(role);

          // Admin o con scope all (según tipo de recurso)
          bool hasAutoAccess = false;
          if (memberData.member.roleId == 'admin') {
            hasAutoAccess = true;
          } else if (widget.resourceType == 'project') {
            hasAutoAccess =
                permissions.viewProjectsScope == PermissionScope.all;
          } else if (widget.resourceType == 'batch') {
            hasAutoAccess = permissions.viewBatchesScope == PermissionScope.all;
          }

          if (hasAutoAccess) {
            autoAccessMembers.add(memberData);
          }
        }
      }

      return autoAccessMembers;
    } catch (e) {
      debugPrint('Error getting auto-access members: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _getOrganization(String organizationId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .get();

      return doc.data();
    } catch (e) {
      return null;
    }
  }

  Future<OrganizationMemberWithUser?> _getMemberWithRole(String userId) async {
    try {
      final memberDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('members')
          .doc(userId)
          .get();

      if (!memberDoc.exists) return null;

      final member = OrganizationMemberModel.fromMap(
        memberDoc.data()!,
        docId: memberDoc.id,
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return null;

      final user = UserModel.fromMap(userDoc.data()!);

      return OrganizationMemberWithUser(
        member: member,
        userName: user.name,
        userEmail: user.email,
        userPhotoUrl: user.photoURL,
      );
    } catch (e) {
      return null;
    }
  }
}
