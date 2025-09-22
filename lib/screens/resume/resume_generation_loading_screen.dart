import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class ResumeGenerationLoadingScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const ResumeGenerationLoadingScreen({super.key, this.onAnimationComplete});

  @override
  State<ResumeGenerationLoadingScreen> createState() =>
      ResumeGenerationLoadingScreenState();
}

class ResumeGenerationLoadingScreenState
    extends State<ResumeGenerationLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _completionController;
  late AnimationController _dotsController;
  late Animation<double> _progressAnimation;
  late Animation<double> _completionAnimation;
  bool _shouldComplete = false;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();

    // Controller for the main progress animation (0-95%)
    // Adjusted for 60-90 second API duration
    _progressController = AnimationController(
      duration: const Duration(seconds: 75), // Average of 60-90 seconds
      vsync: this,
    );

    // Controller for completion animation (95-100%)
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create a custom curved animation for realistic progress
    // Fast from 0-70%, moderate from 70-85%, then slow from 85-95%
    _progressAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 0.70,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20, // 20% of time to reach 70% progress
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.70,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.linear)),
        weight: 30, // 30% of time for 15% progress
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.85,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50, // 50% of time for remaining 10% progress
      ),
    ]).animate(_progressController);

    // Completion animation from current progress to 100%
    _completionAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.easeInOut),
    );

    // Controller for blinking dots animation
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

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
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                // Top section with logo - flexible space
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/icons/logo-fox-on-left.png',
                          height: 55,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content section - centered
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                                backgroundColor: AppColors.inputBorder
                                    .withValues(alpha: 0.3),
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
                      const SizedBox(height: 40),

                      // Main title with animated dots
                      AnimatedBuilder(
                        animation: _dotsController,
                        builder: (context, child) {
                          String dots = '';
                          int dotCount =
                              (_dotsController.value * 4).floor() % 4;
                          for (int i = 0; i < dotCount; i++) {
                            dots += '.';
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Left spacer to balance the dots container
                              const SizedBox(width: 36),
                              const Text(
                                'Crafting Your Resume',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(
                                width: 36, // Fixed width to hold up to 3 dots
                                child: Text(
                                  dots,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      const Text(
                        'Scout is generating your professional resume',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom spacer - flexible space
                const Expanded(flex: 2, child: SizedBox()),
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
