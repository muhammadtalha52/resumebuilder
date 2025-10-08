import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/common/custom_text_field.dart';

class EditStudentPersonalDetailsScreen extends ConsumerStatefulWidget {
  const EditStudentPersonalDetailsScreen({super.key});

  @override
  ConsumerState<EditStudentPersonalDetailsScreen> createState() =>
      _EditStudentPersonalDetailsScreenState();
}

class _EditStudentPersonalDetailsScreenState
    extends ConsumerState<EditStudentPersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _homeTownController = TextEditingController();

  String _selectedCountryCode = 'US'; // Default country code
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Country code mapping for common countries
  final Map<String, String> _countryCodeMap = {
    '1684': 'AS',
    '1787': 'PR',
    '1939': 'PR',
    '1671': 'GU',
    '1670': 'MP',
    '1340': 'VI',
    '1284': 'VG',
    '1246': 'BB',
    '1242': 'BS',
    '1268': 'AG',
    '1264': 'AI',
    '1345': 'KY',
    '1441': 'BM',
    '1473': 'GD',
    '1649': 'TC',
    '1664': 'MS',
    '1721': 'SX',
    '1758': 'LC',
    '1767': 'DM',
    '1784': 'VC',
    '1809': 'DO',
    '1829': 'DO',
    '1849': 'DO',
    '1868': 'TT',
    '1869': 'KN',
    '1876': 'JM',
    '1878': 'NA',
    '1902': 'CA',
    '1905': 'CA',
    '966': 'SA',
    '971': 'AE',
    '234': 'NG',
    '254': 'KE',
    '1': 'US',
    '92': 'PK',
    '91': 'IN',
    '44': 'GB',
    '49': 'DE',
    '33': 'FR',
    '39': 'IT',
    '34': 'ES',
    '86': 'CN',
    '81': 'JP',
    '82': 'KR',
    '61': 'AU',
    '55': 'BR',
    '52': 'MX',
    '7': 'RU',
    '90': 'TR',
    '20': 'EG',
    '27': 'ZA',
    '60': 'MY',
    '65': 'SG',
    '66': 'TH',
    '84': 'VN',
    '63': 'PH',
    '62': 'ID',
  };

  String _detectCountryCode(String phoneNumber) {
    if (phoneNumber.isEmpty) return 'US';
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanNumber.startsWith('+')) {
      cleanNumber = cleanNumber.substring(1);
    }
    List<String> codes = _countryCodeMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (String code in codes) {
      if (cleanNumber.startsWith(code)) {
        String remainingDigits = cleanNumber.substring(code.length);
        if (remainingDigits.length >= 7 && remainingDigits.length <= 12) {
          return _countryCodeMap[code]!;
        }
      }
    }
    return 'US';
  }

  String _extractPhoneNumber(String fullPhoneNumber) {
    if (fullPhoneNumber.isEmpty) return '';
    String cleanNumber = fullPhoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanNumber.startsWith('+')) {
      cleanNumber = cleanNumber.substring(1);
    }
    List<String> codes = _countryCodeMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (String code in codes) {
      if (cleanNumber.startsWith(code)) {
        String remainingDigits = cleanNumber.substring(code.length);
        if (remainingDigits.length >= 7 && remainingDigits.length <= 12) {
          return remainingDigits;
        }
      }
    }
    return cleanNumber;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user != null) {
      ref.read(profileProvider.notifier).initializeWithUserData(user);

      _fullNameController.text = user.fullName ?? '';
      _homeTownController.text = user.homeTown ?? '';

      final savedPhone = user.phoneNumber ?? '';
      if (savedPhone.isNotEmpty) {
        final detectedCountryCode = _detectCountryCode(savedPhone);
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
    _homeTownController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_autovalidateMode != AutovalidateMode.onUserInteraction) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
    }

    if (_formKey.currentState!.validate()) {
      final profileNotifier = ref.read(profileProvider.notifier);
      profileNotifier.updateField('full_name', _fullNameController.text.trim());
      profileNotifier.updateField('home_town', _homeTownController.text.trim());

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
                                hintText: 'John Doe',
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                maxLength: 50,
                                isRequired: true,
                                inputFormatters: [
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
                                  if (!RegExp(
                                    r"^[a-zA-Z\s\-'.]+$",
                                  ).hasMatch(value)) {
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
                                    key: ValueKey(_selectedCountryCode),
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
                                controller: _homeTownController,
                                labelText: 'Home Town',
                                hintText: 'Los Angeles',
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.done,
                                maxLength: 100,
                                onChanged: (value) {
                                  ref
                                      .read(profileProvider.notifier)
                                      .updateField('home_town', value);
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
