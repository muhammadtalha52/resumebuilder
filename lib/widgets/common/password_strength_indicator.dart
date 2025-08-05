import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/validators.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final double height;
  final double spacing;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.height = 4.0,
    this.spacing = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final strength = Validators.getPasswordStrength(password);
    final strengthText = Validators.getPasswordStrengthText(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bars
        Row(
          children: List.generate(4, (index) {
            Color barColor;
            if (index < strength) {
              switch (strength) {
                case 0:
                case 1:
                  barColor = AppColors.error;
                  break;
                case 2:
                  barColor = AppColors.warning;
                  break;
                case 3:
                  barColor = Colors.orange;
                  break;
                case 4:
                  barColor = AppColors.success;
                  break;
                default:
                  barColor = AppColors.greyLight;
              }
            } else {
              barColor = AppColors.greyLight;
            }

            return Expanded(
              child: Container(
                height: height,
                margin: EdgeInsets.only(right: index < 3 ? spacing : 0),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            );
          }),
        ),

        // Strength text
        const SizedBox(height: 8),
        if (password.isNotEmpty)
          Text(
            'Password strength: $strengthText',
            style: TextStyle(
              fontSize: 12,
              color: _getStrengthTextColor(strength),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Color _getStrengthTextColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return Colors.orange;
      case 4:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}

class PasswordRequirementsIndicator extends StatelessWidget {
  final String password;

  const PasswordRequirementsIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password must contain:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        _buildRequirement('At least 8 characters', password.length >= 8),
        _buildRequirement(
          'One uppercase letter (A-Z)',
          password.contains(RegExp(r'[A-Z]')),
        ),
        _buildRequirement(
          'One lowercase letter (a-z)',
          password.contains(RegExp(r'[a-z]')),
        ),
        _buildRequirement(
          'One number (0-9)',
          password.contains(RegExp(r'[0-9]')),
        ),
        _buildRequirement(
          'One special character (!@#\$%^&*)',
          password.contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]')),
        ),
      ],
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isMet ? AppColors.success : AppColors.textSecondary,
                fontWeight: isMet ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
