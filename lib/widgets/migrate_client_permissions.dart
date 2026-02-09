// ignore_for_file: avoid_print

import 'package:cloud_functions/cloud_functions.dart';

/// Script para migrar permisos de usuarios clientes desde formato antiguo a nuevo
///
/// Este script debe ser ejecutado UNA VEZ por organización por un administrador
///
/// **Formato Antiguo (clientPermissions en formato simple):**
/// ```
/// permissionOverrides: {
///   "batches.create": true,
///   "projects.view": "assigned"
/// }
/// ```
///
/// **Formato Nuevo (PermissionOverridesModel completo):**
/// ```
/// permissionOverrides: {
///   "batches.create": {
///     moduleKey: "batches",
///     actionKey: "create",
///     type: "enable",
///     value: true,
///     reason: "Client permissions",
///     createdAt: Timestamp,
///     createdBy: "system"
///   },
///   "projects.view": {
///     moduleKey: "projects",
///     actionKey: "view",
///     type: "change_scope",
///     value: "assigned",
///     reason: "Client permissions",
///     createdAt: Timestamp,
///     createdBy: "system"
///   }
/// }
/// ```
class ClientPermissionMigration {
  /// Ejecutar migración de permisos de clientes
  ///
  /// [organizationId] - ID de la organización a migrar
  /// [dryRun] - Si es true, solo simula sin hacer cambios reales (default: true)
  ///
  /// Retorna un Map con el resultado de la migración:
  /// ```dart
  /// {
  ///   "success": true,
  ///   "dryRun": true,
  ///   "summary": {
  ///     "processed": 5,
  ///     "migrated": 3,
  ///     "skipped": 2,
  ///     "errors": 0
  ///   },
  ///   "details": [...]
  /// }
  /// ```
  static Future<Map<String, dynamic>> migrate({
    required String organizationId,
    bool dryRun = true,
  }) async {
    try {
      print('🔄 Iniciando migración de permisos...');
      print('   Organización: $organizationId');
      print('   Modo: ${dryRun ? "DRY RUN (simulación)" : "REAL"}');

      if (dryRun) {
        print('   ⚠️  Esto es una simulación. Los cambios NO se aplicarán.');
        print('   ⚠️  Para aplicar cambios reales, usa dryRun: false');
      }

      final functions = FirebaseFunctions.instance;
      final callable =
          functions.httpsCallable('migrateClientPermissionOverrides');

      final result = await callable.call({
        'organizationId': organizationId,
        'dryRun': dryRun,
      });

      final data = Map<String, dynamic>.from(result.data as Map);

      _printResults(data, dryRun);

      return data;
    } catch (e) {
      print('❌ Error ejecutando migración: $e');
      rethrow;
    }
  }

  /// Imprimir resultados de forma legible
  static void _printResults(Map<String, dynamic> data, bool dryRun) {
    print('\n✅ Migración ${dryRun ? "simulada" : "completada"} exitosamente\n');

    final summary = Map<String, dynamic>.from(data['summary'] as Map);
    final details = List<Map<String, dynamic>>.from((data['details'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map)));

    print('📊 RESUMEN:');
    print('   - Procesados: ${summary['processed']}');
    print('   - Migrados:   ${summary['migrated']}');
    print('   - Omitidos:   ${summary['skipped']}');
    print('   - Errores:    ${summary['errors']}');

    if (details.isNotEmpty) {
      print('\n📋 DETALLES:');

      // Usuarios migrados
      final migrated = details.where((d) => d['status'] == 'migrated').toList();
      if (migrated.isNotEmpty) {
        print('\n   ✅ Usuarios migrados (${migrated.length}):');
        for (final detail in migrated) {
          print('      - ${detail['userName'] ?? detail['userId']}');
          print('        Cliente: ${detail['clientId']}');
          if (detail['newOverrides'] != null) {
            final overrides = Map<String, dynamic>.from(detail['newOverrides'] as Map);
            print('        Permisos: ${overrides.keys.join(', ')}');
          }
        }
      }

      // Usuarios omitidos
      final skipped = details.where((d) => d['status'] == 'skipped').toList();
      if (skipped.isNotEmpty) {
        print('\n   ⏭️  Usuarios omitidos (${skipped.length}):');
        for (final detail in skipped) {
          print('      - ${detail['userId']}: ${detail['reason']}');
        }
      }

      // Errores
      final errors = details.where((d) => d['status'] == 'error').toList();
      if (errors.isNotEmpty) {
        print('\n   ❌ Errores (${errors.length}):');
        for (final detail in errors) {
          print('      - ${detail['userId']}: ${detail['error']}');
        }
      }
    }

    if (dryRun) {
      print('\n⚠️  RECORDATORIO: Esto fue una SIMULACIÓN');
      print('   Para aplicar los cambios realmente, ejecuta con dryRun: false');
    } else {
      print('\n✅ Cambios aplicados exitosamente en Firebase');
    }
  }
}

/// Ejemplo de uso desde la app:
/// 
/// ```dart
/// // 1. Primero hacer un dry run para ver qué se migrará
/// await ClientPermissionMigration.migrate(
///   organizationId: 'cde33a84-f9e7-4cf0-833d-bc4674ad3b7',
///   dryRun: true, // Simulación
/// );
/// 
/// // 2. Si todo se ve bien, ejecutar la migración real
/// await ClientPermissionMigration.migrate(
///   organizationId: 'cde33a84-f9e7-4cf0-833d-bc4674ad3b7',
///   dryRun: false, // Aplicar cambios reales
/// );
/// ```
/// 
/// También puedes crear un botón temporal en la pantalla de administración:
/// 
/// ```dart
/// if (isAdmin) {
///   ElevatedButton(
///     onPressed: () async {
///       final confirm = await showDialog<bool>(
///         context: context,
///         builder: (context) => AlertDialog(
///           title: Text('Migrar permisos de clientes'),
///           content: Text('¿Deseas migrar los permisos al nuevo formato?'),
///           actions: [
///             TextButton(
///               onPressed: () => Navigator.pop(context, false),
///               child: Text('Cancelar'),
///             ),
///             ElevatedButton(
///               onPressed: () => Navigator.pop(context, true),
///               child: Text('Migrar'),
///             ),
///           ],
///         ),
///       );
///       
///       if (confirm == true) {
///         final result = await ClientPermissionMigration.migrate(
///           organizationId: currentUser.organizationId!,
///           dryRun: false,
///         );
///         
///         ScaffoldMessenger.of(context).showSnackBar(
///           SnackBar(content: Text('Migración completada: ${result['summary']['migrated']} usuarios')),
///         );
///       }
///     },
///     child: Text('Migrar permisos'),
///   ),
/// }
/// ```