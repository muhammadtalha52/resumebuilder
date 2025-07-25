import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';

class Step5Skills extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const Step5Skills({super.key, required this.onNext});

  @override
  ConsumerState<Step5Skills> createState() => _Step5SkillsState();
}

class _Step5SkillsState extends ConsumerState<Step5Skills> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Skills & Tools section coming soon',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 32),
        // Next button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: widget.onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Next',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
