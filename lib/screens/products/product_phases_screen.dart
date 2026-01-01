import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/phase_model.dart'; // Necesario para el modelo
import '../../services/phase_service.dart';
import '../../widgets/phase_progress_widget.dart';

class ProductPhasesScreen extends StatefulWidget {
  final String organizationId;
  final String projectId;
  final String productId;
  final String productName;
  final UserModel currentUser;

  const ProductPhasesScreen({
    Key? key,
    required this.organizationId,
    required this.projectId,
    required this.productId,
    required this.productName,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ProductPhasesScreen> createState() => _ProductPhasesScreenState();
}

class _ProductPhasesScreenState extends State<ProductPhasesScreen> {
  final PhaseService _phaseService = PhaseService();
  bool _isInitializing = false;

  // Roles que pueden gestionar la estructura de fases (Admin y Jefe de Producción)
  bool get _canManageStructure {
    final role = widget.currentUser.role.toLowerCase();
    return role == 'admin' || role == 'production_manager';
  }

  // Roles de solo lectura (Cliente y Contable)
  bool get _isReadOnly {
    final role = widget.currentUser.role.toLowerCase();
    return role == 'client' || role == 'contable';
  }

  Future<void> _initializePhases() async {
    setState(() => _isInitializing = true);
    try {
      // Usamos el servicio existente para copiar las fases de la organización al producto
      await _phaseService.initializeProductPhases(
        widget.organizationId,
        widget.projectId,
        widget.productId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fases inicializadas correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _resetPhases() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar Fases'),
        content: const Text(
          '¿Estás seguro? Esto borrará el progreso actual y volverá a copiar las fases activas de la organización. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Nota: El servicio actual no tiene un método explícito "deleteProductPhases".
      // La inicialización (initializeProductPhases) usa 'set' en el documento, 
      // por lo que sobrescribirá los documentos existentes con los nuevos valores por defecto.
      // Esto efectivamente reinicia el progreso.
      await _initializePhases();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fases de Producción'),
            Text(
              widget.productName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Opción para administradores: Reiniciar/Actualizar fases si cambian en la organización
          if (_canManageStructure)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'reset') _resetPhases();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.restore, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Reiniciar/Sincronizar fases'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      // Usamos un StreamBuilder aquí para determinar si mostrar el Widget de Progreso
      // o el botón de Inicialización.
      body: StreamBuilder<List<ProductPhaseProgress>>(
        stream: _phaseService.getProductPhaseProgressStream(
          widget.organizationId,
          widget.projectId,
          widget.productId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final phases = snapshot.data ?? [];

          // ESTADO 1: NO HAY FASES (Inicialización necesaria)
          if (phases.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.settings_suggest,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Producto sin flujo de producción',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[700],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Este producto aún no tiene fases asignadas. Inicialízalo para comenzar el seguimiento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    if (_canManageStructure)
                      _isInitializing
                          ? const CircularProgressIndicator()
                          : FilledButton.icon(
                              onPressed: _initializePhases,
                              icon: const Icon(Icons.play_circle_outline),
                              label: const Text('Inicializar Fases de Producción'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline,
                                color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Contacta con un administrador\npara configurar las fases.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          // ESTADO 2: HAY FASES (Gestión normal)
          // Reutilizamos el widget existente para no duplicar lógica de UI
          return PhaseProgressWidget(
            organizationId: widget.organizationId,
            projectId: widget.projectId,
            productId: widget.productId,
            currentUser: widget.currentUser,
            isReadOnly: _isReadOnly,
          );
        },
      ),
    );
  }
}