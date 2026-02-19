/**
 * Firebase Cloud Functions - Production Tracker
 * v2 API con ESLint
 */

const {setGlobalOptions} = require("firebase-functions/v2/options");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

// Configuración global
setGlobalOptions({
  maxInstances: 3,
  region: "us-central1",
});

// Inicializar Admin SDK
admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

// Configurar transporte de correo
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "sinsin379@gmail.com",
    pass: "msav labv rgnh mmez",
  },
});

// ============================================================
// FUNCIÓN 1: Enviar notificación de solicitud de activación
// ============================================================

exports.sendActivationNotification = onDocumentCreated(
    "activation_requests/{docId}",
    async (event) => {
      const snapshot = event.data;
      if (!snapshot) return;

      const data = snapshot.data();
      const docId = event.params.docId;

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
        return snapshot.ref.update({notificationSent: true});
      } catch (error) {
        console.error("❌ Error enviando correo:", error);
        return null;
      }
    },
);

// ============================================================
// FUNCIÓN 2: Validar código de invitación (Callable)
// ============================================================

exports.validateInvitationCode = onCall(async (request) => {
  const {code} = request.data;

  // Validar input
  if (!code || typeof code !== "string") {
    throw new HttpsError("invalid-argument", "Código inválido");
  }

  try {
    // Buscar código en colección global
    const invitationsSnapshot = await db
        .collection("invitations")
        .where("code", "==", code.toUpperCase())
        .limit(1)
        .get();

    if (invitationsSnapshot.empty) {
      throw new HttpsError("not-found", "Código de invitación no encontrado");
    }

    const invitationDoc = invitationsSnapshot.docs[0];
    const invitation = {
      id: invitationDoc.id,
      ...invitationDoc.data(),
    };

    // Validar estado
    if (invitation.status !== "active") {
      throw new HttpsError(
          "failed-precondition",
          `Invitación ya usada on inválida`,
      );
    }

    // Validar expiración
    const now = admin.firestore.Timestamp.now();
    if (invitation.expiresAt.toMillis() < now.toMillis()) {
      throw new HttpsError(
          "failed-precondition",
          "Esta invitación ha expirado",
      );
    }

    // Validar usos máximos
    if (invitation.usedCount >= invitation.maxUses) {
      throw new HttpsError(
          "failed-precondition",
          "Esta invitación alcanzó el máximo de usos",
      );
    }

    // Retornar invitación válida
    return {
      valid: true,
      invitation: invitation,
    };
  } catch (error) {
    console.error("Error validando invitación:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Error validando invitación");
  }
});

// ============================================================
// FUNCIÓN 3: Crear usuario con email y unirse a organización
// ============================================================

exports.createUserWithEmailAndJoin = onCall(async (request) => {
  const {
    email,
    password,
    name,
    phone,
    invitationId,
    organizationId,
    roleId,
    clientId,
  } = request.data;

  // Validar inputs obligatorios
  if (!email || !password || !name || !invitationId ||
      !organizationId || !roleId) {
    throw new HttpsError("invalid-argument", "Faltan campos obligatorios");
  }

  try {
    // 1. Crear usuario en Firebase Auth
    const userRecord = await auth.createUser({
      email: email,
      password: password,
      displayName: name,
    });

    const userId = userRecord.uid;

    // 2. Crear documento en users/
    await db.collection("users").doc(userId).set({
      uid: userId,
      email: email,
      name: name,
      phone: phone || null,
      organizationId: organizationId,
      role: roleId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 3. Obtener datos del rol
    const roleDoc = await db
        .collection("organizations")
        .doc(organizationId)
        .collection("roles")
        .doc(roleId)
        .get();

    if (!roleDoc.exists) {
      throw new HttpsError("not-found", "Rol no encontrado");
    }

    const role = roleDoc.data();

    // 4. Obtener permisos del cliente si aplica y transformarlos
    let permissionOverrides = null;
    if (clientId) {
      const clientDoc = await db
          .collection("organizations")
          .doc(organizationId)
          .collection("clients")
          .doc(clientId)
          .get();

      if (clientDoc.exists && clientDoc.data().clientPermissions) {
        // Transformar clientPermissions (formato simple)
        //  a PermissionOverridesModel
        permissionOverrides = transformClientPermissionsToOverrides(
            clientDoc.data().clientPermissions,
            userId,
        );
      }
    }

    // 5. Crear miembro en organization/members/
    // TODO: canManageAllPhases segun permiso del rol (obtener de firebase)
    await db
        .collection("organizations")
        .doc(organizationId)
        .collection("members")
        .doc(userId)
        .set({
          userId: userId,
          organizationId: organizationId,
          roleId: roleId,
          roleName: role.name,
          roleColor: role.color,
          clientId: clientId || null,
          permissionOverrides: permissionOverrides,
          assignedPhases: [],
          canManageAllPhases: clientId ? false : true,
          joinedAt: admin.firestore.FieldValue.serverTimestamp(),
          isActive: true,
        });

    // 6. Marcar invitación como usada
    await db.collection("invitations").doc(invitationId).update({
      usedCount: admin.firestore.FieldValue.increment(1),
      usedBy: admin.firestore.FieldValue.arrayUnion(userId),
    });

    // Verificar si alcanzó máximo de usos
    const invDoc = await db.collection("invitations").doc(invitationId).get();
    const inv = invDoc.data();
    if (inv.usedCount >= inv.maxUses) {
      await db.collection("invitations").doc(invitationId).update({
        status: "used",
      });
    }

    // 7. Notificar a miembros existentes
    await notifyMembersNewJoin(organizationId, userId, name, role.name);

    return {
      success: true,
      userId: userId,
      organizationId: organizationId,
    };
  } catch (error) {
    console.error("Error creando usuario:", error);

    // Manejar error de email ya existente
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
          "already-exists",
          "Este correo ya está registrado",
      );
    }

    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Error creando cuenta");
  }
});

// ============================================================
// FUNCIÓN 4: Unirse con Google Sign-In (usuario ya autenticado)
// ============================================================

exports.joinOrganizationWithGoogle = onCall(async (request) => {
  const {invitationId, organizationId, roleId, clientId, name, phone} =
    request.data;

  // Verificar autenticación
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "Debes estar autenticado con Google",
    );
  }

  const userId = request.auth.uid;

  // Validar inputs
  if (!invitationId || !organizationId || !roleId) {
    throw new HttpsError("invalid-argument", "Faltan campos obligatorios");
  }

  try {
    // 1. Actualizar documento del usuario
    await db.collection("users").doc(userId).set({
      uid: userId,
      email: request.auth.token.email || null,
      name: name || request.auth.token.name || "User?",
      phone: phone || null,
      organizationId: organizationId,
      role: roleId,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    // 2. Obtener datos del rol
    const roleDoc = await db
        .collection("organizations")
        .doc(organizationId)
        .collection("roles")
        .doc(roleId)
        .get();

    if (!roleDoc.exists) {
      throw new HttpsError("not-found", "Rol no encontrado");
    }

    const role = roleDoc.data();

    // 3. Obtener permisos del cliente si aplica y transformarlos
    let permissionOverrides = null;
    if (clientId) {
      const clientDoc = await db
          .collection("organizations")
          .doc(organizationId)
          .collection("clients")
          .doc(clientId)
          .get();

      if (clientDoc.exists && clientDoc.data().clientPermissions) {
        // Transformar clientPermissions (formato simple)
        //  a PermissionOverridesModel
        permissionOverrides = transformClientPermissionsToOverrides(
            clientDoc.data().clientPermissions,
            userId,
        );
      }
    }

    // 4. Crear miembro en organization/members/
    await db
        .collection("organizations")
        .doc(organizationId)
        .collection("members")
        .doc(userId)
        .set({
          userId: userId,
          organizationId: organizationId,
          roleId: roleId,
          roleName: role.name,
          roleColor: role.color,
          clientId: clientId || null,
          permissionOverrides: permissionOverrides,
          assignedPhases: [],
          canManageAllPhases: true,
          joinedAt: admin.firestore.FieldValue.serverTimestamp(),
          isActive: true,
        });

    // 5. Marcar invitación como usada
    await db.collection("invitations").doc(invitationId).update({
      usedCount: admin.firestore.FieldValue.increment(1),
      usedBy: admin.firestore.FieldValue.arrayUnion(userId),
    });

    // Verificar si alcanzó máximo de usos
    const invDoc = await db.collection("invitations").doc(invitationId).get();
    const inv = invDoc.data();
    if (inv.usedCount >= inv.maxUses) {
      await db.collection("invitations").doc(invitationId).update({
        status: "used",
      });
    }

    // 6. Notificar a miembros existentes
    const userName = name || request.auth.token.name || "Usuario";
    await notifyMembersNewJoin(organizationId, userId, userName, role.name);

    return {
      success: true,
      userId: userId,
      organizationId: organizationId,
    };
  } catch (error) {
    console.error("Error uniéndose con Google:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Error uniéndose a organización");
  }
});

