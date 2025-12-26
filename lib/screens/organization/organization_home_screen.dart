import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/organization_service.dart';
import 'create_organization_screen.dart';
import 'organization_detail_screen.dart';
import 'join_organization_screen.dart';
import 'pending_invitations_screen.dart';
import '../../models/user_model.dart';

class OrganizationHomeScreen extends StatefulWidget {
  const OrganizationHomeScreen({super.key});

  @override
  State<OrganizationHomeScreen> createState() => _OrganizationHomeScreenState();
}

class _OrganizationHomeScreenState extends State<OrganizationHomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrganization();
  }

  Future<void> _loadOrganization() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final organizationService =
        Provider.of<OrganizationService>(context, listen: false);

    final user = authService.currentUserData;
    if (user?.organizationId != null) {
      await organizationService.loadOrganization(user!.organizationId!);
    } else {
      // Reload user data from Firestore to get updated organizationId
      await authService.getUserData();
    }
  }

  
    
@override
Widget build(BuildContext context) {
  final authService = Provider.of<AuthService>(context);
  final organizationService = Provider.of<OrganizationService>(context);
  
  // Usamos un valor local para evitar problemas con nulos
  final currentUser = authService.currentUserData;

  if (currentUser == null) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  // LÓGICA PRINCIPAL: Escuchar cambios en tiempo real
  return StreamBuilder<UserModel?>(
    // Usamos el stream para detectar si aceptaste una invitación
    stream: authService.userStream, 
    initialData: currentUser, // Usamos los datos actuales mientras conecta
    builder: (context, snapshot) {
      
      final user = snapshot.data ?? currentUser;

      // CASO 1: El usuario YA TIENE organización (detectado por Stream o local)
      if (user.organizationId != null) {
        
        // Verificamos si necesitamos cargar los datos de la org en el servicio
        if (organizationService.currentOrganization?.id != user.organizationId) {
           Future.microtask(() => 
             organizationService.loadOrganization(user.organizationId!)
           );
        }

        // Si el servicio ya cargó la org, mostramos el Dashboard
        if (organizationService.currentOrganization != null && !organizationService.isLoading) {
           return const OrganizationDetailScreen(); // Esta pantalla ya tiene su propio Scaffold
        }

        // Si está cargando la org, mostramos rueda
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      // CASO 2: NO TIENE ORGANIZACIÓN (Aquí estaba el error de pantalla negra)
      // Debemos devolver un Scaffold explícito aquí para pintar el fondo y la AppBar
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Organización'),
          actions: [
            // TU CÓDIGO DE BURBUJA (BADGE)
            StreamBuilder<List<dynamic>>(
              stream: organizationService.getPendingInvitations(user.email),
              builder: (context, invitationSnapshot) {
                final count = invitationSnapshot.data?.length ?? 0;
                if (count == 0) return const SizedBox.shrink();

                return IconButton(
                  icon: Badge(
                    label: Text('$count'),
                    child: const Icon(Icons.mail_outline),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PendingInvitationsScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        // Aquí pintamos la vista que antes salía negra, ahora dentro del body
        body: organizationService.isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _buildNoOrganizationView(context, user),
      );
    },
  );
}

  Widget _buildNoOrganizationView(BuildContext context, user) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No perteneces a ninguna organización',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Crea tu propia organización o únete a una existente',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Crear organización (solo para fabricantes, admin, etc.)
            if (user.canManageProduction) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateOrganizationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_business),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Crear mi organización',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[400])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'o',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400])),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Unirse con código
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinOrganizationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.vpn_key),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Unirse con código',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Invitaciones pendientes
            StreamBuilder<List<dynamic>>(
              stream: Provider.of<OrganizationService>(context, listen: false)
                  .getPendingInvitations(user.email),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                if (count == 0) return const SizedBox.shrink();

                return Card(
                  color: Colors.blue[50],
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PendingInvitationsScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.mail, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tienes $count invitación${count > 1 ? 'es' : ''} pendiente${count > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                Text(
                                  'Toca para ver',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.blue[700]),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}