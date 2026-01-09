const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
const releaseData = require('./release_data.json');

// 1. Inicializar Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function uploadRelease() {
  try {
    console.log(`🚀 Preparando lanzamiento v${releaseData.version}...`);

    // Convertir 1.0.0 a 1_0_0 para el ID del documento
    const docId = releaseData.version.replace(/\./g, '_');
    
    // Preparar el objeto con Timestamp de servidor
    const payload = {
      ...releaseData,
      date: admin.firestore.FieldValue.serverTimestamp() // Fecha automática
    };

    // Subir a Firestore
    await db.collection('releases').doc(docId).set(payload);

    console.log(`✅ ¡ÉXITO! Novedades de v${releaseData.version} subidas a Firestore.`);
    console.log(`ID del documento: ${docId}`);

  } catch (error) {
    console.error('❌ Error subiendo novedades:', error);
  } finally {
    process.exit(); // Cerrar el proceso
  }
}

uploadRelease();