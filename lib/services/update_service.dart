import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/release_note_model.dart';

class UpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _lastSeenVersionKey = 'last_seen_version';

  /// Verifica si hay novedades que mostrar.
  /// Retorna el modelo con las notas si debe mostrarse, o null si no.
  Future<ReleaseNoteModel?> checkForUpdates() async {
    try {
      // 1. Obtener versión actual de la App (del pubspec.yaml)
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 2. Obtener última versión vista (Local - Gratis)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? lastSeenVersion = prefs.getString(_lastSeenVersionKey);

      // Si las versiones son iguales, no hacemos nada (ahorramos lectura DB)
      if (lastSeenVersion == currentVersion) {
        return null;
      }

      // 3. Si son diferentes, buscamos las notas en Firestore (1 Lectura)
      // Convertimos "1.0.5" a "1_0_5" para usarlo como ID
      String docId = currentVersion.replaceAll('.', '_');
      
      final doc = await _firestore.collection('releases').doc(docId).get();

      if (!doc.exists) {
        // Si no hay doc para esta versión, simplemente actualizamos la local para no volver a buscar
        await markVersionAsSeen(); 
        return null;
      }

      final data = doc.data();
      if (data == null || data['isActive'] == false) return null;

      return ReleaseNoteModel.fromMap(data);

    } catch (e) {
      print('Error checking for updates: $e');
      return null;
    }
  }

  /// Marca la versión actual como vista para que no vuelva a salir
  Future<void> markVersionAsSeen() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenVersionKey, packageInfo.version);
  }
}