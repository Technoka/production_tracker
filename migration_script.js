const admin = require('firebase-admin');
const serviceAccount = require('./scripts/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();

async function migrateToNewPermissionSystem() {
  console.log('🚀 Iniciando migración al nuevo sistema de permisos...');
  
  try {
    // 1. Obtener todas las organizaciones
    const orgsSnapshot = await db.collection('organizations').get();
    
    for (const orgDoc of orgsSnapshot.docs) {
      const orgId = orgDoc.id;
      const orgData = orgDoc.data();
      
      console.log(`\n📦 Procesando organización: ${orgData.name} (${orgId})`);
      
      // 1.1 Inicializar roles predeterminados
      // await initializeRoles(orgId, orgData.ownerId);
      
      // 1.2 Migrar miembros existentes
      // await migrateMembersForOrganization(orgId, orgData);
      
      // 1.3 Inicializar estados de producto
      // await initializeStatuses(orgId, orgData.ownerId);
      
      // 1.4 Inicializar transiciones de estado
      // await initializeTransitions(orgId, orgData.ownerId);
      
      // 1.5 Actualizar lotes con assignedMembers
      // await addAssignedMembersToBatches(orgId);
      
      // 1.6 Añadir campos de estado a productos
      await addStatusFieldsToProducts(orgId);
      
      // 1.7 Verificar proyectos
      // await verifyProjectsAssignedMembers(orgId);
      
      // 1.8 Marcar organización como migrada
      // await orgDoc.ref.update({
      //   statusesInitialized: true,
      //   migratedToNewPermissions: true,
      //   migrationDate: admin.firestore.FieldValue.serverTimestamp()
      // });
      
      console.log(`✅ Organización ${orgData.name} migrada exitosamente`);
    }
    
    console.log('\n🎉 ¡Migración completada exitosamente!');
    
  } catch (error) {
    console.error('❌ Error en migración:', error);
    throw error;
  }
}

// 1. Inicializar roles predeterminados
async function initializeRoles(orgId, createdBy) {
  console.log('  → Inicializando roles...');
  
  const roles = [
    {
      id: 'owner',
      name: 'Owner',
      description: 'Acceso completo a toda la organización',
      color: '#9C27B0',
      isSystem: true,
      isDefault: false,
      permissions: {
        kanban: { view: true, edit: true },
        batches: {
          view: true, viewScope: 'all',
          create: true,
          edit: true, editScope: 'all',
          delete: true, deleteScope: 'all',
          startProduction: true,
          completeBatch: true,
          addProducts: true
        },
        products: {
          view: true, viewScope: 'all',
          move: true,
          changeStatus: true
        },
        projects: {
          view: true, viewScope: 'all',
          create: true,
          edit: true, editScope: 'all',
          delete: true
        },
        clients: { view: true, create: true, edit: true, delete: true },
        catalog: { view: true, create: true, edit: true, delete: true },
        phases: { view: true, create: true, edit: true, delete: true },
        chat: { view: true, send: true, delete: true },
        organization: {
          viewSettings: true,
          editSettings: true,
          manageMembers: true,
          manageRoles: true
        }
      }
    },
    {
      id: 'admin',
      name: 'Administrador',
      description: 'Gestión completa excepto eliminación de organización',
      color: '#F44336',
      isSystem: true,
      isDefault: false,
      permissions: {
        kanban: { view: true, edit: true },
        batches: {
          view: true, viewScope: 'all',
          create: true,
          edit: true, editScope: 'all',
          delete: true, deleteScope: 'all',
          startProduction: true,
          completeBatch: true,
          addProducts: true
        },
        products: {
          view: true, viewScope: 'all',
          move: true,
          changeStatus: true
        },
        projects: {
          view: true, viewScope: 'all',
          create: true,
          edit: true, editScope: 'all',
          delete: true
        },
        clients: { view: true, create: true, edit: true, delete: true },
        catalog: { view: true, create: true, edit: true, delete: true },
        phases: { view: true, create: true, edit: true, delete: true },
        chat: { view: true, send: true, delete: true },
        organization: {
          viewSettings: true,
          editSettings: true,
          manageMembers: true,
          manageRoles: false
        }
      }
    },
    {
      id: 'production_manager',
      name: 'Gestor de Producción',
      description: 'Gestión completa de producción y lotes',
      color: '#2196F3',
      isSystem: true,
      isDefault: false,
      permissions: {
        kanban: { view: true, edit: true },
        batches: {
          view: true, viewScope: 'all',
          create: true,
          edit: true, editScope: 'all',
          delete: false,
          startProduction: true,
          completeBatch: true,
          addProducts: true
        },
        products: {
          view: true, viewScope: 'all',
          move: true,
          changeStatus: true
        },
        projects: {
          view: true, viewScope: 'all',
          create: true,
          edit: true, editScope: 'all',
          delete: false
        },
        clients: { view: true, create: true, edit: true, delete: false },
        catalog: { view: true, create: true, edit: true, delete: false },
        phases: { view: true, create: false, edit: false, delete: false },
        chat: { view: true, send: true, delete: false },
        organization: {
          viewSettings: true,
          editSettings: false,
          manageMembers: false,
          manageRoles: false
        }
      }
    },
    {
      id: 'operator',
      name: 'Operario',
      description: 'Operación de fases asignadas',
      color: '#4CAF50',
      isSystem: true,
      isDefault: true,
      permissions: {
        kanban: { view: true, edit: false },
        batches: {
          view: true, viewScope: 'assigned',
          create: false,
          edit: false,
          delete: false,
          startProduction: false,
          completeBatch: false,
          addProducts: false
        },
        products: {
          view: true, viewScope: 'assigned',
          move: true,  // Solo en sus fases asignadas
          changeStatus: false
        },
        projects: {
          view: true, viewScope: 'assigned',
          create: false,
          edit: false,
          delete: false
        },
        clients: { view: true, create: false, edit: false, delete: false },
        catalog: { view: true, create: false, edit: false, delete: false },
        phases: { view: true, create: false, edit: false, delete: false },
        chat: { view: true, send: true, delete: false },
        organization: {
          viewSettings: false,
          editSettings: false,
          manageMembers: false,
          manageRoles: false
        }
      }
    },
    {
      id: 'quality_control',
      name: 'Control de Calidad',
      description: 'Gestión de estados y calidad de productos',
      color: '#FF9800',
      isSystem: true,
      isDefault: false,
      permissions: {
        kanban: { view: true, edit: true },
        batches: {
          view: true, viewScope: 'all',
          create: false,
          edit: false,
          delete: false,
          startProduction: false,
          completeBatch: false,
          addProducts: false
        },
        products: {
          view: true, viewScope: 'all',
          move: false,
          changeStatus: true  // Su función principal
        },
        projects: {
          view: true, viewScope: 'all',
          create: false,
          edit: false,
          delete: false
        },
        clients: { view: true, create: false, edit: false, delete: false },
        catalog: { view: true, create: false, edit: false, delete: false },
        phases: { view: true, create: false, edit: false, delete: false },
        chat: { view: true, send: true, delete: false },
        organization: {
          viewSettings: false,
          editSettings: false,
          manageMembers: false,
          manageRoles: false
        }
      }
    },
    {
      id: 'client',
      name: 'Cliente',
      description: 'Ver sus proyectos y productos',
      color: '#607D8B',
      isSystem: true,
      isDefault: false,
      permissions: {
        kanban: { view: false, edit: false },
        batches: {
          view: true, viewScope: 'assigned',
          create: false,
          edit: false,
          delete: false,
          startProduction: false,
          completeBatch: false,
          addProducts: false
        },
        products: {
          view: true, viewScope: 'assigned',
          move: false,
          changeStatus: false
        },
        projects: {
          view: true, viewScope: 'assigned',
          create: false,
          edit: false,
          delete: false
        },
        clients: { view: false, create: false, edit: false, delete: false },
        catalog: { view: false, create: false, edit: false, delete: false },
        phases: { view: false, create: false, edit: false, delete: false },
        chat: { view: true, send: true, delete: false },
        organization: {
          viewSettings: false,
          editSettings: false,
          manageMembers: false,
          manageRoles: false
        }
      }
    }
  ];
  
  const batch = db.batch();
  
  for (const role of roles) {
    const roleRef = db.collection('organizations')
      .doc(orgId)
      .collection('roles')
      .doc(role.id);
    
    batch.set(roleRef, {
      ...role,
      organizationId: orgId,
      createdBy: createdBy,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
  
  await batch.commit();
  console.log(`    ✓ ${roles.length} roles creados`);
}

// 2. Migrar miembros existentes
async function migrateMembersForOrganization(orgId, orgData) {
  console.log('  → Migrando miembros...');
  
  const memberIds = orgData.memberIds || [];
  const adminIds = orgData.adminIds || [];
  const ownerId = orgData.ownerId;
  
  let migratedCount = 0;
  
  for (const userId of memberIds) {
    try {
      // Obtener datos del usuario
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        console.log(`    ⚠️  Usuario ${userId} no encontrado, saltando...`);
        continue;
      }
      
      const userData = userDoc.data();
      const legacyRole = userData.role || 'operator';
      
      // Determinar roleId según sistema legacy
      let roleId = 'operator'; // default
      
      if (userId === ownerId) {
        roleId = 'owner';
      } else if (adminIds.includes(userId)) {
        roleId = 'admin';
      } else {
        // Mapear roles legacy a nuevos roles
        const roleMapping = {
          'admin': 'admin',
          'production_manager': 'production_manager',
          'manufacturer': 'production_manager', // legacy
          'operator': 'operator',
          'quality_control': 'quality_control',
          'client': 'client'
        };
        roleId = roleMapping[legacyRole] || 'operator';
      }
      
      // Obtener rol para denormalizar
      const roleDoc = await db.collection('organizations')
        .doc(orgId)
        .collection('roles')
        .doc(roleId)
        .get();
      
      if (!roleDoc.exists) {
        console.log(`    ⚠️  Rol ${roleId} no encontrado para usuario ${userId}`);
        continue;
      }
      
      const roleData = roleDoc.data();
      
      // Crear documento de miembro
      await db.collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(userId)
        .set({
          userId: userId,
          organizationId: orgId,
          roleId: roleId,
          roleName: roleData.name,
          roleColor: roleData.color,
          role: legacyRole, // Mantener por compatibilidad
          assignedPhases: [],
          canManageAllPhases: roleId !== 'operator',
          joinedAt: userData.createdAt || admin.firestore.FieldValue.serverTimestamp(),
          isActive: true
        });
      
      migratedCount++;
      
    } catch (error) {
      console.log(`    ❌ Error migrando usuario ${userId}:`, error.message);
    }
  }
  
  console.log(`    ✓ ${migratedCount} miembros migrados`);
}

// 3. Inicializar estados predeterminados
async function initializeStatuses(orgId, createdBy) {
  console.log('  → Inicializando estados de producto...');
  
  const statuses = [
    {
      id: 'pending',
      name: 'Pendiente',
      description: 'Producto en espera de iniciar producción',
      color: '#757575',
      icon: 'schedule',
      order: 0,
      isDefault: true,
      isActive: true
    },
    {
      id: 'hold',
      name: 'Hold',
      description: 'Producto enviado al cliente para evaluación',
      color: '#FF9800',
      icon: 'pause_circle_outline',
      order: 1,
      isDefault: true,
      isActive: true
    },
    {
      id: 'cao',
      name: 'CAO',
      description: 'Producto con defectos reportados por el cliente',
      color: '#F44336',
      icon: 'report_problem',
      order: 2,
      isDefault: true,
      isActive: true
    },
    {
      id: 'control',
      name: 'Control',
      description: 'Producto en control de calidad para clasificación',
      color: '#2196F3',
      icon: 'fact_check',
      order: 3,
      isDefault: true,
      isActive: true
    },
    {
      id: 'ok',
      name: 'OK',
      description: 'Producto aprobado y finalizado',
      color: '#4CAF50',
      icon: 'check_circle',
      order: 4,
      isDefault: true,
      isActive: true
    }
  ];
  
  const batch = db.batch();
  
  for (const status of statuses) {
    const statusRef = db.collection('organizations')
      .doc(orgId)
      .collection('product_statuses')
      .doc(status.id);
    
    batch.set(statusRef, {
      ...status,
      organizationId: orgId,
      createdBy: createdBy,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
  
  await batch.commit();
  console.log(`    ✓ ${statuses.length} estados creados`);
}

// 4. Inicializar transiciones predeterminadas
async function initializeTransitions(orgId, createdBy) {
  console.log('  → Inicializando transiciones de estado...');
  
  const transitions = [
    {
      fromStatusId: 'pending',
      toStatusId: 'hold',
      fromStatusName: 'Pendiente',
      toStatusName: 'Hold',
      validationType: 'none',
      validationConfig: {},
      allowedRoles: ['owner', 'admin', 'production_manager']
    },
    {
      fromStatusId: 'hold',
      toStatusId: 'ok',
      fromStatusName: 'Hold',
      toStatusName: 'OK',
      validationType: 'simple_approval',
      validationConfig: {},
      allowedRoles: ['owner', 'admin', 'quality_control']
    },
    {
      fromStatusId: 'hold',
      toStatusId: 'cao',
      fromStatusName: 'Hold',
      toStatusName: 'CAO',
      validationType: 'quantity_and_text',
      validationConfig: {
        quantityLabel: 'Cantidad defectuosa',
        quantityMin: 1,
        quantityPlaceholder: 'Ej: 3',
        textLabel: 'Descripción del defecto',
        textMinLength: 10,
        textMaxLength: 500,
        textPlaceholder: 'Describe el problema...'
      },
      conditionalLogic: {
        field: 'quantity',
        operator: 'greaterThan',
        value: 5,
        action: {
          type: 'require_approval',
          parameters: {
            requiredRoles: ['admin', 'production_manager']
          }
        }
      },
      allowedRoles: ['owner', 'admin', 'quality_control']
    },
    {
      fromStatusId: 'cao',
      toStatusId: 'control',
      fromStatusName: 'CAO',
      toStatusName: 'Control',
      validationType: 'simple_approval',
      validationConfig: {},
      allowedRoles: ['owner', 'admin', 'quality_control']
    },
    {
      fromStatusId: 'control',
      toStatusId: 'ok',
      fromStatusName: 'Control',
      toStatusName: 'OK',
      validationType: 'simple_approval',
      validationConfig: {},
      allowedRoles: ['owner', 'admin', 'quality_control']
    }
  ];
  
  const batch = db.batch();
  
  for (const transition of transitions) {
    const transitionRef = db.collection('organizations')
      .doc(orgId)
      .collection('status_transitions')
      .doc();
    
    batch.set(transitionRef, {
      ...transition,
      isActive: true,
      organizationId: orgId,
      createdBy: createdBy,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
  
  await batch.commit();
  console.log(`    ✓ ${transitions.length} transiciones creadas`);
}

// 5. Añadir assignedMembers a lotes
async function addAssignedMembersToBatches(orgId) {
  console.log('  → Actualizando lotes con assignedMembers...');
  
  const batchesSnapshot = await db.collection('organizations')
    .doc(orgId)
    .collection('production_batches')
    .get();
  
  let updatedCount = 0;
  const batch = db.batch();
  
  for (const batchDoc of batchesSnapshot.docs) {
    const batchData = batchDoc.data();
    
    // Si ya tiene assignedMembers, saltar
    if (batchData.assignedMembers && batchData.assignedMembers.length > 0) {
      continue;
    }
    
    // Por defecto, asignar al creador
    const assignedMembers = [batchData.createdBy];
    
    batch.update(batchDoc.ref, {
      assignedMembers: assignedMembers
    });
    
    updatedCount++;
  }
  
  if (updatedCount > 0) {
    await batch.commit();
  }
  
  console.log(`    ✓ ${updatedCount} lotes actualizados`);
}

// 6. Añadir campos de estado a productos
async function addStatusFieldsToProducts(orgId) {
  console.log('  → Actualizando productos con campos de estado...');
  
  const batchesSnapshot = await db.collection('organizations')
    .doc(orgId)
    .collection('production_batches')
    .get();
  
  let totalUpdated = 0;
  
  for (const batchDoc of batchesSnapshot.docs) {
    const productsSnapshot = await batchDoc.ref
      .collection('batch_products')
      .get();
    
    if (productsSnapshot.empty) continue;
    
    const batch = db.batch();
    let batchCount = 0;
    
    for (const productDoc of productsSnapshot.docs) {
      const productData = productDoc.data();
      
      // Si ya tiene statusId, saltar
      if (productData.statusId) {
        continue;
      }
      
      // Estado inicial: pending
      batch.update(productDoc.ref, {
        statusId: 'pending',
        statusName: 'Pendiente',
        statusColor: '#757575',
        statusHistory: [
          {
            statusId: 'pending',
            statusName: 'Pendiente',
            statusColor: '#757575',
            timestamp: productData.createdAt || admin.firestore.FieldValue.serverTimestamp(),
            userId: productData.createdBy || 'system',
            userName: 'Sistema'
          }
        ]
      });
      
      batchCount++;
    }
    
    if (batchCount > 0) {
      await batch.commit();
      totalUpdated += batchCount;
    }
  }
  
  console.log(`    ✓ ${totalUpdated} productos actualizados`);
}

// 7. Verificar proyectos
async function verifyProjectsAssignedMembers(orgId) {
  console.log('  → Verificando proyectos...');
  
  const projectsSnapshot = await db.collection('organizations')
    .doc(orgId)
    .collection('projects')
    .get();
  
  let missingCount = 0;
  const batch = db.batch();
  
  for (const projectDoc of projectsSnapshot.docs) {
    const projectData = projectDoc.data();
    
    // Si no tiene assignedMembers, añadir el creador
    if (!projectData.assignedMembers || projectData.assignedMembers.length === 0) {
      batch.update(projectDoc.ref, {
        assignedMembers: [projectData.createdBy]
      });
      missingCount++;
    }
  }
  
  if (missingCount > 0) {
    await batch.commit();
    console.log(`    ✓ ${missingCount} proyectos actualizados`);
  } else {
    console.log(`    ✓ Todos los proyectos tienen assignedMembers`);
  }
}

// Exportar función para Cloud Functions
exports.migrateToNewPermissionSystem = migrateToNewPermissionSystem;

// Para ejecutar manualmente (descomentar si ejecutas en Cloud Shell):
migrateToNewPermissionSystem()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });