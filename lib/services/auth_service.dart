import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Importar storage
import '../models/user_model.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Importar compresor
import 'package:cloud_functions/cloud_functions.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
      bucket: 'gs://production-tracker-top.firebasestorage.app');

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  UserModel? _currentUserData;
  UserModel? get currentUserData => _currentUserData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Registrar nuevo usuario
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Crear usuario en Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar el nombre de usuario en Firebase Auth
      await userCredential.user!.updateDisplayName(name);

      // Crear documento de usuario en Firestore
      final userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        role: role,
        phone: phone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());

      _currentUserData = userModel;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error inesperado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Iniciar sesión
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await loadUserData();

      // Verificar si el usuario está activo
      if (_currentUserData != null && !_currentUserData!.isActive) {
        await signOut();
        _error = 'Tu cuenta ha sido desactivada. Contacta al administrador.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      // Errores específicos de Firebase Auth
      if (e.code == 'email-already-in-use') {
        _error = 'Este correo ya está registrado';
      } else if (e.code == 'wrong-password') {
        _error = 'Contraseña incorrecta';
      } else if (e.code == 'user-not-found') {
        _error = 'Usuario no encontrado';
      } else if (e.code == 'invalid-email') {
        _error = 'Email inválido';
      } else if (e.code == 'weak-password') {
        _error = 'Contraseña muy débil';
      } else {
        _error = _getErrorMessage(e.code);
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Si no es FirebaseAuthException pero sí es un String (el throw anterior), relanzar
      if (e is String) {
        rethrow;
      }

      _error = 'Error inesperado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      // 1. Limpiar datos locales primero
      _currentUserData = null;
      _error = null;
      _isLoading = false;

      // 2. Terminar Firestore para cancelar TODOS los listeners activos.
      // Esto evita el "FIRESTORE INTERNAL ASSERTION FAILED: Unexpected state"
      // que ocurre al cambiar de usuario con streams abiertos.
      // Firestore se reinicia automáticamente en la próxima operación.
      try {
        await FirebaseFirestore.instance.terminate();
        await FirebaseFirestore.instance.clearPersistence();
      } catch (firestoreError) {
        // No es crítico si falla (ej: ya estaba terminado)
        debugPrint('Aviso al terminar Firestore: $firestoreError');
      }

      // 3. Cerrar sesión de Google
      await _googleSignIn.signOut().catchError((e) {
        debugPrint('Error al cerrar sesión de Google: $e');
      });

      // 4. Cerrar sesión de Firebase Auth
      await _auth.signOut();

      notifyListeners();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      // Forzar limpieza aunque haya error
      _currentUserData = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
    }
  }

