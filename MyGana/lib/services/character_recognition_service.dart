import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:nihongo_japanese_app/models/japanese_character.dart';
import 'package:nihongo_japanese_app/services/tflite_model_handler.dart';

class RecognitionResult {
  final String recognizedCharacter;
  final double confidence;
  final List<String> alternativeMatches;
  final bool isCorrect;
  final String englishTranslation;
  final String feedback;
  final double accuracyScore; // 0-100 score for stroke accuracy

  RecognitionResult({
    required this.recognizedCharacter,
    required this.confidence,
    this.alternativeMatches = const [],
    required this.isCorrect,
    required this.englishTranslation,
    required this.feedback,
    required this.accuracyScore,
  });
}

class CharacterRecognitionService {
  final TFLiteModelHandler _tfliteHandler = TFLiteModelHandler();

  // Map of Japanese characters to their English translations
  final Map<String, String> _characterTranslations = {
    // Hiragana
    'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
    'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
    'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
    'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
    'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no',
    'は': 'ha', 'ひ': 'hi', 'ふ': 'fu', 'へ': 'he', 'ほ': 'ho',
    'ま': 'ma', 'み': 'mi', 'む': 'mu', 'め': 'me', 'も': 'mo',
    'や': 'ya', 'ゆ': 'yu', 'よ': 'yo',
    'ら': 'ra', 'り': 'ri', 'る': 'ru', 'れ': 're', 'ろ': 'ro',
    'わ': 'wa', 'を': 'wo', 'ん': 'n',
    'が': 'ga', 'ぎ': 'gi', 'ぐ': 'gu', 'げ': 'ge', 'ご': 'go',
    'ざ': 'za', 'じ': 'ji', 'ず': 'zu', 'ぜ': 'ze', 'ぞ': 'zo',
    'だ': 'da', 'ぢ': 'ji', 'づ': 'zu', 'で': 'de', 'ど': 'do',
    'ば': 'ba', 'び': 'bi', 'ぶ': 'bu', 'べ': 'be', 'ぼ': 'bo',
    'ぱ': 'pa', 'ぴ': 'pi', 'ぷ': 'pu', 'ぺ': 'pe', 'ぽ': 'po',

    // Katakana
    'ア': 'a', 'イ': 'i', 'ウ': 'u', 'エ': 'e', 'オ': 'o',
    'カ': 'ka', 'キ': 'ki', 'ク': 'ku', 'ケ': 'ke', 'コ': 'ko',
    'サ': 'sa', 'シ': 'shi', 'ス': 'su', 'セ': 'se', 'ソ': 'so',
    'タ': 'ta', 'チ': 'chi', 'ツ': 'tsu', 'テ': 'te', 'ト': 'to',
    'ナ': 'na', 'ニ': 'ni', 'ヌ': 'nu', 'ネ': 'ne', 'ノ': 'no',
    'ハ': 'ha', 'ヒ': 'hi', 'フ': 'fu', 'ヘ': 'he', 'ホ': 'ho',
    'マ': 'ma', 'ミ': 'mi', 'ム': 'mu', 'メ': 'me', 'モ': 'mo',
    'ヤ': 'ya', 'ユ': 'yu', 'ヨ': 'yo',
    'ラ': 'ra', 'リ': 'ri', 'ル': 'ru', 'レ': 're', 'ロ': 'ro',
    'ワ': 'wa', 'ヲ': 'wo', 'ン': 'n',
    'ガ': 'ga', 'ギ': 'gi', 'グ': 'gu', 'ゲ': 'ge', 'ゴ': 'go',
    'ザ': 'za', 'ジ': 'ji', 'ズ': 'zu', 'ゼ': 'ze', 'ゾ': 'zo',
    'ダ': 'da', 'ヂ': 'ji', 'ヅ': 'zu', 'デ': 'de', 'ド': 'do',
    'バ': 'ba', 'ビ': 'bi', 'ブ': 'bu', 'ベ': 'be', 'ボ': 'bo',
    'パ': 'pa', 'ピ': 'pi', 'プ': 'pu', 'ペ': 'pe', 'ポ': 'po',
  };

  // Get English translation for a character
  String getEnglishTranslation(String character) {
    return _characterTranslations[character] ?? 'unknown';
  }

