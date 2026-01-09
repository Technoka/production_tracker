import 'package:flutter/material.dart';
import '../models/release_note_model.dart';
import '../l10n/app_localizations.dart'; // Importar para usar traducciones estáticas del título

class WhatsNewDialog extends StatelessWidget {
  final ReleaseNoteModel note;
  final VoidCallback onClose;

  const WhatsNewDialog({
    Key? key, 
    required this.note,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Detectar idioma actual del usuario
    final String currentLang = Localizations.localeOf(context).languageCode;
    
    // 2. Obtener listas filtradas por idioma
    final features = note.getFeatures(currentLang);
    final fixes = note.getFixes(currentLang);

    // Títulos dinámicos (puedes usar l10n aquí si quieres)
    final isSpanish = currentLang == 'es';
    final titleFeatures = isSpanish ? '✨ Novedades' : '✨ What\'s new';
    final titleFixes = isSpanish ? '🛠️ Correcciones' : '🛠️ Fixes';
    final btnText = isSpanish ? 'Entendido, ¡vamos!' : 'Got it, let\'s go!';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rocket_launch, 
                  size: 40, 
                  color: Theme.of(context).primaryColor
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Center(
              child: Text(
                'v${note.version}',
                style: const TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Lista de Features
            if (features.isNotEmpty) ...[
              Text(
                titleFeatures,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...features.map((feature) => _buildItem(feature, Icons.check_circle_outline, Colors.green)),
              const SizedBox(height: 16),
            ],

            // Lista de Fixes
            if (fixes.isNotEmpty) ...[
              Text(
                titleFixes,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...fixes.map((fix) => _buildItem(fix, Icons.build_circle_outlined, Colors.orange)),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onClose,
                child: Text(btnText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}