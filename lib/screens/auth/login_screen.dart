import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillresy/constants/app_colors.dart';
import 'package:skillresy/constants/app_sizes.dart';
import 'package:skillresy/constants/app_strings.dart';
import 'package:skillresy/providers/auth_provider.dart';
import 'package:skillresy/utils/validators.dart';
import 'package:skillresy/utils/snackbar_utils.dart';
import 'package:skillresy/widgets/common/custom_button.dart';
import 'package:skillresy/widgets/common/custom_text_field.dart'
    hide CustomButton;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
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
      }

      if (next.isAuthenticated && !previous!.isAuthenticated) {
        context.go('/home');
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
                  padding: EdgeInsets.all(isTablet ? AppSizes.paddingXL : 10),
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
                            padding: const EdgeInsets.all(AppSizes.paddingL),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // SkillResy Logo
                                  Image.asset(
                                    'assets/icons/logo-fox-on-top.png',
                                    height: isTablet ? 150 : 120,
                                  ),

                                  const SizedBox(height: AppSizes.spaceS),

                                  // Subtitle
                                  Text(
                                    'Welcome back! Sign in to be guided by instinct, enhanced by AI.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSizes.spaceXL),

                                  // Email Field
                                  CustomTextField(
                                    controller: _emailController,
                                    labelText: AppStrings.email,
                                    hintText: 'Enter email',
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.validateEmail,
                                  ),
                                  const SizedBox(height: AppSizes.spaceL),

                                  // Password Field
                                  CustomTextField(
                                    controller: _passwordController,
                                    labelText: AppStrings.password,
                                    hintText: 'Enter password',
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    validator: Validators.validatePassword,
                                    onFieldSubmitted: (_) => _handleLogin(),
                                  ),
                                  const SizedBox(height: AppSizes.spaceM),

                                  // Forgot Password Link
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        // TODO: Navigate to forgot password
                                      },
                                      child: Text(
                                        AppStrings.forgotPassword,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.spaceL),

                                  // Login Button
                                  CustomButton(
                                    text: AppStrings.login,
                                    onPressed: authState.isLoading
                                        ? null
                                        : _handleLogin,
                                    isLoading: authState.isLoading,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceL),

                        // Signup Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have a Skillresy account? ",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            TextButton(
                              onPressed: () {
                                context.go('/onboarding');
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Create Account',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
}
