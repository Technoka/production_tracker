/**
 * Script de Migración de Permisos de Firebase
 * 
 * Este script:
 * 1. Lee la estructura de permisos correcta desde permissionRegistry
 * 2. Actualiza todos los roles en todas las organizaciones
 * 3. Elimina campos obsoletos que no existen en permission_registry_model.dart
 * 4. Añade campos faltantes con valores apropiados según el rol
 * 
 * USO:
 * 1. Instalar: npm install firebase-admin
 * 2. Descargar serviceAccountKey.json de Firebase Console
 * 3. Ejecutar: node migrate_permissions.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./scripts/serviceAccountKey.json');

// Inicializar Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// ==================== ESTRUCTURA DE PERMISOS CORRECTA (desde permission_registry_model.dart) ====================

const PERMISSION_REGISTRY = {
  kanban: {
    view: { type: 'boolean' },
    moveProducts: { type: 'scoped' },
    editProductDetails: { type: 'scoped' }
  },
  phases: {
    view: { type: 'boolean' },
    create: { type: 'boolean' },
    edit: { type: 'boolean' },
    delete: { type: 'boolean' },
    assignToMembers: { type: 'boolean' },
    manageTransitions: { type: 'boolean' }
  },
  batches: {
    view: { type: 'scoped' },
    create: { type: 'boolean' },
    edit: { type: 'scoped' },
    delete: { type: 'scoped' },
    startProduction: { type: 'boolean' },
    completeBatch: { type: 'boolean' }
  },
  batch_products: {
    view: { type: 'scoped' },
    create: { type: 'boolean' },
    edit: { type: 'scoped' },
    delete: { type: 'scoped' },
    changeStatus: { type: 'scoped' },
    changeUrgency: { type: 'scoped' }
  },
  projects: {
    view: { type: 'scoped' },
    create: { type: 'boolean' },
    edit: { type: 'scoped' },
    delete: { type: 'scoped' },
    assignMembers: { type: 'boolean' }
  },
  product_catalog: {
    view: { type: 'boolean' },
    create: { type: 'boolean' },
    edit: { type: 'boolean' },
    delete: { type: 'boolean' }
  },
  clients: {
    view: { type: 'boolean' },
    create: { type: 'boolean' },
    edit: { type: 'boolean' },
    delete: { type: 'boolean' }
  },
  chat: {
    view: { type: 'boolean' },
    send: { type: 'boolean' },
    delete: { type: 'boolean' },
    pin: { type: 'boolean' },
    viewInternal: { type: 'boolean' }
  },
  organization: {
    viewMembers: { type: 'boolean' },
    inviteMembers: { type: 'boolean' },
    removeMembers: { type: 'boolean' },
    manageRoles: { type: 'boolean' },
    manageSettings: { type: 'boolean' }
  },
  reports: {
    view: { type: 'boolean' },
    generate: { type: 'boolean' },
    export: { type: 'boolean' }
  },
  sla: {
    view: { type: 'boolean' },
    configure: { type: 'boolean' },
    manageAlerts: { type: 'boolean' }
  }
};

// ==================== PERMISOS POR ROL ====================

const ROLE_PERMISSIONS = {
  owner: {
    kanban: { view: true, moveProducts: 'all', editProductDetails: 'all' },
    phases: { view: true, create: true, edit: true, delete: true, assignToMembers: true, manageTransitions: true },
    batches: { view: 'all', create: true, edit: 'all', delete: 'all', startProduction: true, completeBatch: true },
    batch_products: { view: 'all', create: true, edit: 'all', delete: 'all', changeStatus: 'all', changeUrgency: 'all' },
    projects: { view: 'all', create: true, edit: 'all', delete: 'all', assignMembers: true },
    product_catalog: { view: true, create: true, edit: true, delete: true },
    clients: { view: true, create: true, edit: true, delete: true },
    chat: { view: true, send: true, delete: true, pin: true, viewInternal: true },
    organization: { viewMembers: true, inviteMembers: true, removeMembers: true, manageRoles: true, manageSettings: true },
    reports: { view: true, generate: true, export: true },
    sla: { view: true, configure: true, manageAlerts: true }
  },
  admin: {
    kanban: { view: true, moveProducts: 'all', editProductDetails: 'all' },
    phases: { view: true, create: true, edit: true, delete: true, assignToMembers: true, manageTransitions: true },
    batches: { view: 'all', create: true, edit: 'all', delete: 'all', startProduction: true, completeBatch: true },
    batch_products: { view: 'all', create: true, edit: 'all', delete: 'all', changeStatus: 'all', changeUrgency: 'all' },
    projects: { view: 'all', create: true, edit: 'all', delete: 'all', assignMembers: true },
    product_catalog: { view: true, create: true, edit: true, delete: true },
    clients: { view: true, create: true, edit: true, delete: true },
    chat: { view: true, send: true, delete: true, pin: true, viewInternal: true },
    organization: { viewMembers: true, inviteMembers: true, removeMembers: true, manageRoles: true, manageSettings: false },
    reports: { view: true, generate: true, export: true },
    sla: { view: true, configure: true, manageAlerts: true }
  },
  production_manager: {
    kanban: { view: true, moveProducts: 'all', editProductDetails: 'all' },
    phases: { view: true, create: false, edit: true, delete: false, assignToMembers: true, manageTransitions: false },
    batches: { view: 'all', create: true, edit: 'all', delete: 'assigned', startProduction: true, completeBatch: true },
    batch_products: { view: 'all', create: true, edit: 'all', delete: 'assigned', changeStatus: 'all', changeUrgency: 'all' },
    projects: { view: 'all', create: true, edit: 'all', delete: 'assigned', assignMembers: true },
    product_catalog: { view: true, create: true, edit: true, delete: false },
    clients: { view: true, create: true, edit: true, delete: false },
    chat: { view: true, send: true, delete: false, pin: true, viewInternal: true },
    organization: { viewMembers: true, inviteMembers: true, removeMembers: false, manageRoles: false, manageSettings: false },
    reports: { view: true, generate: true, export: true },
    sla: { view: true, configure: false, manageAlerts: true }
  },
  operator: {
    kanban: { view: true, moveProducts: 'assigned', editProductDetails: 'assigned' },
    phases: { view: true, create: false, edit: false, delete: false, assignToMembers: false, manageTransitions: false },
    batches: { view: 'assigned', create: false, edit: 'assigned', delete: 'none', startProduction: false, completeBatch: false },
    batch_products: { view: 'assigned', create: false, edit: 'assigned', delete: 'none', changeStatus: 'assigned', changeUrgency: 'none' },
    projects: { view: 'assigned', create: false, edit: 'none', delete: 'none', assignMembers: false },
    product_catalog: { view: true, create: false, edit: false, delete: false },
    clients: { view: false, create: false, edit: false, delete: false },
    chat: { view: true, send: true, delete: false, pin: false, viewInternal: false },
    organization: { viewMembers: true, inviteMembers: false, removeMembers: false, manageRoles: false, manageSettings: false },
    reports: { view: false, generate: false, export: false },
    sla: { view: false, configure: false, manageAlerts: false }
  },
  quality_control: {
    kanban: { view: true, moveProducts: 'all', editProductDetails: 'all' },
    phases: { view: true, create: false, edit: false, delete: false, assignToMembers: false, manageTransitions: false },
    batches: { view: 'all', create: false, edit: 'assigned', delete: 'none', startProduction: false, completeBatch: false },
    batch_products: { view: 'all', create: false, edit: 'all', delete: 'none', changeStatus: 'all', changeUrgency: 'assigned' },
    projects: { view: 'all', create: false, edit: 'none', delete: 'none', assignMembers: false },
    product_catalog: { view: true, create: false, edit: false, delete: false },
    clients: { view: true, create: false, edit: false, delete: false },
    chat: { view: true, send: true, delete: false, pin: false, viewInternal: true },
    organization: { viewMembers: true, inviteMembers: false, removeMembers: false, manageRoles: false, manageSettings: false },
    reports: { view: true, generate: false, export: false },
    sla: { view: true, configure: false, manageAlerts: false }
  },
  client: {
    kanban: { view: false, moveProducts: 'none', editProductDetails: 'none' },
    phases: { view: false, create: false, edit: false, delete: false, assignToMembers: false, manageTransitions: false },
    batches: { view: 'assigned', create: false, edit: 'none', delete: 'none', startProduction: false, completeBatch: false },
    batch_products: { view: 'assigned', create: false, edit: 'none', delete: 'none', changeStatus: 'none', changeUrgency: 'none' },
    projects: { view: 'assigned', create: false, edit: 'none', delete: 'none', assignMembers: false },
    product_catalog: { view: true, create: false, edit: false, delete: false },
    clients: { view: false, create: false, edit: false, delete: false },
    chat: { view: true, send: true, delete: false, pin: false, viewInternal: false },
    organization: { viewMembers: false, inviteMembers: false, removeMembers: false, manageRoles: false, manageSettings: false },
    reports: { view: false, generate: false, export: false },
    sla: { view: false, configure: false, manageAlerts: false }
  }
};

// ==================== FUNCIONES DE MIGRACIÓN ====================

/**
 * Convierte permisos del rol a la estructura correcta de Firebase
 */