// ============================================================
// HELPER: Transformar clientPermissions a PermissionOverridesModel
// ============================================================

/**
 * Transforma clientPermissions (formato simple) a PermissionOverridesModel
 *
 * Formato entrada: { "batches.create": true, "projects.view": "assigned" }
 * Formato salida: {
 *   "batches.create": {
 *     moduleKey: "batches",
 *     actionKey: "create",
 *     type: "enable",
 *     value: true,
 *     createdAt: Timestamp,
 *     createdBy: "system"
 *   },
 *   "projects.view": {
 *     moduleKey: "projects",
 *     actionKey: "view",
 *     type: "change_scope",
 *     value: "assigned",
 *     createdAt: Timestamp,
 *     createdBy: "system"
 *   }
 * }
 *
 * @param {Object} clientPermissions - Permisos del cliente en formato simple
 * @param {string} createdBy - ID del usuario que crea (o "system")
 * @return {Object} PermissionOverridesModel en formato Firestore
 */
function transformClientPermissionsToOverrides(clientPermissions, createdBy) {
  if (!clientPermissions || typeof clientPermissions !== "object") {
    return {};
  }

  const overrides = {};
  const now = admin.firestore.Timestamp.now();

  Object.entries(clientPermissions).forEach(([key, value]) => {
    // Separar moduleKey.actionKey
    const parts = key.split(".");
    if (parts.length !== 2) {
      console.warn(`⚠️ Formato inválido de permiso: ${key}`);
      return;
    }

    const [moduleKey, actionKey] = parts;

    // Determinar el tipo de override según el valor
    let type;
    let normalizedValue;

    if (typeof value === "boolean") {
      // Boolean: enable si true, disable si false
      type = value ? "enable" : "disable";
      normalizedValue = value;
    } else if (typeof value === "string") {
      // String: debe ser un scope (all, assigned, none)
      const validScopes = ["all", "assigned", "none"];
      if (!validScopes.includes(value)) {
        console.warn(`⚠️ Scope inválido para ${key}: ${value}`);
        return;
      }
      type = "change_scope";
      normalizedValue = value;
    } else {
      console.warn(`⚠️ Tipo de valor no soportado para ${key}:
         ${typeof value}`);
      return;
    }

    // Crear entry del override
    overrides[key] = {
      moduleKey: moduleKey,
      actionKey: actionKey,
      type: type,
      value: normalizedValue,
      reason: "Client permissions",
      createdAt: now,
      createdBy: createdBy || "system",
    };
  });

  return overrides;
}

// ============================================================
// HELPER: Transformar clientPermissions a PermissionOverridesModel
//  - Callable desde Flutter
// ============================================================

