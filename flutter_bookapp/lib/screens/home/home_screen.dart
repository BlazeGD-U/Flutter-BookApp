import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/recommendation_card.dart';
import 'discover_form_sheet.dart';
import 'recommendation_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyBooks'),
      ),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, _) {
          final recommendations = bookProvider.recommendations;

          if (recommendations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay recomendaciones disponibles',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recomendaciones',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (_) => const DiscoverFormSheet(),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Descubre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: AppConstants.textPrimaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final book = recommendations[index];
                    return RecommendationCard(
                      book: book,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecommendationDetailScreen(book: book),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

