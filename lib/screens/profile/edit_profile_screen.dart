import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Variables para controlar el estado de los cambios
  String _originalName = '';
  String _originalPhone = '';
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    loadUserData();

    // Listeners para detectar cambios en tiempo real
    _nameController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _phoneController.removeListener(_checkForChanges);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;
    if (user != null) {
      _originalName = user.name;
      _originalPhone = user.phone ?? '';

      _nameController.text = _originalName;
      _phoneController.text = _originalPhone;
    }
  }

  // Compara los valores actuales con los originales
  void _checkForChanges() {
    final nameChanged = _nameController.text.trim() != _originalName;
    final phoneChanged = _phoneController.text.trim() != _originalPhone;
    
    final hasChangesNow = nameChanged || phoneChanged;

    if (_hasChanges != hasChangesNow) {
      setState(() {
        _hasChanges = hasChangesNow;
      });
    }
  }

  Future<bool> _onWillPop(AppLocalizations l10n) async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChangesTitle),
        content: Text(l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // No salir (quedarse)
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true), // Salir (descartar)
            // style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _pickAndUploadPhoto() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.uploadingPhoto)),
        );
      }

      final url = await authService.uploadProfilePhoto(image);

      if (mounted && url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.photoUpdated), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    // Doble verificación por seguridad
    if (!_hasChanges) return;
    

    final authService = Provider.of<AuthService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    // Desenfocar campos para cerrar teclado
    FocusScope.of(context).unfocus();

    final success = await authService.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (mounted) {
      if (success) {
        // Actualizar valores originales para que _hasChanges vuelva a false
        setState(() {
          _originalName = _nameController.text.trim();
          _originalPhone = _phoneController.text.trim();
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(l10n.profileUpdatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        // Opcional: Salir automáticamente al guardar
        // Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.error ?? l10n.updateProfileError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () => _onWillPop(l10n),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.editProfileTitle),
          actions: [
            // Badge de "Sin guardar"
            if (_hasChanges)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.unsavedChanges,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            // onChanged: ya no es necesario aquí porque usamos controllers listeners
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        backgroundImage: (user.photoURL != null && user.photoURL!.isNotEmpty)  
                            ? NetworkImage(user.photoURL!) 
                            : null,
                        child: (user.photoURL == null || user.photoURL!.isEmpty)
                            ? Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: authService.isLoading ? null : _pickAndUploadPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: authService.isLoading
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Nombre
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.fullNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterNameError;
                    }
                    if (value.length < 3) {
                      return l10n.nameMinLengthError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email (solo lectura)
                TextFormField(
                  initialValue: user.email,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    helperText: l10n.emailReadOnlyHelper,
                    helperStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 16),

                // Teléfono
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.phoneOptionalLabel,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: const OutlineInputBorder(),
                    helperText: l10n.phoneHelper,
                  ),
                ),
                const SizedBox(height: 16),

                // Rol (solo lectura)
                TextFormField(
                  initialValue: user.roleDisplayName,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: l10n.accountType,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: const OutlineInputBorder(),
                    helperText: l10n.roleReadOnlyHelper,
                  ),
                ),
                const SizedBox(height: 16),
              FilledButton(
                onPressed: _isLoading || !_hasChanges ? null : () => _saveChanges(),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveChangesButton),
              ),
              const SizedBox(height: 16),

              ],
            ),
          ),
        ),
      ),
    );
  }
}