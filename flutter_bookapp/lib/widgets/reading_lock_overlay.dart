import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../providers/reading_session_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class ReadingLockOverlay extends StatelessWidget {
  const ReadingLockOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReadingSessionProvider>(
      builder: (context, session, _) {
        if (!session.isActive || session.activeBook == null) {
          return const SizedBox.shrink();
        }

        final book = session.activeBook!;

        return Material(
          color: AppConstants.backgroundColor,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Icon(
                    Icons.menu_book_rounded,
                    size: 72,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sesión de lectura',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    book.author,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    session.formattedRemaining,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La app está bloqueada hasta que completes o canceles',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  CustomButton(
                    text: 'Completado (+${AppConstants.readingSessionPoints} pts)',
                    onPressed: () {
                      _onComplete(context, session);
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Cancelar sesión',
                    onPressed: () {
                      session.cancelSession();
                    },
                    isOutlined: true,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onComplete(
    BuildContext context,
    ReadingSessionProvider session,
  ) async {
    final book = session.activeBook;
    if (book == null) return;

    final auth = context.read<AuthProvider>();
    final bookProvider = context.read<BookProvider>();
    final user = auth.user;

    if (user == null) return;

    final awarded = session.completeEarly();
    if (!awarded) return;

    final matches = bookProvider.books.where((b) => b.id == book.id);
    final latestBook = matches.isNotEmpty ? matches.first : book;

    final success = await bookProvider.awardReadingSessionPoints(
      userId: user.id,
      book: latestBook,
      currentUserPoints: user.totalPoints,
    );

    session.clearCompletedFlag();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '¡Excelente! Ganaste ${AppConstants.readingSessionPoints} puntos'
              : bookProvider.error ?? 'No se pudieron guardar los puntos',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
