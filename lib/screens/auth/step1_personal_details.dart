import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../constants/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/education_data_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/password_strength_indicator.dart';

class Step1PersonalDetails extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const Step1PersonalDetails({super.key, required this.onNext});

  @override
  ConsumerState<Step1PersonalDetails> createState() =>
      _Step1PersonalDetailsState();
}

class _Step1PersonalDetailsState extends ConsumerState<Step1PersonalDetails> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _websiteController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _completePhoneNumber = '';
  String _selectedCountryCode = 'US'; // Default country code
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _prefetchEducationData();
  }

  // Prefetch education data in background for Step 3
  void _prefetchEducationData() {
    // This triggers the API call and caches the result
    ref.read(educationDataProvider);
  }

  void _loadExistingData() {
    final state = ref.read(onboardingProvider);
    _fullNameController.text = state.fullName ?? '';
    _emailController.text = state.email ?? '';

    // Handle phone number - extract number without country code
    final savedPhone = state.phone ?? '';
    if (savedPhone.isNotEmpty) {
      // Store the complete phone number for later use
      _completePhoneNumber = savedPhone;

      // Extract just the phone number without country code
      // Since we default to US (+1), we'll handle that case specially
      // For other countries, we'll try to extract based on common patterns
      String phoneNumber = savedPhone;

      // Remove + sign if present
      if (phoneNumber.startsWith('+')) {
        phoneNumber = phoneNumber.substring(1);
      }

      // For US numbers (+1), remove the 1
      if (phoneNumber.startsWith('1') && phoneNumber.length > 10) {
        phoneNumber = phoneNumber.substring(1);
        _selectedCountryCode = 'US';
      }
      // For other common country codes, you can add more cases here
      // For now, we'll just remove the first 2-3 digits as country code
      else if (phoneNumber.length > 10) {
        // Try to detect country code length (usually 1-3 digits)
        // This is a simple heuristic - for production, use a proper library
        if (phoneNumber.length > 11) {
          phoneNumber = phoneNumber.substring(2); // Assume 2-digit country code
        }
      }

      _phoneController.text = phoneNumber;
    }

    _linkedInController.text = state.linkedIn ?? '';
    _websiteController.text = state.website ?? '';
    _passwordController.text = state.password ?? '';
    _confirmPasswordController.text = state.password ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedInController.dispose();
    _websiteController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // Unfocus any text fields before deactivation to prevent
    // looking up deactivated widget's ancestor
    FocusManager.instance.primaryFocus?.unfocus();
    super.deactivate();
  }

  void _handleSubmit() {
    // Dismiss keyboard before validation
    FocusScope.of(context).requestFocus(FocusNode());

    // Enable autovalidation after first submission attempt
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    if (_formKey.currentState!.validate()) {
      // Ensure we use the complete phone number with country code
      final phoneNumber = _completePhoneNumber.isNotEmpty
          ? _completePhoneNumber
          : '+1${_phoneController.text.trim()}'; // Default to US country code if not set

      ref
          .read(onboardingProvider.notifier)
          .updatePersonalDetails(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: phoneNumber,
            linkedIn: _linkedInController.text.trim(),
            website: _websiteController.text.trim(),
          );

      // Also save password to onboarding provider
      ref
          .read(onboardingProvider.notifier)
          .setUserDetails(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _fullNameController,
            labelText: 'Full Name',
            hintText: 'John Alex',
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            maxLength: 50,
            isRequired: true,
            inputFormatters: [
              // Allow letters, spaces, hyphens, apostrophes, and periods
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-'.]")),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              // Check if name contains only valid characters
              if (!RegExp(r"^[a-zA-Z\s\-'.]+$").hasMatch(value)) {
                return 'Name can only contain letters, spaces, hyphens, apostrophes, and periods';
              }
              // Check if name has at least 2 characters (excluding spaces)
              if (value.replaceAll(' ', '').length < 2) {
                return 'Please enter a valid name';
              }
              // Check if name doesn't start or end with special characters
              if (value.startsWith('-') ||
                  value.startsWith('.') ||
                  value.endsWith('-') ||
                  value.endsWith('.')) {
                return 'Name cannot start or end with special characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _emailController,
            labelText: 'Email',
            hintText: 'john.alex@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            maxLength: 100,
            isRequired: true,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Phone Number',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
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
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.inputBorderFocused,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  counterText: '',
                ),
                initialCountryCode: _selectedCountryCode,
                onChanged: (phone) {
                  setState(() {
                    _completePhoneNumber = phone.completeNumber;
                  });
                },
                validator: (phone) {
                  if (phone == null || phone.number.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
                showCountryFlag: true,
                showDropdownIcon: true,
                flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 12),
                dropdownIconPosition: IconPosition.trailing,
                dropdownIcon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _linkedInController,
            labelText: 'LinkedIn Profile',
            hintText: 'https://www.linkedin.com/in/yourprofile',
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            maxLength: 200,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _websiteController,
            labelText: 'Personal Website',
            hintText: 'https://www.yourwebsite.com',
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            maxLength: 200,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            textInputAction: TextInputAction.next,
            obscureText: _obscurePassword,
            isRequired: true,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
              setState(
                () {},
              ); // Trigger rebuild for password strength indicator
            },
          ),
          const SizedBox(height: 12),
          // Password strength indicator
          PasswordStrengthIndicator(password: _passwordController.text),
          const SizedBox(height: 8),
          // Password requirements
          if (_passwordController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: PasswordRequirementsIndicator(
                password: _passwordController.text,
              ),
            ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password *',
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
                  _obscureConfirmPassword = !_obscureConfirmPassword;
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
          ),
          const SizedBox(height: 20),
          // Next button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _handleSubmit,
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
      ),
    );
  }
}
