import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase con la configuración
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'MyBooks',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Timer? _notificationCheckTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Si el usuario está autenticado, iniciar verificación periódica
    if (authProvider.isAuthenticated && authProvider.user != null) {
      _startNotificationCheck(authProvider.user!.id);
    }
  }

  void _startNotificationCheck(String userId) {
    // Verificar notificaciones inmediatamente
    _checkNotifications(userId);
    
    // Luego verificar cada 2 minutos para las pruebas
    // En producción cambiar a Duration(minutes: 30)
    _notificationCheckTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _checkNotifications(userId),
    );
  }

  void _checkNotifications(String userId) {
    final notificationProvider = 
        Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.checkPendingBooks(userId);
  }

  @override
  void dispose() {
    _notificationCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Mostrar pantalla de carga mientras se verifica la autenticación
        if (authProvider.user == null && authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si el usuario está autenticado, mostrar la pantalla principal
        if (authProvider.isAuthenticated) {
          return const MainScreen();
        }

        // Si no está autenticado, mostrar la pantalla de login
        return const LoginScreen();
      },
    );
  }
}

