import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/invitation_service.dart';
import '../../services/role_service.dart';
import '../../services/auth_service.dart';
import '../../models/role_model.dart';

/// Pantalla para crear invitaciones directas
/// 
/// Admin selecciona rol y configuración, se genera código automáticamente
class CreateInvitationScreen extends StatefulWidget {
  final String organizationId;

  const CreateInvitationScreen({
    super.key,
    required this.organizationId,
  });

  @override
  State<CreateInvitationScreen> createState() => _CreateInvitationScreenState();
}

class _CreateInvitationScreenState extends State<CreateInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedRoleId;
  int _maxUses = 1;
  int _expirationDays = 7;

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

    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final invitationService =
        Provider.of<InvitationService>(context, listen: false);

    final user = authService.currentUserData;
    if (user == null) return;

    final invitation = await invitationService.createInvitation(
      organizationId: widget.organizationId,
      roleId: _selectedRoleId!,
      createdBy: user.uid,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      maxUses: _maxUses,
      daysUntilExpiration: _expirationDays,
    );

    if (!mounted) return;

    if (invitation != null) {
      // Mostrar diálogo con el código generado
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.invitationCreatedSuccess)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.invitationCodeGenerated),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      invitation.code,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: invitation.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.invitationCodeCopied)),
                        );
                      },
                      tooltip: l10n.copyInvitationCode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${l10n.invitationUses}: ${invitation.maxUses}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              Text(
                '${l10n.invitationExpires}: ${invitation.daysUntilExpiration} ${l10n.days}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
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
          content: Text(
            invitationService.error ?? l10n.invitationCreateError,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final invitationService = Provider.of<InvitationService>(context);
    final roleService = Provider.of<RoleService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createInvitationTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icono
                Icon(
                  Icons.group_add,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),

                Text(
                  l10n.createInvitationTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Selector de rol
                FutureBuilder<List<RoleModel>>(
                  future: roleService.getAllRoles(widget.organizationId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final roles = snapshot.data!;

                    return DropdownButtonFormField<String>(
                      value: _selectedRoleId,
                      decoration: InputDecoration(
                        labelText: l10n.selectRoleForInvitation,
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(),
                      ),
                      items: roles.map((role) {
                        return DropdownMenuItem(
                          value: role.id,
                          child: Text(role.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedRoleId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return l10n.selectRoleForInvitation;
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Descripción opcional
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.invitationDescription,
                    hintText: l10n.invitationDescriptionHint,
                    prefixIcon: const Icon(Icons.description),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Usos máximos
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.maxUsesLabel,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    DropdownButton<int>(
                      value: _maxUses,
                      items: [1, 5, 10, 20, 50]
                          .map((uses) => DropdownMenuItem(
                                value: uses,
                                child: Text(uses.toString()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _maxUses = value ?? 1);
                      },
                    ),
                  ],
                ),
                const Divider(),

                // Días hasta expiración
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.expirationDaysLabel,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    DropdownButton<int>(
                      value: _expirationDays,
                      items: [1, 3, 7, 14, 30, 90]
                          .map((days) => DropdownMenuItem(
                                value: days,
                                child: Text('$days ${l10n.days}'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _expirationDays = value ?? 7);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Botón crear
                FilledButton(
                  onPressed: invitationService.isLoading ? null : _handleCreate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: invitationService.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.createInvitationButton,
                            style: const TextStyle(fontSize: 16),
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
}