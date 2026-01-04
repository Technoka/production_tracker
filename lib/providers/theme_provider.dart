import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/organization_settings_model.dart';

class ThemeProvider extends ChangeNotifier {
  OrganizationBranding? _branding;
  
  OrganizationBranding? get branding => _branding;

  /// Actualizar branding y regenerar tema
  void updateBranding(OrganizationBranding? branding) {
    _branding = branding;
    notifyListeners();
  }

  /// Convertir string hex a Color
  Color _colorFromHex(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.blue; // Fallback
    }
  }

  /// Obtener color primario
  Color get primaryColor {
    if (_branding == null) return Colors.blue;
    return _colorFromHex(_branding!.primaryColor);
  }

  /// Obtener color secundario
  Color get secondaryColor {
    if (_branding == null) return Colors.orange;
    return _colorFromHex(_branding!.secondaryColor);
  }

  /// Obtener color de acento
  Color get accentColor {
    if (_branding == null) return Colors.green;
    return _colorFromHex(_branding!.accentColor);
  }

  /// Obtener tipografía
  TextTheme _getTextTheme(String fontFamily) {
    try {
      return GoogleFonts.getTextTheme(
        fontFamily,
        ThemeData.light().textTheme,
      );
    } catch (e) {
      // Si la fuente no está disponible, usar Roboto por defecto
      return GoogleFonts.robotoTextTheme(ThemeData.light().textTheme);
    }
  }

  /// Generar ThemeData basado en branding
  ThemeData get lightTheme {
    final primary = primaryColor;
    final secondary = secondaryColor;
    final accent = accentColor;
    final fontFamily = _branding?.fontFamily ?? 'Roboto';

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Colores
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        secondary: secondary,
        tertiary: accent,
        brightness: Brightness.light,
      ),
      
      // Tipografía
      textTheme: _getTextTheme(fontFamily),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _getTextTheme(fontFamily).titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      
      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Cards
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: primary.withOpacity(0.1),
        labelStyle: TextStyle(color: primary),
        secondaryLabelStyle: TextStyle(color: secondary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 1,
        space: 1,
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return Colors.grey;
        }),
      ),
      
      // Radio
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return Colors.grey;
        }),
      ),
      
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.2),
      ),
    );
  }

  /// Tema oscuro (opcional, para futuro)
  ThemeData get darkTheme {
    final primary = primaryColor;
    final secondary = secondaryColor;
    final accent = accentColor;
    final fontFamily = _branding?.fontFamily ?? 'Roboto';

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        secondary: secondary,
        tertiary: accent,
        brightness: Brightness.dark,
      ),
      
      textTheme: _getTextTheme(fontFamily),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _getTextTheme(fontFamily).titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}