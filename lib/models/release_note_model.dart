import 'package:cloud_firestore/cloud_firestore.dart';

class ReleaseNoteModel {
  final String version;
  final DateTime date;
  // Ahora guardamos el mapa completo de idiomas
  final Map<String, List<String>> featuresMap;
  final Map<String, List<String>> fixesMap;

  ReleaseNoteModel({
    required this.version,
    required this.date,
    required this.featuresMap,
    required this.fixesMap,
  });

  factory ReleaseNoteModel.fromMap(Map<String, dynamic> map) {
    // Helper para convertir el JSON en Mapa de Listas de Strings
    Map<String, List<String>> parseLocalizedList(dynamic data) {
      if (data == null) return {};
      final result = <String, List<String>>{};
      
      if (data is Map) {
        data.forEach((key, value) {
          if (value is List) {
            result[key.toString()] = List<String>.from(value);
          }
        });
      }
      return result;
    }

    return ReleaseNoteModel(
      version: map['version'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      featuresMap: parseLocalizedList(map['features']),
      fixesMap: parseLocalizedList(map['fixes']),
    );
  }

  // Método inteligente para obtener la lista según el idioma
  List<String> getFeatures(String languageCode) {
    return _getListForLocale(featuresMap, languageCode);
  }

  List<String> getFixes(String languageCode) {
    return _getListForLocale(fixesMap, languageCode);
  }

  // Lógica de fallback: Idioma pedido -> Inglés -> Español -> Primera disponible -> Vacío
  List<String> _getListForLocale(Map<String, List<String>> map, String code) {
    if (map.containsKey(code)) return map[code]!;
    if (map.containsKey('en')) return map['en']!;
    if (map.containsKey('es')) return map['es']!;
    if (map.isNotEmpty) return map.values.first;
    return [];
  }
}