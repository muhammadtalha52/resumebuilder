import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/common/custom_text_field.dart';

class EditPersonalDetailsScreen extends ConsumerStatefulWidget {
  const EditPersonalDetailsScreen({super.key});

  @override
  ConsumerState<EditPersonalDetailsScreen> createState() =>
      _EditPersonalDetailsScreenState();
}

class _EditPersonalDetailsScreenState
    extends ConsumerState<EditPersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _websiteController = TextEditingController();

  String _completePhoneNumber = '';
  String _selectedCountryCode = 'US'; // Default country code
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user != null) {
      _fullNameController.text = user.fullName ?? '';
      _linkedInController.text = user.linkedinUrl ?? '';
      _websiteController.text = user.portfolioUrl ?? '';

      // Handle phone number - extract number without country code
      final savedPhone = user.phoneNumber ?? '';
      if (savedPhone.isNotEmpty) {
        // Store the complete phone number for later use
        _completePhoneNumber = savedPhone;

        // Extract just the phone number without country code
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
        else if (phoneNumber.length > 10) {
          // Try to detect country code length (usually 1-3 digits)
          if (phoneNumber.length > 11) {
            phoneNumber = phoneNumber.substring(
              2,
            ); // Assume 2-digit country code
          }
        }

        _phoneController.text = phoneNumber;
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _linkedInController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    // Enable autovalidation after first submission attempt
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // TODO: Implement API call to update personal details
        // Ensure we use the complete phone number with country code
        // final phoneNumber = _completePhoneNumber.isNotEmpty
        //     ? _completePhoneNumber
        //     : '+1${_phoneController.text.trim()}'; // Default to US country code if not set

        // For now, just simulate a delay
        await Future.delayed(const Duration(seconds: 1));

        // Show success message
        if (mounted) {
          showSuccessSnackBar(
            context: context,
            message: 'Personal details updated successfully!',
          );

          // Navigate back to profile screen
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          showErrorSnackBar(
            context: context,
            message: 'Failed to update personal details. Please try again.',
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/fox-mascot.png', height: 35),
            const SizedBox(width: 8),
            const Text(
              'Edit Personal Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/icons/background.png',
              fit: BoxFit.cover,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Main container with white background (like onboarding)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Form(
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Phone Number Field
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
                                    text: ' *',
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
                                  borderSide: const BorderSide(
                                    color: AppColors.inputBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.inputBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.inputBorderFocused,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.error,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.error,
                                  ),
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
                              flagsButtonPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
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

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: AppColors.primary
                                  .withValues(alpha: 0.6),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
