import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/custom_picker_field.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/tag_field.dart';

class EditOthersScreen extends ConsumerStatefulWidget {
  const EditOthersScreen({super.key});

  @override
  ConsumerState<EditOthersScreen> createState() => _EditOthersScreenState();
}

class _EditOthersScreenState extends ConsumerState<EditOthersScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _languagesController = TextEditingController();
  final TextEditingController _volunteerWorkController =
      TextEditingController();
  final TextEditingController _hobbiesInterestsController =
      TextEditingController();
  final TextEditingController _referencesController = TextEditingController();

  List<String> _languages = [];
  List<String> _volunteerWork = [];
  List<String> _hobbiesInterests = [];
  String _references = '';
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Store original values for comparison
  List<String> _originalLanguages = [];
  List<String> _originalVolunteerWork = [];
  List<String> _originalHobbiesInterests = [];
  String _originalReferences = '';

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
      // Load languages from list
      if (user.languages != null && user.languages!.isNotEmpty) {
        _languages = List.from(user.languages!);
        _originalLanguages = List.from(_languages);
      }

      // Load volunteer work from list
      if (user.volunteerWork != null && user.volunteerWork!.isNotEmpty) {
        _volunteerWork = List.from(user.volunteerWork!);
        _originalVolunteerWork = List.from(_volunteerWork);
      }

      // Load hobbies & interests from list
      if (user.hobbiesInterests != null && user.hobbiesInterests!.isNotEmpty) {
        _hobbiesInterests = List.from(user.hobbiesInterests!);
        _originalHobbiesInterests = List.from(_hobbiesInterests);
      }

      // Set references
      _references = user.references ?? '';
      _originalReferences = _references;
      _referencesController.text = _references;

      setState(() {});
    }
  }

  @override
  void dispose() {
    _languagesController.dispose();
    _volunteerWorkController.dispose();
    _hobbiesInterestsController.dispose();
    _referencesController.dispose();
    super.dispose();
  }

  void _addTag(
    String tag,
    List<String> list,
    TextEditingController controller,
  ) {
    if (tag.trim().isNotEmpty && !list.contains(tag.trim())) {
      setState(() {
        list.add(tag.trim());
      });
      controller.clear();
    }
  }

  void _removeTag(String tag, List<String> list) {
    setState(() {
      list.remove(tag);
    });
  }

  void _clearTagError(List<String> list) {
    // No specific errors for others fields as they're optional
    setState(() {});
  }

  bool _hasChanges() {
    // Check if any field has changed
    final languagesChanged = !_listEquals(_languages, _originalLanguages);
    final volunteerWorkChanged = !_listEquals(
      _volunteerWork,
      _originalVolunteerWork,
    );
    final hobbiesChanged = !_listEquals(
      _hobbiesInterests,
      _originalHobbiesInterests,
    );
    final referencesChanged = _references != _originalReferences;

    return languagesChanged ||
        volunteerWorkChanged ||
        hobbiesChanged ||
        referencesChanged;
  }

  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void _handleSave() async {
    // Check if there are any changes
    if (!_hasChanges()) {
      showErrorSnackBar(context: context, message: 'No changes to save');
      return;
    }

    // Prepare the update data
    final updateData = <String, dynamic>{};

    // Send lists directly as arrays for API
    // Only add fields that have changed
    if (!_listEquals(_languages, _originalLanguages)) {
      updateData['languages'] = _languages;
    }

    if (!_listEquals(_volunteerWork, _originalVolunteerWork)) {
      updateData['volunteer_work'] = _volunteerWork;
    }

    if (!_listEquals(_hobbiesInterests, _originalHobbiesInterests)) {
      updateData['hobbies_interests'] = _hobbiesInterests;
    }

    if (_references != _originalReferences) {
      updateData['references'] = _references;
    }

    // Use profile provider to update
    final profileNotifier = ref.read(profileProvider.notifier);
    final success = await profileNotifier.updateProfileFields(updateData);

    if (success && mounted) {
      showSuccessSnackBar(
        context: context,
        message: 'Optional info updated successfully!',
      );
      context.pop();
    } else if (mounted) {
      final error = ref.read(profileProvider).error;
      showErrorSnackBar(
        context: context,
        message: error ?? 'Failed to update optional info. Please try again.',
      );
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
              'Optional info',
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

                      // Main container with white background
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
                              // Languages
                              TagField(
                                label: 'Languages',
                                isRequired: false,
                                tags: _languages,
                                controller: _languagesController,
                                onAdd: (tag) => _addTag(
                                  tag,
                                  _languages,
                                  _languagesController,
                                ),
                                onRemove: (tag) => _removeTag(tag, _languages),
                                errorText: null,
                                onClearError: () => _clearTagError(_languages),
                              ),
                              const SizedBox(height: 24),

                              // Volunteer Work
                              TagField(
                                label: 'Volunteer Work',
                                isRequired: false,
                                tags: _volunteerWork,
                                controller: _volunteerWorkController,
                                onAdd: (tag) => _addTag(
                                  tag,
                                  _volunteerWork,
                                  _volunteerWorkController,
                                ),
                                onRemove: (tag) =>
                                    _removeTag(tag, _volunteerWork),
                                errorText: null,
                                onClearError: () =>
                                    _clearTagError(_volunteerWork),
                              ),
                              const SizedBox(height: 24),

                              // Hobbies & Interests
                              TagField(
                                label: 'Hobbies & Interests',
                                isRequired: false,
                                tags: _hobbiesInterests,
                                controller: _hobbiesInterestsController,
                                onAdd: (tag) => _addTag(
                                  tag,
                                  _hobbiesInterests,
                                  _hobbiesInterestsController,
                                ),
                                onRemove: (tag) =>
                                    _removeTag(tag, _hobbiesInterests),
                                errorText: null,
                                onClearError: () =>
                                    _clearTagError(_hobbiesInterests),
                              ),
                              const SizedBox(height: 24),

                              // References
                              CustomTextField(
                                labelText: 'References',
                                controller: _referencesController,
                                hintText: 'Type here',
                                isRequired: false,
                                maxLines: 3,
                                onChanged: (value) {
                                  setState(() {
                                    _references = value;
                                  });
                                },
                              ),

                              const SizedBox(height: 32),

                              // Update button
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
                                          'Update',
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
