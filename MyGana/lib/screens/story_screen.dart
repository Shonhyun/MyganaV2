import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firebase_user_sync_service.dart';
import '../services/progress_service.dart';
import 'difficulty_selection_screen.dart';

enum CharacterPosition { left, center, right }

// NEW: Particle class for visual effects
class Particle {
  double x, y, vx, vy;
  int life;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
  });

  void update() {
    x += vx;
    y += vy;
    life--;
  }

  bool isDead() => life <= 0;
}

// NEW: Haptic feedback types
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}

class StoryScreen extends StatefulWidget {
  final Difficulty difficulty;

  const StoryScreen({
    super.key,
    required this.difficulty,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> with TickerProviderStateMixin {
  // Story progression state
  int _currentStoryIndex = 0;
  bool _showingQuestion = false;
  String? _selectedAnswer;
  bool _showingFeedback = false;
  bool _isCorrect = false;
  bool _showingCompletionScreen = false;
  bool _showingFailureScreen = false;

  // Track incorrect attempts for current question
  // Remove `int _incorrectAttempts = 0;`
  // Remove `bool _showSkipOption = false;`

  // NEW: Lives system
  double _lives = 5.0; // Start with 5 full hearts
  static const double _maxLives = 5.0;
  static const double _livesLostPerWrongAnswer = 0.5;

  // Animation controllers
  late AnimationController _characterAnimationController;
  late AnimationController _dialogAnimationController;
  late AnimationController _scoreAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _completionAnimationController;
  late AnimationController _livesAnimationController; // NEW: For heart animations

  // Animations
  late Animation<double> _characterSlideAnimation;
  late Animation<double> _dialogFadeAnimation;
  late Animation<double> _scoreScaleAnimation;
  late Animation<double> _backgroundFadeAnimation;
  late Animation<double> _completionFadeAnimation;
  late Animation<double> _livesShakeAnimation; // NEW: For heart shake effect

  // Confetti controller for celebrations
  late ConfettiController _confettiController;
  late ConfettiController _completionConfettiController;

  // Controller for page transitions
  final PageController _pageController = PageController();

  // Story data based on difficulty
  late List<StoryBeat> _currentStoryBeats;

  // Audio players
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _transitionSoundPlayer = AudioPlayer();
  final AudioPlayer _correctSoundPlayer = AudioPlayer();
  final AudioPlayer _incorrectSoundPlayer = AudioPlayer();
  final AudioPlayer _victoryMusicPlayer = AudioPlayer();
  final AudioPlayer _heartLostSoundPlayer = AudioPlayer(); // NEW: Heart lost sound

  // Loading screen state
  bool _isLoading = true;
  int _currentInteraction = 1;
  bool _completedInteraction = false;

  // Player score tracking and achievements
  int _correctAnswers = 0;
  int _streak = 0;
  int _maxStreak = 0;
  bool _hasStartedQuestions = false;
  final List<String> _achievements = [];
  bool _showAchievement = false;
  String _currentAchievement = '';

  // UI enhancements
  bool _showHint = false;
  int _hintsUsed = 0;
  double _confidence = 0.0;

  // Game-like features
  int _totalScore = 0;
  int _experiencePoints = 0;
  String _playerRank = 'Novice';
  final List<String> _unlockedTitles = ['Kanji Seeker'];

  // New state for handling final question flow
  bool _hasAnsweredFinalQuestion = false;
  bool _finalQuestionProcessed = false;
  bool _showingFailureDialogue = false;

  // Add this with other state variables
  bool _showFloatingMessage = false;
  String _floatingMessage = '';
  late AnimationController _floatingMessageController;
  late Animation<double> _floatingMessageAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _characterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _dialogAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _completionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // NEW: Lives animation controller
    _livesAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Add this in initState() with other animation controllers
    _floatingMessageController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _floatingMessageAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingMessageController,
      curve: Curves.elasticOut,
    ));

    // Initialize animations
    _characterSlideAnimation = Tween<double>(
      begin: -200.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _characterAnimationController,
      curve: Curves.elasticOut,
    ));

