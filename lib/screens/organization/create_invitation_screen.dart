import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/invitation_service.dart';
import '../../services/role_service.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../models/role_model.dart';
import '../../models/client_model.dart';
import '../../utils/filter_utils.dart';

/// Pantalla para crear invitaciones directas
///
/// Admin selecciona rol y configuración, se genera código automáticamente
/// Si el rol es 'client', permite asociar el miembro a un cliente existente
class CreateInvitationScreen extends StatefulWidget {
  final String organizationId;
  final String organizationName;

  const CreateInvitationScreen({
    super.key,
    required this.organizationId,
    required this.organizationName,
  });

  @override
  State<CreateInvitationScreen> createState() => _CreateInvitationScreenState();
}

class _CreateInvitationScreenState extends State<CreateInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedRoleId;
  String? _selectedClientId; // Para asociar con cliente si rol es 'client'
  int _maxUses = 1;
  int _expirationDays = 7;
  String? clientName;

  bool get _isClientRole {
    if (_selectedRoleId == null) return false;
    return _selectedRoleId!.toLowerCase() == 'client' ||
        _selectedRoleId!.toLowerCase() == 'cliente';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectRoleForInvitation),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar cliente si el rol es 'client'
    if (_isClientRole && _selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectClientRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final invitationService =
        Provider.of<InvitationService>(context, listen: false);

    final user = authService.currentUserData;
    if (user == null) return;

    final invitation = await invitationService.createInvitation(
      organizationId: widget.organizationId,
      organizationName: widget.organizationName,
      roleId: _selectedRoleId!,
      createdBy: user.uid,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      maxUses: _maxUses,
      daysUntilExpiration: _expirationDays,
      clientId: _isClientRole ? _selectedClientId : null, // Agregar clientId
      clientName: _isClientRole ? clientName : null,
    );

    if (!mounted) return;

    if (invitation != null) {
      // Mostrar diálogo con el código generado
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.invitationCreatedSuccess,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.invitationCodeGenerated,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        invitation.code,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: invitation.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(l10n.invitationCodeCopied),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      tooltip: l10n.copyInvitationCode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoRow(
                Icons.group,
                l10n.invitationUses,
                '${invitation.usedCount}/${invitation.maxUses}',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.calendar_today,
                l10n.invitationExpires,
                '${invitation.daysUntilExpiration} ${l10n.days}',
              ),
              if (_isClientRole && _selectedClientId != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.business,
                  l10n.associatedClient,
                  clientName!,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Volver atrás
              },
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  invitationService.error ?? l10n.invitationCreateError,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _getClientName(String clientId) {
    // Obtener nombre del cliente del StreamBuilder
    return 'Cliente'; // Se actualizará desde el StreamBuilder
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final invitationService = Provider.of<InvitationService>(context);
    final roleService = Provider.of<RoleService>(context, listen: false);
    final clientService = Provider.of<ClientService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.createInvitationTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card principal
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.group_add,
                                color: Theme.of(context).primaryColor,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.createInvitationTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.createInvitationSubtitle,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Selector de rol usando FilterUtils
                        FutureBuilder<List<RoleModel>>(
                          future:
                              roleService.getAllRoles(widget.organizationId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final roles = snapshot.data!;

                            return FilterUtils.buildFullWidthDropdown<String>(
                              context: context,
                              label: l10n.role,
                              value: _selectedRoleId,
                              items: roles.map((role) {
                                return DropdownMenuItem(
                                  value: role.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Color(
                                            int.parse(
                                              role.color
                                                  .replaceFirst('#', '0xFF'),
                                            ),
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(role.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRoleId = value;
                                  // Limpiar cliente si cambia de rol
                                  if (!_isClientRole) {
                                    _selectedClientId = null;
                                  }
                                });
                              },
                              icon: Icons.badge,
                              hintText: l10n.selectRoleForInvitation,
                              isRequired: true,
                            );
                          },
                        ),

                        // Selector de cliente (solo si rol es 'client')
                        if (_isClientRole) ...[
                          const SizedBox(height: 16),
                          StreamBuilder<List<ClientModel>>(
                            stream: clientService
                                .watchClients(widget.organizationId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final clients = snapshot.data!;

                              if (clients.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          l10n.noClientsAvailable,
                                          style: TextStyle(
                                            color: Colors.orange[900],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return FilterUtils.buildFullWidthDropdown<String>(
                                context: context,
                                label: l10n.client,
                                value: _selectedClientId,
                                items: clients.map((client) {
                                  return DropdownMenuItem(
                                    value: client.id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.business,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                client.company,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                client.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedClientId = value;

                                    // Buscamos el objeto cliente completo en la lista usando el ID seleccionado
                                    final selectedClient = clients
                                        .firstWhere((c) => c.id == value);

                                    // Ahora asignamos el nombre del cliente encontrado
                                    clientName = selectedClient.name;
                                  });
                                },
                                icon: Icons.business,
                                hintText: l10n.selectClient,
                                isRequired: true,
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Descripción opcional
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: l10n.invitationDescription,
                            hintText: l10n.invitationDescriptionHint,
                            prefixIcon: const Icon(Icons.description),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Card de configuración
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.settings,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.configuration,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Usos máximos
                        _buildConfigRow(
                          icon: Icons.group,
                          label: l10n.maxUsesLabel,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButton<int>(
                              value: _maxUses,
                              underline: const SizedBox(),
                              items: [1, 5, 10, 20, 50]
                                  .map((uses) => DropdownMenuItem(
                                        value: uses,
                                        child: Text(
                                          uses.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _maxUses = value ?? 1);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Días hasta expiración
                        _buildConfigRow(
                          icon: Icons.calendar_today,
                          label: l10n.expirationDaysLabel,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButton<int>(
                              value: _expirationDays,
                              underline: const SizedBox(),
                              items: [1, 3, 7, 14, 30, 90]
                                  .map((days) => DropdownMenuItem(
                                        value: days,
                                        child: Text(
                                          '$days ${l10n.days}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _expirationDays = value ?? 7);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botón crear
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed:
                        invitationService.isLoading ? null : _handleCreate,
                    icon: invitationService.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      l10n.createInvitationButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
