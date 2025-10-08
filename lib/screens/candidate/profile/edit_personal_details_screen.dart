import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/common/custom_text_field.dart';

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

  String _selectedCountryCode = 'US'; // Default country code
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Country code mapping for common countries
  // IMPORTANT: Order matters - longer codes must come before shorter ones
  final Map<String, String> _countryCodeMap = {
    // North American specific codes (longer codes first)
    '1684': 'AS', // American Samoa
    '1787': 'PR', // Puerto Rico
    '1939': 'PR', // Puerto Rico
    '1671': 'GU', // Guam
    '1670': 'MP', // Northern Mariana Islands
    '1340': 'VI', // US Virgin Islands
    '1284': 'VG', // British Virgin Islands
    '1246': 'BB', // Barbados
    '1242': 'BS', // Bahamas
    '1268': 'AG', // Antigua and Barbuda
    '1264': 'AI', // Anguilla
    '1345': 'KY', // Cayman Islands
    '1441': 'BM', // Bermuda
    '1473': 'GD', // Grenada
    '1649': 'TC', // Turks and Caicos
    '1664': 'MS', // Montserrat
    '1721': 'SX', // Sint Maarten
    '1758': 'LC', // Saint Lucia
    '1767': 'DM', // Dominica
    '1784': 'VC', // Saint Vincent and the Grenadines
    '1809': 'DO', // Dominican Republic
    '1829': 'DO', // Dominican Republic
    '1849': 'DO', // Dominican Republic
    '1868': 'TT', // Trinidad and Tobago
    '1869': 'KN', // Saint Kitts and Nevis
    '1876': 'JM', // Jamaica
    '1878': 'NA', // North America (other)
    '1902': 'CA', // Canada (Nova Scotia)
    '1905': 'CA', // Canada (Ontario)
    // Other longer codes
    '966': 'SA', // Saudi Arabia
    '971': 'AE', // UAE
    '234': 'NG', // Nigeria
    '254': 'KE', // Kenya
    // Common country codes
    '1': 'US', // USA, Canada (fallback for +1)
    '92': 'PK', // Pakistan
    '91': 'IN', // India
    '44': 'GB', // UK
    '49': 'DE', // Germany
    '33': 'FR', // France
    '39': 'IT', // Italy
    '34': 'ES', // Spain
    '86': 'CN', // China
    '81': 'JP', // Japan
    '82': 'KR', // South Korea
    '61': 'AU', // Australia
    '55': 'BR', // Brazil
    '52': 'MX', // Mexico
    '7': 'RU', // Russia
    '90': 'TR', // Turkey
    '20': 'EG', // Egypt
    '27': 'ZA', // South Africa
    '60': 'MY', // Malaysia
    '65': 'SG', // Singapore
    '66': 'TH', // Thailand
    '84': 'VN', // Vietnam
    '63': 'PH', // Philippines
    '62': 'ID', // Indonesia
  };

  // Detect country code from phone number
  String _detectCountryCode(String phoneNumber) {
    if (phoneNumber.isEmpty) return 'US';

    print('DEBUG: Original phone: $phoneNumber');

    // Remove all non-digit characters except +
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    print('DEBUG: Cleaned phone: $cleanNumber');

    // Remove + sign if present
    if (cleanNumber.startsWith('+')) {
      cleanNumber = cleanNumber.substring(1);
    }
    print('DEBUG: Without +: $cleanNumber');

    // Try to match country codes (from longest to shortest)
    List<String> codes = _countryCodeMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (String code in codes) {
      if (cleanNumber.startsWith(code)) {
        // Verify remaining digits form a reasonable phone number
        String remainingDigits = cleanNumber.substring(code.length);
        print(
          'DEBUG: Trying code $code, remaining: $remainingDigits (length: ${remainingDigits.length})',
        );
        if (remainingDigits.length >= 7 && remainingDigits.length <= 12) {
          print('DEBUG: Found match! Country: ${_countryCodeMap[code]}');
          return _countryCodeMap[code]!;
        }
      }
    }

    print('DEBUG: No match found, defaulting to US');
    return 'US'; // Default fallback
  }

  // Extract phone number without country code
  String _extractPhoneNumber(String fullPhoneNumber) {
    if (fullPhoneNumber.isEmpty) return '';

    print('DEBUG Extract: Original phone: $fullPhoneNumber');

    // Remove all non-digit characters except +
    String cleanNumber = fullPhoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    print('DEBUG Extract: Cleaned phone: $cleanNumber');

    // Remove + sign if present
    if (cleanNumber.startsWith('+')) {
      cleanNumber = cleanNumber.substring(1);
    }
    print('DEBUG Extract: Without +: $cleanNumber');

    // Try to match country codes (from longest to shortest)
    List<String> codes = _countryCodeMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (String code in codes) {
      if (cleanNumber.startsWith(code)) {
        String remainingDigits = cleanNumber.substring(code.length);
        print(
          'DEBUG Extract: Trying code $code, remaining: $remainingDigits (length: ${remainingDigits.length})',
        );
        if (remainingDigits.length >= 7 && remainingDigits.length <= 12) {
          print('DEBUG Extract: Extracting: $remainingDigits');
          return remainingDigits;
        }
      }
    }

    // If no country code found, return the original number (cleaned)
    print('DEBUG Extract: No match, returning cleaned: $cleanNumber');
    return cleanNumber;
  }

  @override
  void initState() {
    super.initState();
    // Delay the provider initialization to avoid modifying state during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user != null) {
      // Initialize profile provider with user data
      ref.read(profileProvider.notifier).initializeWithUserData(user);

      _fullNameController.text = user.fullName ?? '';
      _linkedInController.text = user.linkedinUrl ?? '';
      _websiteController.text = user.portfolioUrl ?? '';

      // Handle phone number - extract number without country code
      final savedPhone = user.phoneNumber ?? '';
      if (savedPhone.isNotEmpty) {
        // Detect country code from saved phone number
        final detectedCountryCode = _detectCountryCode(savedPhone);

        // Extract phone number without country code
        String phoneNumber = _extractPhoneNumber(savedPhone);

        setState(() {
          _selectedCountryCode = detectedCountryCode;
          _phoneController.text = phoneNumber;
        });
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
    if (_autovalidateMode != AutovalidateMode.onUserInteraction) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
    }

    if (_formKey.currentState!.validate()) {
      // Update profile fields in provider before saving
      final profileNotifier = ref.read(profileProvider.notifier);
      profileNotifier.updateField('full_name', _fullNameController.text.trim());
      profileNotifier.updateField(
        'linkedin_url',
        _linkedInController.text.trim(),
      );
      profileNotifier.updateField(
        'portfolio_url',
        _websiteController.text.trim(),
      );

      // Call the update profile method
      final success = await profileNotifier.updateProfile();

      if (success && mounted) {
        showSuccessSnackBar(
          context: context,
          message: 'Personal details updated successfully!',
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(profileProvider).error;
        showErrorSnackBar(
          context: context,
          message:
              error ?? 'Failed to update personal details. Please try again.',
        );
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
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                                inputFormatters: [
                                  // Allow letters, spaces, hyphens, apostrophes, and periods
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r"[a-zA-Z\s\-'.]"),
                                  ),
                                ],
                                onChanged: (value) {
                                  ref
                                      .read(profileProvider.notifier)
                                      .updateField('full_name', value);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  // Check if name contains only valid characters
                                  if (!RegExp(
                                    r"^[a-zA-Z\s\-'.]+$",
                                  ).hasMatch(value)) {
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
                                    key: ValueKey(
                                      _selectedCountryCode,
                                    ), // Force rebuild when country code changes
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      counterText: '',
                                    ),
                                    initialCountryCode: _selectedCountryCode,
                                    onChanged: (phone) {
                                      ref
                                          .read(profileProvider.notifier)
                                          .updatePhoneNumber(
                                            phone.completeNumber,
                                            phone.number,
                                          );
                                    },
                                    validator: (phone) {
                                      if (phone == null ||
                                          phone.number.isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      return null;
                                    },
                                    textInputAction: TextInputAction.next,
                                    showCountryFlag: true,
                                    showDropdownIcon: true,
                                    flagsButtonPadding:
                                        const EdgeInsets.symmetric(
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
                                hintText:
                                    'https://www.linkedin.com/in/yourprofile',
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.next,
                                maxLength: 200,
                                onChanged: (value) {
                                  ref
                                      .read(profileProvider.notifier)
                                      .updateField('linkedin_url', value);
                                },
                              ),
                              const SizedBox(height: 20),

                              CustomTextField(
                                controller: _websiteController,
                                labelText: 'Personal Website',
                                hintText: 'https://www.yourwebsite.com',
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.done,
                                maxLength: 200,
                                onChanged: (value) {
                                  ref
                                      .read(profileProvider.notifier)
                                      .updateField('portfolio_url', value);
                                },
                              ),

                              const SizedBox(height: 32),

                              // Save button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      ref.watch(profileProvider).isLoading
                                      ? null
                                      : _handleSave,
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
                                  child: ref.watch(profileProvider).isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
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
