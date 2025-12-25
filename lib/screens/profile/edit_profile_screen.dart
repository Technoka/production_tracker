import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;

    if (user == null) return;

    // Verificar si hubo cambios
    final nameChanged = _nameController.text.trim() != user.name;
    final phoneChanged = _phoneController.text.trim() != (user.phone ?? '');

    if (!nameChanged && !phoneChanged) {
      Navigator.pop(context);
      return;
    }

    final success = await authService.updateProfile(
      name: nameChanged ? _nameController.text.trim() : null,
      phone: phoneChanged ? _phoneController.text.trim() : null,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.error ?? 'Error al actualizar perfil'),
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

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          TextButton(
            onPressed: authService.isLoading ? null : _saveChanges,
            child: authService.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          onChanged: () {
            setState(() {
              _hasChanges = true;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar inicial
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Nombre
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  if (value.length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
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
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                  helperText: 'El correo no se puede modificar',
                  helperStyle: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Ej: +34 123 456 789',
                ),
              ),
              const SizedBox(height: 16),

              // Rol (solo lectura)
              TextFormField(
                initialValue: user.roleDisplayName,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Tipo de cuenta',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'El tipo de cuenta no se puede modificar',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}