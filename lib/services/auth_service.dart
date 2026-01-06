import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Importar storage
import '../models/user_model.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Importar compresor

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'gs://production-tracker-top.firebasestorage.app'
  );
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
      String error = 'Ha ocurrido un error: ${e.message}';
      _isLoading = false;
      notifyListeners();
      if (e.code == 'user-not-found') {
      error = 'El usuario no existe.';
    } else if (e.code == 'wrong-password') {
      error = 'Contraseña incorrecta.';
    } else if (e.code == 'invalid-email') {
      error = 'El formato del correo es inválido.';
    }
      // Lanzamos una excepción que capturaremos en la UI para mostrar el SnackBar
      throw error;
    } catch (e) {
      _error = 'Error inesperado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      // Limpiar datos locales primero
      _currentUserData = null;
      _error = null;
      _isLoading = false;
      
      // Cerrar sesión de Google primero (sin await para evitar bloqueos)
      _googleSignIn.signOut().catchError((e) {
        debugPrint('Error al cerrar sesión de Google: $e');
      });
      
      // Cerrar sesión de Firebase
      await _auth.signOut();
      
      // Notificar cambios
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
  Future<bool> signInWithGoogle({String? role}) async {
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
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception("Tokens de Google nulos. Verifica la configuración de GCP.");
      }

      // 3. Credencial Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Login en Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception("Firebase devolvió un usuario nulo");
      }

      // 5. Verificar Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // --- USUARIO NUEVO ---
        if (role == null) {
          await signOut();
          _error = 'Selecciona un tipo de cuenta'; // Este string exacto es el que espera tu LoginScreen
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // Validación defensiva del email
        final email = user.email;
        if (email == null) {
          throw Exception("Tu cuenta de Google no comparte el email. No podemos registrarte.");
        }

        final userModel = UserModel(
          uid: user.uid,
          email: email, 
          name: user.displayName ?? 'Usuario',
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          // Asegúrate de pasar todos los campos que tu modelo requiera
        );

        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
        _currentUserData = userModel;
        
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
          throw Exception("Error en tus datos de perfil: $e. Contacta soporte.");
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
    } catch (e, stackTrace) { // Agregamos stackTrace para ver en consola
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
      final Uint8List compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 256,
        minHeight: 256,
        quality: 85,
        format: CompressFormat.png,
      );

      // 3. Subir
      await ref.putData(compressedBytes, SettableMetadata(contentType: 'image/png'));
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
    final doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    
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
        return 'La contraseña actual es incorrecta';
      case 'invalid-credential':
        return 'La contraseña actual es incorrecta';
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
      final doc = await _firestore
          .collection('users')
            .doc(userId)
          .get();

      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
}