import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../constants/app_colors.dart';
import '../../../../providers/onboarding_provider.dart';
import '../../../../utils/validators.dart';
import '../../../../widgets/common/custom_text_field.dart';

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

  String _completePhoneNumber = '';
  String? _phoneValidationError;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final state = ref.read(onboardingProvider);
    _fullNameController.text = state.fullName ?? '';
    _emailController.text = 'john@gmail.com';
    _phoneController.text = '4444777553';
    _linkedInController.text = state.linkedIn ?? '';
    _websiteController.text = state.website ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedInController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(onboardingProvider.notifier)
          .updatePersonalDetails(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _completePhoneNumber.isNotEmpty
                ? _completePhoneNumber
                : _phoneController.text.trim(),
            linkedIn: _linkedInController.text.trim(),
            website: _websiteController.text.trim(),
          );
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _fullNameController,
            labelText: 'Full Name *',
            hintText: 'John Alex',
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            maxLength: 50,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _emailController,
            labelText: 'Email *',
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
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              IntlPhoneField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
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
                initialCountryCode: 'US',
                onChanged: (phone) {
                  setState(() {
                    _completePhoneNumber = phone.completeNumber;
                    _phoneValidationError = null;
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
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            maxLength: 200,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _websiteController,
            labelText: 'Personal Website',
            hintText: 'https://www.yourwebsite.com',
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            maxLength: 200,
          ),
          const SizedBox(height: 32),
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