exports.applyClientPermissions = onCall(async (request) => {
  const {organizationId, clientId, clientPermissions} = request.data;

  // Verificar autenticación
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "Debes estar autenticado con Google",
    );
  }

  if (!organizationId || !clientId || !clientPermissions) {
    throw new HttpsError(
        "invalid-argument",
        "Faltan parámetros: organizationId, clientId, clientPermissions.");
  }

  const createdBy = request.auth.uid;

  const permissionOverrides =
  transformClientPermissionsToOverrides(clientPermissions, createdBy);

  const membersSnapshot = await admin.firestore()
      .collection("organizations")
      .doc(organizationId)
      .collection("members")
      .where("roleId", "==", "client")
      .where("clientId", "==", clientId)
      .get();

  if (membersSnapshot.empty) {
    return {success: true, updatedCount: 0};
  }

  const batch = admin.firestore().batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  membersSnapshot.docs.forEach((memberDoc) => {
    batch.update(memberDoc.ref, {
      "permissionOverrides": permissionOverrides,
      "updatedAt": now,
    });
  });

  await batch.commit();

  console.log(`✅ applyClientPermissions: ${membersSnapshot.size}
     miembros actualizados para cliente ${clientId}`);

  return {success: true, updatedCount: membersSnapshot.size};
});

// ============================================================
// HELPER: Notificar a miembros de nueva incorporación
// ============================================================

/**
 * Notifica a todos los miembros de una organización cuando alguien se une
 * @param {string} organizationId - ID de la organización
 * @param {string} newUserId - ID del nuevo usuario
 * @param {string} newUserName - Nombre del nuevo usuario
 * @param {string} roleName - Nombre del rol asignado
 */
