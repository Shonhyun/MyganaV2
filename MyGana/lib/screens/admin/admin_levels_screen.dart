import 'package:flutter/material.dart';
import 'admin_categories_screen.dart';

class AdminLevelsScreen extends StatelessWidget {
  const AdminLevelsScreen({super.key});

  final List<String> levels = const ['Beginner', 'Intermediate', 'Advanced'];

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'Beginner':
        return Icons.school;
      case 'Intermediate':
        return Icons.auto_stories;
      case 'Advanced':
        return Icons.psychology;
      default:
        return Icons.book;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 1200),
          margin: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : isTablet ? 24 : 16,
          ),
          child: ListView.builder(
            padding: EdgeInsets.only(
              top: isDesktop ? 40 : isTablet ? 28 : 16,
              bottom: isDesktop ? 32 : isTablet ? 24 : 16,
            ),
            itemCount: levels.length + 1, // +1 for the header
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  margin: EdgeInsets.only(bottom: isDesktop ? 40 : isTablet ? 32 : 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue[600]!,
                                  Colors.blue[700]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level Management',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isDesktop ? 32 : isTablet ? 28 : 24,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Select a level to manage categories and lessons',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: isDesktop ? 18 : isTablet ? 16 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              final levelIndex = index - 1;
              final level = levels[levelIndex];
              final cardColor = _getLevelColor(level);
              final levelIcon = _getLevelIcon(level);

              return Container(
                margin: EdgeInsets.only(bottom: isDesktop ? 24 : isTablet ? 20 : 16),
                child: Hero(
                  tag: 'admin_level_card_$level',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cardColor.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminCategoriesScreen(
                                level: level,
                                cardColor: cardColor,
                                icon: levelIcon,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: EdgeInsets.all(isDesktop ? 28 : isTablet ? 24 : 20),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isDesktop ? 20 : isTablet ? 16 : 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      cardColor,
                                      cardColor.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cardColor.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  levelIcon,
                                  color: Colors.white,
                                  size: isDesktop ? 32 : isTablet ? 28 : 24,
                                ),
                              ),
                              SizedBox(width: isDesktop ? 24 : isTablet ? 20 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      level,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isDesktop ? 24 : isTablet ? 20 : 18,
                                        color: cardColor,
                                      ),
                                    ),
                                    SizedBox(height: isDesktop ? 8 : 6),
                                    Text(
                                      'Manage categories and lessons',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: isDesktop ? 16 : isTablet ? 14 : 12,
                                      ),
                                    ),
                                    SizedBox(height: isDesktop ? 16 : 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: cardColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.arrow_forward,
                                            color: cardColor,
                                            size: isDesktop ? 18 : isTablet ? 16 : 14,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Tap to manage',
                                            style: TextStyle(
                                              color: cardColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: isDesktop ? 14 : isTablet ? 12 : 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cardColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  color: cardColor,
                                  size: isDesktop ? 24 : isTablet ? 20 : 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}