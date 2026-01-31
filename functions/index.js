/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 3, region: "us-central1"});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// Enviar correo al recibir una nueva solicitud de activación
/**
 * Import function triggers from their respective submodules:
 * See: https://firebase.google.com/docs/functions
 */
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
// const { setGlobalOptions } = require("firebase-functions/v2/options");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

// Inicializar la app de admin (necesario si vas a escribir en BD)
admin.initializeApp();

// Configurar transporte de correo (GMAIL o SMTP)
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "sinsin379@gmail.com",
    pass: "msav labv rgnh mmez",
  },
});

exports.sendActivationNotification = onDocumentCreated(
    "activation_requests/{docId}",
    async (event) => {
      // 1. En v2, 'event.data' es el snapshot del documento
      const snapshot = event.data;

      // Si no hay datos (ej: borrado), salimos
      if (!snapshot) {
        return;
      }

      const data = snapshot.data();
      const docId = event.params.docId; // Acceso a los parámetros {}

      const mailOptions = {
        from: "Production Tracker <sinsin379@gmail.com>",
        to: "davidpp00@outlook.com",
        subject: `🚀 Nueva Solicitud: ${data.companyName}`,
        html: `
          <h1>Nueva solicitud de activación</h1>
          <p>Has recibido una nueva petición en la app.</p>
          <ul>
            <li><strong>ID:</strong> ${docId}</li>
            <li><strong>Empresa:</strong> ${data.companyName}</li>
            <li><strong>Contacto:</strong> ${data.contactName}</li>
            <li><strong>Email:</strong> ${data.contactEmail}</li>
            <li><strong>Teléfono:</strong> ${data.contactPhone}</li>
            <li><strong>Mensaje:</strong> ${data.message || "Sin mensaje"}</li>
          </ul>
          <p>Fecha: ${new Date().toLocaleString()}</p>
        `,
      };

      try {
        await transporter.sendMail(mailOptions);
        console.log("✅ Correo enviado correctamente a", data.contactEmail);

        // Opcional: Marcar como notificado en Firestore
        // Usamos snapshot.ref para obtener la referencia al documento
        return snapshot.ref.update({notificationSent: true});
      } catch (error) {
        console.error("❌ Error enviando correo:", error);
        return null;
      }
    },
);
