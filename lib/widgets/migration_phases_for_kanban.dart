import 'package:cloud_firestore/cloud_firestore.dart';

/// Script de migración para añadir campos Kanban a fases existentes
class PhaseMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Configuración de colores e iconos por fase
  static const Map<String, Map<String, dynamic>> phaseConfig = {
    'planned': {
      'color': '#9C27B0',
      'icon': 'planned',
      'wipLimit': 10,
      'order': 1,
    },
    'cutting': {
      'color': '#2196F3',
      'icon': 'cutting',
      'wipLimit': 8,
      'order': 2,
    },
    'skiving': {
      'color': '#FF9800',
      'icon': 'skiving',
      'wipLimit': 6,
      'order': 3,
    },
    'assembly': {
      'color': '#4CAF50',
      'icon': 'assembly',
      'wipLimit': 8,
      'order': 4,
    },
    'studio': {
      'color': '#F44336',
      'icon': 'studio',
      'wipLimit': 10,
      'order': 5,
    },
  };

  /// Migrar todas las fases de una organización
  Future<void> migrateOrganizationPhases(String organizationId) async {
    try {
      print('🔄 Iniciando migración de fases para organización: $organizationId');
      
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('phases')
          .get();

      if (snapshot.docs.isEmpty) {
        print('⚠️  No se encontraron fases para migrar');
        return;
      }

      final batch = _firestore.batch();
      int updatedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final phaseName = (data['name'] as String?)?.toLowerCase() ?? '';
        
        // Buscar configuración por ID primero, luego por nombre
        Map<String, dynamic>? config = phaseConfig[doc.id];
        
        if (config == null) {
          // Buscar por nombre
          for (var entry in phaseConfig.entries) {
            if (phaseName.contains(entry.key)) {
              config = entry.value;
              break;
            }
          }
        }
        
        // Si no hay config específica, usar valores por defecto
        config ??= {
          'color': '#2196F3',
          'icon': 'work',
          'wipLimit': 10,
          'order': 99,
        };

        // Solo actualizar si los campos no existen
        final updates = <String, dynamic>{};
        
        if (!data.containsKey('color')) {
          updates['color'] = config['color'];
        }
        if (!data.containsKey('icon')) {
          updates['icon'] = config['icon'];
        }
        if (!data.containsKey('wipLimit')) {
          updates['wipLimit'] = config['wipLimit'];
        }
        if (!data.containsKey('kanbanPosition')) {
          updates['kanbanPosition'] = data['order'] ?? config['order'];
        }

        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
          updatedCount++;
          print('  ✓ Fase actualizada: ${doc.id} (${data['name']})');
        } else {
          print('  - Fase ya migrada: ${doc.id} (${data['name']})');
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
        print('✅ Migración completada: $updatedCount fases actualizadas');
      } else {
        print('✅ Todas las fases ya estaban migradas');
      }

    } catch (e) {
      print('❌ Error en la migración: $e');
      rethrow;
    }
  }

  /// Migrar productos de un lote para añadir campos Kanban
  Future<void> migrateBatchProducts({
    required String organizationId,
    required String projectId,
    required String batchId,
  }) async {
    try {
      print('🔄 Iniciando migración de productos del lote: $batchId');
      
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .get();

      if (snapshot.docs.isEmpty) {
        print('⚠️  No se encontraron productos para migrar');
        return;
      }

      final batch = _firestore.batch();
      int updatedCount = 0;

      for (var i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();

        final updates = <String, dynamic>{};
        
        // Añadir campos Kanban si no existen
        if (!data.containsKey('kanbanPosition')) {
          updates['kanbanPosition'] = i;
        }
        if (!data.containsKey('swimlane')) {
          updates['swimlane'] = 'default';
        }
        if (!data.containsKey('isBlocked')) {
          updates['isBlocked'] = false;
        }
        if (!data.containsKey('blockReason')) {
          updates['blockReason'] = null;
        }

        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
          updatedCount++;
          print('  ✓ Producto actualizado: ${doc.id}');
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
        print('✅ Migración completada: $updatedCount productos actualizados');
      } else {
        print('✅ Todos los productos ya estaban migrados');
      }

    } catch (e) {
      print('❌ Error en la migración de productos: $e');
      rethrow;
    }
  }

  /// Migrar todos los lotes de un proyecto
  Future<void> migrateProjectBatches({
    required String organizationId,
    required String projectId,
  }) async {
    try {
      print('🔄 Iniciando migración de lotes del proyecto: $projectId');
      
      final batchesSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .collection('batches')
          .get();

      if (batchesSnapshot.docs.isEmpty) {
        print('⚠️  No se encontraron lotes para migrar');
        return;
      }

      for (var batchDoc in batchesSnapshot.docs) {
        print('\n📦 Migrando lote: ${batchDoc.id}');
        await migrateBatchProducts(
          organizationId: organizationId,
          projectId: projectId,
          batchId: batchDoc.id,
        );
      }

      print('\n✅ Migración de proyecto completada');

    } catch (e) {
      print('❌ Error en la migración del proyecto: $e');
      rethrow;
    }
  }

  /// Verificar estado de migración
  Future<Map<String, dynamic>> checkMigrationStatus(String organizationId) async {
    try {
      final phasesSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('phases')
          .get();

      int totalPhases = phasesSnapshot.docs.length;
      int migratedPhases = 0;

      for (var doc in phasesSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('color') && 
            data.containsKey('icon') && 
            data.containsKey('wipLimit') &&
            data.containsKey('kanbanPosition')) {
          migratedPhases++;
        }
      }

      return {
        'totalPhases': totalPhases,
        'migratedPhases': migratedPhases,
        'pendingPhases': totalPhases - migratedPhases,
        'isComplete': migratedPhases == totalPhases,
      };

    } catch (e) {
      print('❌ Error verificando estado: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Resetear campos Kanban (útil para desarrollo/testing)
  Future<void> resetKanbanFields(String organizationId) async {
    try {
      print('⚠️  ADVERTENCIA: Reseteando campos Kanban');
      print('   Esto eliminará color, icon, wipLimit y kanbanPosition');
      
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('phases')
          .get();

      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'color': FieldValue.delete(),
          'icon': FieldValue.delete(),
          'wipLimit': FieldValue.delete(),
          'kanbanPosition': FieldValue.delete(),
        });
      }

      await batch.commit();
      print('✅ Campos Kanban reseteados');

    } catch (e) {
      print('❌ Error reseteando campos: $e');
      rethrow;
    }
  }
}

// Ejemplo de uso:
/*
void main() async {
  final migrationService = PhaseMigrationService();
  final organizationId = 'tu-org-id';
  
  // Verificar estado
  final status = await migrationService.checkMigrationStatus(organizationId);
  print('Estado: $status');
  
  // Migrar fases
  await migrationService.migrateOrganizationPhases(organizationId);
  
  // Migrar productos de un proyecto
  await migrationService.migrateProjectBatches(
    organizationId: organizationId,
    projectId: 'tu-project-id',
  );
}
*/