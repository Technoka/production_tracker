import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

      await _loadUserData();

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

  // Cerrar sesión
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _currentUserData = null;
    notifyListeners();
  }

  // Iniciar sesión con Google
  Future<bool> signInWithGoogle({String? role}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Iniciar el flujo de autenticación de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Obtener los detalles de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Verifica que los tokens no sean nulos antes de crear la credencial
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw Exception("No se pudo obtener la autenticación de Google");
      }

      // Crear credencial para Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase con la credencial de Google
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Verificar si el usuario ya existe en Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Es un nuevo usuario, necesita elegir rol
        if (role == null) {
          // Si no se proporcionó rol, cerrar sesión y pedir rol
          await signOut();
          _error = 'Por favor selecciona un tipo de cuenta';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // Crear documento de usuario en Firestore
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? 'Usuario',
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toMap());

        _currentUserData = userModel;
      } else {
        // Usuario existente, cargar datos
        await _loadUserData();

        // Verificar si el usuario está activo
        if (_currentUserData != null && !_currentUserData!.isActive) {
          await signOut();
          _error = 'Tu cuenta ha sido desactivada. Contacta al administrador.';
          _isLoading = false;
          notifyListeners();
          return false;
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
    } catch (e) {
      _error = 'Error al iniciar sesión con Google: $e';
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
      await _loadUserData();

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
  Future<void> _loadUserData() async {
    if (currentUser == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        _currentUserData = UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error al cargar datos del usuario: $e');
    }
  }

  // Obtener datos del usuario
  Future<UserModel?> getUserData() async {
    if (_currentUserData != null) return _currentUserData;

    if (currentUser == null) return null;

    await _loadUserData();
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
        return 'Contraseña incorrecta';
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
}