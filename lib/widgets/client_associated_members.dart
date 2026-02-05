import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_produccion/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
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
        const SizedBox(height: 40),
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
            padding: const EdgeInsets.only(left: 10),
            itemCount: memberDocs.length,
            separatorBuilder: (context, index) => const Divider(height: 4),
            itemBuilder: (context, index) {
              final memberData =
                  memberDocs[index].data() as Map<String, dynamic>;
              return _buildMemberTile(context, memberData, l10n);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemberTile(BuildContext context, Map<String, dynamic> memberData,
      AppLocalizations l10n) {
    // 1. Obtenemos el ID del miembro desde el mapa
    final userId = memberData['userId'] as String? ?? '';

    // Si no hay ID, no podemos buscar, retornamos algo vacío o genérico
    if (userId.isEmpty) return const SizedBox.shrink();

    // 2. Usamos FutureBuilder para esperar los datos del AuthService
    return FutureBuilder<UserModel?>(
      future:
          Provider.of<AuthService>(context, listen: false).getUserById(userId),
      builder: (context, snapshot) {
        // --- A. Estado de Carga ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: const CircleAvatar(
                child: SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2))),
            title: Text(l10n.loadingUser, style: TextStyle(color: Colors.grey)),
          );
        }

        // --- B. Obtener datos reales o usar fallbacks ---
        final user = snapshot.data;
        final userName = user?.name ?? l10n.unknownUser;
        final userEmail = user?.email ?? l10n.unknownEmail;
        final photoUrl =
            user?.photoURL; // Asumiendo que tu UserModel tiene este campo

        // Helper para iniciales (Mantenido de tu código original)
        String getInitials(String name) {
          final parts = name.trim().split(' ');
          if (parts.isEmpty) return '?';
          if (parts.length == 1) {
            return parts[0].substring(0, 1).toUpperCase();
          }
          return (parts[0].substring(0, 1) +
                  parts[parts.length - 1].substring(0, 1))
              .toUpperCase();
        }

        // --- C. Construir el Tile con los datos frescos ---
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            // 3. Lógica de imagen: Si hay URL usa NetworkImage, si no, usa texto
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(
                    getInitials(userName),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null, // Si hay imagen, no ponemos texto hijo
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
        );
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
