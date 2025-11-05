import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class EditStudentEducationScreen extends ConsumerStatefulWidget {
  const EditStudentEducationScreen({super.key});

  @override
  ConsumerState<EditStudentEducationScreen> createState() =>
      _EditStudentEducationScreenState();
}

class _EditStudentEducationScreenState
    extends ConsumerState<EditStudentEducationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _schoolMajorController = TextEditingController();

  DateTime? _graduationDate;
  String? _graduationDateError;

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Store original values for comparison
  String? _originalSchoolName;
  String? _originalSchoolMajor;
  DateTime? _originalGraduationDate;

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
      setState(() {
        _schoolNameController.text = user.schoolName ?? '';
        _originalSchoolName = user.schoolName;

        _schoolMajorController.text = user.schoolMajor ?? '';
        _originalSchoolMajor = user.schoolMajor;

        if (user.schoolGraduationDate != null &&
            user.schoolGraduationDate!.isNotEmpty) {
          try {
            _graduationDate = DateTime.parse(user.schoolGraduationDate!);
            _originalGraduationDate = _graduationDate;
          } catch (e) {
            _graduationDate = null;
            _originalGraduationDate = null;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolMajorController.dispose();
    super.dispose();
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Graduation Date',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final initialDate =
                _graduationDate != null && _graduationDate!.isAfter(now)
                ? now
                : _graduationDate ?? now;

            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(1950),
              lastDate: DateTime(now.year + 10),
            );
            if (picked != null) {
              setState(() {
                _graduationDate = picked;
                _graduationDateError = null;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(
                color: _graduationDateError != null
                    ? AppColors.error
                    : AppColors.inputBorder,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _graduationDate != null
                        ? '${_graduationDate!.day.toString().padLeft(2, '0')}/${_graduationDate!.month.toString().padLeft(2, '0')}/${_graduationDate!.year}'
                        : 'DD/MM/YYYY',
                    style: TextStyle(
                      color: _graduationDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_graduationDateError != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              _graduationDateError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _hasChanges() {
    final schoolNameChanged =
        _schoolNameController.text.trim() != (_originalSchoolName ?? '');
    final schoolMajorChanged =
        _schoolMajorController.text.trim() != (_originalSchoolMajor ?? '');
    final graduationDateChanged = _graduationDate != _originalGraduationDate;

    return schoolNameChanged || schoolMajorChanged || graduationDateChanged;
  }

  void _handleSave() async {
    if (_autovalidateMode != AutovalidateMode.onUserInteraction) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
    }

    if (_formKey.currentState!.validate()) {
      // Check if there are any changes
      if (!_hasChanges()) {
        showErrorSnackBar(context: context, message: 'No changes to save');
        return;
      }

      // Prepare the update data
      final updateData = <String, dynamic>{};

      // Only add fields that have changed
      if (_schoolNameController.text.trim() != (_originalSchoolName ?? '')) {
        updateData['school_name'] = _schoolNameController.text.trim();
      }

      if (_schoolMajorController.text.trim() != (_originalSchoolMajor ?? '')) {
        updateData['school_major'] = _schoolMajorController.text.trim();
      }

      if (_graduationDate != _originalGraduationDate) {
        updateData['school_graduation_date'] = DateHelpers.formatToApiDate(
          _graduationDate,
        );
      }

      // Use profile provider to update
      final profileNotifier = ref.read(profileProvider.notifier);
      final success = await profileNotifier.updateProfileFields(updateData);

      if (success && mounted) {
        showSuccessSnackBar(
          context: context,
          message: 'Education updated successfully!',
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(profileProvider).error;
        showErrorSnackBar(
          context: context,
          message: error ?? 'Failed to update education. Please try again.',
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
              'Education',
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
                                controller: _schoolMajorController,
                                labelText: 'School Major',
                                hintText: 'Computer Science',
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                maxLength: 100,
                                onChanged: (value) {
                                  ref
                                      .read(profileProvider.notifier)
                                      .updateField('school_major', value);
                                },
                              ),
                              const SizedBox(height: 20),

                              CustomTextField(
                                controller: _schoolNameController,
                                labelText: 'School Name',
                                hintText:
                                    'University of California, Los Angeles',
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                maxLength: 200,
                                onChanged: (value) {
                                  ref
                                      .read(profileProvider.notifier)
                                      .updateField('school_name', value);
                                },
                              ),
                              const SizedBox(height: 20),

                              _buildDatePicker(),

                              const SizedBox(height: 32),

                              // Update button
                              CustomButton(
                                text: 'Update',
                                onPressed: ref.watch(profileProvider).isLoading
                                    ? null
                                    : _handleSave,
                                isLoading: ref.watch(profileProvider).isLoading,
                                height: 56,
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
