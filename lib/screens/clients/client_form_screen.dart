import 'package:flutter/material.dart';
import 'package:gestion_produccion/services/permission_service.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/client_model.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../widgets/client_color_picker.dart';
import '../../widgets/client_permissions_selector.dart';

/// Pantalla unificada para crear y editar clientes
///
/// Modo de uso:
/// - Para crear: ClientFormScreen()
/// - Para editar: ClientFormScreen(client: clientToEdit)
class ClientFormScreen extends StatefulWidget {
  final ClientModel? client; // null = crear, no-null = editar

  const ClientFormScreen({super.key, this.client});

  /// Helper: determinar si está en modo edición
  bool get isEditMode => client != null;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _emailController;
  late final TextEditingController _phonePrefixController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;
  late final TextEditingController _notesController;

  // Estado del formulario
  String? _selectedColor;
  Map<String, dynamic> _clientPermissions = {};
  bool _hasUnsavedChanges = false;

  // Permisos RBAC
  bool _canEditPermissions = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _checkPermissions();
  }

  void _initializeControllers() {
    final client = widget.client;

    _nameController = TextEditingController(text: client?.name ?? '');
    _companyController = TextEditingController(text: client?.company ?? '');
    _emailController = TextEditingController(text: client?.email ?? '');
    _phonePrefixController = TextEditingController(text: client?.phonePrefix ?? '+34');
    _phoneController = TextEditingController(text: client?.phone ?? '');
    _addressController = TextEditingController(text: client?.address ?? '');
    _cityController = TextEditingController(text: client?.city ?? '');
    _postalCodeController =
        TextEditingController(text: client?.postalCode ?? '');
    _countryController = TextEditingController(text: client?.country ?? '');
    _notesController = TextEditingController(text: client?.notes ?? '');

    _selectedColor = client?.color;
    _clientPermissions = client != null
        ? Map<String, dynamic>.from(client.clientPermissions)
        : {};

    // Listeners para detectar cambios
    _nameController.addListener(_onFieldChanged);
    _companyController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phonePrefixController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _postalCodeController.addListener(_onFieldChanged);
    _countryController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
  }

  Future<void> _checkPermissions() async {
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);

    // Solo admins/owners pueden gestionar permisos de clientes
    final canManageRoles = permissionService.canManageRoles;

    setState(() {
      _canEditPermissions = canManageRoles;
    });
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _onColorChanged(String color) {
    setState(() {
      _selectedColor = color;
      _hasUnsavedChanges = true;
    });
  }

  void _onPermissionsChanged(Map<String, dynamic> permissions) {
    setState(() {
      _clientPermissions = permissions;
      _hasUnsavedChanges = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phonePrefixController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final l10n = AppLocalizations.of(context)!;
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChangesTitle),
        content: Text(l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(l10n.discardChanges),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final clientService = Provider.of<ClientService>(context, listen: false);

    final user = authService.currentUserData;
    if (user == null || user.organizationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mustBelongToOrganization),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Procesar teléfono - ahora separado en prefijo y número
    final phonePrefix = _phonePrefixController.text.trim().isEmpty
        ? null
        : _phonePrefixController.text.trim();
    
    final phone = _phoneController.text.trim().isEmpty
        ? null
        : _phoneController.text.trim();

        print("valor de phone prefix: ${phonePrefix}");

    bool success;
    if (widget.isEditMode) {
      // EDITAR
      success = await clientService.updateClient(
        organizationId: user.organizationId!,
        clientId: widget.client!.id,
        name: _nameController.text.trim(),
        company: _companyController.text.trim(),
        email: _emailController.text.trim(),
        phonePrefix: phonePrefix,
        phone: phone,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty
            ? null
            : _postalCodeController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        color: _selectedColor,
        clientPermissions: _clientPermissions,
      );
    } else {
      // CREAR
      final clientId = await clientService.createClient(
        organizationId: user.organizationId!,
        name: _nameController.text.trim(),
        company: _companyController.text.trim(),
        email: _emailController.text.trim(),
        phonePrefix: phonePrefix,
        phone: phone,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty
            ? null
            : _postalCodeController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdBy: user.uid,
        color: _selectedColor,
        clientPermissions: _clientPermissions,
      );
      success = clientId != null;
    }

    if (mounted) {
      if (success) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? l10n.clientUpdatedSuccess
                  : l10n.clientCreatedSuccess,
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              clientService.error ??
                  (widget.isEditMode
                      ? l10n.updateClientError
                      : l10n.createClientError),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clientService = Provider.of<ClientService>(context);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              widget.isEditMode ? l10n.editClientTitle : l10n.newClientTitle),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Información básica
                  _buildCard(
                    context,
                    title: l10n.basicInfoSection,
                    icon: Icons.info_outline,
                    iconColor: Colors.blue,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.contactNameLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.enterNameError;
                          }
                          if (value.length < 2) {
                            return l10n.nameLengthError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.companyLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.enterCompanyError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.emailLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.enterEmailError;
                          }
                          if (!value.contains('@')) {
                            return l10n.enterValidEmailError;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Contacto
                  _buildCard(
                    context,
                    title: l10n.contactInfo,
                    icon: Icons.phone_outlined,
                    iconColor: Colors.green,
                    children: [
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.phoneLabel,
                          hintText: '123 456 789',
                          border: const OutlineInputBorder(),
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                showCountryPicker(
                                  context: context,
                                  favorite: <String>['ES', 'US', 'GB', 'FR'],
                                  showPhoneCode: true,
                                  onSelect: (Country country) {
                                    setState(() {
                                      _phonePrefixController.text = '+${country.phoneCode}';
                                    });
                                  },
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone_outlined, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _phonePrefixController.text,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Dirección
                  _buildCard(
                    context,
                    title: l10n.addressLabel,
                    icon: Icons.location_on_outlined,
                    iconColor: Colors.red,
                    children: [
                      TextFormField(
                        controller: _addressController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.addressLabel,
                          border: const OutlineInputBorder(),
                          helperText: l10n.addressHelper,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _cityController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: l10n.cityLabel,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _postalCodeController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.zipCodeLabel,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _countryController,
                        readOnly: true,
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            favorite: <String>['ES'],
                            showPhoneCode: false,
                            onSelect: (Country country) {
                              setState(() {
                                _countryController.text =
                                    "${country.flagEmoji} ${country.nameLocalized ?? country.name}";
                              });
                            },
                            countryListTheme: CountryListThemeData(
                              borderRadius: BorderRadius.circular(15),
                              inputDecoration: InputDecoration(
                                labelText: l10n.searchCountryHint,
                                prefixIcon: const Icon(Icons.search),
                              ),
                            ),
                          );
                        },
                        decoration: InputDecoration(
                          labelText: l10n.countryLabel,
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Color
                  _buildCard(
                    context,
                    title: l10n.clientColorLabel,
                    icon: Icons.palette_outlined,
                    iconColor: Colors.purple,
                    children: [
                      ClientColorPicker(
                        currentColor: _selectedColor,
                        onColorChanged: _onColorChanged,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Notas
                  _buildCard(
                    context,
                    title: l10n.notesSection,
                    icon: Icons.note_outlined,
                    iconColor: Colors.orange,
                    children: [
                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: l10n.additionalNotesHelper,
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Permisos especiales (solo si tiene permisos)
                  if (_canEditPermissions)
                    _buildCard(
                      context,
                      title: l10n.clientSpecialPermissions,
                      icon: Icons.security_outlined,
                      iconColor: Colors.deepPurple,
                      children: [
                        ClientPermissionsSelector(
                          initialPermissions: _clientPermissions,
                          onPermissionsChanged: _onPermissionsChanged,
                        ),
                      ],
                    ),

                  if (_canEditPermissions) const SizedBox(height: 16),

                  // Botones
                  FilledButton(
                    onPressed: clientService.isLoading ? null : _handleSubmit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: clientService.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.isEditMode
                                  ? l10n.saveChangesButton
                                  : l10n.createClientButton,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      if (_hasUnsavedChanges) {
                        final shouldPop = await _onWillPop();
                        if (shouldPop && context.mounted) {
                          Navigator.pop(context);
                        }
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
