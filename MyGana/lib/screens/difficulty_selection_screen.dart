import 'package:flutter/material.dart';
import 'story_screen.dart';

enum Difficulty {
  EASY,
  NORMAL,
  HARD,
}

class DifficultySelectionScreen extends StatefulWidget {
  const DifficultySelectionScreen({super.key});

  @override
  State<DifficultySelectionScreen> createState() => _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState extends State<DifficultySelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Allow flexible orientation - no forced constraints
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _selectDifficulty(Difficulty difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryScreen(difficulty: difficulty),
      ),
    );
  }

  void _showGameOverview() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final maxWidth = screenSize.width * 0.8;
        final maxHeight = screenSize.height * 0.8;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'Journey of the Kanji Seeker',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.025,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'TheLastShuriken',
                        color: Colors.amber,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Overview text
                    Text(
                      'You are Haruki, a curious student who discovers a mysterious notebook in the library. The moment you open it, you are transported into a strange world where Kanji comes alive.\n\nIn this journey, you will meet 10 different people—each with their own story and challenge. They will test your knowledge of Kanji through questions, phrases, and sentences. Answer correctly, and you will move forward. Fail, and your path will grow more difficult.\n\nOnly by completing all 10 interactions and proving your understanding of Kanji can you return to the real world. Your adventure begins now—are you ready to walk the path of the Kanji Seeker?',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.015,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 20),
                    
                    // Yes button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.withOpacity(0.8),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Yes',
                          style: TextStyle(
                            fontSize: screenSize.width * 0.018,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'TheLastShuriken',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/backgrounds/Gate (Intro).png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(Icons.image_not_supported,
                      color: Colors.white, size: 48),
                ),
              );
            },
          ),
          
          // Game Overview Button (upper-right corner)
          Positioned(
            top: 20,
            right: 20,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.8),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: _showGameOverview,
                  icon: const Icon(
                    Icons.info_outline,
                    color: Colors.amber,
                    size: 24,
                  ),
                  tooltip: 'Game Overview',
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: isLandscape ? 12 : 16,
                        horizontal: isLandscape ? 24 : 28,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Journey of the Kanji Seeker',
                        style: TextStyle(
                          fontSize: isLandscape 
                            ? screenSize.width * 0.03 
                            : screenSize.width * 0.06,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'TheLastShuriken',
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    SizedBox(height: isLandscape ? 16 : 24),
                    
                    // Subtitle
                    Text(
                      'Select your difficulty level',
                      style: TextStyle(
                        fontSize: isLandscape 
                          ? screenSize.width * 0.02 
                          : screenSize.width * 0.04,
                        fontWeight: FontWeight.bold,
                        fontFamily: "TheLastShuriken",
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.8),
                            offset: const Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: isLandscape ? 32 : 48),
                    
                    // Difficulty buttons - responsive layout
                    isLandscape 
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDifficultyButton(
                              difficulty: Difficulty.EASY,
                              color: Colors.green,
                              description: 'For beginners',
                            ),
                            const SizedBox(width: 20),
                            _buildDifficultyButton(
                              difficulty: Difficulty.NORMAL,
                              color: Colors.blue,
                              description: 'Standard challenge',
                            ),
                            const SizedBox(width: 20),
                            _buildDifficultyButton(
                              difficulty: Difficulty.HARD,
                              color: Colors.red,
                              description: 'Advanced learners',
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildDifficultyButton(
                              difficulty: Difficulty.EASY,
                              color: Colors.green,
                              description: 'For beginners',
                            ),
                            const SizedBox(height: 16),
                            _buildDifficultyButton(
                              difficulty: Difficulty.NORMAL,
                              color: Colors.blue,
                              description: 'Standard challenge',
                            ),
                            const SizedBox(height: 16),
                            _buildDifficultyButton(
                              difficulty: Difficulty.HARD,
                              color: Colors.red,
                              description: 'Advanced learners',
                            ),
                          ],
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyButton({
    required Difficulty difficulty,
    required Color color,
    required String description,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    String difficultyText = difficulty.toString().split('.').last;
    
    return Container(
      width: isLandscape 
        ? screenSize.width * 0.18 
        : screenSize.width * 0.7,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _selectDifficulty(difficulty),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: isLandscape ? 16 : 20,
            horizontal: isLandscape ? 8 : 16,
          ),
          backgroundColor: color.withOpacity(0.8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color, width: 2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              difficultyText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isLandscape ? 14 : 18,
                fontFamily: "TheLastShuriken"
              ),
            ),
            SizedBox(height: isLandscape ? 6 : 8),
            Text(
              description,
              style: TextStyle(
                fontSize: isLandscape ? 12 : 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
