import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';

class Step6OptionalInfo extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const Step6OptionalInfo({super.key, required this.onNext});

  @override
  ConsumerState<Step6OptionalInfo> createState() => _Step6OptionalInfoState();
}

class _Step6OptionalInfoState extends ConsumerState<Step6OptionalInfo> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Optional Information section coming soon',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 32),
        // Complete button
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
              'Complete',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