function buildPermissionsStructure(roleId) {
  const rolePermissions = ROLE_PERMISSIONS[roleId];
  
  if (!rolePermissions) {
    console.warn(`⚠️  Rol desconocido: ${roleId}, usando permisos vacíos`);
    return buildEmptyPermissions();
  }

  const permissions = {};

  for (const [moduleKey, moduleActions] of Object.entries(PERMISSION_REGISTRY)) {
    permissions[moduleKey] = {};
    const roleModulePerms = rolePermissions[moduleKey] || {};

    for (const [actionKey, actionDef] of Object.entries(moduleActions)) {
      const roleValue = roleModulePerms[actionKey];

      if (actionDef.type === 'scoped') {
        // Para acciones scoped: 
        // - Si es string ('all', 'assigned', 'none'), el permiso base es true
        // - Si es boolean false, el permiso es false y scope es 'none'
        
        if (typeof roleValue === 'string') {
          permissions[moduleKey][actionKey] = true;
          permissions[moduleKey][`${actionKey}Scope`] = roleValue;
        } else {
          permissions[moduleKey][actionKey] = roleValue || false;
          permissions[moduleKey][`${actionKey}Scope`] = roleValue ? 'all' : 'none';
        }
      } else {
        // Para acciones boolean: simplemente true/false
        permissions[moduleKey][actionKey] = roleValue || false;
      }
    }
  }

  return permissions;
}