// Iniciar sesión con Google (VERSIÓN SEGURA)
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 1. Iniciar flujo
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Obtener auth
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception(
            "Tokens de Google nulos. Verifica la configuración de GCP.");
      }

      // 3. Credencial Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Login en Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception("Firebase devolvió un usuario nulo");
      }

      // 5. Verificar Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await signOut();
        _error = 'Este usuario no existe.';
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        // --- USUARIO EXISTENTE ---
        // Aquí suele estar el error: los datos en Firestore están corruptos o incompletos
        try {
          // Usamos el mapa directamente para evitar que fromMap crashee si falta algo
          final data = userDoc.data();
          if (data == null) throw Exception("Documento de usuario vacío");

          // Intenta cargar, si falla fromMap, capturamos el error específico
          _currentUserData = UserModel.fromMap(data);

          if (!_currentUserData!.isActive) {
            await signOut();
            _error = 'Tu cuenta ha sido desactivada.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } catch (e) {
          print("Error al mapear usuario existente: $e");
          // Si el usuario existe pero está corrupto, ¿qué hacemos?
          // Opción: Sobreescribirlo o lanzar error
          throw Exception(
              "Error en tus datos de perfil: $e. Contacta soporte.");
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      // Agregamos stackTrace para ver en consola
      print("Error detallado: $e");
      print(stackTrace);
      _error = 'Error: $e'; // Mostramos el error real en pantalla
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Recuperar contraseña
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al enviar correo de recuperación: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar perfil de usuario
  Future<bool> updateProfile({
    String? name,
    String? phone,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (currentUser == null || _currentUserData == null) {
        throw Exception('Usuario no autenticado');
      }

      // Actualizar nombre en Firebase Auth si cambió
      if (name != null && name != _currentUserData!.name) {
        await currentUser!.updateDisplayName(name);
      }

      // Actualizar en Firestore
      final updatedData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updatedData['name'] = name;
      if (phone != null) updatedData['phone'] = phone;

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updatedData);

      // Recargar datos del usuario
      await loadUserData();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar perfil: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

// Subir foto de perfil (Versión robusta con XFile)
  Future<String?> uploadProfilePhoto(XFile imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      _isLoading = true;
      notifyListeners();

      final ref = _storage.ref().child('users/${user.uid}/profile.png');

      // 1. Leer bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // 2. Comprimir
      final Uint8List compressedBytes =
          await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 256,
        minHeight: 256,
        quality: 85,
        format: CompressFormat.png,
      );

      // 3. Subir
      await ref.putData(
          compressedBytes, SettableMetadata(contentType: 'image/png'));
      final downloadUrl = await ref.getDownloadURL();

      // 4. Actualizar perfil
      await user.updatePhotoURL(downloadUrl);
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadUserData(); // Refrescar datos locales

      _isLoading = false;
      notifyListeners();
      return downloadUrl;
    } catch (e) {
      _error = 'Error al subir foto: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Cambiar contraseña
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (currentUser == null || currentUser!.email == null) {
        throw Exception('Usuario no autenticado');
      }

      // Reautenticar usuario
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );

      await currentUser!.reauthenticateWithCredential(credential);

      // Cambiar contraseña
      await currentUser!.updatePassword(newPassword);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al cambiar contraseña: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cargar datos del usuario desde Firestore
  Future<void> loadUserData() async {
    if (currentUser == null) {
      _currentUserData = null;
      notifyListeners();
      return;
    }

    try {
      final doc =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      if (doc.exists && doc.data() != null) {
        // Usamos un try-catch interno por si el mapeo de datos falla
        try {
          _currentUserData = UserModel.fromMap(doc.data()!);
        } catch (mapError) {
          debugPrint('Error de mapeo en UserModel: $mapError');
          _currentUserData = null;
        }
      } else {
        _currentUserData = null;
      }
    } catch (e) {
      debugPrint('Error al cargar datos del usuario: $e');
      _currentUserData = null;
    } finally {
      // ESTO ES LO MÁS IMPORTANTE:
      // Siempre avisamos a la app que la carga terminó, sea con éxito o error.
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener datos del usuario
  Future<UserModel?> getUserData() async {
    if (_currentUserData != null) return _currentUserData;

    if (currentUser == null) return null;

    await loadUserData();
    return _currentUserData;
  }

  // Mensajes de error traducidos
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Email o contraseña incorrecta';
      case 'invalid-credential':
        return 'Email o contraseña incorrecta';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'requires-recent-login':
        return 'Por seguridad, debes iniciar sesión nuevamente';
      default:
        return 'Error de autenticación';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 1. NUEVA FUNCIÓN: Escucha cambios en tiempo real del usuario
  Stream<UserModel?> get userStream {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      // Asegúrate de que tu UserModel tenga fromMap
      return UserModel.fromMap(snapshot.data()!);
    });
  }

  /// Obtener cliente por ID (one-time)
  Future<UserModel?> getUserById(
    String userId,
  ) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

// ==================== MÉTODOS CLOUD FUNCTIONS ====================

  /// Crear usuario con email/password y unirse a organización
  /// Usa Cloud Function para seguridad
  Future<Map<String, dynamic>?> createUserWithEmailAndJoin({
    required String email,
    required String password,
    required String name,
    String? phone,
    required String invitationId,
    required String organizationId,
    required String roleId,
    String? clientId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Llamar Cloud Function
      final result =
          await _functions.httpsCallable('createUserWithEmailAndJoin').call({
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
        'invitationId': invitationId,
        'organizationId': organizationId,
        'roleId': roleId,
        'clientId': clientId,
      });

      // Iniciar sesión con el nuevo usuario
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cargar datos del usuario
      await loadUserData();

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'userId': result.data['userId'],
        'organizationId': result.data['organizationId'],
      };
    } on FirebaseAuthException catch (e) {
      // Errores específicos de Firebase Auth
      if (e.code == 'email-already-in-use') {
        _error = 'Este correo ya está registrado';
      } else if (e.code == 'wrong-password') {
        _error = 'Contraseña incorrecta';
      } else if (e.code == 'user-not-found') {
        _error = 'Usuario no encontrado';
      } else if (e.code == 'invalid-email') {
        _error = 'Email inválido';
      } else if (e.code == 'weak-password') {
        _error = 'Contraseña muy débil';
      } else {
        _error = _getErrorMessage(e.code);
      }
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Error inesperado: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Unirse a organización con Google Sign-In
  /// Usuario ya está autenticado, solo se une
  Future<Map<String, dynamic>?> joinOrganizationWithGoogle({
    required String invitationId,
    required String organizationId,
    required String roleId,
    String? clientId,
    String? name,
    String? phone,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Verificar que el usuario esté autenticado
      if (_auth.currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Llamar Cloud Function
      final result =
          await _functions.httpsCallable('joinOrganizationWithGoogle').call({
        'invitationId': invitationId,
        'organizationId': organizationId,
        'roleId': roleId,
        'clientId': clientId,
        'name': name ?? _auth.currentUser!.displayName,
        'phone': phone,
      });

      // Recargar datos del usuario
      await loadUserData();

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'userId': result.data['userId'],
        'organizationId': result.data['organizationId'],
      };
    } on FirebaseFunctionsException catch (e) {
      _error = e.message ?? 'Error al unirse';
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Error inesperado: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Sign in with Google (solo autenticación, sin unirse)
  /// Para uso en RegisterScreen antes de unirse
  Future<UserCredential?> signInWithGoogleOnly() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      _isLoading = false;
      notifyListeners();

      return userCredential;
    } catch (e) {
      _error = 'Error con Google Sign-In: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
