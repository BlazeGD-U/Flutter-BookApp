import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/reading_session_provider.dart';
import '../../widgets/reading_lock_overlay.dart';
import '../home/home_screen.dart';
import '../books/books_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';
import '../../providers/chat_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BooksScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  void _initializeProviders() {
    final authProvider = context.read<AuthProvider>();
    final bookProvider = context.read<BookProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.user != null) {
      // Inicializar streams de libros, notificaciones y chat
      bookProvider.initializeStreams(authProvider.user!.id);
      notificationProvider.initializeStream(authProvider.user!.id);
      chatProvider.initialize(authProvider.user!.id);
      
      // Verificar libros pendientes para notificaciones
      notificationProvider.checkPendingBooks(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionActive = context.watch<ReadingSessionProvider>().isActive;

    return PopScope(
      canPop: !sessionActive,
      child: Scaffold(
        body: Stack(
          children: [
            _screens[_currentIndex],
            const ReadingLockOverlay(),
          ],
        ),
        bottomNavigationBar: sessionActive
            ? null
            : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Libros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Comunidad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      ),
    );
  }
}