/**
 * Construye permisos vacíos (todos en false/none)
 */
function buildEmptyPermissions() {
  const permissions = {};

  for (const [moduleKey, moduleActions] of Object.entries(PERMISSION_REGISTRY)) {
    permissions[moduleKey] = {};

    for (const [actionKey, actionDef] of Object.entries(moduleActions)) {
      if (actionDef.type === 'scoped') {
        permissions[moduleKey][actionKey] = false;
        permissions[moduleKey][`${actionKey}Scope`] = 'none';
      } else {
        permissions[moduleKey][actionKey] = false;
      }
    }
  }

  return permissions;
}

/**
 * Limpiar campos obsoletos de permisos existentes
 */
function cleanObsoleteFields(existingPermissions) {
  const cleaned = { ...existingPermissions };
  const validModules = Object.keys(PERMISSION_REGISTRY);

  // 1. Eliminar módulos que ya no existen
  for (const moduleKey of Object.keys(cleaned)) {
    if (!validModules.includes(moduleKey)) {
      console.log(`   🗑️  Eliminando módulo obsoleto: ${moduleKey}`);
      delete cleaned[moduleKey];
    }
  }

  // 2. Eliminar acciones obsoletas dentro de cada módulo
  for (const [moduleKey, moduleActions] of Object.entries(PERMISSION_REGISTRY)) {
    if (!cleaned[moduleKey]) continue;

    const validActions = Object.keys(moduleActions);
    const modulePerms = cleaned[moduleKey];

    for (const actionKey of Object.keys(modulePerms)) {
      // Ignorar campos *Scope (se validarán con su acción base)
      if (actionKey.endsWith('Scope')) continue;

      if (!validActions.includes(actionKey)) {
        console.log(`   🗑️  Eliminando acción obsoleta: ${moduleKey}.${actionKey}`);
        delete modulePerms[actionKey];
        // También eliminar el scope si existe
        delete modulePerms[`${actionKey}Scope`];
      }
    }
  }

  return cleaned;
}

/**
 * Migrar un rol individual
 */