  // Main recognition method that analyzes stroke data
  Future<RecognitionResult> recognizeCharacter(
    List<List<Offset>> userStrokes,
    JapaneseCharacter expectedCharacter,
  ) async {
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 500));

    // Validate input first
    if (!_validateInput(userStrokes)) {
      return RecognitionResult(
        recognizedCharacter: expectedCharacter.character,
        confidence: 0.0,
        alternativeMatches: [],
        isCorrect: false,
        englishTranslation: getEnglishTranslation(expectedCharacter.character),
        feedback: "Please draw something to check! 📝",
        accuracyScore: 0.0,
      );
    }

    try {
      // Convert strokes to image for TFLite model
      final imageBytes = await _strokesToImage(userStrokes);

      // Get TFLite model predictions
      final tflitePredictions = await _tfliteHandler.recognizeCharacter(imageBytes);

      // Get rule-based analysis as backup
      final ruleBasedAnalysis = _analyzeStrokes(userStrokes, expectedCharacter);

      // Combine TFLite and rule-based results
      final combinedResult =
          _combineResults(tflitePredictions, ruleBasedAnalysis, expectedCharacter);

      return combinedResult;
    } catch (e) {
      print('Error in character recognition: $e');

      // Fallback to rule-based analysis if TFLite fails
      final analysis = _analyzeStrokes(userStrokes, expectedCharacter);
      final isCorrect = analysis['isCorrect'] as bool;
      final confidence = analysis['confidence'] as double;
      final accuracyScore = analysis['accuracyScore'] as double;

      return RecognitionResult(
        recognizedCharacter: expectedCharacter.character,
        confidence: confidence,
        alternativeMatches: [],
        isCorrect: isCorrect,
        englishTranslation: getEnglishTranslation(expectedCharacter.character),
        feedback: _generateFeedback(analysis, isCorrect, expectedCharacter),
        accuracyScore: accuracyScore,
      );
    }
  }

  // Convert strokes to image for TFLite model
  Future<Uint8List> _strokesToImage(List<List<Offset>> strokes) async {
    const int imageSize = 64;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imageSize.toDouble(), imageSize.toDouble()),
      Paint()..color = Colors.white,
    );

    // Draw strokes
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;

      final path = Path();
      path.moveTo(
        stroke.first.dx * imageSize,
        stroke.first.dy * imageSize,
      );

      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(
          stroke[i].dx * imageSize,
          stroke[i].dy * imageSize,
        );
      }

      canvas.drawPath(path, paint);
    }

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(imageSize, imageSize);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  // Combine TFLite and rule-based results
  RecognitionResult _combineResults(
    Map<String, double> tflitePredictions,
    Map<String, dynamic> ruleBasedAnalysis,
    JapaneseCharacter expectedCharacter,
  ) {
    // Get top TFLite prediction
    final topTflitePrediction = tflitePredictions.isNotEmpty
        ? tflitePredictions.entries.first
        : MapEntry(expectedCharacter.character, 0.0);

    final tfliteCharacter = topTflitePrediction.key;
    final tfliteConfidence = topTflitePrediction.value;

    // Get rule-based scores
    final ruleBasedScore = ruleBasedAnalysis['accuracyScore'] as double;

    // Combine scores (70% TFLite, 30% rule-based)
    final combinedScore = (tfliteConfidence * 0.7) + (ruleBasedScore / 100.0 * 0.3);

    // Determine if correct
    final isCorrect = tfliteCharacter == expectedCharacter.character && combinedScore >= 0.6;

    // Get alternative matches from TFLite
    final alternativeMatches = tflitePredictions.entries
        .take(5)
        .map((e) => e.key)
        .where((char) => char != tfliteCharacter)
        .toList();

    // Generate feedback
    final feedback = _generateCombinedFeedback(
        isCorrect, combinedScore, tfliteConfidence, ruleBasedScore, expectedCharacter);

    return RecognitionResult(
      recognizedCharacter: tfliteCharacter,
      confidence: combinedScore,
      alternativeMatches: alternativeMatches,
      isCorrect: isCorrect,
      englishTranslation: getEnglishTranslation(tfliteCharacter),
      feedback: feedback,
      accuracyScore: combinedScore * 100,
    );
  }

  // Generate feedback for combined results
  String _generateCombinedFeedback(
    bool isCorrect,
    double combinedScore,
    double tfliteConfidence,
    double ruleBasedScore,
    JapaneseCharacter expectedCharacter,
  ) {
    if (isCorrect) {
      if (combinedScore >= 0.9) {
        return "Outstanding! Perfect recognition! 🌟";
      } else if (combinedScore >= 0.8) {
        return "Excellent! Very accurate! 🎉";
      } else if (combinedScore >= 0.7) {
        return "Great job! Well recognized! 👍";
      } else {
        return "Good! Keep practicing! 💪";
      }
    } else {
      if (tfliteConfidence < 0.3) {
        return "The character wasn't recognized clearly. Try drawing more carefully! 📝";
      } else if (ruleBasedScore < 50) {
        return "Focus on stroke count and order. The shape needs work! 🔄";
      } else {
        return "Close! The AI model suggests: ${(tfliteConfidence * 100).toStringAsFixed(1)}% confidence. Try again! 📈";
      }
    }
  }

  // Validate that the input is meaningful
  bool _validateInput(List<List<Offset>> userStrokes) {
    if (userStrokes.isEmpty) return false;

    // Check if there are any meaningful strokes
    int totalPoints = 0;
    double totalLength = 0.0;

    for (final stroke in userStrokes) {
      if (stroke.length < 2) continue;
      totalPoints += stroke.length;
      totalLength += _calculateStrokeLength(stroke);
    }

    // Must have at least 3 points and some length
    return totalPoints >= 3 && totalLength > 0.05;
  }

  // Analyze user strokes against expected character
  Map<String, dynamic> _analyzeStrokes(
      List<List<Offset>> userStrokes, JapaneseCharacter expectedCharacter) {
    if (userStrokes.isEmpty) {
      return {
        'isCorrect': false,
        'confidence': 0.0,
        'accuracyScore': 0.0,
        'strokeCountMatch': false,
        'strokeOrderMatch': false,
        'shapeSimilarity': 0.0,
      };
    }

    // Enhanced stroke analysis
    final strokeCountMatch = _checkStrokeCount(userStrokes, expectedCharacter);
    final strokeOrderMatch = _checkStrokeOrder(userStrokes, expectedCharacter);
    final shapeSimilarity = _calculateShapeSimilarity(userStrokes, expectedCharacter);
    final strokeQuality = _assessStrokeQuality(userStrokes);
    final proportionality = _calculateProportionality(userStrokes, expectedCharacter);

    // More sophisticated scoring system
    double accuracyScore = 0.0;

    // Stroke count (25 points) - critical for Japanese characters
    if (strokeCountMatch) {
      accuracyScore += 25;
    } else {
      // Partial credit for close stroke count
      final expectedCount = expectedCharacter.strokeOrder.length;
      final actualCount = userStrokes.length;
      final difference = (actualCount - expectedCount).abs();
      if (difference <= 2) {
        accuracyScore += 20 - (difference * 5); // 20, 15, 10 points
      }
    }

    // Stroke order (25 points) - very important for Japanese writing
    if (strokeOrderMatch) {
      accuracyScore += 25;
    } else {
      // Partial credit for reasonable stroke order
      final orderScore = _calculatePartialStrokeOrderScore(userStrokes, expectedCharacter);
      accuracyScore += orderScore * 25;
    }

    // Shape similarity (30 points) - overall character shape
    accuracyScore += shapeSimilarity * 30;

    // Stroke quality (15 points) - smoothness and consistency
    accuracyScore += strokeQuality * 15;

    // Proportionality (5 points) - proper character proportions
    accuracyScore += proportionality * 5;

    // Ensure score doesn't exceed 100
    accuracyScore = math.min(accuracyScore, 100.0);

    // More nuanced correctness determination
    bool isCorrect = false;
    if (accuracyScore >= 80) {
      isCorrect = true; // Excellent
    } else if (accuracyScore >= 70 && strokeCountMatch && shapeSimilarity > 0.6) {
      isCorrect = true; // Good with key elements correct
    } else if (accuracyScore >= 65 && strokeCountMatch && shapeSimilarity > 0.5) {
      isCorrect = true; // Acceptable for learning
    }

    // Calculate confidence based on accuracy
    final confidence = math.min(accuracyScore / 100.0, 1.0);

    return {
      'isCorrect': isCorrect,
      'confidence': confidence,
      'accuracyScore': accuracyScore,
      'strokeCountMatch': strokeCountMatch,
      'strokeOrderMatch': strokeOrderMatch,
      'shapeSimilarity': shapeSimilarity,
      'strokeQuality': strokeQuality,
      'proportionality': proportionality,
      'actualStrokeCount': userStrokes.length,
    };
  }

  // Check if stroke count matches expected
  bool _checkStrokeCount(List<List<Offset>> userStrokes, JapaneseCharacter expectedCharacter) {
    final expectedStrokeCount = expectedCharacter.strokeOrder.length;
    final actualStrokeCount = userStrokes.length;

    // Allow some tolerance (±1 stroke)
    return (actualStrokeCount - expectedStrokeCount).abs() <= 1;
  }

  // Check if stroke order is roughly correct
  bool _checkStrokeOrder(List<List<Offset>> userStrokes, JapaneseCharacter expectedCharacter) {
    if (userStrokes.length != expectedCharacter.strokeOrder.length) {
      return false;
    }

    // Enhanced stroke order checking
    int correctOrderCount = 0;
    const double tolerance = 0.25; // 25% tolerance for starting points

    for (int i = 0; i < userStrokes.length; i++) {
      if (userStrokes[i].isEmpty || expectedCharacter.strokeOrder[i].isEmpty) {
        continue;
      }

      final userStart = userStrokes[i].first;
      final expectedStart = expectedCharacter.strokeOrder[i].first;

      // Check if starting points are reasonably close
      final distance = (userStart - expectedStart).distance;
      if (distance <= tolerance) {
        correctOrderCount++;
      }
    }

    // Require at least 70% of strokes to be in correct order
    return correctOrderCount >= (userStrokes.length * 0.7).ceil();
  }

  // Calculate partial stroke order score for more nuanced feedback
  double _calculatePartialStrokeOrderScore(
      List<List<Offset>> userStrokes, JapaneseCharacter expectedCharacter) {
    if (userStrokes.isEmpty || expectedCharacter.strokeOrder.isEmpty) {
      return 0.0;
    }

    int correctOrderCount = 0;
    const double tolerance = 0.3; // 30% tolerance for partial credit

    final minLength = math.min(userStrokes.length, expectedCharacter.strokeOrder.length);

    for (int i = 0; i < minLength; i++) {
      if (userStrokes[i].isEmpty || expectedCharacter.strokeOrder[i].isEmpty) {
        continue;
      }

      final userStart = userStrokes[i].first;
      final expectedStart = expectedCharacter.strokeOrder[i].first;

      final distance = (userStart - expectedStart).distance;
      if (distance <= tolerance) {
        correctOrderCount++;
      }
    }

    return minLength > 0 ? correctOrderCount / minLength : 0.0;
  }

  // Calculate shape similarity based on bounding box and general shape
  double _calculateShapeSimilarity(
      List<List<Offset>> userStrokes, JapaneseCharacter expectedCharacter) {
    if (userStrokes.isEmpty || expectedCharacter.strokeOrder.isEmpty) {
      return 0.0;
    }

    // Calculate bounding boxes
    final userBounds = _calculateBounds(userStrokes);
    final expectedBounds = _calculateBounds(expectedCharacter.strokeOrder);

    // Compare aspect ratios
    final userAspectRatio = (userBounds['width'] as double) / (userBounds['height'] as double);
    final expectedAspectRatio =
        (expectedBounds['width'] as double) / (expectedBounds['height'] as double);
    final aspectRatioSimilarity = 1.0 -
        (userAspectRatio - expectedAspectRatio).abs() /
            math.max(userAspectRatio, expectedAspectRatio);

    // Compare center positions
    final centerDistance =
        ((userBounds['center'] as Offset) - (expectedBounds['center'] as Offset)).distance;
    final centerSimilarity = math.max(0.0, 1.0 - centerDistance / 0.5); // 50% tolerance

    // Combine similarities
    return (aspectRatioSimilarity * 0.6 + centerSimilarity * 0.4).clamp(0.0, 1.0);
  }

  // Assess the quality of individual strokes
  double _assessStrokeQuality(List<List<Offset>> userStrokes) {
    if (userStrokes.isEmpty) return 0.0;

    double totalQuality = 0.0;

    for (final stroke in userStrokes) {
      if (stroke.length < 2) {
        totalQuality += 0.0;
        continue;
      }

      // Check stroke smoothness (avoid too many sharp angles)
      double smoothness = 1.0;
      for (int i = 2; i < stroke.length; i++) {
        final p1 = stroke[i - 2];
        final p2 = stroke[i - 1];
        final p3 = stroke[i];

        // Calculate angle between consecutive segments
        final angle = _calculateAngle(p1, p2, p3);
        if (angle < 0.5) {
          // Very sharp angle
          smoothness -= 0.1;
        }
      }

      // Check stroke length (not too short, not too long)
      final strokeLength = _calculateStrokeLength(stroke);
      final lengthScore = strokeLength > 0.1 && strokeLength < 0.8 ? 1.0 : 0.5;

      // Check stroke consistency (consistent width/flow)
      final consistency = _calculateStrokeConsistency(stroke);

      totalQuality += (smoothness * 0.5 + lengthScore * 0.3 + consistency * 0.2).clamp(0.0, 1.0);
    }

    return totalQuality / userStrokes.length;
  }

  // Calculate character proportionality
  double _calculateProportionality(
      List<List<Offset>> userStrokes, JapaneseCharacter expectedCharacter) {
    if (userStrokes.isEmpty || expectedCharacter.strokeOrder.isEmpty) {
      return 0.0;
    }

    final userBounds = _calculateBounds(userStrokes);
    final expectedBounds = _calculateBounds(expectedCharacter.strokeOrder);

    // Check if character fills appropriate space (not too small, not too large)
    final userSize = (userBounds['width'] as double) * (userBounds['height'] as double);
    final expectedSize = (expectedBounds['width'] as double) * (expectedBounds['height'] as double);

    if (expectedSize == 0) return 0.0;

    final sizeRatio = userSize / expectedSize;
    final sizeScore = (1.0 - (sizeRatio - 1.0).abs()).clamp(0.0, 1.0);

    // Check aspect ratio similarity
    final userAspectRatio = (userBounds['width'] as double) / (userBounds['height'] as double);
    final expectedAspectRatio =
        (expectedBounds['width'] as double) / (expectedBounds['height'] as double);
    final aspectRatioScore = (1.0 -
            (userAspectRatio - expectedAspectRatio).abs() /
                math.max(userAspectRatio, expectedAspectRatio))
        .clamp(0.0, 1.0);

    return (sizeScore * 0.6 + aspectRatioScore * 0.4);
  }

  // Calculate stroke consistency (flow and pressure simulation)
  double _calculateStrokeConsistency(List<Offset> stroke) {
    if (stroke.length < 3) return 1.0;

    double totalConsistency = 0.0;
    int segmentCount = 0;

    for (int i = 1; i < stroke.length - 1; i++) {
      final prevSegment = stroke[i] - stroke[i - 1];
      final nextSegment = stroke[i + 1] - stroke[i];

      final prevLength = prevSegment.distance;
      final nextLength = nextSegment.distance;

      if (prevLength == 0 || nextLength == 0) continue;

      // Check for consistent segment lengths (flow consistency)
      final lengthRatio = math.min(prevLength, nextLength) / math.max(prevLength, nextLength);
      totalConsistency += lengthRatio;
      segmentCount++;
    }

    return segmentCount > 0 ? totalConsistency / segmentCount : 1.0;
  }

  // Helper methods
  Map<String, dynamic> _calculateBounds(List<List<Offset>> strokes) {
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      for (final point in stroke) {
        minX = math.min(minX, point.dx);
        maxX = math.max(maxX, point.dx);
        minY = math.min(minY, point.dy);
        maxY = math.max(maxY, point.dy);
      }
    }

    return {
      'minX': minX,
      'maxX': maxX,
      'minY': minY,
      'maxY': maxY,
      'width': maxX - minX,
      'height': maxY - minY,
      'center': Offset((minX + maxX) / 2, (minY + maxY) / 2),
    };
  }

  double _calculateAngle(Offset p1, Offset p2, Offset p3) {
    final v1 = p2 - p1;
    final v2 = p3 - p2;

    final dot = v1.dx * v2.dx + v1.dy * v2.dy;
    final mag1 = v1.distance;
    final mag2 = v2.distance;

    if (mag1 == 0 || mag2 == 0) return 0;

    final cosAngle = dot / (mag1 * mag2);
    return math.acos(cosAngle.clamp(-1.0, 1.0));
  }

  double _calculateStrokeLength(List<Offset> stroke) {
    if (stroke.length < 2) return 0.0;

    double length = 0.0;
    for (int i = 1; i < stroke.length; i++) {
      length += (stroke[i] - stroke[i - 1]).distance;
    }
    return length;
  }

  // Get similar characters for alternatives
  List<String> _getSimilarCharacters(String character, String type) {
    if (type == 'hiragana') {
      return _getSimilarHiragana(character);
    } else if (type == 'katakana') {
      return _getSimilarKatakana(character);
    }
    return [];
  }

  // Helper method to get similar hiragana characters
  List<String> _getSimilarHiragana(String character) {
    final Map<String, List<String>> similarHiragana = {
      'あ': ['お', 'め'],
      'い': ['り', 'こ'],
      'う': ['つ', 'ら'],
      'え': ['ん', 'れ'],
      'お': ['あ', 'ほ'],
      'か': ['が', 'た'],
      'き': ['さ', 'ぎ'],
      'く': ['へ', 'ぐ'],
      'け': ['は', 'せ'],
      'こ': ['に', 'ろ'],
      'さ': ['き', 'ち'],
      'し': ['つ', 'そ'],
      'す': ['む', 'ぬ'],
      'せ': ['さ', 'ね'],
      'そ': ['ろ', 'う'],
      'た': ['な', 'に'],
      'ち': ['さ', 'り'],
      'つ': ['し', 'う'],
      'て': ['で', 'ね'],
      'と': ['ど', 'の'],
      'な': ['た', 'は'],
      'に': ['こ', 'れ'],
      'ぬ': ['め', 'ね'],
      'ね': ['れ', 'わ'],
      'の': ['め', 'ほ'],
      'は': ['ほ', 'け'],
      'ひ': ['き', 'み'],
      'ふ': ['ぶ', 'む'],
      'へ': ['く', 'ほ'],
      'ほ': ['は', 'お'],
      'ま': ['も', 'ほ'],
      'み': ['ひ', 'き'],
      'む': ['ぬ', 'す'],
      'め': ['ぬ', 'ね'],
      'も': ['ま', 'よ'],
      'や': ['か', 'た'],
      'ゆ': ['み', 'よ'],
      'よ': ['ま', 'も'],
      'ら': ['う', 'ろ'],
      'り': ['い', 'ち'],
      'る': ['ろ', 'そ'],
      'れ': ['わ', 'ね'],
      'ろ': ['る', 'そ'],
      'わ': ['れ', 'ね'],
      'を': ['お', 'ほ'],
      'ん': ['そ', 'る'],
    };

    return similarHiragana[character] ?? [];
  }

  // Helper method to get similar katakana characters
  List<String> _getSimilarKatakana(String character) {
    final Map<String, List<String>> similarKatakana = {
      'ア': ['マ', 'ヤ'],
      'イ': ['ィ', 'ナ'],
      'ウ': ['ワ', 'フ'],
      'エ': ['ユ', 'ヨ'],
      'オ': ['ロ', 'コ'],
      'カ': ['ガ', 'タ'],
      'キ': ['サ', 'ギ'],
      'ク': ['ケ', 'タ'],
      'ケ': ['ク', 'セ'],
      'コ': ['ユ', 'ロ'],
      'サ': ['キ', 'チ'],
      'シ': ['ツ', 'ソ'],
      'ス': ['ヌ', 'ム'],
      'セ': ['サ', 'ネ'],
      'ソ': ['ン', 'シ'],
      'タ': ['ダ', 'カ'],
      'チ': ['テ', 'デ'],
      'ツ': ['シ', 'ソ'],
      'テ': ['デ', 'チ'],
      'ト': ['ド', 'ヌ'],
      'ナ': ['メ', 'ヌ'],
      'ニ': ['ミ', 'ハ'],
      'ヌ': ['ス', 'ム'],
      'ネ': ['メ', 'ホ'],
      'ノ': ['メ', 'ヘ'],
      'ハ': ['バ', 'パ'],
      'ヒ': ['ビ', 'ピ'],
      'フ': ['ブ', 'プ'],
      'ヘ': ['ベ', 'ペ'],
      'ホ': ['ボ', 'ポ'],
      'マ': ['ア', 'ム'],
      'ミ': ['ニ', 'ム'],
      'ム': ['ス', 'ヌ'],
      'メ': ['ネ', 'ノ'],
      'モ': ['ヨ', 'ユ'],
      'ヤ': ['ア', 'マ'],
      'ユ': ['エ', 'ヨ'],
      'ヨ': ['モ', 'ユ'],
      'ラ': ['フ', 'ウ'],
      'リ': ['ソ', 'ン'],
      'ル': ['ロ', 'コ'],
      'レ': ['ソ', 'ン'],
      'ロ': ['コ', 'ル'],
      'ワ': ['ウ', 'フ'],
      'ヲ': ['コ', 'ロ'],
      'ン': ['ソ', 'シ'],
    };

    return similarKatakana[character] ?? [];
  }

  // Generate feedback based on analysis
  String _generateFeedback(
      Map<String, dynamic> analysis, bool isCorrect, JapaneseCharacter expectedCharacter) {
    if (isCorrect) {
      final accuracy = analysis['accuracyScore'] as double;
      if (accuracy >= 95) {
        return "Outstanding! Perfect Japanese character! 🌟";
      } else if (accuracy >= 90) {
        return "Excellent! Almost perfect! 🎉";
      } else if (accuracy >= 85) {
        return "Great job! Very well written! 👍";
      } else if (accuracy >= 80) {
        return "Good work! Keep practicing! 💪";
      } else {
        return "Nice try! You're getting better! 📈";
      }
    } else {
      final issues = <String>[];
      final suggestions = <String>[];

      // Analyze specific issues and provide targeted feedback
      final strokeCountMatch = analysis['strokeCountMatch'] as bool;
      final strokeOrderMatch = analysis['strokeOrderMatch'] as bool;
      final shapeSimilarity = analysis['shapeSimilarity'] as double;
      final strokeQuality = analysis['strokeQuality'] as double;
      final proportionality = analysis['proportionality'] as double;

      if (!strokeCountMatch) {
        final expectedCount = expectedCharacter.strokeOrder.length;
        final actualCount = analysis['actualStrokeCount'] ?? expectedCount;
        issues.add("stroke count");
        suggestions.add("This character needs $expectedCount strokes, detected $actualCount");
      }

      if (!strokeOrderMatch) {
        issues.add("stroke order");
        suggestions.add("Try following the correct stroke sequence");
      }

      if (shapeSimilarity < 0.6) {
        issues.add("character shape");
        suggestions.add("Focus on the overall shape and proportions");
      }

      if (strokeQuality < 0.6) {
        issues.add("stroke smoothness");
        suggestions.add("Try drawing with smoother, more fluid strokes");
      }

      if (proportionality < 0.6) {
        issues.add("character size");
        suggestions.add("Make sure the character fills the space appropriately");
      }

      // Generate encouraging feedback
      if (issues.isEmpty) {
        return "You're very close! Try again! 🔄";
      } else if (issues.length == 1) {
        return "Almost there! Focus on ${issues.first}. ${suggestions.isNotEmpty ? suggestions.first : ''} 📝";
      } else if (issues.length <= 3) {
        return "Good effort! Work on: ${issues.take(2).join(' and ')}. ${suggestions.isNotEmpty ? suggestions.first : ''} 💪";
      } else {
        return "Keep practicing! Focus on: ${issues.take(2).join(' and ')}. You're learning! 🌱";
      }
    }
  }

  // Helper method to convert a drawing to an image (for future ML integration)
  Future<Uint8List> drawingToImage(List<List<Offset>> strokes, Size size,
      {Color strokeColor = Colors.black}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw strokes
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;

      final path = Path();
      path.moveTo(
        stroke.first.dx * size.width,
        stroke.first.dy * size.height,
      );

      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(
          stroke[i].dx * size.width,
          stroke[i].dy * size.height,
        );
      }

      canvas.drawPath(path, paint);
    }

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}
