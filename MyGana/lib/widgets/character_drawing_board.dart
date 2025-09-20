import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nihongo_japanese_app/models/japanese_character.dart';
import 'package:nihongo_japanese_app/models/user_progress.dart';
import 'package:nihongo_japanese_app/services/character_recognition_service.dart';
import 'package:nihongo_japanese_app/services/progress_service.dart';
import 'package:painter/painter.dart';

class CharacterDrawingBoard extends StatefulWidget {
  final JapaneseCharacter character;
  final bool showStrokeOrder;
  final bool showHints;
  final Function(bool)? onExpandStateChanged;
  final bool initialExpandedState;
  final bool showSvgGuideline;
  final bool enableRecognition;
  final bool enableRealTimeRecognition;
  final Function(RecognitionResult)? onRecognitionComplete;

  const CharacterDrawingBoard({
    super.key,
    required this.character,
    this.showStrokeOrder = true,
    this.showHints = true,
    this.onExpandStateChanged,
    this.initialExpandedState = true,
    this.showSvgGuideline = true,
    this.enableRecognition = true,
    this.enableRealTimeRecognition = true,
    this.onRecognitionComplete,
  });

  @override
  State<CharacterDrawingBoard> createState() => _CharacterDrawingBoardState();
}

class _CharacterDrawingBoardState extends State<CharacterDrawingBoard>
    with SingleTickerProviderStateMixin {
  List<List<Offset>> _userStrokes = [];
  List<Offset> _currentStroke = [];
  bool _isDrawing = false;

  // Current stroke hint
  final int _currentStrokeHint = 0;
  final bool _showingHint = false;
  final bool _showStrokeDirections = false;

  late AnimationController _animationController;

  // Grid for alignment
  bool _showGrid = true;
  bool _showSvgGuideline = true;

  // Drawing settings
  final Color _strokeColor = Colors.deepPurple;
  final double _minBrushWidth = 3.0;
  final double _maxBrushWidth = 12.0;

  // Drawing mode
  final bool _isGuidedMode = true;

  // Painter controller
  late PainterController _painterController;

  // Recognition and feedback
  final CharacterRecognitionService _recognitionService = CharacterRecognitionService();
  final ProgressService _progressService = ProgressService();
  RecognitionResult? _lastRecognitionResult;
  RecognitionResult? _realTimeResult;
  bool _isRecognizing = false;
  bool _showRecognitionResult = false;
  bool _showRealTimeFeedback = false;
  late ConfettiController _confettiController;

  // Real-time recognition timer
  Timer? _recognitionTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });

    // Initialize painter controller
    _painterController = PainterController();

    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    // Initialize progress service
    _progressService.initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _painterController.dispose();
    _confettiController.dispose();
    _recognitionTimer?.cancel();
    super.dispose();
  }

  void _clearDrawing() {
    setState(() {
      _userStrokes = [];
      _currentStroke = [];
      _isDrawing = false;
      _showRecognitionResult = false;
      _showRealTimeFeedback = false;
      _lastRecognitionResult = null;
      _realTimeResult = null;

      // Clear painter
      _painterController.clear();
    });

    // Cancel any pending recognition
    _recognitionTimer?.cancel();
  }

  // Real-time recognition as user draws
  void _triggerRealTimeRecognition() {
    if (!widget.enableRealTimeRecognition || _userStrokes.isEmpty) return;

    // Cancel previous timer
    _recognitionTimer?.cancel();

    // Set a longer delay to avoid too frequent recognition and improve performance
    _recognitionTimer = Timer(const Duration(milliseconds: 800), () async {
      if (_userStrokes.isNotEmpty && mounted) {
        await _performRealTimeRecognition();
      }
    });
  }

  Future<void> _performRealTimeRecognition() async {
    if (_userStrokes.isEmpty) return;

    try {
      final result = await _recognitionService.recognizeCharacter(
        _userStrokes,
        widget.character,
      );

      setState(() {
        _realTimeResult = result;
        _showRealTimeFeedback = true;
      });

      // Auto-hide real-time feedback after 3 seconds for better user experience
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showRealTimeFeedback = false;
          });
        }
      });
    } catch (e) {
      // Silently handle errors for real-time recognition
      print('Real-time recognition error: $e');
    }
  }

  Future<void> _checkCharacter() async {
    if (!widget.enableRecognition || _userStrokes.isEmpty) return;

    setState(() {
      _isRecognizing = true;
    });

    try {
      final result = await _recognitionService.recognizeCharacter(
        _userStrokes,
        widget.character,
      );

      setState(() {
        _lastRecognitionResult = result;
        _showRecognitionResult = true;
        _isRecognizing = false;
      });

      // Update progress
      await _updateProgress(result);

      // Show confetti for correct recognition
      if (result.isCorrect) {
        _confettiController.play();
        // Add success haptic feedback
        HapticFeedback.mediumImpact();
      } else {
        // Add gentle feedback for incorrect attempt
        HapticFeedback.lightImpact();
      }

      // Notify parent widget
      widget.onRecognitionComplete?.call(result);

      // Auto-hide result after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showRecognitionResult = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isRecognizing = false;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recognition failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProgress(RecognitionResult result) async {
    try {
      final characterProgress =
          _progressService.getUserProgress().characterProgress[widget.character.character];

      if (characterProgress != null) {
        // Update mastery level based on accuracy
        final accuracyScore = result.accuracyScore / 100.0;
        characterProgress.updateMastery(accuracyScore);

        // Add stroke evaluation
        characterProgress.addEvaluation(StrokeEvaluation(
          strokeCountScore: result.isCorrect ? 100.0 : 50.0,
          strokeOrderScore: result.isCorrect ? 100.0 : 50.0,
          positionScore: result.accuracyScore,
          directionScore: result.accuracyScore,
          overallScore: result.accuracyScore,
          evaluatedAt: DateTime.now(),
        ));
      } else {
        // Create new character progress
        final newProgress = CharacterProgress(
          character: widget.character.character,
          characterType: widget.character.type,
        );
        newProgress.updateMastery(result.accuracyScore / 100.0);
        _progressService.getUserProgress().characterProgress[widget.character.character] =
            newProgress;
      }

      // Save progress
      await _progressService.saveProgress();
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        // Background grid
        if (_showGrid)
          CustomPaint(
            painter: GridPainter(
              color: colorScheme.onSurface.withAlpha((0.1 * 255).round()),
              centerColor: colorScheme.primary.withAlpha((0.2 * 255).round()),
            ),
            child: Container(),
          ),

        // SVG guideline for tracing
        if (_showSvgGuideline && widget.character.fullSvgPath != null) _buildSvgGuideline(),

        // Stroke order guide (if stroke data becomes available)
        if (widget.showStrokeOrder && widget.character.strokeOrder.isNotEmpty && _isGuidedMode)
          CustomPaint(
            painter: StrokeOrderPainter(
              strokes: widget.character.strokeOrder,
              currentStroke: _currentStrokeHint,
              showAllStrokes: _showingHint,
              color: colorScheme.primary.withAlpha((0.3 * 255).round()),
            ),
            child: Container(),
          ),

        // User's drawing using Painter
        GestureDetector(
          onPanStart: (details) {
            final size = context.size!;

            // Add haptic feedback for better user experience
            HapticFeedback.lightImpact();

            setState(() {
              _isDrawing = true;
              _currentStroke = [
                Offset(
                  details.localPosition.dx / size.width,
                  details.localPosition.dy / size.height,
                ),
              ];
            });
          },
          onPanUpdate: (details) {
            if (_isDrawing) {
              final size = context.size!;
              final currentPoint = details.localPosition;

              setState(() {
                _currentStroke.add(
                  Offset(
                    currentPoint.dx / size.width,
                    currentPoint.dy / size.height,
                  ),
                );
              });
            }
          },
          onPanEnd: (details) {
            setState(() {
              _isDrawing = false;
              if (_currentStroke.isNotEmpty) {
                _userStrokes.add(List.from(_currentStroke));
                _currentStroke = [];

                // Trigger real-time recognition after each stroke
                _triggerRealTimeRecognition();
              }
            });
          },
          child: RepaintBoundary(
            child: CustomPaint(
              painter: BrushDrawingPainter(
                strokes: _userStrokes,
                currentStroke: _currentStroke,
                strokeColor: _strokeColor,
                minStrokeWidth: _minBrushWidth,
                maxStrokeWidth: _maxBrushWidth,
              ),
              child: Container(),
            ),
          ),
        ),

        // Stroke direction hint
        if (widget.showHints && _showStrokeDirections && widget.character.strokeDirections != null)
          _buildStrokeDirectionHint(),

        // Real-time feedback overlay
        if (_showRealTimeFeedback && _realTimeResult != null) _buildRealTimeFeedbackOverlay(),

        // Recognition result overlay
        if (_showRecognitionResult && _lastRecognitionResult != null)
          _buildRecognitionResultOverlay(),

        // Recognition loading overlay
        if (_isRecognizing) _buildRecognitionLoadingOverlay(),

        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: math.pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            maxBlastForce: 20,
            minBlastForce: 10,
            gravity: 0.1,
          ),
        ),

        // Drawing tools - compact version for fullscreen
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surface.withAlpha((0.85 * 255).round()),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.15 * 255).round()),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCompactToolButton(
                    icon: Icons.brush,
                    isActive: true,
                    onPressed: () {}, // Always active now
                    tooltip: 'Brush',
                  ),
                  const SizedBox(width: 4),
                  _buildCompactToolButton(
                    icon: Icons.undo,
                    onPressed: () {
                      if (_userStrokes.isNotEmpty) {
                        setState(() {
                          _userStrokes.removeLast();
                        });
                      }
                    },
                    tooltip: 'Undo',
                  ),
                  const SizedBox(width: 4),
                  _buildCompactToolButton(
                    icon: Icons.delete,
                    onPressed: _clearDrawing,
                    tooltip: 'Clear',
                  ),
                  const SizedBox(width: 4),
                  _buildCompactToolButton(
                    icon: Icons.grid_on,
                    isActive: _showGrid,
                    onPressed: _toggleGrid,
                    tooltip: 'Toggle Grid',
                  ),
                  const SizedBox(width: 4),
                  _buildCompactToolButton(
                    icon: Icons.format_shapes,
                    isActive: _showSvgGuideline,
                    onPressed: _toggleSvgGuideline,
                    tooltip: 'Toggle Guideline',
                  ),
                  if (widget.enableRecognition) ...[
                    const SizedBox(width: 4),
                    _buildCompactToolButton(
                      icon: Icons.check_circle,
                      onPressed: _userStrokes.isNotEmpty ? _checkCharacter : null,
                      isActive: _userStrokes.isNotEmpty,
                      tooltip: 'Check Character',
                      color: _userStrokes.isNotEmpty ? Colors.green : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactToolButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isActive = false,
    String? tooltip,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive
              ? color ?? colorScheme.primary
              : colorScheme.surface.withAlpha((0.5 * 255).round()),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: isActive ? colorScheme.onPrimary : color ?? colorScheme.onSurface,
            size: 18,
          ),
          onPressed: onPressed,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildRealTimeFeedbackOverlay() {
    final result = _realTimeResult!;

    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: result.isCorrect ? Colors.green.withOpacity(0.9) : Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  result.isCorrect ? Icons.check_circle : Icons.info,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecognitionResultOverlay() {
    final result = _lastRecognitionResult!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Result icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: result.isCorrect
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    result.isCorrect ? Icons.check_circle : Icons.info,
                    size: 40,
                    color: result.isCorrect ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),

                // Result text
                Text(
                  result.isCorrect ? 'Correct!' : 'Try Again',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: result.isCorrect ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),

                // Target character only
                Center(
                  child: _buildCharacterDisplay(
                    'Target:',
                    widget.character.character,
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // ML confidence display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        ' Confidence',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(result.confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Accuracy score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Accuracy: ${result.accuracyScore.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Feedback message
                Text(
                  result.feedback,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showRecognitionResult = false;
                        });
                      },
                      child: const Text('Continue'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        _clearDrawing();
                        setState(() {
                          _showRecognitionResult = false;
                        });
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterDisplay(String label, String character, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              character,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecognitionLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Analyzing your character...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrokeDirectionHint() {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((0.7 * 255).round()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.character.strokeDirections![_currentStrokeHint - 1],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
  }

  void _toggleSvgGuideline() {
    setState(() {
      _showSvgGuideline = !_showSvgGuideline;
    });
  }

  Widget _buildSvgGuideline() {
    if (widget.character.fullSvgPath == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Center(
        child: RepaintBoundary(
          child: SvgPicture.asset(
            widget.character.fullSvgPath!,
            color: Colors.grey.withOpacity(0.3),
            width: 280,
            height: 280,
            fit: BoxFit.contain,
            placeholderBuilder: (context) => Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  final Color centerColor;

  GridPainter({
    this.color = Colors.grey,
    this.centerColor = Colors.red,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    for (int i = 1; i < 10; i++) {
      final y = size.height * (i / 10);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw vertical lines
    for (int i = 1; i < 10; i++) {
      final x = size.width * (i / 10);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw center lines with different color
    final centerPaint = Paint()
      ..color = centerColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Horizontal center line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );

    // Vertical center line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.centerColor != centerColor;
  }
}

class StrokeOrderPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final int currentStroke;
  final bool showAllStrokes;
  final Color color;

  StrokeOrderPainter({
    required this.strokes,
    required this.currentStroke,
    required this.showAllStrokes,
    this.color = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      final path = Path();
      if (stroke.isEmpty) continue;

      path.moveTo(
        stroke.first.dx * size.width,
        stroke.first.dy * size.height,
      );

      for (int j = 1; j < stroke.length; j++) {
        path.lineTo(
          stroke[j].dx * size.width,
          stroke[j].dy * size.height,
        );
      }

      if (i == currentStroke && showAllStrokes) {
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(StrokeOrderPainter oldDelegate) {
    return oldDelegate.currentStroke != currentStroke ||
        oldDelegate.showAllStrokes != showAllStrokes ||
        oldDelegate.color != color;
  }
}

class BrushDrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color strokeColor;
  final double minStrokeWidth;
  final double maxStrokeWidth;

  BrushDrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokeColor,
    required this.minStrokeWidth,
    required this.maxStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;

      _drawBrushStroke(canvas, size, stroke);
    }

    // Draw current stroke with real-time feedback
    if (currentStroke.isNotEmpty) {
      _drawBrushStroke(canvas, size, currentStroke);
    }
  }

  void _drawBrushStroke(Canvas canvas, Size size, List<Offset> stroke) {
    if (stroke.length < 2) return;

    for (int i = 1; i < stroke.length; i++) {
      final p0 = stroke[i - 1];
      final p1 = stroke[i];

      // Calculate stroke width based on speed (simulating brush pressure)
      double speed = 1.0;
      if (i > 1) {
        final prevPoint = stroke[i - 2];
        final distance = (p0 - prevPoint).distance;
        speed = math.min(math.max(distance * 10, 0.5), 2.0);
      }

      // Calculate brush width - thicker when slower, thinner when faster
      final brushWidth = maxStrokeWidth - ((maxStrokeWidth - minStrokeWidth) * (speed - 0.5));

      // Create a path for this segment
      final path = Path();

      // Use quadratic bezier for smoother lines if we have enough points
      if (i > 1 && i < stroke.length - 1) {
        // Calculate control points for smoother curve
        final controlPoint1 = Offset(
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );

        path.moveTo(
          p0.dx * size.width,
          p0.dy * size.height,
        );

        path.quadraticBezierTo(
          controlPoint1.dx * size.width,
          controlPoint1.dy * size.height,
          p1.dx * size.width,
          p1.dy * size.height,
        );
      } else {
        // Simple line for start/end segments
        path.moveTo(
          p0.dx * size.width,
          p0.dy * size.height,
        );

        path.lineTo(
          p1.dx * size.width,
          p1.dy * size.height,
        );
      }

      // Create brush-like paint
      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = brushWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      // Draw the path
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(BrushDrawingPainter oldDelegate) {
    // Only repaint when strokes actually change for better performance
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.strokeColor != strokeColor;
  }
}
