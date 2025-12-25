import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/organization_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => OrganizationService()),
      ],
      child: MaterialApp(
        title: 'Gestión de Producción',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. Esperar a que Firebase Auth responda
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Si hay sesión activa, verificar datos de Firestore
        if (snapshot.hasData) {
          return FutureBuilder(
            // Llamamos a getUserData que ahora será más robusto
            future: authService.getUserData(), 
            builder: (context, userSnapshot) {
              // Mientras carga el perfil de Firestore
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // Si hubo un error o el usuario no existe en Firestore (aunque tenga sesión)
              if (userSnapshot.data == null) {
                return const LoginScreen();
              }

              // Todo correcto, vamos al Home
              return const HomeScreen();
            },
          );
        }

        // 3. Si no hay sesión, ir a Login
        return const LoginScreen();
      },
    );
  }
}