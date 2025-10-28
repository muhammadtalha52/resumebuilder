import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../utils/snackbar_utils.dart';
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

  // Store objects to preserve IDs
  List<Language> _languageObjects = [];
  List<VolunteerWork> _volunteerWorkObjects = [];
  List<HobbyInterest> _hobbyObjects = [];
  String _references = '';
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Store original values for comparison
  List<Language> _originalLanguageObjects = [];
  List<VolunteerWork> _originalVolunteerWorkObjects = [];
  List<HobbyInterest> _originalHobbyObjects = [];
  String _originalReferences = '';

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
      // Load objects preserving IDs
      if (user.languages != null && user.languages!.isNotEmpty) {
        _languageObjects = List.from(user.languages!);
        _originalLanguageObjects = List.from(_languageObjects);
      }

      if (user.volunteerWork != null && user.volunteerWork!.isNotEmpty) {
        _volunteerWorkObjects = List.from(user.volunteerWork!);
        _originalVolunteerWorkObjects = List.from(_volunteerWorkObjects);
      }

      if (user.hobbiesInterests != null && user.hobbiesInterests!.isNotEmpty) {
        _hobbyObjects = List.from(user.hobbiesInterests!);
        _originalHobbyObjects = List.from(_hobbyObjects);
      }

      // Set references
      _references = user.references ?? '';
      _originalReferences = _references;
      _referencesController.text = _references;

      setState(() {});
    }
  }

  // Helper methods to convert objects to strings for display
  List<String> _languageStrings() {
    return _languageObjects
        .map((e) => e.language ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> _volunteerWorkStrings() {
    return _volunteerWorkObjects
        .map((e) => e.description ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> _hobbyStrings() {
    return _hobbyObjects
        .map((e) => e.hobbyInterest ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _languagesController.dispose();
    _volunteerWorkController.dispose();
    _hobbiesInterestsController.dispose();
    _referencesController.dispose();
    super.dispose();
  }

  // Add language
  void _addLanguage(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;

    if (_languageObjects.any((obj) => obj.language == trimmed)) return;

    setState(() {
      _languageObjects.add(Language(language: trimmed));
    });
    _languagesController.clear();
  }

  void _removeLanguage(String tag) {
    setState(() {
      _languageObjects.removeWhere((obj) => obj.language == tag);
    });
  }

  // Add volunteer work
  void _addVolunteerWork(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;

    if (_volunteerWorkObjects.any((obj) => obj.description == trimmed)) return;

    setState(() {
      _volunteerWorkObjects.add(VolunteerWork(description: trimmed));
    });
    _volunteerWorkController.clear();
  }

  void _removeVolunteerWork(String tag) {
    setState(() {
      _volunteerWorkObjects.removeWhere((obj) => obj.description == tag);
    });
  }

  // Add hobby/interest
  void _addHobby(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;

    if (_hobbyObjects.any((obj) => obj.hobbyInterest == trimmed)) return;

    setState(() {
      _hobbyObjects.add(HobbyInterest(hobbyInterest: trimmed));
    });
    _hobbiesInterestsController.clear();
  }

  void _removeHobby(String tag) {
    setState(() {
      _hobbyObjects.removeWhere((obj) => obj.hobbyInterest == tag);
    });
  }

  bool _hasChanges() {
    final languagesChanged = !_listEquals(
      _languageStrings(),
      _originalLanguageObjects.map((e) => e.language ?? '').toList(),
    );
    final volunteerWorkChanged = !_listEquals(
      _volunteerWorkStrings(),
      _originalVolunteerWorkObjects.map((e) => e.description ?? '').toList(),
    );
    final hobbiesChanged = !_listEquals(
      _hobbyStrings(),
      _originalHobbyObjects.map((e) => e.hobbyInterest ?? '').toList(),
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

    // Send string arrays for API
    final languagesChanged = !_listEquals(
      _languageStrings(),
      _originalLanguageObjects.map((e) => e.language ?? '').toList(),
    );
    final volunteerWorkChanged = !_listEquals(
      _volunteerWorkStrings(),
      _originalVolunteerWorkObjects.map((e) => e.description ?? '').toList(),
    );
    final hobbiesChanged = !_listEquals(
      _hobbyStrings(),
      _originalHobbyObjects.map((e) => e.hobbyInterest ?? '').toList(),
    );

    if (languagesChanged) {
      updateData['languages'] = _languageStrings();
    }

    if (volunteerWorkChanged) {
      updateData['volunteer_work'] = _volunteerWorkStrings();
    }

    if (hobbiesChanged) {
      updateData['hobbies_interests'] = _hobbyStrings();
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
                                tags: _languageStrings(),
                                controller: _languagesController,
                                onAdd: _addLanguage,
                                onRemove: _removeLanguage,
                                errorText: null,
                                onClearError: () {},
                              ),
                              const SizedBox(height: 24),

                              // Volunteer Work
                              TagField(
                                label: 'Volunteer Work',
                                isRequired: false,
                                tags: _volunteerWorkStrings(),
                                controller: _volunteerWorkController,
                                onAdd: _addVolunteerWork,
                                onRemove: _removeVolunteerWork,
                                errorText: null,
                                onClearError: () {},
                              ),
                              const SizedBox(height: 24),

                              // Hobbies & Interests
                              TagField(
                                label: 'Hobbies & Interests',
                                isRequired: false,
                                tags: _hobbyStrings(),
                                controller: _hobbiesInterestsController,
                                onAdd: _addHobby,
                                onRemove: _removeHobby,
                                errorText: null,
                                onClearError: () {},
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