async function notifyMembersNewJoin(
    organizationId,
    newUserId,
    newUserName,
    roleName,
) {
  try {
    // Obtener todos los miembros excepto el nuevo
    const membersSnapshot = await db
        .collection("organizations")
        .doc(organizationId)
        .collection("members")
        .where("isActive", "==", true)
        .get();

    const destinationUserIds = membersSnapshot.docs
        .map((doc) => doc.id)
        .filter((id) => id !== newUserId);

    if (destinationUserIds.length === 0) {
      console.log("No hay miembros a notificar");
      return;
    }

    // Crear notificación maestra
    const notificationRef = await db
        .collection("organizations")
        .doc(organizationId)
        .collection("notifications")
        .add({
          type: "member_joined",
          title: "Nuevo miembro",
          message: `${newUserName} se ha unido como ${roleName}`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: admin.firestore.Timestamp.fromDate(
              new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          ), // 7 días
          status: "active",
          priority: "info",
          destinationUserIds: destinationUserIds,
          organizationId: organizationId,
          relatedEntityType: "member",
          relatedEntityId: newUserId,
        });

    // Crear referencias individuales para cada usuario
    const batch = db.batch();
    destinationUserIds.forEach((userId) => {
      const userNotifRef = db
          .collection("organizations")
          .doc(organizationId)
          .collection("user_notifications")
          .doc(userId)
          .collection("items")
          .doc(notificationRef.id);

      batch.set(userNotifRef, {
        notificationId: notificationRef.id,
        read: false,
        resolved: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
    console.log(`✅ Notificación enviada a ${destinationUserIds.length}
       miembros`);
  } catch (error) {
    console.error("Error notificando miembros:", error);
    // No lanzar error, solo loguear
  }
}

// ============================================================
// FUNCIÓN 5: Migrar permisos de usuarios clientes existentes
// ============================================================

/**
 * Función administrativa para migrar permissionOverrides de usuarios
 * con rol de cliente desde el formato antiguo al nuevo formato
 *
 * Esta función debe ser llamada UNA VEZ para migrar datos existentes
 * Requiere autenticación y permisos de admin
 */
exports.migrateClientPermissionOverrides = onCall(async (request) => {
  // Verificar autenticación
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes estar autenticado");
  }

  const {organizationId, dryRun} = request.data;

  // Validar inputs
  if (!organizationId || typeof organizationId !== "string") {
    throw new HttpsError("invalid-argument", "organizationId requerido");
  }

  // Verificar que el usuario sea admin de la organización
  const callerMemberDoc = await db
      .collection("organizations")
      .doc(organizationId)
      .collection("members")
      .doc(request.auth.uid)
      .get();

  if (!callerMemberDoc.exists) {
    throw new HttpsError(
        "permission-denied",
        "No eres miembro de esta organización",
    );
  }

  const callerMember = callerMemberDoc.data();

  // Verificar que tenga permisos de admin (roleId === 'admin' o legacy role)
  const isAdmin =
    callerMember.roleId === "owner" || callerMember.role === "admin";
  if (!isAdmin) {
    throw new HttpsError(
        "permission-denied",
        "Solo administradores pueden ejecutar esta migración",
    );
  }

  try {
    console.log(`🔄 Iniciando migración de permisos en org: ${organizationId}`);
    console.log(`   Modo: ${dryRun ? "DRY RUN (simulación)" : "REAL"}`);

    const results = {
      processed: 0,
      migrated: 0,
      skipped: 0,
      errors: 0,
      details: [],
    };

    // 1. Obtener todos los miembros con clientId (usuarios cliente)
    const membersSnapshot = await db
        .collection("organizations")
        .doc(organizationId)
        .collection("members")
        .where("clientId", "!=", null)
        .get();

    console.log(`   Encontrados ${membersSnapshot.size} miembros con clientId`);

    // 2. Procesar cada miembro
    for (const memberDoc of membersSnapshot.docs) {
      results.processed++;
      const memberId = memberDoc.id;
      const member = memberDoc.data();

      try {
        // Obtener el cliente asociado
        if (!member.clientId) {
          results.skipped++;
          results.details.push({
            userId: memberId,
            status: "skipped",
            reason: "Sin clientId",
          });
          continue;
        }

        const clientDoc = await db
            .collection("organizations")
            .doc(organizationId)
            .collection("clients")
            .doc(member.clientId)
            .get();

        if (!clientDoc.exists) {
          results.skipped++;
          results.details.push({
            userId: memberId,
            status: "skipped",
            reason: "Cliente no encontrado",
          });
          continue;
        }

        const client = clientDoc.data();

        // Verificar si tiene clientPermissions en formato antiguo
        if (!client.clientPermissions ||
            typeof client.clientPermissions !== "object" ||
            Object.keys(client.clientPermissions).length === 0) {
          results.skipped++;
          results.details.push({
            userId: memberId,
            status: "skipped",
            reason: "Cliente sin clientPermissions",
          });
          continue;
        }

        // Verificar si ya tiene permissionOverrides en formato nuevo
        const currentOverrides = member.permissionOverrides;
        const hasNewFormat =
          currentOverrides &&
          typeof currentOverrides === "object" &&
          Object.values(currentOverrides).some(
              (override) => override && override.moduleKey &&
               override.actionKey,
          );

        if (hasNewFormat) {
          results.skipped++;
          results.details.push({
            userId: memberId,
            status: "skipped",
            reason: "Ya tiene formato nuevo",
          });
          continue;
        }

        // Transformar permisos
        const newOverrides = transformClientPermissionsToOverrides(
            client.clientPermissions,
            "migration-script",
        );

        console.log(`   ✅ Migrando usuario ${memberId}:`);
        console.log(`      - Overrides antiguos:`, member.permissionOverrides);
        console.log(`      - Overrides nuevos:`, newOverrides);

        // Actualizar en Firestore (solo si no es dry run)
        if (!dryRun) {
          await memberDoc.ref.update({
            permissionOverrides: newOverrides,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        results.migrated++;
        results.details.push({
          userId: memberId,
          userName: member.userName || "Unknown",
          clientId: member.clientId,
          status: "migrated",
          oldOverrides: member.permissionOverrides,
          newOverrides: newOverrides,
        });
      } catch (error) {
        console.error(`   ❌ Error procesando ${memberId}:`, error);
        results.errors++;
        results.details.push({
          userId: memberId,
          status: "error",
          error: error.message,
        });
      }
    }

    console.log(`✅ Migración completada:`);
    console.log(`   - Procesados: ${results.processed}`);
    console.log(`   - Migrados: ${results.migrated}`);
    console.log(`   - Omitidos: ${results.skipped}`);
    console.log(`   - Errores: ${results.errors}`);

    return {
      success: true,
      dryRun: dryRun || false,
      summary: {
        processed: results.processed,
        migrated: results.migrated,
        skipped: results.skipped,
        errors: results.errors,
      },
      details: results.details,
    };
  } catch (error) {
    console.error("❌ Error en migración:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Error ejecutando migración");
  }
});
