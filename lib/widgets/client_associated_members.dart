import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../models/organization_member_model.dart';
import '../../models/user_model.dart';

/// Widget que muestra los miembros asociados a un cliente
/// 
/// Busca miembros con rol 'client' y que tengan el clientId correspondiente
class ClientAssociatedMembers extends StatelessWidget {
  final String organizationId;
  final String clientId;
  final bool showTitle;

  const ClientAssociatedMembers({
    super.key,
    required this.organizationId,
    required this.clientId,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .where('clientId', isEqualTo: clientId)
          .where('roleId', isEqualTo: 'client')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorCard(context, l10n);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(context, l10n);
        }

        final memberDocs = snapshot.data?.docs ?? [];

        if (memberDocs.isEmpty) {
          return _buildEmptyCard(context, l10n);
        }

        return _buildMembersCard(context, l10n, memberDocs);
      },
    );
  }

  Widget _buildMembersCard(
    BuildContext context,
    AppLocalizations l10n,
    List<QueryDocumentSnapshot> memberDocs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              Icon(Icons.people_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.associatedMembers,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${memberDocs.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: memberDocs.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final memberData = memberDocs[index].data() as Map<String, dynamic>;
              return _buildMemberTile(context, memberData);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemberTile(BuildContext context, Map<String, dynamic> memberData) {
    // Obtener datos del usuario desde el member
    final userName = memberData['userName'] as String? ?? 'Usuario';
    final userEmail = memberData['userEmail'] as String? ?? '';
    final userId = memberData['userId'] as String? ?? '';

    // Obtener initials
    String getInitials(String name) {
      final parts = name.trim().split(' ');
      if (parts.isEmpty) return '?';
      if (parts.length == 1) {
        return parts[0].substring(0, 1).toUpperCase();
      }
      return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
          .toUpperCase();
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Text(
          getInitials(userName),
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        userName,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: userEmail.isNotEmpty
          ? Text(
              userEmail,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
        size: 20,
      ),
      onTap: () {
        // TODO: Navegar a detalles del miembro
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (context) => MemberDetailScreen(userId: userId),
        // ));
      },
    );
  }

  Widget _buildEmptyCard(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              Icon(Icons.people_outline, color: Colors.grey.shade400, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.associatedMembers,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noAssociatedMembers,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noAssociatedMembersHint,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              Icon(Icons.people_outline, color: Colors.grey.shade400, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.associatedMembers,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              Icon(Icons.people_outline, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.associatedMembers,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.errorLoadingMembers,
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}