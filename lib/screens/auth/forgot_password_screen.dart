import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillresy/constants/app_colors.dart';
import 'package:skillresy/constants/app_sizes.dart';
import 'package:skillresy/providers/auth_provider.dart';
import 'package:skillresy/utils/validators.dart';
import 'package:skillresy/utils/snackbar_utils.dart';
import 'package:skillresy/widgets/common/custom_button.dart';
import 'package:skillresy/widgets/common/custom_text_field.dart'
    hide CustomButton;

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendResetLink() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .forgotPassword(email: _emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= AppSizes.tabletBreakpoint;

    // Listen for auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isLoading == true &&
          !next.isLoading &&
          next.error != null) {
        showErrorSnackBar(context: context, message: next.error!);
        setState(() {
          _emailSent = false;
        });
      }

      // Show success state when reset email is sent
      if (previous?.isLoading == true &&
          !next.isLoading &&
          next.error == null) {
        setState(() {
          _emailSent = true;
        });
      }
    });

    return GestureDetector(
      onTap: () {
        // Unfocus when tapping outside text fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background pattern
            Positioned.fill(
              child: Image.asset(
                'assets/icons/background.png',
                fit: BoxFit.cover,
              ),
            ),
            // Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? AppSizes.paddingXL : 5),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 600 : double.infinity,
                    ),
                    child: Column(
                      children: [
                        // Card
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusL,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.paddingM),
                            child: _emailSent
                                ? _buildSuccessView(context, isTablet)
                                : _buildFormView(context, isTablet, authState),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView(
    BuildContext context,
    bool isTablet,
    AuthState authState,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SkillResy Logo
          Image.asset(
            'assets/icons/logo-fox-on-left.png',
            height: isTablet ? 150 : 120,
            width: isTablet ? 350 : 300,
          ),

          const SizedBox(height: AppSizes.spaceS),
          // Title
          Text(
            'Reset Your Password',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spaceS),
          // Subtitle
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spaceXL),

          // Email Field
          CustomTextField(
            controller: _emailController,
            labelText: 'Email',
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.validateEmail,
            onFieldSubmitted: (_) => _handleSendResetLink(),
          ),
          const SizedBox(height: AppSizes.spaceXL),

          // Send Reset Link Button
          CustomButton(
            text: 'Send Reset Link',
            onPressed: authState.isLoading ? null : _handleSendResetLink,
            isLoading: authState.isLoading,
          ),
          const SizedBox(height: AppSizes.spaceM),

          // Back to Login Button
          TextButton(
            onPressed: () {
              context.go('/login');
            },
            child: Text(
              'Back to Login',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // SkillResy Logo
        Image.asset(
          'assets/icons/logo-fox-on-left.png',
          height: isTablet ? 150 : 120,
          width: isTablet ? 350 : 300,
        ),

        const SizedBox(height: AppSizes.spaceL),

        // Success Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            size: 50,
            color: AppColors.success,
          ),
        ),

        const SizedBox(height: AppSizes.spaceL),

        // Success Title
        Text(
          'Email Sent Successfully!',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSizes.spaceM),

        // Success Message
        Text(
          'We\'ve sent a password reset link to',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spaceXS),
        Text(
          _emailController.text.trim(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSizes.spaceM),

        // Instructions
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Please check your email inbox and follow these steps:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spaceS),
              _buildInstructionItem(context, '1', 'Open the email we sent you'),
              _buildInstructionItem(
                context,
                '2',
                'Click on the password reset link',
              ),
              _buildInstructionItem(context, '3', 'Set your new password'),
              _buildInstructionItem(
                context,
                '4',
                'Login with your new password',
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.spaceXL),

        // Back to Login Button
        CustomButton(
          text: 'Back to Login',
          onPressed: () {
            context.go('/login');
          },
        ),

        const SizedBox(height: AppSizes.spaceS),

        // Resend Email Button
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: Text(
            'Didn\'t receive the email? Send again',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(
    BuildContext context,
    String number,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spaceS),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
