import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class AccountCreationLoadingScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const AccountCreationLoadingScreen({super.key, this.onAnimationComplete});

  @override
  State<AccountCreationLoadingScreen> createState() =>
      AccountCreationLoadingScreenState();
}

class AccountCreationLoadingScreenState
    extends State<AccountCreationLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _completionController;
  late Animation<double> _progressAnimation;
  late Animation<double> _completionAnimation;
  bool _shouldComplete = false;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();

    // Controller for the main progress animation (0-95%)
    _progressController = AnimationController(
      duration: const Duration(seconds: 10), // Total time to reach 95%
      vsync: this,
    );

    // Controller for completion animation (95-100%)
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create a custom curved animation for smart progress
    // Fast from 0-80%, then slow from 80-95%
    _progressAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 0.80,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30, // 30% of time to reach 80% progress
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.80,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 70, // 70% of time for remaining 15% progress
      ),
    ]).animate(_progressController);

    // Completion animation from current progress to 100%
    _completionAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.easeInOut),
    );

    // Start the progress animation
    _progressController.forward();

    // Listen to progress animation
    _progressAnimation.addListener(() {
      setState(() {
        _currentProgress = _progressAnimation.value;
      });
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
      _completionAnimation = Tween<double>(begin: _currentProgress, end: 1.0)
          .animate(
            CurvedAnimation(
              parent: _completionController,
              curve: Curves.easeInOut,
            ),
          );

      // Start the completion animation
      _completionController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 30),
                Image.asset('assets/icons/logo-fox-on-left.png', height: 55),
                SizedBox(height: 50),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular progress indicator
                    SizedBox(
                      width: 235,
                      height: 235,
                      child: CustomPaint(
                        painter: CircularProgressPainter(
                          progress: _currentProgress,
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
                SizedBox(height: 50),
                const Text(
                  'Assembling Your Skill Card',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                const Text(
                  'Get ready to level up your lair!',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
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
