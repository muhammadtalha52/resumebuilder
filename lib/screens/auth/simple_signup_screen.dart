import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/password_strength_indicator.dart';
import '../../widgets/dialogs/email_exists_dialog.dart';
import 'account_creation_loading_screen.dart';

class SimpleSignupScreen extends ConsumerStatefulWidget {
  const SimpleSignupScreen({super.key});

  @override
  ConsumerState<SimpleSignupScreen> createState() => _SimpleSignupScreenState();
}

class _SimpleSignupScreenState extends ConsumerState<SimpleSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCheckingEmail = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  final AuthService _authService = AuthService();
  
  String? _selectedHeardAboutUs;
  final List<Map<String, String>> _marketingSources = [
    {'label': 'Radio', 'value': 'radio'},
    {'label': 'Facebook', 'value': 'facebook'},
    {'label': 'Instagram', 'value': 'instagram'},
    {'label': 'TikTok', 'value': 'tiktok'},
    {'label': 'YouTube', 'value': 'youtube'},
    {'label': 'Reddit', 'value': 'reddit'},
    {'label': 'Friend/Referral', 'value': 'friend_referral'},
    {'label': 'Blog', 'value': 'blog'},
    {'label': 'Tools Directory', 'value': 'tools_directory'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Enable autovalidation after first submission attempt
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if email already exists
    setState(() {
      _isCheckingEmail = true;
    });

    try {
      final emailAvailable = await _authService.checkEmailAvailable(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isCheckingEmail = false;
      });

      if (!emailAvailable) {
        // Show email exists dialog
        await showEmailExistsDialog(
          context: context,
          email: _emailController.text.trim(),
        );
        return;
      }

      // Email is available, proceed with signup
      await _completeSignup();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCheckingEmail = false;
      });

      showErrorSnackBar(
        context: context,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> _completeSignup() async {
    final authNotifier = ref.read(authProvider.notifier);

    // Create a GlobalKey to control the loading screen animation
    final loadingScreenKey = GlobalKey<AccountCreationLoadingScreenState>();

    // Navigate to loading screen
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AccountCreationLoadingScreen(
              key: loadingScreenKey,
              isStudent: false,
              onAnimationComplete: () {
                // Navigate to home screen after animation completes
                if (mounted) {
                  context.go('/home');
                }
              },
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    try {
      // Call signup API
      await authNotifier.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        heardAboutUs: _selectedHeardAboutUs,
      );

      // Check if we're still mounted before showing UI
      if (!mounted) return;

      // Trigger the completion animation
      loadingScreenKey.currentState?.completeAnimation();
    } catch (e) {
      // Handle error - pop loading screen and show error
      if (!mounted) return;

      Navigator.of(context).pop();

      showErrorSnackBar(
        context: context,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= AppSizes.tabletBreakpoint;

    return GestureDetector(
      onTap: () {
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
                            child: Form(
                              key: _formKey,
                              autovalidateMode: _autovalidateMode,
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
                                    'Create Account',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: AppSizes.spaceS),

                                  // Subtitle
                                  Text(
                                    'Sign up to get started with SkillResy',
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
                                    labelText: 'Email',
                                    hintText: 'Enter your email',
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    maxLength: 100,
                                    isRequired: true,
                                    validator: Validators.validateEmail,
                                  ),
                                  const SizedBox(height: AppSizes.spaceL),

                                  // Password Field
                                  CustomTextField(
                                    controller: _passwordController,
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    textInputAction: TextInputAction.next,
                                    obscureText: _obscurePassword,
                                    isRequired: true,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    validator: Validators.validatePassword,
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // Password strength indicator
                                  PasswordStrengthIndicator(
                                    password: _passwordController.text,
                                  ),
                                  const SizedBox(height: 8),

                                  // Password requirements
                                  if (_passwordController.text.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.inputBorder,
                                        ),
                                      ),
                                      child: PasswordRequirementsIndicator(
                                        password: _passwordController.text,
                                      ),
                                    ),
                                  const SizedBox(height: AppSizes.spaceL),

                                  // Confirm Password Field
                                  CustomTextField(
                                    controller: _confirmPasswordController,
                                    labelText: 'Confirm Password',
                                    hintText: 'Confirm your password',
                                    textInputAction: TextInputAction.done,
                                    obscureText: _obscureConfirmPassword,
                                    isRequired: true,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                    onFieldSubmitted: (_) => _handleSignup(),
                                  ),
                                  const SizedBox(height: AppSizes.spaceL),

                                  // How did you hear about us? Dropdown
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'How did you hear about us? (Optional)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    value: _selectedHeardAboutUs,
                                    items: _marketingSources.map((source) {
                                      return DropdownMenuItem<String>(
                                        value: source['value'],
                                        child: Text(source['label']!),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedHeardAboutUs = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: AppSizes.spaceXL),

                                  // Create Account Button
                                  CustomButton(
                                    text: _isCheckingEmail
                                        ? 'Checking email...'
                                        : 'Create Account',
                                    onPressed: _isCheckingEmail
                                        ? null
                                        : _handleSignup,
                                    isLoading: _isCheckingEmail,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceL),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            TextButton(
                              onPressed: () {
                                context.go('/login');
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Sign In',
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