    _dialogFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dialogAnimationController,
      curve: Curves.easeInOut,
    ));

    _scoreScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.elasticOut,
    ));

    _backgroundFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeInOut,
    ));

    _completionFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _completionAnimationController,
      curve: Curves.easeInOut,
    ));

    // NEW: Lives shake animation
    _livesShakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _livesAnimationController,
      curve: Curves.elasticOut,
    ));

    // Initialize confetti controllers
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _completionConfettiController = ConfettiController(duration: const Duration(seconds: 5));

    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Set story beats based on difficulty
    _setStoryBeatsByDifficulty();

    // Initialize audio
    _initBackgroundMusic();
    _initSoundEffects();

    // Show initial loading screen
    _showLoadingScreen();

    // Start animations
    _backgroundAnimationController.forward();
  }

  @override
  void dispose() {
    _characterAnimationController.dispose();
    _dialogAnimationController.dispose();
    _scoreAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _completionAnimationController.dispose();
    _livesAnimationController.dispose(); // NEW
    _confettiController.dispose();
    _completionConfettiController.dispose();
    _pageController.dispose();
    _audioPlayer.dispose();
    _transitionSoundPlayer.dispose();
    _correctSoundPlayer.dispose();
    _incorrectSoundPlayer.dispose();
    _victoryMusicPlayer.dispose();
    _heartLostSoundPlayer.dispose(); // NEW
    // Add this in dispose()
    _floatingMessageController.dispose();
    super.dispose();
  }

  Future<void> _initSoundEffects() async {
    try {
      await _transitionSoundPlayer.setAsset('assets/sounds/bkpage.mp3');
      await _correctSoundPlayer.setAsset('assets/sounds/correct.mp3');
      await _incorrectSoundPlayer.setAsset('assets/sounds/incorrect.mp3');
      await _victoryMusicPlayer.setAsset('assets/sounds/victory.mp3');
      await _heartLostSoundPlayer.setAsset('assets/sounds/heart_lost.mp3'); // NEW

      await _transitionSoundPlayer.setVolume(0.7);
      await _correctSoundPlayer.setVolume(0.8);
      await _incorrectSoundPlayer.setVolume(0.6);
      await _victoryMusicPlayer.setVolume(0.9);
      await _heartLostSoundPlayer.setVolume(0.7); // NEW
    } catch (e) {
      print('Error initializing sound effects: $e');
    }
  }

  Future<void> _playCorrectSound() async {
    try {
      await _correctSoundPlayer.seek(Duration.zero);
      await _correctSoundPlayer.play();
    } catch (e) {
      print('Error playing correct sound: $e');
    }
  }

  Future<void> _playIncorrectSound() async {
    try {
      await _incorrectSoundPlayer.seek(Duration.zero);
      await _incorrectSoundPlayer.play();
    } catch (e) {
      print('Error playing incorrect sound: $e');
    }
  }

  // NEW: Play heart lost sound
  Future<void> _playHeartLostSound() async {
    try {
      await _heartLostSoundPlayer.seek(Duration.zero);
      await _heartLostSoundPlayer.play();
    } catch (e) {
      print('Error playing heart lost sound: $e');
    }
  }

  Future<void> _playVictoryMusic() async {
    try {
      await _audioPlayer.stop();
      await _victoryMusicPlayer.seek(Duration.zero);
      await _victoryMusicPlayer.play();
    } catch (e) {
      print('Error playing victory music: $e');
    }
  }

  Future<void> _initBackgroundMusic() async {
    try {
      await _audioPlayer.setVolume(0.5);
      await _audioPlayer.setAsset('assets/sounds/bgmds.mp3');
      await _audioPlayer.setLoopMode(LoopMode.all);
      await _audioPlayer.play();
    } catch (e) {
      print('Error initializing background music: $e');
    }
  }

  Future<void> _playTransitionSound() async {
    try {
      await _transitionSoundPlayer.seek(Duration.zero);
      await _transitionSoundPlayer.play();
    } catch (e) {
      print('Error playing transition sound: $e');
    }
  }

  // NEW: Lose lives and check for game over
  void _loseLives() {
    setState(() {
      _lives = (_lives - _livesLostPerWrongAnswer).clamp(0.0, _maxLives);
    });

    _playHeartLostSound();
    _livesAnimationController.forward().then((_) {
      _livesAnimationController.reverse();
    });

    // Check if player has run out of lives
    if (_lives <= 0) {
      _insertFailureDialogue();
      setState(() {
        _showingFeedback = false;
        _showingQuestion = false;
        _selectedAnswer = null;
        _showHint = false;
        // Remove `_incorrectAttempts = 0;`
        // Remove `_showSkipOption = false;`
        _showingFailureDialogue = true;
        _currentStoryIndex++;
      });
      _dialogAnimationController.reset();
      _dialogAnimationController.forward();
    }
  }

  // NEW: Enhanced hearts display with better animations
  Widget _buildHeartsDisplay() {
    return AnimatedBuilder(
      animation: _livesShakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_livesShakeAnimation.value * (1 - (_livesAnimationController.value)), 0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.red.withOpacity(0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(5, (index) {
                  double heartValue = _lives - index;
                  if (heartValue >= 1.0) {
                    // Full heart with glow effect
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Stack(
                        children: [
                          // Glow effect
                          Icon(
                            Icons.favorite,
                            color: Colors.red.withOpacity(0.3),
                            size: 24,
                          ),
                          // Main heart
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  } else if (heartValue >= 0.5) {
                    // Half heart
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Stack(
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            color: Colors.red,
                            size: 20,
                          ),
                          ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.5,
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Empty heart
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.grey,
                        size: 20,
                      ),
                    );
                  }
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // NEW: Enhanced streak display
  Widget _buildStreakDisplay() {
    if (_streak <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.9),
            Colors.red.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$_streak',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _setStoryBeatsByDifficulty() {
    switch (widget.difficulty) {
      case Difficulty.EASY:
        _currentStoryBeats = List.from(easyStoryBeats);
        break;
      case Difficulty.NORMAL:
        _currentStoryBeats = List.from(normalStoryBeats);
        break;
      case Difficulty.HARD:
        _currentStoryBeats = List.from(hardStoryBeats);
        break;
    }
  }

  Future<void> _showLoadingScreen() async {
    setState(() {
      _isLoading = true;
    });

    _playTransitionSound();
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // Start character animation when loading is complete
    _characterAnimationController.forward();
    _dialogAnimationController.forward();
  }

  void _calculateFinalScore() {
    // Base score calculation
    _totalScore = _correctAnswers * 100;

    // Difficulty multiplier
    switch (widget.difficulty) {
      case Difficulty.EASY:
        _totalScore = (_totalScore * 1.0).round();
        break;
      case Difficulty.NORMAL:
        _totalScore = (_totalScore * 1.5).round();
        break;
      case Difficulty.HARD:
        _totalScore = (_totalScore * 2.0).round();
        break;
    }

    // Bonus for streaks
    _totalScore += _maxStreak * 50;

    // Bonus for not using hints
    if (_hintsUsed == 0) {
      _totalScore += 500;
    }

    // NEW: Bonus for remaining lives
    _totalScore += (_lives * 100).round();

    // Calculate experience points
    _experiencePoints = _totalScore ~/ 10;

    // Determine rank
    if (_correctAnswers == 10 && _hintsUsed == 0 && _lives == _maxLives) {
      _playerRank = 'Kanji Master';
      _unlockedTitles.add('Perfect Scholar');
    } else if (_correctAnswers >= 8) {
      _playerRank = 'Kanji Expert';
      _unlockedTitles.add('Skilled Learner');
    } else if (_correctAnswers >= 6) {
      _playerRank = 'Kanji Apprentice';
    } else {
      _playerRank = 'Kanji Novice';
    }
  }

  // Save story score to local storage
  Future<void> _saveStoryScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current story total points
      final currentStoryPoints = prefs.getInt('story_total_points') ?? 0;

      // Add the current story score
      final newStoryPoints = currentStoryPoints + _totalScore;

      // Save back to SharedPreferences
      await prefs.setInt('story_total_points', newStoryPoints);

      // Also update total_points for Firebase sync
      final currentTotalPoints = prefs.getInt('total_points') ?? 0;
      final newTotalPoints = currentTotalPoints + _totalScore;
      await prefs.setInt('total_points', newTotalPoints);

      // Sync to Firebase
      final firebaseSync = FirebaseUserSyncService();
      await firebaseSync.syncMojiPoints(newTotalPoints);

      // Also save individual story session data for detailed tracking
      final storySessionKey = 'story_session_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(
          storySessionKey,
          {
            'difficulty': widget.difficulty.toString(),
            'score': _totalScore,
            'correctAnswers': _correctAnswers,
            'maxStreak': _maxStreak,
            'hintsUsed': _hintsUsed,
            'livesRemaining': _lives,
            'experiencePoints': _experiencePoints,
            'playerRank': _playerRank,
            'completedAt': DateTime.now().toIso8601String(),
          }.toString());

      // Update progress service for comprehensive tracking
      final progressService = ProgressService();
      await progressService.initialize();
      await progressService.updateStoryModeScore(
        score: _totalScore,
        correctAnswers: _correctAnswers,
        maxStreak: _maxStreak,
        hintsUsed: _hintsUsed,
        livesRemaining: _lives,
        difficulty: widget.difficulty.toString(),
        playerRank: _playerRank,
      );

      print('Story score saved: $_totalScore points (Total story points: $newStoryPoints)');
    } catch (e) {
      print('Error saving story score: $e');
    }
  }

  void _checkAchievements() {
    List<String> newAchievements = [];

    if (_correctAnswers == 1 && !_achievements.contains('First Success')) {
      newAchievements.add('First Success');
    }

    if (_correctAnswers == 5 && !_achievements.contains('Halfway Hero')) {
      newAchievements.add('Halfway Hero');
    }

    if (_correctAnswers == 10 && !_achievements.contains('Perfect Score')) {
      newAchievements.add('Perfect Score');
    }

    if (_streak >= 3 && !_achievements.contains('Triple Threat')) {
      newAchievements.add('Triple Threat');
    }

    if (_streak >= 5 && !_achievements.contains('Unstoppable')) {
      newAchievements.add('Unstoppable');
    }

    if (_hintsUsed == 0 && _correctAnswers >= 5 && !_achievements.contains('No Help Needed')) {
      newAchievements.add('No Help Needed');
    }

    if (_correctAnswers >= 8 && !_achievements.contains('Speed Demon')) {
      newAchievements.add('Speed Demon');
    }

    // NEW: Lives-based achievements
    if (_lives == _maxLives &&
        _correctAnswers >= 7 &&
        !_achievements.contains('Flawless Victory')) {
      newAchievements.add('Flawless Victory');
    }

    if (_lives >= 4.0 && _correctAnswers >= 5 && !_achievements.contains('Heart Guardian')) {
      newAchievements.add('Heart Guardian');
    }

    for (String achievement in newAchievements) {
      _achievements.add(achievement);
      _showAchievementPopup(achievement);
    }
  }

  void _showAchievementPopup(String achievement) {
    setState(() {
      _showAchievement = true;
      _currentAchievement = achievement;
    });

    _confettiController.play();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showAchievement = false;
        });
      }
    });
  }

  void _showFloatingFeedback(String message) {
    setState(() {
      _showFloatingMessage = true;
      _floatingMessage = message;
    });

    _floatingMessageController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _floatingMessageController.reverse().then((_) {
            setState(() {
              _showFloatingMessage = false;
            });
          });
        }
      });
    });
  }

  bool _isEndOfInteraction() {
    if (_currentStoryIndex >= _currentStoryBeats.length - 1) return true;

    final StoryBeat currentBeat = _currentStoryBeats[_currentStoryIndex];
    final StoryBeat nextBeat = _currentStoryBeats[_currentStoryIndex + 1];

    if (currentBeat.question != null && _showingFeedback && _isCorrect) {
      return true;
    }

    if (currentBeat.background != nextBeat.background) {
      return true;
    }

    return false;
  }

  bool _isAtFinalStoryBeat() {
    return _currentStoryIndex == _currentStoryBeats.length - 1;
  }

  bool _isFinalQuestion() {
    final StoryBeat currentBeat = _currentStoryBeats[_currentStoryIndex];

    // Check if this is the Professor Hoshino question (the 10th question)
    if (currentBeat.question != null &&
        currentBeat.character != null &&
        currentBeat.character!.contains('Prof Hoshino')) {
      return true;
    }

    return false;
  }

  bool _isFailureDialogue() {
    final StoryBeat currentBeat = _currentStoryBeats[_currentStoryIndex];

    return currentBeat.speaker == 'Professor Hoshino' &&
        (currentBeat.text.contains('I\'m sorry, Haruki. You have run out of lives') ||
            currentBeat.text.contains('You haven\'t mastered enough Kanji')) &&
        currentBeat.character != null &&
        currentBeat.character!.contains('Prof Hoshino (Sad)');
  }

  void _insertFailureDialogue() {
    // Insert failure dialogue after the current position
    final failureDialogue = StoryBeat(
      speaker: 'Professor Hoshino',
      text:
          'I\'m sorry, Haruki. You have run out of lives and cannot continue your journey. Your heart was not strong enough to withstand the trials. You must start again to prove your determination.',
      background: 'Principal\'s Office (Inter10).png',
      character: 'Prof Hoshino (Sad).png',
      characterPosition: CharacterPosition.center,
      harukiExpression: 'Haruki (Sad).png',
    );

    // Insert the failure dialogue right after the current position
    _currentStoryBeats.insert(_currentStoryIndex + 1, failureDialogue);
  }

  void _showCompletionScreen() {
    _calculateFinalScore();
    _saveStoryScore(); // Save the score to local storage
    _playVictoryMusic();
    setState(() {
      _showingCompletionScreen = true;
    });
    _completionAnimationController.forward();
    _completionConfettiController.play();
  }

  void _showFailureScreen() {
    _calculateFinalScore();
    _saveStoryScore(); // Save the score to local storage even on failure
    setState(() {
      _showingFailureScreen = true;
    });
    _completionAnimationController.forward();
  }

  // Remove the `_skipQuestion()` method entirely.
  // void _skipQuestion() {
  //   setState(() {
  //     _showingFeedback = false;
  //     _showingQuestion = false;
  //     _selectedAnswer = null;
  //     _showSkipOption = false;
  //     _incorrectAttempts = 0;
  //     _streak = 0;
  //     _showHint = false;

  //     if (_currentStoryIndex < _currentStoryBeats.length - 1) {
  //       _currentStoryIndex++;
  //     }
  //   });

  //   bool endOfInteraction = _isEndOfInteraction();
  //   if (endOfInteraction) {
  //     _currentInteraction++;
  //     _showLoadingScreen();
  //     _characterAnimationController.reset();
  //     _dialogAnimationController.reset();
  //   } else {
  //     _dialogAnimationController.reset();
  //     _dialogAnimationController.forward();
  //   }
  // }

  void _nextStoryBeat() {
    if (_currentStoryIndex >= _currentStoryBeats.length) {
      return;
    }

    // Check if we're currently showing the failure dialogue
    if (_isFailureDialogue()) {
      // User tapped - now show failure screen
      _showFailureScreen();
      return;
    }

    if (_isAtFinalStoryBeat()) {
      // Check if player passed (7 or more correct answers) AND has lives remaining
      if (_correctAnswers >= 7 && _lives > 0) {
        _showCompletionScreen();
      } else {
        _showFailureScreen();
      }
      return;
    }

    final StoryBeat currentBeat = _currentStoryBeats[_currentStoryIndex];

    if (_showingFeedback) {
      if (!_isCorrect) {
        // Show floating message for wrong answer
        _showFloatingFeedback('Not quite right. Try again!');

        // NEW: Lose lives on wrong answer
        _loseLives();

        // Check if lives are depleted (handled in _loseLives method)
        if (_lives <= 0) {
          return; // _loseLives already handles the failure flow
        }

        // Reset for another attempt
        setState(() {
          _showingFeedback = false;
          _selectedAnswer = null;
          _streak = 0;
        });
        _dialogAnimationController.reset();
        _dialogAnimationController.forward();
        return;
      }

      // Handle final question logic
      if (_isFinalQuestion() && !_finalQuestionProcessed) {
        setState(() {
          _hasAnsweredFinalQuestion = true;
          _finalQuestionProcessed = true;
        });

        // Check if player passed (7 or more correct answers AND has lives)
        if (_correctAnswers >= 7 && _lives > 0) {
          // Player passed - proceed to success dialogue
          setState(() {
            _correctAnswers++;
            _streak++;
            _maxStreak = _maxStreak > _streak ? _maxStreak : _streak;
            _confidence = (_correctAnswers / 10.0).clamp(0.0, 1.0);
            _showingFeedback = false;
            _showingQuestion = false;
            _selectedAnswer = null;
            _showHint = false;
            // Remove `_incorrectAttempts = 0;`
            // Remove `_showSkipOption = false;`
            _currentStoryIndex++;
          });
        } else {
          // Player failed - insert failure dialogue and proceed to it
          _insertFailureDialogue();
          setState(() {
            _showingFeedback = false;
            _showingQuestion = false;
            _selectedAnswer = null;
            _showHint = false;
            // Remove `_incorrectAttempts = 0;`
            // Remove `_showSkipOption = false;`
            _showingFailureDialogue = true;
            _currentStoryIndex++;
          });
        }

        _scoreAnimationController.forward().then((_) {
          _scoreAnimationController.reverse();
        });

        _checkAchievements();
        _dialogAnimationController.reset();
        _dialogAnimationController.forward();
        return;
      }

      // Regular question handling (not final question)
      bool endOfInteraction = _isEndOfInteraction();

      setState(() {
        _correctAnswers++;
        _streak++;
        _maxStreak = _maxStreak > _streak ? _maxStreak : _streak;
        _confidence = (_correctAnswers / 10.0).clamp(0.0, 1.0);
        _showingFeedback = false;
        _showingQuestion = false;
        _selectedAnswer = null;
        _completedInteraction = endOfInteraction;
        _showHint = false;
        // Remove `_incorrectAttempts = 0;`
        // Remove `_showSkipOption = false;`

        if (_currentStoryIndex < _currentStoryBeats.length - 1) {
          _currentStoryIndex++;
        }
      });

      _scoreAnimationController.forward().then((_) {
        _scoreAnimationController.reverse();
      });

      _checkAchievements();

      if (_completedInteraction) {
        _currentInteraction++;
        _showLoadingScreen();
        _characterAnimationController.reset();
        _dialogAnimationController.reset();
      } else {
        _dialogAnimationController.reset();
        _dialogAnimationController.forward();
      }

      return;
    }

    if (_showingQuestion) {
      if (_selectedAnswer == null) return;

      setState(() {
        _isCorrect = _selectedAnswer == currentBeat.question!.correctAnswer;
        _showingFeedback = true;
        // if (!_isCorrect) {
        //   _incorrectAttempts++;
        // }
      });

      if (_isCorrect) {
        _playCorrectSound();
      } else {
        _playIncorrectSound();
      }

      return;
    }

    if (currentBeat.question != null) {
      setState(() {
        _showingQuestion = true;
        _hasStartedQuestions = true;
      });
      return;
    }

    // Handle dialogue progression
    bool endOfInteraction = _isEndOfInteraction();

    if (_currentStoryIndex < _currentStoryBeats.length - 1) {
      setState(() {
        _currentStoryIndex++;
        _completedInteraction = endOfInteraction;
      });

      if (_completedInteraction) {
        _currentInteraction++;
        _showLoadingScreen();
        _characterAnimationController.reset();
        _dialogAnimationController.reset();
      } else {
        _dialogAnimationController.reset();
        _dialogAnimationController.forward();
      }
    }
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswer = answer;
    });
  }

  void _showHintForQuestion() {
    setState(() {
      _showHint = true;
      _hintsUsed++;
    });
  }

  String _getHintForCurrentQuestion() {
    final StoryBeat currentBeat = _currentStoryBeats[_currentStoryIndex];
    if (currentBeat.question == null) return '';

    final correctAnswer = currentBeat.question!.correctAnswer;
    final questionText = currentBeat.question!.text.toLowerCase();

    if (questionText.contains('mountain') || questionText.contains('山')) {
      return 'Think about the shape of a mountain peak...';
    }
    if (questionText.contains('water') || questionText.contains('水')) {
      return 'Imagine flowing water...';
    }
    if (questionText.contains('fire') || questionText.contains('火')) {
      return 'Picture flames dancing upward...';
    }
    if (questionText.contains('time') || questionText.contains('時')) {
      return 'Consider what measures the passage of moments...';
    }

    if (correctAnswer.contains('A.')) return 'The answer starts with the first option...';
    if (correctAnswer.contains('B.')) return 'Look at the second choice carefully...';
    if (correctAnswer.contains('C.')) return 'The third option might be correct...';
    if (correctAnswer.contains('D.')) return 'Consider the last option...';

    return 'Think about the context of the conversation...';
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade900.withOpacity(0.3),
                  Colors.purple.shade900.withOpacity(0.3),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Floating particles effect
          ...List.generate(20, (index) {
            return Positioned(
              left: (index * 37) % MediaQuery.of(context).size.width,
              top: (index * 73) % MediaQuery.of(context).size.height,
              child: AnimatedBuilder(
                animation: _backgroundAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_backgroundAnimationController.value * 100),
                    child: Container(
                      width: 2,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            );
          }),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Enhanced loading container
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Enhanced loading animation
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 3,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Rotating border
                            AnimatedBuilder(
                              animation: _backgroundAnimationController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _backgroundAnimationController.value * 2 * 3.14159,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _getDifficultyColor(),
                                        width: 3,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Center content
                            Center(
                              child: Image.asset(
                                'assets/images/three_dots.gif',
                                height: 50,
                                errorBuilder: (context, error, stackTrace) {
                                  return CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(_getDifficultyColor()),
                                    strokeWidth: 3,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Enhanced loading text
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'Loading Chapter $_currentInteraction...',
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'TheLastShuriken',
                              fontWeight: FontWeight.bold,
                            ),
                            speed: const Duration(milliseconds: 80),
                          ),
                        ],
                        isRepeatingAnimation: false,
                      ),

                      const SizedBox(height: 16),

                      // Difficulty indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor().withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getDifficultyColor(),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'Difficulty: ${widget.difficulty.toString().split('.').last}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Progress dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _backgroundAnimationController,
                            builder: (context, child) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _backgroundAnimationController.value > (index + 1) / 3
                                      ? _getDifficultyColor()
                                      : Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade900.withOpacity(0.9),
              Colors.green.shade700.withOpacity(0.8),
              Colors.green.shade500.withOpacity(0.7),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _completionFadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;

                return Column(
                  children: [
                    // Animated Header (Journey Complete Section)
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.02,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade600,
                              Colors.green.shade800,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Star icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: Icon(
                                Icons.star,
                                color: Colors.yellow.shade300,
                                size: screenWidth * 0.07,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            // Journey Complete text
                            Text(
                              'JOURNEY COMPLETE!',
                              style: TextStyle(
                                fontSize: screenWidth * 0.07,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'TheLastShuriken',
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.6),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Difficulty: ${widget.difficulty.toString().split('.').last}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: _getDifficultyColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Main Content
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenHeight * 0.01,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Stats and Achievements
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(screenWidth * 0.02),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.emoji_events,
                                        color: Colors.yellow.shade300,
                                        size: screenWidth * 0.04,
                                      ),
                                      SizedBox(width: screenWidth * 0.01),
                                      Text(
                                        'Kanji Mastery Achieved',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    'Final Score: $_totalScore',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.025,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'Rank: $_playerRank',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.025,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  // Stats
                                  Wrap(
                                    spacing: screenWidth * 0.02,
                                    runSpacing: screenHeight * 0.01,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      _buildCompactStat(
                                          'Correct', '$_correctAnswers/10', Icons.check_circle),
                                      _buildCompactStat(
                                          'Streak', '$_maxStreak', Icons.local_fire_department),
                                      _buildCompactStat('Lives', '${_lives.toStringAsFixed(1)}/5',
                                          Icons.favorite),
                                      _buildCompactStat('XP', '+$_experiencePoints', Icons.star),
                                    ],
                                  ),
                                  if (_achievements.isNotEmpty) ...[
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      'Achievements Unlocked',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.025,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Wrap(
                                      spacing: screenWidth * 0.01,
                                      runSpacing: screenHeight * 0.005,
                                      alignment: WrapAlignment.center,
                                      children: _achievements
                                          .map((achievement) => Chip(
                                                label: Text(
                                                  achievement,
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.02,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                backgroundColor: Colors.yellow.withOpacity(0.8),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: screenWidth * 0.01),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Action Buttons
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Next Difficulty Button (if not HARD)
                          if (widget.difficulty != Difficulty.HARD)
                            Container(
                              margin: EdgeInsets.only(right: screenWidth * 0.02),
                              child: ElevatedButton(
                                onPressed: () {
                                  SystemChrome.setPreferredOrientations([
                                    DeviceOrientation.portraitUp,
                                    DeviceOrientation.portraitDown,
                                    DeviceOrientation.landscapeLeft,
                                    DeviceOrientation.landscapeRight,
                                  ]).then((_) {
                                    if (mounted) {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => StoryScreen(
                                            difficulty: widget.difficulty == Difficulty.EASY
                                                ? Difficulty.NORMAL
                                                : Difficulty.HARD,
                                          ),
                                        ),
                                      );
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _getNextDifficultyColor(),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.all(screenWidth * 0.02),
                                  shape: const CircleBorder(),
                                  elevation: 4,
                                ),
                                child: Icon(
                                  Icons.arrow_upward,
                                  size: screenWidth * 0.04,
                                ),
                              ),
                            ),
                          // Replay Button
                          Container(
                            margin: EdgeInsets.only(right: screenWidth * 0.02),
                            child: ElevatedButton(
                              onPressed: () {
                                SystemChrome.setPreferredOrientations([
                                  DeviceOrientation.portraitUp,
                                  DeviceOrientation.portraitDown,
                                  DeviceOrientation.landscapeLeft,
                                  DeviceOrientation.landscapeRight,
                                ]).then((_) {
                                  if (mounted) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => StoryScreen(
                                          difficulty: widget.difficulty,
                                        ),
                                      ),
                                    );
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getDifficultyColor(),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                shape: const CircleBorder(),
                                elevation: 4,
                              ),
                              child: Icon(
                                Icons.replay,
                                size: screenWidth * 0.04,
                              ),
                            ),
                          ),
                          // Main Menu Button
                          ElevatedButton(
                            onPressed: () {
                              SystemChrome.setPreferredOrientations([
                                DeviceOrientation.portraitUp,
                                DeviceOrientation.portraitDown,
                                DeviceOrientation.landscapeLeft,
                                DeviceOrientation.landscapeRight,
                              ]).then((_) {
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.all(screenWidth * 0.02),
                              shape: const CircleBorder(),
                              elevation: 4,
                            ),
                            child: Icon(
                              Icons.home,
                              size: screenWidth * 0.04,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

// Helper method for compact stat display
  Widget _buildCompactStat(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _getDifficultyColor(),
            size: 16,
          ),
          SizedBox(width: 4),
          Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFailureScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade900.withOpacity(0.9),
              Colors.red.shade700.withOpacity(0.8),
              Colors.red.shade500.withOpacity(0.7),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _completionFadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;

                return Column(
                  children: [
                    // Animated Header (Game Over Section)
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.02,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade600,
                              Colors.red.shade800,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Broken heart icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.red.shade300,
                                size: screenWidth * 0.07, // Larger icon
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            // Game Over text
                            Text(
                              'GAME OVER',
                              style: TextStyle(
                                fontSize: screenWidth * 0.07, // Larger font
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'TheLastShuriken',
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.6),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Lives Depleted',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04, // Larger font
                                color: Colors.red.shade200,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Main Content
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenHeight * 0.01,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Journey Progress
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(screenWidth * 0.02),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.flag,
                                        color: Colors.red.shade300,
                                        size: screenWidth * 0.04,
                                      ),
                                      SizedBox(width: screenWidth * 0.01),
                                      Text(
                                        'Journey Incomplete',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    'Your Kanji mastery wasn\'t strong enough to complete the trials.',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.025,
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Action Buttons
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Try Again Button
                          Container(
                            margin: EdgeInsets.only(right: screenWidth * 0.02),
                            child: ElevatedButton(
                              onPressed: () {
                                SystemChrome.setPreferredOrientations([
                                  DeviceOrientation.portraitUp,
                                  DeviceOrientation.portraitDown,
                                  DeviceOrientation.landscapeLeft,
                                  DeviceOrientation.landscapeRight,
                                ]).then((_) {
                                  if (mounted) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => StoryScreen(
                                          difficulty: widget.difficulty,
                                        ),
                                      ),
                                    );
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.all(screenWidth * 0.02), // Smaller padding
                                shape: const CircleBorder(),
                                elevation: 4,
                              ),
                              child: Icon(
                                Icons.refresh,
                                size: screenWidth * 0.04, // Smaller icon
                              ),
                            ),
                          ),
                          // Main Menu Button
                          ElevatedButton(
                            onPressed: () {
                              SystemChrome.setPreferredOrientations([
                                DeviceOrientation.portraitUp,
                                DeviceOrientation.portraitDown,
                                DeviceOrientation.landscapeLeft,
                                DeviceOrientation.landscapeRight,
                              ]).then((_) {
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.all(screenWidth * 0.02), // Smaller padding
                              shape: const CircleBorder(),
                              elevation: 4,
                            ),
                            child: Icon(
                              Icons.home,
                              size: screenWidth * 0.04, // Smaller icon
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Color _getNextDifficultyColor() {
    switch (widget.difficulty) {
      case Difficulty.EASY:
        return Colors.blue;
      case Difficulty.NORMAL:
        return Colors.red;
      case Difficulty.HARD:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showingCompletionScreen) {
      return _buildCompletionScreen();
    }

    if (_showingFailureScreen) {
      return _buildFailureScreen();
    }

    if (_currentStoryIndex >= _currentStoryBeats.length) {
      _currentStoryIndex = _currentStoryBeats.length - 1;
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    final StoryBeat currentBeat = _currentStoryBeats[_currentStoryIndex];

    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return GestureDetector(
              onTap: _showingQuestion && _selectedAnswer == null ? null : _nextStoryBeat,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Animated background
                  FadeTransition(
                    opacity: _backgroundFadeAnimation,
                    child: Image.asset(
                      'assets/images/backgrounds/${currentBeat.background}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.black,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.white, size: 48),
                          ),
                        );
                      },
                    ),
                  ),

                  // TOP SECTION - UI Controls
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Story title and difficulty
                          if (_currentStoryIndex == 0)
                            Column(
                              children: [
                                AnimatedTextKit(
                                  animatedTexts: [
                                    TypewriterAnimatedText(
                                      'Journey of the Kanji Seeker',
                                      textStyle: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width * 0.04,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'TheLastShuriken',
                                      ),
                                      speed: const Duration(milliseconds: 100),
                                    ),
                                  ],
                                  isRepeatingAnimation: false,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getDifficultyColor().withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getDifficultyColor(),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    'Difficulty: ${widget.difficulty.toString().split('.').last}',
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width * 0.015,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          // Enhanced lives and scoring display - Moved higher and simplified
                          if (_hasStartedQuestions)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Lives display
                                  _buildHeartsDisplay(),

                                  // Score display
                                  AnimatedBuilder(
                                    animation: _scoreScaleAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _scoreScaleAnimation.value,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                _getDifficultyColor().withOpacity(0.9),
                                                _getDifficultyColor().withOpacity(0.7),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.7),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.4),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.yellow,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$_correctAnswers/10',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Enhanced streak display
                                              if (_streak > 1) ...[
                                                const SizedBox(height: 4),
                                                _buildStreakDisplay(),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Action prompts
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showingQuestion
                                        ? (_showingFeedback
                                            ? (_isCorrect
                                                ? Icons.check_circle_outline
                                                : Icons.cancel)
                                            : _selectedAnswer == null
                                                ? Icons.help_outline
                                                : Icons.check_circle_outline)
                                        : (_isAtFinalStoryBeat() || _isFailureDialogue()
                                            ? Icons.flag
                                            : Icons.touch_app),
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _showingQuestion
                                        ? (_showingFeedback
                                            ? (_isCorrect ? 'Tap to continue' : 'Try again')
                                            : _selectedAnswer == null
                                                ? 'Select an answer'
                                                : 'Tap to check your answer')
                                        : (_isAtFinalStoryBeat() || _isFailureDialogue()
                                            ? 'Complete Journey'
                                            : 'Tap to continue'),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Animated Haruki character
                  AnimatedBuilder(
                    animation: _characterSlideAnimation,
                    builder: (context, child) {
                      return Positioned(
                        bottom: 0,
                        left: _characterSlideAnimation.value,
                        child: Image.asset(
                          'assets/images/characters/${currentBeat.harukiExpression}',
                          height: MediaQuery.of(context).size.height * 0.9,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 350,
                              width: 175,
                              color: Colors.transparent,
                            );
                          },
                        ),
                      );
                    },
                  ),

                  // Other character
                  if (currentBeat.character != null)
                    AnimatedBuilder(
                      animation: _characterAnimationController,
                      builder: (context, child) {
                        return Positioned(
                          bottom: 0,
                          right: _characterSlideAnimation.value.abs(),
                          child: Transform.scale(
                            scale: _characterAnimationController.value,
                            child: Image.asset(
                              'assets/images/characters/${currentBeat.character}',
                              height: MediaQuery.of(context).size.height * 0.9,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 350,
                                  width: 175,
                                  color: Colors.transparent,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),

                  // BOTTOM SECTION - Dialog content
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: FadeTransition(
                      opacity: _dialogFadeAnimation,
                      child: Container(
                        margin: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.25,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: _showingQuestion
                            ? _buildEnhancedQuestionView(currentBeat.question!)
                            : _buildEnhancedDialogView(currentBeat),
                      ),
                    ),
                  ),

                  // Achievement popup
                  if (_showAchievement)
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.3,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 50),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.yellow.withOpacity(0.9),
                                Colors.orange.withOpacity(0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Achievement Unlocked!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _currentAchievement,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Add this as a new Positioned widget in the Stack (after the achievement popup):
                  if (_showFloatingMessage)
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _floatingMessageAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _floatingMessageAnimation.value,
                              child: Transform.translate(
                                offset: Offset(0, -20 * _floatingMessageAnimation.value),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 50),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.withOpacity(0.9),
                                        Colors.orange.withOpacity(0.9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.favorite_border,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _floatingMessage,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Confetti animations
                  Positioned(
                    top: 0,
                    left: MediaQuery.of(context).size.width / 2,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: 1.5708,
                      emissionFrequency: 0.05,
                      numberOfParticles: 20,
                      gravity: 0.1,
                    ),
                  ),

                  // Completion confetti
                  Positioned(
                    top: 0,
                    left: MediaQuery.of(context).size.width / 4,
                    child: ConfettiWidget(
                      confettiController: _completionConfettiController,
                      blastDirection: 1.5708,
                      emissionFrequency: 0.02,
                      numberOfParticles: 50,
                      gravity: 0.05,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: MediaQuery.of(context).size.width / 4,
                    child: ConfettiWidget(
                      confettiController: _completionConfettiController,
                      blastDirection: 1.5708,
                      emissionFrequency: 0.02,
                      numberOfParticles: 50,
                      gravity: 0.05,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (widget.difficulty) {
      case Difficulty.EASY:
        return Colors.green;
      case Difficulty.NORMAL:
        return Colors.blue;
      case Difficulty.HARD:
        return Colors.red;
    }
  }

  Widget _buildEnhancedDialogView(StoryBeat beat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (beat.speaker != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getDifficultyColor().withOpacity(0.8),
                  _getDifficultyColor().withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Text(
              beat.speaker!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: "TheLastShuriken",
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: AnimatedTextKit(
            key: ValueKey(_currentStoryIndex),
            animatedTexts: [
              TypewriterAnimatedText(
                beat.text,
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                speed: const Duration(milliseconds: 50),
              ),
            ],
            isRepeatingAnimation: false,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedQuestionView(Question question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Enhanced question header with better styling
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.9),
                Colors.indigo.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.quiz,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              // Enhanced hint button
              if (!_showHint && _hintsUsed < 3)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.yellow.withOpacity(0.6), width: 2),
                  ),
                  child: IconButton(
                    onPressed: () {
                      _showHintForQuestion();
                      // Add haptic feedback
                      HapticFeedback.lightImpact();
                    },
                    icon: const Icon(
                      Icons.lightbulb,
                      color: Colors.yellow,
                      size: 18,
                    ),
                    tooltip: 'Get a hint (${3 - _hintsUsed} remaining)',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Enhanced hint display
        if (_showHint)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.yellow.withOpacity(0.3),
                  Colors.orange.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.yellow.withOpacity(0.7), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: Colors.yellow.shade800,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getHintForCurrentQuestion(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Enhanced feedback display
        if (_showingFeedback && _isCorrect)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.9),
                  Colors.green.shade600.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.green, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Excellent! You got it right! 🎉',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          // Enhanced answer options with original Wrap layout
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: question.options.map((option) {
              final bool isSelected = _selectedAnswer == option;
              return InkWell(
                onTap: () {
                  _selectAnswer(option);
                  // Add haptic feedback
                  HapticFeedback.selectionClick();
                },
                borderRadius: BorderRadius.circular(15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              _getDifficultyColor(),
                              _getDifficultyColor().withOpacity(0.7),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _getDifficultyColor().withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Enhanced radio button
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.black,
                                size: 12,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class StoryBeat {
  final String text;
  final String? speaker;
  final String background;
  final String? character;
  final CharacterPosition characterPosition;
  final Question? question;
  final String harukiExpression;

  StoryBeat({
    required this.text,
    this.speaker,
    required this.background,
    this.character,
    this.characterPosition = CharacterPosition.center,
    this.question,
    required this.harukiExpression,
  });
}

class Question {
  final String text;
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.text,
    required this.options,
    required this.correctAnswer,
  });
}

// EASY MODE - Simplest questions with obvious answers
final List<StoryBeat> easyStoryBeats = [
  // Introduction
  StoryBeat(
    text:
        'Haruki is a high school student who suddenly gets transported to a mysterious academy where every person he meets tests his Kanji skills. If he passes all 10 trials, he can return home—stronger and wiser.',
    background: 'Gate (Intro).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),

  // Interaction 1: Sensei Aki
  StoryBeat(
    text: 'Haruki wakes up in a classroom bathed in golden light. A kind-looking woman greets him.',
    background: 'Classroom (Inter1).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Aki-sensei',
    text: 'Welcome, Haruki. To move forward, you must understand the basics.',
    background: 'Classroom (Inter1).png',
    character: 'Aki sensei (Delighted).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Classroom (Inter1).png',
    character: 'Aki sensei (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'What does this Kanji mean: 学 (がく)?',
      options: ['A. Tree', 'B. Study', 'C. Moon', 'D. Wind'],
      correctAnswer: 'B. Study',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 2: Yuto
  StoryBeat(
    text: 'Haruki meets a shy first-year named Yuto in the hallway.',
    background: 'Hallway (Inter2).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Yuto',
    text: 'I always mix up the word for "student"... Can you help me figure it out?',
    background: 'Hallway (Inter2).png',
    character: 'Yuto (Sad).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text: '',
    background: 'Hallway (Inter2).png',
    character: 'Yuto (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'Which word means "student"?',
      options: ['A. 先生', 'B. 学生', 'C. 水生', 'D. 車生'],
      correctAnswer: 'B. 学生',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 3: Hana
  StoryBeat(
    text: 'In the library, Haruki meets Hana surrounded by textbooks.',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Hana',
    text: 'I\'m writing a journal entry. Can you help me identify the word for "school"?',
    background: 'Library (Inter3).png',
    character: 'Hana (Delighted).png',
    characterPosition: CharacterPosition.left,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Library (Inter3).png',
    character: 'Hana (Normal).png',
    characterPosition: CharacterPosition.left,
    question: Question(
      text: 'Which word means "school"?',
      options: ['A. 学校', 'B. 教室', 'C. 大学', 'D. 図書館'],
      correctAnswer: 'A. 学校',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 4: Kenta
  StoryBeat(
    text: 'Kenta jogs past Haruki on the school field.',
    background: 'Athletics Track (Inter4).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Kenta',
    text: 'Every day I climb the hills near here. Do you know the Kanji for "mountain"?',
    background: 'Athletics Track (Inter4).png',
    character: 'Kenta (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Laugh).png',
  ),
  StoryBeat(
    text: '',
    background: 'Athletics Track (Inter4).png',
    character: 'Kenta (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'Choose the correct Kanji for "mountain":',
      options: ['A. 山', 'B. 川', 'C. 木', 'D. 田'],
      correctAnswer: 'A. 山',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 5: Emi
  StoryBeat(
    text: 'Haruki sees Emi adjusting a sundial in the courtyard.',
    background: 'Courtyard (Inter5).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Emi',
    text: 'Time is precious. Do you know the Kanji that means "time"?',
    background: 'Courtyard (Inter5).png',
    character: 'Emi (Smug).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Courtyard (Inter5).png',
    character: 'Emi (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'Which Kanji means "time"?',
      options: ['A. 日', 'B. 年', 'C. 時', 'D. 分'],
      correctAnswer: 'C. 時',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 6: Sota
  StoryBeat(
    text: 'Sota breathes fire on stage during a play rehearsal.',
    background: 'Stage (Inter6).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Sota',
    text: 'Fire is my favorite symbol. Can you pick the right Kanji for it?',
    background: 'Stage (Inter6).png',
    character: 'Sota (Laugh).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Laugh).png',
  ),
  StoryBeat(
    text: '',
    background: 'Stage (Inter6).png',
    character: 'Sota (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'Which one means "fire"?',
      options: ['A. 水', 'B. 火', 'C. 木', 'D. 石'],
      correctAnswer: 'B. 火',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 7: Nao
  StoryBeat(
    text: 'Nao dives into the pool with a splash.',
    background: 'Pool (Inter7).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Nao',
    text: 'I love water. It flows like words in a sentence. Can you recognize it?',
    background: 'Pool (Inter7).png',
    character: 'Nao (Smile).png',
    characterPosition: CharacterPosition.left,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Pool (Inter7).png',
    character: 'Nao (Normal).png',
    characterPosition: CharacterPosition.left,
    question: Question(
      text: 'What is the Kanji for "water"?',
      options: ['A. 火', 'B. 土', 'C. 水', 'D. 風'],
      correctAnswer: 'C. 水',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 8: Toshi
  StoryBeat(
    text: 'In the calligraphy room, Toshi shows Haruki a half-written scroll.',
    background: 'Arts Room (Inter8).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Toshi',
    text: 'Which word means "principal" of a school?',
    background: 'Arts Room (Inter8).png',
    character: 'Toshi (Delighted).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Arts Room (Inter8).png',
    character: 'Toshi (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'Which means "school principal"?',
      options: ['A. 学生', 'B. 校長', 'C. 先生', 'D. 学校'],
      correctAnswer: 'B. 校長',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 9: Mei
  StoryBeat(
    text: 'Mei greets Haruki with a bright smile in the study hall.',
    background: 'Student Council Room (Inter9).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Mei',
    text: 'I want to be a university student one day. Do you know how to say that in Kanji?',
    background: 'Student Council Room (Inter9).png',
    character: 'Mei (Smile2).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Student Council Room (Inter9).png',
    character: 'Mei (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'What is the correct phrase for "university student"?',
      options: ['A. 小学生', 'B. 大学生', 'C. 学生大', 'D. 高校生'],
      correctAnswer: 'B. 大学生',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 10: Professor Hoshino
  StoryBeat(
    text: 'Haruki enters the final chamber, where an older professor awaits.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Professor Hoshino',
    text:
        'To return to your world, you must master this final challenge. Form a complete and meaningful phrase.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Normal).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Smug).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'Which of the following means "Japanese language"?',
      options: ['A. 中国語', 'B. 英語', 'C. 日本語', 'D. 語日本'],
      correctAnswer: 'C. 日本語',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Ending
  StoryBeat(
    text:
        'As Haruki answers the final question, the air around him shimmers with golden light. Professor Hoshino smiles and slowly closes the ancient book he had been holding.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Smile1).png',
  ),
  StoryBeat(
    speaker: 'Professor Hoshino',
    text:
        'You\'ve done well, Haruki. You walked the path of the Kanji Seeker, not only memorizing characters—but understanding their meaning in life, through people, and through purpose.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Smile2).png',
  ),
  StoryBeat(
    text:
        'The ground beneath Haruki glows. One by one, all the people he met—Aki-sensei, Yuto, Hana, Kenta, Emi, Sota, Nao, Toshi, Mei—appear around him in a circle. They bow respectfully.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Aki-sensei',
    text:
        'Remember, Kanji is not just for tests. It\'s a mirror of culture, history, and identity.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Aki sensei (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Mei',
    text: 'We\'ll always be part of your story, even when you go back.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Mei (Delighted).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text:
        'The characters begin to fade into glowing symbols, swirling around Haruki as the notebook reappears in his hands. A soft wind blows, carrying the sound of distant school bells.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text:
        'Haruki opens his eyes…\n\nHe\'s back in the real-world school library, sitting exactly where he first found the notebook. The mysterious title on the cover still reads "The Path of Characters," but now—there\'s a new inscription on the last page:\n\n"Those who seek meaning will always find it—in words, in people, in themselves."',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    text:
        'Haruki smiles, stands up, and looks out the window.\n\nFrom that day forward, he approaches his Kanji studies not as a chore—but as a journey.',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Smile2).png',
  ),
  StoryBeat(
    text:
        'Congratulations! You\'ve completed your Kanji Journey with Haruki.\nBut remember—this is only the beginning of your own adventure in Japanese learning!',
    background: 'Gate (Intro).png',
    harukiExpression: 'Haruki (Smile1).png',
  ),
];

// NORMAL MODE - Original story with moderate difficulty
final List<StoryBeat> normalStoryBeats = [
  // Introduction
  StoryBeat(
    text:
        'Haruki is a high school student who suddenly gets transported to a mysterious academy where every person he meets tests his Kanji skills. If he passes all 10 trials, he can return home—stronger and wiser.',
    background: 'Gate (Intro).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),

  // Interaction 1: Sensei Aki
  StoryBeat(
    text: 'Haruki wakes up in a classroom bathed in golden light. A kind-looking woman greets him.',
    background: 'Classroom (Inter1).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Aki-sensei',
    text: 'Welcome, Haruki. To move forward, you must understand the basics.',
    background: 'Classroom (Inter1).png',
    character: 'Aki sensei (Delighted).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Classroom (Inter1).png',
    character: 'Aki sensei (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'What does this Kanji mean: 学 (がく)?',
      options: ['A. Tree', 'B. Study', 'C. Moon', 'D. Wind'],
      correctAnswer: 'B. Study',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 2: Yuto
  StoryBeat(
    text: 'Haruki meets a shy first-year named Yuto in the hallway.',
    background: 'Hallway (Inter2).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Yuto',
    text: 'I always mix up the word for "student"... Can you help me figure it out?',
    background: 'Hallway (Inter2).png',
    character: 'Yuto (Sad).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text: '',
    background: 'Hallway (Inter2).png',
    character: 'Yuto (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'Which Kanji completes this phrase: ___生 (student)?',
      options: ['A. 校', 'B. 学', 'C. 水', 'D. 本'],
      correctAnswer: 'B. 学',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 3: Hana
  StoryBeat(
    text: 'In the library, Haruki meets Hana surrounded by textbooks.',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Hana',
    text:
        'I\'m writing a journal entry. Can you help complete this sentence: わたしは ___校に 行きます。 ("I go to school.")',
    background: 'Library (Inter3).png',
    character: 'Hana (Delighted).png',
    characterPosition: CharacterPosition.left,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Library (Inter3).png',
    character: 'Hana (Normal).png',
    characterPosition: CharacterPosition.left,
    question: Question(
      text: 'Which word best completes the sentence?',
      options: ['A. 学', 'B. 校', 'C. 学校', 'D. 生'],
      correctAnswer: 'C. 学校',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 4: Kenta
  StoryBeat(
    text: 'Kenta jogs past Haruki on the school field.',
    background: 'Athletics Track (Inter4).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Kenta',
    text: 'Every day I climb the hills near here. Do you know the Kanji for "mountain"?',
    background: 'Athletics Track (Inter4).png',
    character: 'Kenta (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Laugh).png',
  ),
  StoryBeat(
    text: '',
    background: 'Athletics Track (Inter4).png',
    character: 'Kenta (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'Choose the correct Kanji for "mountain":',
      options: ['A. 山', 'B. 火', 'C. 木', 'D. 空'],
      correctAnswer: 'A. 山',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 5: Emi
  StoryBeat(
    text: 'Haruki sees Emi adjusting a sundial in the courtyard.',
    background: 'Courtyard (Inter5).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Emi',
    text: 'Time is precious. Do you know the Kanji that means "time"?',
    background: 'Courtyard (Inter5).png',
    character: 'Emi (Smug).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Courtyard (Inter5).png',
    character: 'Emi (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'Which Kanji means "time"?',
      options: ['A. 日', 'B. 分', 'C. 時', 'D. 曜'],
      correctAnswer: 'C. 時',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 6: Sota
  StoryBeat(
    text: 'Sota breathes fire on stage during a play rehearsal.',
    background: 'Stage (Inter6).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Sota',
    text: 'Fire is my favorite symbol. Can you pick the right Kanji for it?',
    background: 'Stage (Inter6).png',
    character: 'Sota (Laugh).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Laugh).png',
  ),
  StoryBeat(
    text: '',
    background: 'Stage (Inter6).png',
    character: 'Sota (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'Which one means "fire"?',
      options: ['A. 水', 'B. 火', 'C. 光', 'D. 石'],
      correctAnswer: 'B. 火',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 7: Nao
  StoryBeat(
    text: 'Nao dives into the pool with a splash.',
    background: 'Pool (Inter7).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Nao',
    text: 'I love water. It flows like words in a sentence. Can you recognize it?',
    background: 'Pool (Inter7).png',
    character: 'Nao (Smile).png',
    characterPosition: CharacterPosition.left,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Pool (Inter7).png',
    character: 'Nao (Normal).png',
    characterPosition: CharacterPosition.left,
    question: Question(
      text: 'What is the Kanji for "water"?',
      options: ['A. 雨', 'B. 氷', 'C. 水', 'D. 海'],
      correctAnswer: 'C. 水',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 8: Toshi
  StoryBeat(
    text: 'In the calligraphy room, Toshi shows Haruki a half-written scroll.',
    background: 'Arts Room (Inter8).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Toshi',
    text: 'I\'m writing "school principal". Which combination should I use?',
    background: 'Arts Room (Inter8).png',
    character: 'Toshi (Delighted).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Arts Room (Inter8).png',
    character: 'Toshi (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'Which Kanji pair means "school principal"?',
      options: ['A. 学生', 'B. 校長', 'C. 大学', 'D. 学本'],
      correctAnswer: 'B. 校長',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 9: Mei
  StoryBeat(
    text: 'Mei greets Haruki with a bright smile in the study hall.',
    background: 'Student Council Room (Inter9).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Mei',
    text: 'I want to be a university student one day. Do you know how to say that in Kanji?',
    background: 'Student Council Room (Inter9).png',
    character: 'Mei (Smile2).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Student Council Room (Inter9).png',
    character: 'Mei (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'What is the correct phrase for "university student"?',
      options: ['A. 高学校', 'B. 大学生', 'C. 学生大', 'D. 大高生'],
      correctAnswer: 'B. 大学生',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 10: Professor Hoshino
  StoryBeat(
    text: 'Haruki enters the final chamber, where an older professor awaits.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Professor Hoshino',
    text:
        'To return to your world, you must master this final challenge. Form a complete and meaningful phrase.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Normal).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Smug).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'Which of the following means "Japanese language"?',
      options: ['A. 日語', 'B. 本日', 'C. 日本語', 'D. 語日'],
      correctAnswer: 'C. 日本語',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Ending (same as easy mode)
  StoryBeat(
    text:
        'As Haruki answers the final question, the air around him shimmers with golden light. Professor Hoshino smiles and slowly closes the ancient book he had been holding.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Smile1).png',
  ),
  StoryBeat(
    speaker: 'Professor Hoshino',
    text:
        'You\'ve done well, Haruki. You walked the path of the Kanji Seeker, not only memorizing characters—but understanding their meaning in life, through people, and through purpose.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Smile2).png',
  ),
  StoryBeat(
    text:
        'The ground beneath Haruki glows. One by one, all the people he met—Aki-sensei, Yuto, Hana, Kenta, Emi, Sota, Nao, Toshi, Mei—appear around him in a circle. They bow respectfully.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Aki-sensei',
    text:
        'Remember, Kanji is not just for tests. It\'s a mirror of culture, history, and identity.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Aki sensei (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Mei',
    text: 'We\'ll always be part of your story, even when you go back.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Mei (Delighted).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text:
        'The characters begin to fade into glowing symbols, swirling around Haruki as the notebook reappears in his hands. A soft wind blows, carrying the sound of distant school bells.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text:
        'Haruki opens his eyes…\n\nHe\'s back in the real-world school library, sitting exactly where he first found the notebook. The mysterious title on the cover still reads "The Path of Characters," but now—there\'s a new inscription on the last page:\n\n"Those who seek meaning will always find it—in words, in people, in themselves."',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    text:
        'Haruki smiles, stands up, and looks out the window.\n\nFrom that day forward, he approaches his Kanji studies not as a chore—but as a journey.',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Smile2).png',
  ),
  StoryBeat(
    text:
        'Congratulations! You\'ve completed your Kanji Journey with Haruki.\nBut remember—this is only the beginning of your own adventure in Japanese learning!',
    background: 'Gate (Intro).png',
    harukiExpression: 'Haruki (Smile1).png',
  ),
];

// HARD MODE - More complex questions with challenging options
final List<StoryBeat> hardStoryBeats = [
  // Introduction
  StoryBeat(
    text:
        'Haruki is a high school student who suddenly gets transported to a mysterious academy where every person he meets tests his Kanji skills. If he passes all 10 trials, he can return home—stronger and wiser.',
    background: 'Gate (Intro).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),

  // Interaction 1: Sensei Aki
  StoryBeat(
    text: 'Haruki wakes up in a classroom bathed in golden light. A kind-looking woman greets him.',
    background: 'Classroom (Inter1).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Aki-sensei',
    text: '学びの旅へようこそ、春樹くん。前に進むためには、基本を理解しなければなりません。',
    background: 'Classroom (Inter1).png',
    character: 'Aki sensei (Delighted).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Classroom (Inter1).png',
    character: 'Aki sensei (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'In the phrase 「学びの旅」(manabi no tabi), what does 学び mean?',
      options: ['A. To travel', 'B. To teach', 'C. To learn', 'D. To write'],
      correctAnswer: 'C. To learn',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 2: Yuto
  StoryBeat(
    text: 'Haruki meets a shy first-year named Yuto in the hallway.',
    background: 'Hallway (Inter2).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Yuto',
    text: '私は学生ですが、「学」と「生」の漢字の意味をいつも混同してしまいます。助けてくれませんか？',
    background: 'Hallway (Inter2).png',
    character: 'Yuto (Sad).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text: '',
    background: 'Hallway (Inter2).png',
    character: 'Yuto (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'What is the correct meaning of the compound 学生 (gakusei)?',
      options: ['A. Someone who studies life', 'B. A student', 'C. A teacher', 'D. School life'],
      correctAnswer: 'B. A student',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 3: Hana
  StoryBeat(
    text: 'In the library, Haruki meets Hana surrounded by textbooks.',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Hana',
    text: '日記を書いています。この文章を完成させるのを手伝ってくれませんか？「私は毎日＿＿＿に行きます。」',
    background: 'Library (Inter3).png',
    character: 'Hana (Delighted).png',
    characterPosition: CharacterPosition.left,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Library (Inter3).png',
    character: 'Hana (Normal).png',
    characterPosition: CharacterPosition.left,
    question: Question(
      text: 'Which would be most natural to complete "私は毎日＿＿＿に行きます。" (I go to ___ every day)?',
      options: ['A. 大学校', 'B. 学校', 'C. 公園校', 'D. 図校'],
      correctAnswer: 'B. 学校',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 4: Kenta
  StoryBeat(
    text: 'Kenta jogs past Haruki on the school field.',
    background: 'Athletics Track (Inter4).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Kenta',
    text: '毎日、近くの山を登っています。山と川、どちらの漢字がより複雑だと思いますか？',
    background: 'Athletics Track (Inter4).png',
    character: 'Kenta (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Laugh).png',
  ),
  StoryBeat(
    text: '',
    background: 'Athletics Track (Inter4).png',
    character: 'Kenta (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'In the compound 山川 (yamagawa), which meaning is correct?',
      options: [
        'A. Mountains and rivers',
        'B. A mountain river',
        'C. A person\'s name',
        'D. A mountain range'
      ],
      correctAnswer: 'A. Mountains and rivers',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 5: Emi
  StoryBeat(
    text: 'Haruki sees Emi adjusting a sundial in the courtyard.',
    background: 'Courtyard (Inter5).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Emi',
    text: '時は貴重です。「時間」と「時計」の違いは何ですか？',
    background: 'Courtyard (Inter5).png',
    character: 'Emi (Smug).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Courtyard (Inter5).png',
    character: 'Emi (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'What is the difference between 時間 (jikan) and 時計 (tokei)?',
      options: [
        'A. 時間 means clock and 時計 means time',
        'B. 時間 means time and 時計 means clock',
        'C. They are synonyms with no difference',
        'D. 時間 is used only for past time, 時計 for future time'
      ],
      correctAnswer: 'B. 時間 means time and 時計 means clock',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 6: Sota
  StoryBeat(
    text: 'Sota breathes fire on stage during a play rehearsal.',
    background: 'Stage (Inter6).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Sota',
    text: '火は私の好きなシンボルです。「火山」という言葉の意味は何ですか？',
    background: 'Stage (Inter6).png',
    character: 'Sota (Laugh).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Laugh).png',
  ),
  StoryBeat(
    text: '',
    background: 'Stage (Inter6).png',
    character: 'Sota (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'What does the compound 火山 (kazan) mean?',
      options: ['A. Fire mountain (volcano)', 'B. Forest fire', 'C. Burning tree', 'D. Campfire'],
      correctAnswer: 'A. Fire mountain (volcano)',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 7: Nao
  StoryBeat(
    text: 'Nao dives into the pool with a splash.',
    background: 'Pool (Inter7).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Nao',
    text: '水が大好きです。文章の中の言葉のように流れます。この漢字「泳」の意味は何ですか？',
    background: 'Pool (Inter7).png',
    character: 'Nao (Smile).png',
    characterPosition: CharacterPosition.left,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Pool (Inter7).png',
    character: 'Nao (Normal).png',
    characterPosition: CharacterPosition.left,
    question: Question(
      text: 'What does the Kanji 泳 in 水泳 (suiei) mean?',
      options: ['A. To drink', 'B. To swim', 'C. To wash', 'D. To flow'],
      correctAnswer: 'B. To swim',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 8: Toshi
  StoryBeat(
    text: 'In the calligraphy room, Toshi shows Haruki a half-written scroll.',
    background: 'Arts Room (Inter8).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Toshi',
    text: '「校長先生」と書いています。「長」の意味は何ですか？',
    background: 'Arts Room (Inter8).png',
    character: 'Toshi (Delighted).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Arts Room (Inter8).png',
    character: 'Toshi (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'In the phrase 校長先生 (kouchou sensei), what does 長 mean?',
      options: ['A. Old', 'B. Long', 'C. Head/Chief', 'D. Teacher'],
      correctAnswer: 'C. Head/Chief',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 9: Mei
  StoryBeat(
    text: 'Mei greets Haruki with a bright smile in the study hall.',
    background: 'Student Council Room (Inter9).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Mei',
    text: 'いつか大学生になりたいです。「大学院生」という言葉の意味は何ですか？',
    background: 'Student Council Room (Inter9).png',
    character: 'Mei (Smile2).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Student Council Room (Inter9).png',
    character: 'Mei (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'What does 大学院生 (daigakuinsei) mean compared to 大学生 (daigakusei)?',
      options: [
        'A. High school student vs. university student',
        'B. University student vs. graduate student',
        'C. Elementary student vs. university student',
        'D. First-year student vs. senior student'
      ],
      correctAnswer: 'B. University student vs. graduate student',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 10: Professor Hoshino
  StoryBeat(
    text: 'Haruki enters the final chamber, where an older professor awaits.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Professor Hoshino',
    text: 'あなたの世界に戻るためには、この最後の挑戦をマスターする必要があります。意味のある文章を作りなさい。',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Normal).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Smug).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'Which of these phrases correctly means "I am studying Japanese at university"?',
      options: [
        'A. 私は大学で日本語を勉強しています',
        'B. 私は日本語で大学を勉強しています',
        'C. 私は勉強で日本語を大学しています',
        'D. 私は大学を日本語で勉強しています'
      ],
      correctAnswer: 'A. 私は大学で日本語を勉強しています',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Ending (same as other modes)
  StoryBeat(
    text:
        'As Haruki answers the final question, the air around him shimmers with golden light. Professor Hoshino smiles and slowly closes the ancient book he had been holding.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Smile1).png',
  ),
  StoryBeat(
    speaker: 'Professor Hoshino',
    text:
        'You\'ve done well, Haruki. You walked the path of the Kanji Seeker, not only memorizing characters—but understanding their meaning in life, through people, and through purpose.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Smile2).png',
  ),
  StoryBeat(
    text:
        'The ground beneath Haruki glows. One by one, all the people he met—Aki-sensei, Yuto, Hana, Kenta, Emi, Sota, Nao, Toshi, Mei—appear around him in a circle. They bow respectfully.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Aki-sensei',
    text:
        'Remember, Kanji is not just for tests. It\'s a mirror of culture, history, and identity.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Aki sensei (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Mei',
    text: 'We\'ll always be part of your story, even when you go back.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Mei (Delighted).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text:
        'The characters begin to fade into glowing symbols, swirling around Haruki as the notebook reappears in his hands. A soft wind blows, carrying the sound of distant school bells.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text:
        'Haruki opens his eyes…\n\nHe\'s back in the real-world school library, sitting exactly where he first found the notebook. The mysterious title on the cover still reads "The Path of Characters," but now—there\'s a new inscription on the last page:\n\n"Those who seek meaning will always find it—in words, in people, in themselves."',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    text:
        'Haruki smiles, stands up, and looks out the window.\n\nFrom that day forward, he approaches his Kanji studies not as a chore—but as a journey.',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Smile2).png',
  ),
  StoryBeat(
    text:
        'Congratulations! You\'ve completed your Kanji Journey with Haruki.\nBut remember—this is only the beginning of your own adventure in Japanese learning!',
    background: 'Gate (Intro).png',
    harukiExpression: 'Haruki (Smile1).png',
  ),
];
