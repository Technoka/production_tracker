// lib/widgets/bottom_nav_bar_widget.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/home_screen.dart';
import '../screens/production/production_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../l10n/app_localizations.dart';
import '../screens/management/management_screen.dart';

class BottomNavBarWidget extends StatelessWidget {
  final int currentIndex;
  final UserModel user;

  const BottomNavBarWidget({
    Key? key,
    required this.currentIndex,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _buildNavItems(l10n);

    // Si hay 2 o menos items, no mostrar barra
    if (items.length <= 2) return const SizedBox.shrink();

    return BottomNavigationBar(
      currentIndex: currentIndex.clamp(0, items.length - 1),
      onTap: (index) => _onItemTapped(context, index, items),
      items: items,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 11,
    );
  }

  List<BottomNavigationBarItem> _buildNavItems(AppLocalizations l10n) {
    final items = <BottomNavigationBarItem>[];

    // Home (siempre visible)
    items.add(
      BottomNavigationBarItem(
        icon: const Icon(Icons.home),
        label: l10n.home,
      ),
    );

    // Producción (si puede gestionar producción)
    // if (user.canManageProduction) {
      items.add(
        BottomNavigationBarItem(
          icon: const Icon(Icons.precision_manufacturing),
          label: l10n.production,
        ),
      );
      items.add(
        BottomNavigationBarItem(
          icon: const Icon(Icons.manage_accounts),
          label: l10n.management,
        ),
      );
    // }

    // Perfil (siempre visible)
    items.add(
      BottomNavigationBarItem(
        icon: const Icon(Icons.person),
        label: l10n.profile,
      ),
    );

    return items;
  }

  void _onItemTapped(BuildContext context, int index, List<BottomNavigationBarItem> items) {
    // No navegar si ya estamos en esa pantalla
    if (index == currentIndex) return;

    final label = items[index].label;

    // Navegar según el label
    Widget? destination;

    if (label == AppLocalizations.of(context)!.home) {
      destination = const HomeScreen();
    } else if (label == AppLocalizations.of(context)!.production) {
      destination = const ProductionScreen();
    } else if (label == AppLocalizations.of(context)!.management) {
      destination = const ManagementScreen();
    } else if (label == AppLocalizations.of(context)!.profile) {
      destination = const ProfileScreen();
    } else {
      // Reportes u otras funcionalidades en desarrollo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loading)),
      );
      return;
    }

    if (destination != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination!,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
    }
  }
}