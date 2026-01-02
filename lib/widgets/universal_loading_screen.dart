import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class UniversalLoadingScreen extends StatelessWidget {
  final String? message;
  final bool showOrganization;

  const UniversalLoadingScreen({
    super.key,
    this.message = "Cargando datos...",
    this.showOrganization = false,
  });

  @override
  Widget build(BuildContext context) {
    // Intentamos obtener datos del usuario (si existen) para mostrar contexto
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;
    
    // Usamos el color primario del tema para el fondo
    final backgroundColor = Theme.of(context).primaryColor;
    final textColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Icono animado o estático
              Icon(
                Icons.factory, // Icono de tu app
                size: 80,
                color: textColor.withOpacity(0.9),
              ),
              const SizedBox(height: 24),

              // 2. Nombre de la App
              Text(
                "PRODUCTION TRACKER",
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              
              // 3. Nombre de la Organización (Si el usuario tiene una y está logueado)
              if (showOrganization && user != null && user.role != null) ...[const SizedBox(height: 24), // Un poco más de espacio respecto al título

                // --- CHIP DE USUARIO ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline, size: 16, color: textColor.withOpacity(0.9)),
                      const SizedBox(width: 8),
                      Text(
                        user.name,
                        style: TextStyle(
                          color: textColor.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- CHIP DE ORGANIZACIÓN (NUEVO) ---
                // Verifica que organizationId exista y no esté vacío
                if (user.organizationId != null && user.organizationId!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business, size: 16, color: textColor.withOpacity(0.9)),
                        const SizedBox(width: 8),
                        Text(
                          "Org: ${user.organizationId}", // Aquí mostramos el ID
                          style: TextStyle(
                            color: textColor.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 48),

              // 4. Indicador de carga
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),

              const SizedBox(height: 16),

              // 5. Mensaje de estado
              Text(
                message!,
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}