import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'manufacturer/manufacturer_dashboard.dart';
import 'client/client_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userData = await authService.getUserData();
    
    if (mounted) {
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text('Error al cargar datos del usuario'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Provider.of<AuthService>(context, listen: false).signOut();
                },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    // Redirigir según el rol del usuario
    if (_userData!.isManufacturer) {
      return ManufacturerDashboard(userData: _userData!);
    } else {
      return ClientDashboard(userData: _userData!);
    }
  }
}