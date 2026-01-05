import 'dart:async';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// Step status for the loading progress
enum StepStatus { pending, inProgress, completed }

/// Model for each loading step
class LoadingStep {
  final String text;
  StepStatus status;

  LoadingStep({required this.text, this.status = StepStatus.pending});
}

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
  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _completionController;
  late AnimationController _dotsController;
  late Animation<double> _progressAnimation;
  late Animation<double> _completionAnimation;

  // Step management
  final List<LoadingStep> _steps = [
    LoadingStep(text: 'Researching the company you\'re targeting'),
    LoadingStep(text: 'Analyzing job requirements'),
    LoadingStep(text: 'Investigating previous employee profiles'),
    LoadingStep(text: 'Cross referencing your skills to adapt'),
  ];

  int _currentStepIndex = 0;
  Timer? _stepTimer;
  bool _apiCompleted = false;
  bool _isCompletingRemainingSteps = false;

  // Progress state
  bool _shouldComplete = false;
  double _currentProgress = 0.0;

  // Step timing constants
  static const Duration _stepDuration = Duration(seconds: 4);
  static const Duration _quickCompleteDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStepSequence();
  }

  void _initializeAnimations() {
    // Controller for the main progress animation (0-95%)
    _progressController = AnimationController(
      duration: const Duration(seconds: 75),
      vsync: this,
    );

    // Controller for completion animation (95-100%)
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Progress animation with realistic curve
    _progressAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 0.70,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.70,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.linear)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.85,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_progressController);

    // Completion animation
    _completionAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.easeInOut),
    );

    // Dots animation controller
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

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

    // Callback when completion animation finishes
    _completionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });

    // Start progress animation
    _progressController.forward();
  }

  void _startStepSequence() {
    // Start first step immediately
    setState(() {
      _steps[0].status = StepStatus.inProgress;
    });

    // Schedule automatic step progression for first 3 steps
    _scheduleNextStep();
  }

  void _scheduleNextStep() {
    _stepTimer?.cancel();

    // Only auto-progress for steps 0, 1, 2 (first 3 steps)
    if (_currentStepIndex < 3 && !_apiCompleted) {
      _stepTimer = Timer(_stepDuration, () {
        if (!mounted) return;

        setState(() {
          // Complete current step
          _steps[_currentStepIndex].status = StepStatus.completed;
          _currentStepIndex++;

          // Start next step if available
          if (_currentStepIndex < _steps.length) {
            _steps[_currentStepIndex].status = StepStatus.inProgress;
          }
        });

        // Schedule next step if we're not at step 4 yet
        if (_currentStepIndex < 3) {
          _scheduleNextStep();
        }
        // Step 4 (index 3) will wait for API completion
      });
    }
  }

  /// Called when API completes - triggers completion animation
  void completeAnimation() {
    if (_shouldComplete) return;

    _apiCompleted = true;
    _stepTimer?.cancel();

    // If there are remaining steps to complete, do them quickly
    if (_currentStepIndex < _steps.length - 1 ||
        _steps[_currentStepIndex].status != StepStatus.completed) {
      _completeRemainingStepsQuickly();
    } else {
      _finishAnimation();
    }
  }

  void _completeRemainingStepsQuickly() {
    if (_isCompletingRemainingSteps) return;
    _isCompletingRemainingSteps = true;

    // Complete remaining steps one by one with quick animation
    _completeNextStepQuickly();
  }

  void _completeNextStepQuickly() {
    if (!mounted) return;

    // If current step is in progress, complete it
    if (_currentStepIndex < _steps.length &&
        _steps[_currentStepIndex].status == StepStatus.inProgress) {
      setState(() {
        _steps[_currentStepIndex].status = StepStatus.completed;
        _currentStepIndex++;
      });
    }

    // If there are more steps, start and complete them
    if (_currentStepIndex < _steps.length) {
      setState(() {
        _steps[_currentStepIndex].status = StepStatus.inProgress;
      });

      Timer(_quickCompleteDuration, () {
        if (!mounted) return;

        setState(() {
          _steps[_currentStepIndex].status = StepStatus.completed;
          _currentStepIndex++;
        });

        if (_currentStepIndex < _steps.length) {
          _completeNextStepQuickly();
        } else {
          _finishAnimation();
        }
      });
    } else {
      _finishAnimation();
    }
  }

  void _finishAnimation() {
    if (_shouldComplete) return;

    setState(() {
      _shouldComplete = true;
    });

    // Stop progress animation
    _progressController.stop();

    // Update completion animation to start from current progress
    _completionAnimation = Tween<double>(begin: _currentProgress, end: 1.0)
        .animate(
          CurvedAnimation(
            parent: _completionController,
            curve: Curves.easeInOut,
          ),
        );

    // Start completion animation
    _completionController.forward();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
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
                // Top section with logo
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

                // Main content section
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Circular progress indicator
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CustomPaint(
                              painter: CircularProgressPainter(
                                progress: _currentProgress,
                                backgroundColor: AppColors.inputBorder
                                    .withValues(alpha: 0.3),
                                progressColor: AppColors.primary,
                                strokeWidth: 10,
                              ),
                            ),
                          ),
                          // Tail icon centered inside the circle
                          SizedBox(
                            width: 130,
                            height: 70,
                            child: Image.asset(
                              'assets/icons/loading-icon-tail.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // // Title
                      // const Text(
                      //   'Crafting Your Resume',
                      //   textAlign: TextAlign.center,
                      //   style: TextStyle(
                      //     fontSize: 22,
                      //     fontWeight: FontWeight.bold,
                      //     color: AppColors.textPrimary,
                      //   ),
                      // ),
                      // const SizedBox(height: 8),
                      //
                      // Subtitle
                      const Text(
                        'Scout is generating your professional resume',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Steps list
                      _buildStepsList(),
                    ],
                  ),
                ),

                // Bottom spacer
                const Expanded(flex: 1, child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return _buildStepItem(step, index);
      }).toList(),
    );
  }

  Widget _buildStepItem(LoadingStep step, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          // Status indicator
          _buildStatusIndicator(step.status),
          const SizedBox(width: 12),
          // Step text with animated dots if in progress
          Expanded(child: _buildStepText(step)),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(StepStatus status) {
    switch (status) {
      case StepStatus.completed:
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        );
      case StepStatus.inProgress:
        return SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          ),
        );
      case StepStatus.pending:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
        );
    }
  }

  Widget _buildStepText(LoadingStep step) {
    final bool isInProgress = step.status == StepStatus.inProgress;
    final bool isPending = step.status == StepStatus.pending;

    final textColor = isPending
        ? AppColors.textSecondary.withValues(alpha: 0.6)
        : AppColors.textPrimary;

    if (isInProgress) {
      // Animated dots for in-progress step
      return AnimatedBuilder(
        animation: _dotsController,
        builder: (context, child) {
          String dots = '';
          int dotCount = (_dotsController.value * 4).floor() % 4;
          for (int i = 0; i < dotCount; i++) {
            dots += '.';
          }
          return Row(
            children: [
              Flexible(
                child: Text(
                  step.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                width: 24,
                child: Text(
                  dots,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return Text(
      step.text,
      style: TextStyle(
        fontSize: 13,
        color: textColor,
        fontWeight: isPending ? FontWeight.normal : FontWeight.w500,
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
