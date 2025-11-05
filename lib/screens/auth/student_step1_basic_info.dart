import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../constants/app_colors.dart';
import '../../providers/student_signup_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/password_strength_indicator.dart';

class StudentStep1BasicInfo extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const StudentStep1BasicInfo({super.key, required this.onNext});

  @override
  ConsumerState<StudentStep1BasicInfo> createState() =>
      _StudentStep1BasicInfoState();
}

class _StudentStep1BasicInfoState extends ConsumerState<StudentStep1BasicInfo> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _completePhoneNumber = '';
  String _selectedCountryCode = 'US';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final state = ref.read(studentSignupProvider);
    _fullNameController.text = state.fullName ?? '';
    _emailController.text = state.email ?? '';

    final savedPhone = state.phone ?? '';
    if (savedPhone.isNotEmpty) {
      _completePhoneNumber = savedPhone;
      String phoneNumber = savedPhone;

      if (phoneNumber.startsWith('+')) {
        phoneNumber = phoneNumber.substring(1);
      }

      if (phoneNumber.startsWith('1') && phoneNumber.length > 10) {
        phoneNumber = phoneNumber.substring(1);
        _selectedCountryCode = 'US';
      }

      _phoneController.text = phoneNumber;
    }

    _passwordController.text = state.password ?? '';
    _confirmPasswordController.text = state.password ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    if (_formKey.currentState!.validate()) {
      final phoneNumber = _completePhoneNumber.isNotEmpty
          ? _completePhoneNumber
          : '+1${_phoneController.text.trim()}';

      ref
          .read(studentSignupProvider.notifier)
          .updateStep1(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: phoneNumber,
            password: _passwordController.text.trim(),
          );

      // Don't call nextStep here - parent will handle it
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
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-'.]")),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              if (!RegExp(r"^[a-zA-Z\s\-'.]+$").hasMatch(value)) {
                return 'Name can only contain letters, spaces, hyphens, apostrophes, and periods';
              }
              if (value.replaceAll(' ', '').length < 2) {
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
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          PasswordStrengthIndicator(password: _passwordController.text),
          const SizedBox(height: 8),
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
          const SizedBox(height: 32),
          // Next button
          CustomButton(text: 'Next', onPressed: _handleSubmit, height: 56),
        ],
      ),
    );
  }
}
