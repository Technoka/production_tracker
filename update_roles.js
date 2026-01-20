const admin = require('firebase-admin');
// Asegúrate de que el nombre del archivo coincida con tu clave descargada
const serviceAccount = require('./scripts/serviceAccountKey.json');

// Inicializar Firebase
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

// ID de la organización específica
const ORGANIZATION_ID = 'cde33a84-f9e7-4cf0-833d-bc46724ad3b7';

async function updateRoles() {
  console.log(`🚀 Iniciando actualización de roles para la organización: ${ORGANIZATION_ID}...`);

  try {
    // 1. Obtener referencia a la colección de roles
    const rolesRef = db.collection('organizations').doc(ORGANIZATION_ID).collection('roles');
    const snapshot = await rolesRef.get();

    if (snapshot.empty) {
      console.log('❌ No se encontraron roles en esta organización.');
      return;
    }

    // Usamos un batch para que todas las escrituras sean atómicas y eficientes
    const batch = db.batch();
    let updateCount = 0;

    snapshot.docs.forEach(doc => {
      const roleId = doc.id;
      const data = doc.data();
      
      // Asegurarnos de que existe el objeto permissions, si no, lo creamos
      let permissions = data.permissions || {};
      let hasChanges = false;

      // --- TAREA 1: RENOMBRAR CATALOG A PRODUCT_CATALOG ---
      if (permissions.products) {
        console.log(`   [${roleId}] Renombrando 'products' a 'batch_products'...`);
        
        // Copiar datos a la nueva key
        permissions.batch_products = permissions.products;
        
        // Eliminar la key antigua
        delete permissions.products;
        
        hasChanges = true;
      } else if (permissions.batch_products) {
        console.log(`   [${roleId}] 'batch_products' ya existe, saltando renombrado.`);
      }

      // --- TAREA 2: AÑADIR PERMISOS SLA ---

      // Solo si hubo cambios (que siempre habrá por el SLA), añadimos al batch
      if (hasChanges) {
        batch.update(doc.ref, { permissions: permissions });
        updateCount++;
      }
    });

    // Ejecutar todos los cambios
    await batch.commit();
    console.log(`\n✅ Actualización completada con éxito. ${updateCount} roles actualizados.`);

  } catch (error) {
    console.error('❌ Error actualizando roles:', error);
  }
}

// Ejecutar la función
updateRoles();