async function migrateRole(orgId, roleDoc) {
  const roleId = roleDoc.id;
  const roleData = roleDoc.data();
  
  console.log(`\n   📝 Migrando rol: ${roleId} (${roleData.name})`);

  // 1. Construir nueva estructura de permisos
  const newPermissions = buildPermissionsStructure(roleId);

  // 2. Limpiar campos obsoletos de permisos existentes (si existen)
  const existingPermissions = roleData.permissions || {};
  const cleanedExisting = cleanObsoleteFields(existingPermissions);

  // 3. Merge: priorizar nuevos valores pero respetar overrides manuales si los hay
  const finalPermissions = { ...newPermissions };

  // 4. Actualizar en Firebase
  try {
    await db
      .collection('organizations')
      .doc(orgId)
      .collection('roles')
      .doc(roleId)
      .update({
        permissions: finalPermissions,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

    console.log(`   ✅ Rol migrado: ${roleId}`);
    return { success: true, roleId };
  } catch (error) {
    console.error(`   ❌ Error migrando rol ${roleId}:`, error.message);
    return { success: false, roleId, error: error.message };
  }
}

/**
 * Migrar una organización completa
 */
async function migrateOrganization(orgDoc) {
  const orgId = orgDoc.id;
  const orgData = orgDoc.data();
  
  console.log(`\n🏢 Migrando organización: ${orgData.name} (${orgId})`);

  try {
    // Obtener todos los roles de la organización
    const rolesSnapshot = await db
      .collection('organizations')
      .doc(orgId)
      .collection('roles')
      .get();

    if (rolesSnapshot.empty) {
      console.log(`   ⚠️  No hay roles en esta organización`);
      return { success: true, orgId, rolesCount: 0 };
    }

    console.log(`   📊 Encontrados ${rolesSnapshot.size} roles`);

    // Migrar cada rol
    const results = [];
    for (const roleDoc of rolesSnapshot.docs) {
      const result = await migrateRole(orgId, roleDoc);
      results.push(result);
    }

    const successCount = results.filter(r => r.success).length;
    const failCount = results.filter(r => !r.success).length;

    console.log(`\n   ✅ Organización migrada: ${successCount} roles exitosos, ${failCount} fallidos`);
    
    return {
      success: true,
      orgId,
      rolesCount: rolesSnapshot.size,
      successCount,
      failCount,
      results
    };
  } catch (error) {
    console.error(`   ❌ Error migrando organización ${orgId}:`, error.message);
    return {
      success: false,
      orgId,
      error: error.message
    };
  }
}

/**
 * Función principal de migración
 */
async function migrateAllOrganizations() {
  console.log('🚀 Iniciando migración de permisos...\n');
  console.log('📋 Estructura de permisos válida:');
  console.log(JSON.stringify(Object.keys(PERMISSION_REGISTRY), null, 2));
  console.log('');

  try {
    // Obtener todas las organizaciones
    const orgsSnapshot = await db.collection('organizations').get();

    if (orgsSnapshot.empty) {
      console.log('⚠️  No se encontraron organizaciones');
      return;
    }

    console.log(`📊 Encontradas ${orgsSnapshot.size} organizaciones\n`);
    console.log('━'.repeat(60));

    // Migrar cada organización
    const results = [];
    for (const orgDoc of orgsSnapshot.docs) {
      const result = await migrateOrganization(orgDoc);
      results.push(result);
      console.log('━'.repeat(60));
    }

    // Resumen final
    console.log('\n📊 RESUMEN DE MIGRACIÓN:');
    console.log('═'.repeat(60));
    
    const totalOrgs = results.length;
    const successOrgs = results.filter(r => r.success).length;
    const failOrgs = results.filter(r => !r.success).length;
    const totalRoles = results.reduce((sum, r) => sum + (r.rolesCount || 0), 0);
    const totalSuccess = results.reduce((sum, r) => sum + (r.successCount || 0), 0);
    const totalFail = results.reduce((sum, r) => sum + (r.failCount || 0), 0);

    console.log(`\n🏢 Organizaciones:`);
    console.log(`   Total: ${totalOrgs}`);
    console.log(`   ✅ Exitosas: ${successOrgs}`);
    console.log(`   ❌ Fallidas: ${failOrgs}`);
    
    console.log(`\n📝 Roles:`);
    console.log(`   Total: ${totalRoles}`);
    console.log(`   ✅ Migrados: ${totalSuccess}`);
    console.log(`   ❌ Fallidos: ${totalFail}`);

    if (totalFail > 0) {
      console.log('\n⚠️  Errores encontrados:');
      results.forEach(org => {
        if (org.results) {
          org.results.filter(r => !r.success).forEach(role => {
            console.log(`   - ${org.orgId}/${role.roleId}: ${role.error}`);
          });
        }
      });
    }

    console.log('\n✅ Migración completada');
    console.log('═'.repeat(60));

  } catch (error) {
    console.error('\n❌ Error fatal durante la migración:', error);
    throw error;
  }
}

// ==================== EJECUTAR MIGRACIÓN ====================

migrateAllOrganizations()
  .then(() => {
    console.log('\n👋 Proceso finalizado');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n💥 Error fatal:', error);
    process.exit(1);
  });