import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/quiz_provider.dart';

class QuizGenerationLoadingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onAnimationComplete;
  final int documentCount;

  const QuizGenerationLoadingScreen({
    super.key,
    this.onAnimationComplete,
    this.documentCount = 1,
  });

  @override
  ConsumerState<QuizGenerationLoadingScreen> createState() =>
      QuizGenerationLoadingScreenState();
}

class QuizGenerationLoadingScreenState
    extends ConsumerState<QuizGenerationLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _completionController;
  late Animation<double> _progressAnimation;
  late Animation<double> _completionAnimation;
  bool _shouldComplete = false;
  double _currentProgress = 0.0;
  bool _apiCompleted = false;

  @override
  void initState() {
    super.initState();

    // Calculate duration: 12 seconds per document
    // 1 doc = 15s, 2 docs = 30s, 3 docs = 45s, etc.
    final durationSeconds = 15 * widget.documentCount;

    // Controller for the main progress animation (0-95% over dynamic duration)
    _progressController = AnimationController(
      duration: Duration(seconds: durationSeconds),
      vsync: this,
    );

    // Controller for completion animation (95-100%)
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Smooth linear progress from 0-95% over calculated duration
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.95).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    // Completion animation from current progress to 100%
    _completionAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.easeInOut),
    );

    // Start the progress animation
    _progressController.forward();

    // Listen to progress animation
    _progressAnimation.addListener(() {
      if (!_apiCompleted) {
        setState(() {
          _currentProgress = _progressAnimation.value;
        });
      }
    });

    // Listen to completion animation
    _completionAnimation.addListener(() {
      setState(() {
        _currentProgress = _completionAnimation.value;
      });
    });

    // Call callback when completion animation finishes
    _completionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  void completeAnimation() {
    if (!_shouldComplete) {
      setState(() {
        _shouldComplete = true;
      });

      // Stop the progress animation
      _progressController.stop();

      // Update the completion animation to start from current progress
      _completionAnimation =
          Tween<double>(begin: _currentProgress, end: 1.0).animate(
            CurvedAnimation(
              parent: _completionController,
              curve: Curves.easeInOut,
            ),
          )..addListener(() {
            setState(() {
              _currentProgress = _completionAnimation.value;
            });
          });

      // Start the completion animation
      _completionController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  /// Get user-friendly message based on progress
  String _getProgressMessage(double progress) {
    final percentage = (progress * 100).toInt();

    if (percentage < 25) {
      return 'Scout is processing documents...';
    } else if (percentage < 50) {
      return 'Scout is analyzing content...';
    } else if (percentage < 75) {
      return 'Scout is creating questions...';
    } else if (percentage < 100) {
      return 'Scout is finalizing your quiz...';
    } else {
      return 'Scout has generated your quiz!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressState = ref.watch(quizGenerationProgressProvider);

    // Check if API completed (progress reaches 100%)
    if (progressState.progress >= 1.0 && !_apiCompleted) {
      _apiCompleted = true;
      // Trigger completion animation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        completeAnimation();
      });
    }

    // Use animated progress for smooth display
    final displayProgress = _currentProgress;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Image.asset('assets/icons/logo-fox-on-left.png', height: 55),
                const SizedBox(height: 50),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular progress indicator
                    SizedBox(
                      width: 235,
                      height: 235,
                      child: CustomPaint(
                        painter: CircularProgressPainter(
                          progress: displayProgress,
                          backgroundColor: AppColors.inputBorder.withValues(
                            alpha: 0.3,
                          ),
                          progressColor: AppColors.primary,
                          strokeWidth: 12,
                        ),
                      ),
                    ),
                    // Tail icon centered inside the circle
                    SizedBox(
                      width: 175,
                      height: 90,
                      child: Image.asset(
                        'assets/icons/loading-icon-tail.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Generating Your Quiz',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle with dynamic message based on progress
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _getProgressMessage(displayProgress),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Show percentage
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${(displayProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressAngle = 2 * 3.141592653589793 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2, // Start from top
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
