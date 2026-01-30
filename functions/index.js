/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

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
setGlobalOptions({ maxInstances: 3 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// Enviar correo al recibir una nueva solicitud de activación
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Configura el transporte (Ejemplo con Gmail, pero idealmente usa SendGrid/Brevo)
// Si usas Gmail, necesitas generar una "Contraseña de aplicación" en tu cuenta Google.
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "sinsin379@gmail.com",
    pass: "Pok3rMa5t3r15",
  },
});

exports.sendActivationNotification = functions.firestore
  .document("activation_requests/{docId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    const mailOptions = {
      from: "Production Tracker <sinsin379@gmail.com>",
      to: "sinsin379@gmail.com", // A donde llega el aviso
      subject: `🚀 Nueva Solicitud de organización: ${data.companyName}`,
      html: `
        <h1>Nueva solicitud de activación de organización</h1>
        <p>Has recibido una nueva petición en la app.</p>
        <ul>
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
      console.log("Correo de notificación enviado correctamente");
      
      // Opcional: Actualizar el documento para marcar que se notificó
      return snap.ref.update({ notificationSent: true });
    } catch (error) {
      console.error("Error enviando correo:", error);
      return null;
    }
  });