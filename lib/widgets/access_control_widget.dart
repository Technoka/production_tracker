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
  final String? customTitle;
  final String? customDescription;
  final String resourceType;

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
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);

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

        // Miembros con acceso automático - Cambiado a FutureBuilder
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

                // Asignar miembros manualmente - Cambiado a FutureBuilder
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_open_outlined,
              size: 18,
              color: Colors.blue.shade700,
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
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: autoAccessMembers.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;
              final isMe = member.userId == widget.currentUserId;
              final isLast = index == autoAccessMembers.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isMe
                              ? Colors.blue.shade100
                              : _parseColor(member.roleColor).withOpacity(0.2),
                          child: Text(
                            member.userName.isNotEmpty
                                ? member.userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isMe
                                  ? Colors.blue.shade700
                                  : _parseColor(member.roleColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      member.userName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
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
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.3),
                                        ),
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
                              const SizedBox(height: 4),
                              Text(
                                member.userEmail,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                      color: Colors.grey.shade200,
                      indent: 54,
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
              width: 120,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: List.generate(2, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
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
                            width: 100,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 140,
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
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            }),
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
    return FutureBuilder<List<OrganizationMemberWithUser>>(
      future: _getOrganizationMembersWithRoles(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMemberSelectionSkeleton();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.noMembersFound,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        final allMembers = snapshot.data!;
        final autoAccessMemberIds =
            autoAccessMembers.map((m) => m.userId).toSet();
        final manualMembers = allMembers
            .where((m) => !autoAccessMemberIds.contains(m.userId))
            .toList();

// All members have automatic access
        if (manualMembers.isEmpty) {
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
                Expanded(
                  child: Text(
                    l10n.assignAdditionalMembers,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
                children: manualMembers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final member = entry.value;
                  final isMe = member.userId == widget.currentUserId;
                  final isSelected =
                      _internalSelectedMembers.contains(member.userId);
                  final isLast = index == manualMembers.length - 1;

                  return Column(
                    children: [
                      CheckboxListTile(
                        value: isSelected,
                        onChanged: widget.readOnly
                            ? null
                            : (value) => _toggleMember(member.userId),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.userName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
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
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.3),
                                  ),
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
                            const SizedBox(width: 8),
                            _buildRoleBadge(
                              member.roleName,
                              _parseColor(member.roleColor),
                              compact: true,
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              member.userEmail,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                        secondary: CircleAvatar(
                          radius: 18,
                          backgroundColor: isMe
                              ? Colors.blue.shade100
                              : _parseColor(member.roleColor).withOpacity(0.2),
                          child: Icon(
                            isMe ? Icons.account_circle : Icons.person,
                            color: isMe
                                ? Colors.blue.shade700
                                : _parseColor(member.roleColor),
                            size: 20,
                          ),
                        ),
                        activeColor: Theme.of(context).primaryColor,
                        controlAffinity: ListTileControlAffinity.trailing,
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
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 5,
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
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
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

  /// Obtener miembros de la organización con sus roles
  /// OPTIMIZADO: Obtiene de organization->members en lugar de users
  Future<List<OrganizationMemberWithUser>> _getOrganizationMembersWithRoles(
    BuildContext context,
  ) async {
    try {
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('members')
          .get();

      final List<OrganizationMemberWithUser> membersWithRoles = [];

      for (final memberDoc in membersSnapshot.docs) {
        try {
          final member = OrganizationMemberModel.fromMap(
            memberDoc.data(),
            docId: memberDoc.id,
          );

          // Obtener datos del usuario
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

  /// Obtener miembros con acceso automático (owner, admin, scope all en projects)
  Future<List<OrganizationMemberWithUser>> _getMembersWithAutoAccess(
    PermissionService permissionService,
  ) async {
    try {
      final organizationService =
          Provider.of<OrganizationService>(context, listen: false);

      // Obtener organización para saber quién es el owner
      final org =
          await organizationService.getOrganization(widget.organizationId);
      if (org == null) return [];

      // Obtener todos los miembros de organization->members
      final membersWithRoles = await _getOrganizationMembersWithRoles(context);

      final autoAccessMembers = <OrganizationMemberWithUser>[];

      for (final memberWithRole in membersWithRoles) {
        // Owner siempre tiene acceso
        if (memberWithRole.userId == org.ownerId) {
          autoAccessMembers.add(memberWithRole);
          continue;
        }

        // Obtener el rol
        final roleDoc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(widget.organizationId)
            .collection('roles')
            .doc(memberWithRole.member.roleId)
            .get();

        if (!roleDoc.exists) continue;

        final role = RoleModel.fromMap(roleDoc.data()!, docId: roleDoc.id);
        final permissions = memberWithRole.member.getEffectivePermissions(role);

        // Admin o Production Manager con scope all
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
}
