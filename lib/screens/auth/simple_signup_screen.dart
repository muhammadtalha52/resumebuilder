import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../utils/validators.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/password_strength_indicator.dart';
import '../../widgets/dialogs/email_exists_dialog.dart';
import '../../widgets/common/server_url_tap_detector.dart';
import 'account_creation_loading_screen.dart';

class SimpleSignupScreen extends ConsumerStatefulWidget {
  const SimpleSignupScreen({super.key});

  @override
  ConsumerState<SimpleSignupScreen> createState() => _SimpleSignupScreenState();
}

class _SimpleSignupScreenState extends ConsumerState<SimpleSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _hometownController = TextEditingController();

  String _completePhoneNumber = '';
  String _selectedCountryCode = 'US';
  String? _phoneErrorText;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCheckingEmail = false;
  bool _isDetectingLocation = false;
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
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneControllerChanged);
  }

  void _onPhoneControllerChanged() {
    if (_autovalidateMode != AutovalidateMode.disabled || _phoneErrorText != null) {
      final error = _validatePhone(_phoneController.text);
      if (error != _phoneErrorText) {
        setState(() {
          _phoneErrorText = error;
        });
      }
    }
  }

  String? _validatePhone(String? value) {
    final phone = (value ?? _phoneController.text).trim();
    if (phone.isEmpty) {
      return 'Please enter your phone number';
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneControllerChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _hometownController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetectingLocation = true;
    });

    try {
      final locationService = LocationService();
      final location = await locationService.getCurrentCityAndState();

      if (!mounted) return;

      if (location != null) {
        _hometownController.text = location;
      } else {
        showErrorSnackBar(
          context: context,
          message: 'Unable to detect location. Please enter manually.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        context: context,
        message: 'Unable to detect location. Please enter manually.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  Future<void> _handleSignup() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Validate phone number and enable autovalidation
    final phoneError = _validatePhone(_phoneController.text);
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
      _phoneErrorText = phoneError;
    });

    final isFormValid = _formKey.currentState!.validate();

    if (!isFormValid || phoneError != null) {
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

    // Build the complete phone number
    final phoneNumber = _completePhoneNumber.isNotEmpty
        ? _completePhoneNumber
        : (_phoneController.text.trim().isNotEmpty
            ? '+1${_phoneController.text.trim()}'
            : null);

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
        fullName: _fullNameController.text.trim(),
        phoneNumber: phoneNumber,
        hometown: _hometownController.text.trim().isNotEmpty
            ? _hometownController.text.trim()
            : null,
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/user-type-selection');
        }
      },
      child: GestureDetector(
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
                                    ServerUrlTapDetector(
                                      child: Image.asset(
                                        'assets/icons/logo-fox-on-left.png',
                                        height: isTablet ? 150 : 120,
                                        width: isTablet ? 350 : 300,
                                      ),
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

                                    // Full Name Field
                                    CustomTextField(
                                      controller: _fullNameController,
                                      labelText: 'Full Name',
                                      hintText: 'Type your full name here',
                                      keyboardType: TextInputType.name,
                                      textInputAction: TextInputAction.next,
                                      maxLength: 50,
                                      isRequired: true,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r"[a-zA-Z\s\-'.]"),
                                        ),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your full name';
                                        }
                                        if (!RegExp(r"^[a-zA-Z\s\-'.]+$")
                                            .hasMatch(value)) {
                                          return 'Name can only contain letters, spaces, hyphens, apostrophes, and periods';
                                        }
                                        if (value.replaceAll(' ', '').length <
                                            2) {
                                          return 'Please enter a valid name';
                                        }
                                        if (value.startsWith('-') ||
                                            value.startsWith('.') ||
                                            value.endsWith('-') ||
                                            value.endsWith('.')) {
                                          return 'Name cannot start or end with special characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppSizes.spaceL),

                                    // Email Field
                                    CustomTextField(
                                      controller: _emailController,
                                      labelText: 'Email',
                                      hintText: 'Enter your email',
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      maxLength: 100,
                                      isRequired: true,
                                      validator: Validators.validateEmail,
                                    ),
                                    const SizedBox(height: AppSizes.spaceL),

                                    // Phone Number Field
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: const TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Phone Number',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      AppColors.textPrimary,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '*',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        IntlPhoneField(
                                          controller: _phoneController,
                                          autovalidateMode: _autovalidateMode,
                                          disableLengthCheck: true,
                                          decoration: InputDecoration(
                                            hintText: '(000) 000-0000',
                                            hintStyle: const TextStyle(
                                              color: AppColors.textLight,
                                              fontSize: 13,
                                            ),
                                            errorText: _phoneErrorText,
                                            errorStyle: const TextStyle(
                                              color: AppColors.error,
                                              fontSize: 12,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.inputBorder,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: _phoneErrorText != null
                                                    ? AppColors.error
                                                    : AppColors.inputBorder,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: _phoneErrorText != null
                                                    ? AppColors.error
                                                    : AppColors
                                                        .inputBorderFocused,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.error,
                                              ),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.error,
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                            counterText: '',
                                          ),
                                          initialCountryCode:
                                              _selectedCountryCode,
                                          onCountryChanged: (country) {
                                            setState(() {
                                              _selectedCountryCode =
                                                  country.code;
                                            });
                                          },
                                          onChanged: (phone) {
                                            _completePhoneNumber =
                                                phone.completeNumber;
                                            if (_autovalidateMode !=
                                                    AutovalidateMode.disabled ||
                                                _phoneErrorText != null) {
                                              final error = _validatePhone(
                                                  phone.number);
                                              if (error != _phoneErrorText) {
                                                setState(() {
                                                  _phoneErrorText = error;
                                                });
                                              }
                                            }
                                          },
                                          textInputAction:
                                              TextInputAction.next,
                                          showCountryFlag: true,
                                          showDropdownIcon: true,
                                          flagsButtonPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          dropdownIconPosition:
                                              IconPosition.trailing,
                                          dropdownIcon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSizes.spaceL),

                                    // Hometown & State Field
                                    CustomTextField(
                                      controller: _hometownController,
                                      labelText: 'Hometown & State',
                                      hintText: 'e.g Austin, Texas',
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.next,
                                      isRequired: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your hometown';
                                        }
                                        return null;
                                      },
                                      suffixIcon: _isDetectingLocation
                                          ? const Padding(
                                              padding: EdgeInsets.all(12.0),
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : InkWell(
                                              onTap: _detectLocation,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.my_location,
                                                      color:
                                                          AppColors.primary,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Locate',
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .primary,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
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
                                            _obscurePassword =
                                                !_obscurePassword;
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.inputBorder,
                                          ),
                                        ),
                                        child:
                                            PasswordRequirementsIndicator(
                                          password:
                                              _passwordController.text,
                                        ),
                                      ),
                                    const SizedBox(height: AppSizes.spaceL),

                                    // Confirm Password Field
                                    CustomTextField(
                                      controller:
                                          _confirmPasswordController,
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
                                        if (value !=
                                            _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) =>
                                          _handleSignup(),
                                    ),
                                    const SizedBox(height: AppSizes.spaceL),

                                    // How did you hear about us? Dropdown
                                    DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText:
                                            'How did you hear about us? (Optional)',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      value: _selectedHeardAboutUs,
                                      items:
                                          _marketingSources.map((source) {
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
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
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
      ),
    );
  }
}
