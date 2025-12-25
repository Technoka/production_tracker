import 'package:flutter/material.dart';

class CommonRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const CommonRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      // Configuración visual unificada para toda la app
      color: Colors.white,
      backgroundColor: Colors.blue, 
      strokeWidth: 3,
      onRefresh: onRefresh,
      // NotificationListener es un truco para asegurar que el scroll funcione
      // incluso si el hijo no llena la pantalla.
      child: child, 
    );
  }
}