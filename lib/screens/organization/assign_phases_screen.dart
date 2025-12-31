import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/phase_model.dart';
import '../../models/user_model.dart';
import '../../services/phase_service.dart';

class AssignPhasesScreen extends StatefulWidget {
  final String organizationId;
  final String operatorId;
  final String operatorName;
  final UserModel currentUser;

  const AssignPhasesScreen({
    Key? key,
    required this.organizationId,
    required this.operatorId,
    required this.operatorName,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<AssignPhasesScreen> createState() => _AssignPhasesScreenState();
}

class _AssignPhasesScreenState extends State<AssignPhasesScreen> {
  final PhaseService _phaseService = PhaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Set<String> _selectedPhaseIds = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentAssignments();
  }

  Future<void> _loadCurrentAssignments() async {
    setState(() => _isLoading = true);

    try {
      final assignmentDoc = await _firestore
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('phaseAssignments')
          .doc(widget.operatorId)
          .get();

      if (assignmentDoc.exists) {
        final data = assignmentDoc.data() as Map<String, dynamic>;
        setState(() {
          _selectedPhaseIds = Set<String>.from(data['phases'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar asignaciones: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAssignments() async {
    setState(() => _isSaving = true);

    try {
      await _phaseService.assignPhasesToUser(
        widget.operatorId,
        widget.organizationId,
        _selectedPhaseIds.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asignaciones guardadas correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asignar Fases'),
            Text(
              widget.operatorName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedPhaseIds.clear();
                });
              },
              child: const Text('Limpiar'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ProductionPhase>>(
              stream: _phaseService.getOrganizationPhasesStream(
                widget.organizationId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final phases = snapshot.data ?? [];
                final activePhases =
                    phases.where((p) => p.isActive).toList();

                if (activePhases.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No hay fases activas disponibles.\nConfigure las fases en la gestión de organización.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Header con información
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selecciona las fases que puede gestionar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedPhaseIds.isEmpty
                                ? 'Sin restricciones (puede gestionar todas)'
                                : '${_selectedPhaseIds.length} fase(s) seleccionada(s)',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Lista de fases
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activePhases.length,
                        itemBuilder: (context, index) {
                          final phase = activePhases[index];
                          final isSelected =
                              _selectedPhaseIds.contains(phase.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: isSelected ? 4 : 1,
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedPhaseIds.add(phase.id);
                                  } else {
                                    _selectedPhaseIds.remove(phase.id);
                                  }
                                });
                              },
                              title: Text(
                                phase.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: phase.description != null
                                  ? Text(phase.description!)
                                  : null,
                              secondary: CircleAvatar(
                                backgroundColor: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                                child: Text(
                                  phase.order.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveAssignments,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
    );
  }
}