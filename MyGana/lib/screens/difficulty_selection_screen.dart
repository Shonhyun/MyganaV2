import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Allow all orientations when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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

  @override
  Widget build(BuildContext context) {
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
          
          // Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 22),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Journey of the Kanji Seeker',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'TheLastShuriken',
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Subtitle
                  Text(
                    'Select your difficulty level',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.025,
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
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Difficulty buttons
                  Row(
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
                  ),
                ],
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
    String difficultyText = difficulty.toString().split('.').last;
    
    return Container(
      width: MediaQuery.of(context).size.width * 0.2,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: "TheLastShuriken"
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                
              ),
            ),
          ],
        ),
      ),
    );
  }
}
