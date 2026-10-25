import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/tour_strings.dart';

/// A high-converting, non-intrusive Guided Tour Overlay.
///
/// Highlights targeted elements on the screen with a cutout backdrop,
/// glowing outline, and contextual tooltip cards with step progression.
class GuidedTourOverlay extends StatefulWidget {
  final List<GlobalKey> targetKeys;
  final List<TourStepData> steps;
  final VoidCallback onFinish;
  final Function(int skippedAtStep) onSkip;

  const GuidedTourOverlay({
    super.key,
    required this.targetKeys,
    required this.steps,
    required this.onFinish,
    required this.onSkip,
  });

  /// Static helper to display the tour over an existing navigator
  static OverlayEntry? show({
    required BuildContext context,
    required List<GlobalKey> targetKeys,
    required List<TourStepData> steps,
    required VoidCallback onFinish,
    required Function(int skippedAtStep) onSkip,
  }) {
    final overlayState = Overlay.of(context, rootOverlay: true);
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (ctx) => GuidedTourOverlay(
        targetKeys: targetKeys,
        steps: steps,
        onFinish: () {
          entry?.remove();
          onFinish();
        },
        onSkip: (step) {
          entry?.remove();
          onSkip(step);
        },
      ),
    );

    overlayState.insert(entry);
    return entry;
  }

  @override
  State<GuidedTourOverlay> createState() => _GuidedTourOverlayState();
}

class _GuidedTourOverlayState extends State<GuidedTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Rect? _getTargetRect() {
    if (_currentStep >= widget.targetKeys.length) return null;
    final key = widget.targetKeys[_currentStep];
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;

    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      widget.onFinish();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final targetRect = _getTargetRect();
    final currentStepData = widget.steps[_currentStep];
    final isLastStep = _currentStep == widget.steps.length - 1;

    // Expand rect slightly for padding around highlighted widget
    final highlightRect = targetRect != null
        ? Rect.fromLTRB(
            targetRect.left - 6,
            targetRect.top - 6,
            targetRect.right + 6,
            targetRect.bottom + 6,
          )
        : Rect.fromCenter(
            center: Offset(screenSize.width / 2, screenSize.height / 2),
            width: 100,
            height: 100,
          );

    final isTargetInBottomHalf = highlightRect.top > (screenSize.height * 0.55);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. Dimmed backdrop with Cutout over the target element
          CustomPaint(
            size: screenSize,
            painter: _TourCutoutPainter(
              targetRect: highlightRect,
              borderRadius: 14.0,
            ),
          ),

          // 2. Animated Pulsing Glow Outline around Target
          Positioned(
            left: highlightRect.left,
            top: highlightRect.top,
            width: highlightRect.width,
            height: highlightRect.height,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Tooltip Card positioned dynamically above or below target
          Positioned(
            left: screenSize.width * 0.05,
            right: screenSize.width * 0.05,
            top: isTargetInBottomHalf ? null : (highlightRect.bottom + screenSize.height * 0.02),
            bottom: isTargetInBottomHalf ? (screenSize.height - highlightRect.top + screenSize.height * 0.02) : null,
            child: _buildTooltipCard(currentStepData, isLastStep),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltipCard(TourStepData data, bool isLastStep) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Counter Badge + Close '✕' Button (Matching Web spec)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP ${_currentStep + 1} OF ${widget.steps.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: () => widget.onSkip(_currentStep + 1),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            data.description,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons: Skip (Left) | Back + Next/Finish (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => widget.onSkip(_currentStep + 1),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  TourStrings.skip,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                      ),
                      child: const Text('← ${TourStrings.back}'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastStep ? TourStrings.finish : TourStrings.next,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (!isLastStep) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter that dims the whole screen while leaving a clear rounded cutout
class _TourCutoutPainter extends CustomPainter {
  final Rect targetRect;
  final double borderRadius;

  _TourCutoutPainter({
    required this.targetRect,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          targetRect,
          Radius.circular(borderRadius),
        ),
      );

    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.68)
      ..style = PaintingStyle.fill;

    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _TourCutoutPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
