import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skillresy/utils/snackbar_utils.dart';

import '../constants/app_colors.dart';
import '../models/generate_resume_response.dart';
import '../providers/resume_provider.dart';
import '../providers/resume_edit_provider.dart';
import '../widgets/dialogs/confirmation_dialog.dart';

class ResumeEditModal extends ConsumerStatefulWidget {
  final GenerateResumeResponse resumeData;
  final Function(GenerateResumeResponse) onResumeUpdated;
  final String? jobUrl;
  final String? jobDescription;
  final String template;

  const ResumeEditModal({
    super.key,
    required this.resumeData,
    required this.onResumeUpdated,
    this.jobUrl,
    this.jobDescription,
    required this.template,
  });

  @override
  ConsumerState<ResumeEditModal> createState() => _ResumeEditModalState();
}

class _ResumeEditModalState extends ConsumerState<ResumeEditModal> {
  final ScrollController _scrollController = ScrollController();
  late final StateNotifierProvider<ResumeEditNotifier, ResumeEditState>
  _editProvider;

  @override
  void initState() {
    super.initState();
    // Create a provider instance for this modal
    _editProvider = createResumeEditProvider(widget.resumeData);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper getters to access state easily
  ResumeEditState get _state => ref.read(_editProvider);

  ResumeEditNotifier get _notifier => ref.read(_editProvider.notifier);

  GenerateResumeResponse get _editableResumeData => _state.editableResumeData;

  String? get _suggestedContent => _state.suggestedContent;

  String? get _suggestedSection => _state.suggestedSection;

  bool get _isLoadingAISuggestion => _state.isLoadingAISuggestion;

  bool get _isSavingChanges => _state.isSavingChanges;

  bool get _hasChanges => _state.hasChanges;

  /// Shows a month/year picker using CupertinoDatePicker
  Future<DateTime?> _showMonthYearPicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    DateTime selectedDate = initialDate;

    return await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(sheetContext).pop(selectedDate),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.monthYear,
                  initialDateTime: initialDate,
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  onDateTimeChanged: (date) {
                    selectedDate = date;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Parses date strings in multiple formats commonly used in resumes
  /// Supports: MM/yyyy, MMM yyyy, MMMM yyyy, yyyy-MM-dd, yyyy-MM, etc.
  DateTime? _parseFlexibleDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    final formats = [
      'MM/yyyy',
      'M/yyyy',
      'MMM yyyy',
      'MMMM yyyy',
      'yyyy-MM-dd',
      'yyyy-MM',
      'dd/MM/yyyy',
      'MM-yyyy',
      'yyyy',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (_) {
        // Try next format
      }
    }

    debugPrint('⚠️ Could not parse date: $dateStr');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_editProvider);

    return PopScope(
      canPop: false, // Disable back button
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: AbsorbPointer(
            absorbing: state.isSavingChanges,
            child: Stack(
              children: [
                // Main content
                Column(
                  children: [
                    // Header with X close and Save button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Close button
                          GestureDetector(
                            onTap: state.isSavingChanges
                                ? null
                                : _handleCloseButton,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          // Save button
                          GestureDetector(
                            onTap: state.isSavingChanges ? null : _saveChanges,
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: state.isSavingChanges
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Resume content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProfileSection(),
                                const SizedBox(height: 20),
                                _buildProfessionalSummarySection(),
                                const SizedBox(height: 20),
                                _buildCoreSkillsSection(),
                                const SizedBox(height: 20),
                                _buildWorkExperienceSection(),
                                const SizedBox(height: 20),
                                _buildProjectsSection(),
                                const SizedBox(height: 20),
                                _buildEducationSection(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // AI Suggestions bottom panel - only show when there are suggestions
                if (state.showAISuggestions) _buildAISuggestionsPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final personal = _editableResumeData.resumeData?.personal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Details heading with edit button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Personal Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            GestureDetector(
              onTap: _editPersonalDetails,
              child: const Icon(Icons.edit, color: AppColors.primary, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Name and details
        Text(
          personal?.name ?? 'Your Name',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        if (personal?.email != null && personal!.email!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.email, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                personal.email!,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
        if (personal?.phone != null && personal!.phone!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.phone, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                personal.phone!,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
        if (personal?.linkedin != null && personal!.linkedin!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.link, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  personal.linkedin!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (personal?.personalWebsite != null &&
            personal!.personalWebsite!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.language, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  personal.personalWebsite!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProfessionalSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Professional Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            GestureDetector(
              onTap: _editProfessionalSummary,
              child: const Icon(Icons.edit, color: AppColors.primary, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _editableResumeData.resumeData?.summary ??
                'Experienced ux/ui designer with 3 years of industry experience. Proven track record of delivering high-quality solutions and collaborating effectively with cross-functional teams. Strong expertise in modern technologies and methodologies.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoreSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSkillCategorySection(
          title: 'Hard Skills',
          category: 'hard',
          description: 'Technical skills and job-specific competencies',
        ),
        const SizedBox(height: 16),
        _buildSkillCategorySection(
          title: 'Soft Skills',
          category: 'soft',
          description: 'Interpersonal and communication abilities',
        ),
        const SizedBox(height: 16),
        _buildSkillCategorySection(
          title: 'Tools & Technologies',
          category: 'tools',
          description: 'Software, frameworks, and technical tools',
        ),
      ],
    );
  }

  Widget _buildSkillCategorySection({
    required String title,
    required String category,
    required String description,
  }) {
    final skills = _editableResumeData.resumeData?.skills;
    List<String> categorySkills = [];

    switch (category) {
      case 'hard':
        categorySkills = skills?.hardSkills ?? [];
        break;
      case 'soft':
        categorySkills = skills?.softSkills ?? [];
        break;
      case 'tools':
        categorySkills = skills?.toolsAndTechnologies ?? [];
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...categorySkills.map((skill) => _buildSkillChip(skill)),
            GestureDetector(
              onTap: () => _showAddSkillDialog(category: category),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF4285F4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              skill,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeSkill(skill),
            child: const Icon(Icons.close, size: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkExperienceSection() {
    final workExperiences =
        _editableResumeData.resumeData?.workExperience ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.work, color: Colors.white, size: 11),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Work Experience',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _addWorkExperience(),
              child: const Icon(
                Icons.add_circle,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (workExperiences.isNotEmpty)
          ...workExperiences.asMap().entries.map(
            (entry) => _buildWorkExperienceItem(entry.value, entry.key),
          )
        else
          GestureDetector(
            onTap: _addWorkExperience,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.shade50,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add Your First Work Experience',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to add your work history',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWorkExperienceItem(WorkExperience experience, int index) {
    final workExperiences =
        _editableResumeData.resumeData?.workExperience ?? [];
    final isFirst = index == 0;
    final isLast = index == workExperiences.length - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isFirst)
                GestureDetector(
                  onTap: () => _notifier.moveWorkExperienceUp(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_upward,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              if (!isLast)
                GestureDetector(
                  onTap: () => _notifier.moveWorkExperienceDown(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_downward,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () => _editWorkExperience(experience, index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit, size: 18, color: AppColors.primary),
                ),
              ),
              GestureDetector(
                onTap: () => _deleteWorkExperience(index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete, size: 18, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            experience.role ?? 'Role',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            experience.company ?? 'Company',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          if (experience.location != null) ...[
            const SizedBox(height: 2),
            Text(
              experience.location!,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            '${experience.fromDate ?? 'Start Date'} - ${experience.toDate ?? 'End Date'}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (experience.description != null &&
              experience.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...experience.description!.map(
              (desc) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Text(
                        desc,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addWorkExperience() {
    _showWorkExperienceDialog(null, null);
  }

  void _editWorkExperience(WorkExperience experience, int index) {
    _showWorkExperienceDialog(experience, index);
  }

  void _showWorkExperienceDialog(WorkExperience? experience, int? index) {
    final isEditing = experience != null && index != null;

    final companyController = TextEditingController(
      text: experience?.company ?? '',
    );
    final roleController = TextEditingController(text: experience?.role ?? '');
    final locationController = TextEditingController(
      text: experience?.location ?? '',
    );

    // Parse dates from string format (supports multiple formats)
    DateTime? selectedFromDate;
    DateTime? selectedToDate;

    if (experience?.fromDate != null && experience!.fromDate!.isNotEmpty) {
      selectedFromDate = _parseFlexibleDate(experience.fromDate!);
    }

    if (experience?.toDate != null &&
        experience!.toDate!.isNotEmpty &&
        experience.toDate!.toLowerCase() != 'present') {
      selectedToDate = _parseFlexibleDate(experience.toDate!);
    }

    // Create controllers list for responsibilities (auto-add pattern)
    // Always include one empty field at the end for easy adding
    final descriptionList = List<String>.from(experience?.description ?? []);
    final responsibilitiesControllers = [
      ...descriptionList.map((d) => TextEditingController(text: d)),
      TextEditingController(), // Always show one empty field for adding
    ];

    final toDateLower = experience?.toDate?.toLowerCase().trim() ?? '';
    bool isCurrentlyWorking =
        toDateLower == 'present' ||
        toDateLower == 'current' ||
        toDateLower == 'currently' ||
        (isEditing && toDateLower.isEmpty);

    // Error state for inline validation
    String? roleError;
    String? companyError;
    String? startDateError;
    String? endDateError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.only(
            left: 10,
            right: 10,
            top: 0,
            bottom: 20,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Experience' : 'Add Experience',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF6B7280),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role & Company Row
                        _buildCompactTextField(
                          controller: roleController,
                          label: 'Role *',
                          hint: 'e.g Software Engineer',
                          errorText: roleError,
                          onChanged: () {
                            if (roleError != null) {
                              setDialogState(() => roleError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildCompactTextField(
                          controller: companyController,
                          label: 'Company *',
                          hint: 'e.g Google',
                          errorText: companyError,
                          onChanged: () {
                            if (companyError != null) {
                              setDialogState(() => companyError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Location
                        _buildCompactTextField(
                          controller: locationController,
                          label: 'Location',
                          hint: 'San Francisco, CA (Optional)',
                          maxLength: 100,
                        ),
                        const SizedBox(height: 12),

                        // Date Fields Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDateField(
                                    label: 'Start Date *',
                                    value: selectedFromDate,
                                    placeholder: 'MM/YYYY',
                                    onTap: () async {
                                      final picked = await _showMonthYearPicker(
                                        context: context,
                                        initialDate:
                                            selectedFromDate ?? DateTime.now(),
                                        firstDate: DateTime(1950),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        setDialogState(() {
                                          selectedFromDate = picked;
                                          startDateError = null;
                                        });
                                      }
                                    },
                                  ),
                                  if (startDateError != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      startDateError!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                label: 'End Date',
                                value: selectedToDate,
                                placeholder: isCurrentlyWorking
                                    ? 'Present'
                                    : 'MM/YYYY',
                                enabled: !isCurrentlyWorking,
                                onTap: isCurrentlyWorking
                                    ? null
                                    : () async {
                                        final picked =
                                            await _showMonthYearPicker(
                                              context: context,
                                              initialDate:
                                                  selectedToDate ??
                                                  DateTime.now(),
                                              firstDate: DateTime(1950),
                                              lastDate: DateTime.now(),
                                            );
                                        if (picked != null) {
                                          setDialogState(() {
                                            selectedToDate = picked;
                                            endDateError = null;
                                          });
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),

                        // Currently Working Checkbox - more compact
                        Transform.translate(
                          offset: const Offset(-8, 0),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 36,
                                width: 36,
                                child: Checkbox(
                                  value: isCurrentlyWorking,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      isCurrentlyWorking = value ?? false;
                                      if (isCurrentlyWorking) {
                                        selectedToDate = null;
                                      }
                                      endDateError = null;
                                    });
                                  },
                                  activeColor: AppColors.primary,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const Text(
                                'I currently work here',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (endDateError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            endDateError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Responsibilities - Auto-add fields
                        _buildResponsibilitiesSection(
                          controllers: responsibilitiesControllers,
                          setDialogState: setDialogState,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          // Validation with inline errors
                          bool hasError = false;

                          if (roleController.text.trim().isEmpty) {
                            setDialogState(
                              () => roleError = 'Role is required',
                            );
                            hasError = true;
                          }
                          if (companyController.text.trim().isEmpty) {
                            setDialogState(
                              () => companyError = 'Company name is required',
                            );
                            hasError = true;
                          }
                          if (selectedFromDate == null) {
                            setDialogState(
                              () => startDateError = 'Start date is required',
                            );
                            hasError = true;
                          }
                          if (selectedToDate == null && !isCurrentlyWorking) {
                            setDialogState(
                              () => endDateError =
                                  'Please select an end date or check "I currently work here"',
                            );
                            hasError = true;
                          }

                          if (hasError) return;

                          // Collect responsibilities from controllers
                          final descriptions = responsibilitiesControllers
                              .map((c) => c.text.trim())
                              .where((text) => text.isNotEmpty)
                              .toList();

                          // Create work experience object
                          final workExp = WorkExperience(
                            company: companyController.text.trim(),
                            role: roleController.text.trim(),
                            location: locationController.text.trim().isEmpty
                                ? null
                                : locationController.text.trim(),
                            fromDate: DateFormat(
                              'MMM yyyy',
                            ).format(selectedFromDate!),
                            toDate: isCurrentlyWorking
                                ? 'Present'
                                : (selectedToDate != null
                                      ? DateFormat(
                                          'MMM yyyy',
                                        ).format(selectedToDate!)
                                      : null),
                            description: descriptions.isEmpty
                                ? null
                                : descriptions,
                          );

                          // Add or update
                          if (isEditing) {
                            _notifier.updateWorkExperience(index, workExp);
                            showSuccessSnackBar(
                              context: context,
                              message: 'Experience updated',
                            );
                          } else {
                            _notifier.addWorkExperience(workExp);
                            showSuccessSnackBar(
                              context: context,
                              message: 'Experience added',
                            );
                          }

                          Navigator.of(context).pop();
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              isEditing ? 'Save Changes' : 'Add Experience',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
    );
  }

  // Helper widget for compact text fields
  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? errorText,
    VoidCallback? onChanged,
    TextInputType? keyboardType,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          keyboardType: keyboardType,
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            counterText: '',
            // Hide the character counter
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : const Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : const Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
          textCapitalization: TextCapitalization.words,
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
      ],
    );
  }

  // Helper widget for date fields
  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required String placeholder,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
              color: enabled
                  ? const Color(0xFFF9FAFB)
                  : const Color(0xFFE5E7EB),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? DateFormat('MMM yyyy').format(value)
                        : placeholder,
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null || !enabled
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey[400],
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: enabled ? AppColors.primary : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for responsibilities section with auto-add pattern
  Widget _buildResponsibilitiesSection({
    required List<TextEditingController> controllers,
    required void Function(void Function()) setDialogState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Responsibilities',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        ...List.generate(controllers.length, (i) {
          // Check if this is the last field and it's empty (the "add more" field)
          final isAddMoreField =
              i == controllers.length - 1 && controllers[i].text.trim().isEmpty;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bullet or + indicator
                Container(
                  margin: const EdgeInsets.only(top: 10, right: 8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isAddMoreField
                        ? Colors.grey[200]
                        : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isAddMoreField
                        ? Icon(Icons.add, size: 14, color: Colors.grey[400])
                        : Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
                // Text field
                Expanded(
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        // Remove empty fields on blur (keep at least one)
                        if (controllers[i].text.trim().isEmpty &&
                            controllers.length > 1) {
                          setDialogState(() {
                            controllers.removeAt(i);
                          });
                        }
                      }
                    },
                    child: TextField(
                      controller: controllers[i],
                      // maxLength: 500,
                      decoration: InputDecoration(
                        hintText: isAddMoreField
                            ? '+ Add responsibility'
                            : 'e.g., Led team of 5 engineers...',
                        hintStyle: TextStyle(
                          color: isAddMoreField
                              ? Colors.grey[400]
                              : Colors.grey[400],
                          fontSize: 13,
                          fontStyle: isAddMoreField
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                        counterText: '',
                        // Hide the character counter
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isAddMoreField
                                ? Colors.grey[300]!
                                : const Color(0xFFE5E7EB),
                            style: isAddMoreField
                                ? BorderStyle.solid
                                : BorderStyle.solid,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isAddMoreField
                                ? Colors.grey[300]!
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        filled: true,
                        fillColor: isAddMoreField
                            ? Colors.grey[50]
                            : const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      minLines: 1,
                      onChanged: (value) {
                        // Auto-add new field when typing in last field
                        if (i == controllers.length - 1 &&
                            value.isNotEmpty &&
                            controllers.length < 10) {
                          setDialogState(() {
                            controllers.add(TextEditingController());
                          });
                        }
                      },
                    ),
                  ),
                ),
                // Delete button (only show for filled fields, not the add-more field)
                if (controllers.length > 1 && !isAddMoreField)
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        controllers.removeAt(i);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 4, top: 6),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Helper widget for courses section with auto-add pattern
  Widget _buildCoursesSection({
    required List<TextEditingController> controllers,
    required void Function(void Function()) setDialogState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Relevant Courses',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        ...List.generate(controllers.length, (i) {
          final isAddMoreField =
              i == controllers.length - 1 && controllers[i].text.trim().isEmpty;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bullet or + indicator
                Container(
                  margin: const EdgeInsets.only(top: 10, right: 8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isAddMoreField
                        ? Colors.grey[200]
                        : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isAddMoreField
                        ? Icon(Icons.add, size: 14, color: Colors.grey[400])
                        : Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
                // Text field
                Expanded(
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        if (controllers[i].text.trim().isEmpty &&
                            controllers.length > 1) {
                          setDialogState(() {
                            controllers.removeAt(i);
                          });
                        }
                      }
                    },
                    child: TextField(
                      controller: controllers[i],
                      decoration: InputDecoration(
                        hintText: isAddMoreField
                            ? '+ Add course'
                            : 'e.g., Data Structures, Algorithms',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontStyle: isAddMoreField
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isAddMoreField
                                ? Colors.grey[300]!
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isAddMoreField
                                ? Colors.grey[300]!
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        filled: true,
                        fillColor: isAddMoreField
                            ? Colors.grey[50]
                            : const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (value) {
                        // Auto-add new field when typing in last field
                        if (i == controllers.length - 1 &&
                            value.isNotEmpty &&
                            controllers.length < 10) {
                          setDialogState(() {
                            controllers.add(TextEditingController());
                          });
                        }
                      },
                    ),
                  ),
                ),
                // Delete button (only show for filled fields, not the add-more field)
                if (controllers.length > 1 && !isAddMoreField)
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        controllers.removeAt(i);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 4, top: 6),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Helper widget for project description section with auto-add pattern
  Widget _buildProjectDescriptionSection({
    required List<TextEditingController> controllers,
    required void Function(void Function()) setDialogState,
  }) {
    // Ensure there's always one empty field at the end for adding
    if (controllers.isEmpty || controllers.last.text.trim().isNotEmpty) {
      controllers.add(TextEditingController());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        ...List.generate(controllers.length, (i) {
          final isAddMoreField =
              i == controllers.length - 1 && controllers[i].text.trim().isEmpty;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bullet or + indicator
                Container(
                  margin: const EdgeInsets.only(top: 10, right: 8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isAddMoreField
                        ? Colors.grey[200]
                        : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isAddMoreField
                        ? Icon(Icons.add, size: 14, color: Colors.grey[400])
                        : Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
                // Text field
                Expanded(
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        if (controllers[i].text.trim().isEmpty &&
                            controllers.length > 1) {
                          setDialogState(() {
                            controllers.removeAt(i);
                          });
                        }
                      }
                    },
                    child: TextField(
                      controller: controllers[i],
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: isAddMoreField
                            ? '+ Add description'
                            : 'e.g., Built REST API with Node.js...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontStyle: isAddMoreField
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isAddMoreField
                                ? Colors.grey[300]!
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isAddMoreField
                                ? Colors.grey[300]!
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        filled: true,
                        fillColor: isAddMoreField
                            ? Colors.grey[50]
                            : const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      minLines: 1,
                      onChanged: (value) {
                        if (i == controllers.length - 1 &&
                            value.isNotEmpty &&
                            controllers.length < 10) {
                          setDialogState(() {
                            controllers.add(TextEditingController());
                          });
                        }
                      },
                    ),
                  ),
                ),
                // Delete button
                if (controllers.length > 1 && !isAddMoreField)
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        controllers.removeAt(i);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 4, top: 6),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _deleteWorkExperience(int index) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Work Experience?',
      subtitle: 'This action cannot be undone.',
      icon: Icons.delete_outline,
      iconBackgroundColor: Colors.red,
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmButtonColor: Colors.red,
    );

    if (confirmed == true) {
      _notifier.deleteWorkExperience(index);
      showSuccessSnackBar(context: context, message: 'Work experience deleted');
    }
  }

  void _addProject() {
    _showProjectDialog(null, null);
  }

  void _editProject(Projects project, int index) {
    _showProjectDialog(project, index);
  }

  void _showProjectDialog(Projects? project, int? index) {
    final isEditing = project != null && index != null;

    final nameController = TextEditingController(text: project?.name ?? '');
    final linkController = TextEditingController(text: project?.link ?? '');

    // Error state for inline validation
    String? nameError;

    // Parse existing dates for editing (supports multiple formats)
    DateTime? selectedFromDate;
    DateTime? selectedToDate;

    if (project?.fromDate != null && project!.fromDate!.isNotEmpty) {
      selectedFromDate = _parseFlexibleDate(project.fromDate!);
      debugPrint(
        '📅 Project parsed fromDate: ${project.fromDate} -> $selectedFromDate',
      );
    }

    if (project?.toDate != null && project!.toDate!.isNotEmpty) {
      selectedToDate = _parseFlexibleDate(project.toDate!);
      debugPrint(
        '📅 Project parsed toDate: ${project.toDate} -> $selectedToDate',
      );
    }

    final descriptionList = List<String>.from(project?.description ?? []);
    final descriptionControllers = descriptionList
        .map((desc) => TextEditingController(text: desc))
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.only(
            left: 10,
            right: 10,
            top: 0,
            bottom: 20,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  isEditing ? 'Edit Project' : 'Add Project',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 16),

                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Field
                        _buildCompactTextField(
                          controller: nameController,
                          label: 'Project Name *',
                          hint: 'E-commerce Platform',
                          maxLength: 50,
                          errorText: nameError,
                          onChanged: () {
                            if (nameError != null) {
                              setDialogState(() => nameError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Link Field
                        _buildCompactTextField(
                          controller: linkController,
                          label: 'Project Link',
                          hint: 'e.g https://skillresy.com/',
                          maxLength: 150,
                        ),
                        const SizedBox(height: 12),

                        // Date Fields Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                label: 'Start',
                                value: selectedFromDate,
                                placeholder: 'MM/YYYY',
                                onTap: () async {
                                  final picked = await _showMonthYearPicker(
                                    context: context,
                                    initialDate:
                                        selectedFromDate ?? DateTime.now(),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setDialogState(
                                      () => selectedFromDate = picked,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                label: 'End',
                                value: selectedToDate,
                                placeholder: 'MM/YYYY',
                                onTap: () async {
                                  final picked = await _showMonthYearPicker(
                                    context: context,
                                    initialDate:
                                        selectedToDate ?? DateTime.now(),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setDialogState(
                                      () => selectedToDate = picked,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Description Section - Auto-add pattern
                        _buildProjectDescriptionSection(
                          controllers: descriptionControllers,
                          setDialogState: setDialogState,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          // Validation with inline error
                          if (nameController.text.trim().isEmpty) {
                            setDialogState(() {
                              nameError = 'Project name is required';
                            });
                            return;
                          }

                          // Collect descriptions
                          final descriptions = descriptionControllers
                              .map((c) => c.text.trim())
                              .where((text) => text.isNotEmpty)
                              .toList();

                          // Create project object
                          final projectObj = Projects(
                            name: nameController.text.trim(),
                            type: project?.type,
                            fromDate: selectedFromDate != null
                                ? DateFormat(
                                    'MMM yyyy',
                                  ).format(selectedFromDate!)
                                : null,
                            toDate: selectedToDate != null
                                ? DateFormat('MMM yyyy').format(selectedToDate!)
                                : null,
                            link: linkController.text.trim().isEmpty
                                ? null
                                : linkController.text.trim(),
                            description: descriptions.isEmpty
                                ? null
                                : descriptions,
                          );

                          // Add or update
                          if (isEditing) {
                            _notifier.updateProject(index, projectObj);
                            showSuccessSnackBar(
                              context: context,
                              message: 'Project updated',
                            );
                          } else {
                            _notifier.addProject(projectObj);
                            showSuccessSnackBar(
                              context: context,
                              message: 'Project added',
                            );
                          }

                          Navigator.of(context).pop();
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              isEditing ? 'Save Changes' : 'Add Project',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
    );
  }

  Future<void> _deleteProject(int index) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Project?',
      subtitle: 'This action cannot be undone.',
      icon: Icons.delete_outline,
      iconBackgroundColor: Colors.red,
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmButtonColor: Colors.red,
    );

    if (confirmed == true) {
      _notifier.deleteProject(index);
      showSuccessSnackBar(context: context, message: 'Project deleted');
    }
  }

  Widget _buildProjectsSection() {
    final projects = _editableResumeData.resumeData?.projects ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.code, color: Colors.white, size: 11),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Projects',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _addProject(),
              child: const Icon(
                Icons.add_circle,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (projects.isNotEmpty)
          ...projects.asMap().entries.map(
            (entry) => _buildProjectItem(entry.value, entry.key),
          )
        else
          GestureDetector(
            onTap: _addProject,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF4CAF50),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.green.shade50,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add Your First Project',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to add your projects',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProjectItem(Projects project, int index) {
    final projects = _editableResumeData.resumeData?.projects ?? [];
    final isFirst = index == 0;
    final isLast = index == projects.length - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isFirst)
                GestureDetector(
                  onTap: () => _notifier.moveProjectUp(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_upward,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              if (!isLast)
                GestureDetector(
                  onTap: () => _notifier.moveProjectDown(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_downward,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () => _editProject(project, index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit, size: 18, color: AppColors.primary),
                ),
              ),
              GestureDetector(
                onTap: () => _deleteProject(index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete, size: 18, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            project.name ?? 'Project Name',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (project.type != null && project.type!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              project.type!,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
          if (project.fromDate != null || project.toDate != null) ...[
            const SizedBox(height: 2),
            Text(
              '${project.fromDate ?? ''} - ${project.toDate ?? ''}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (project.link != null && project.link!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              project.link!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
          if (project.description != null &&
              project.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...project.description!.map(
              (desc) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Text(
                        desc,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAISuggestionsPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              0.6, // Limit to 60% of screen
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar for visual indication
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _isLoadingAISuggestion
                    ? _buildLoadingContent()
                    : _buildSuggestionContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        // Animated AI icon
        Image.asset('assets/icons/fox.png', height: 80, width: 80),
        const SizedBox(height: 24),
        const Text(
          'Scout is crafting your content',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Analyzing job requirements and optimizing for ${_suggestedSection?.replaceAll('_', ' ') ?? 'your'} section...',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          backgroundColor: Color(0xFFE5E7EB),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSuggestionContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'AI Suggestion for ${_suggestedSection?.replaceAll('_', ' ').toUpperCase() ?? 'Section'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            GestureDetector(
              onTap: _dismissSuggestion,
              child: const Icon(Icons.close, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Show the suggested content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.blue.shade50,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SCOUT AI RECOMMENDATION:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _suggestedContent ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _dismissSuggestion,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Keep Original',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _acceptSuggestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Use This',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _editProfessionalSummary() {
    final controller = TextEditingController(
      text: _editableResumeData.resumeData?.summary ?? '',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.only(
          left: 10,
          right: 10,
          top: 0,
          bottom: 20,
        ),
        child: Container(
          width: MediaQuery.of(context).size.width,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title - centered
              const Text(
                'Edit Professional Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Label
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),

              // Text Field
              TextField(
                controller: controller,
                maxLines: 8,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'Enter your professional summary...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              ),

              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Save button
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        _notifier.updateSummary(controller.text);
                        Navigator.of(context).pop();
                        showSuccessSnackBar(
                          context: context,
                          message: 'Professional summary updated',
                        );
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSkillDialog({String category = 'hard'}) {
    final controller = TextEditingController();

    // Get category display name
    String getCategoryDisplayName(String cat) {
      switch (cat) {
        case 'soft':
          return 'Soft Skills';
        case 'tools':
          return 'Tools & Technologies';
        case 'hard':
        default:
          return 'Hard Skills';
      }
    }

    // Get category-specific hint
    String getHintForCategory(String cat) {
      switch (cat) {
        case 'soft':
          return 'e.g., Leadership, Communication';
        case 'tools':
          return 'e.g., Flutter, JavaScript, Figma';
        case 'hard':
        default:
          return 'e.g., Data Analysis, Project Management';
      }
    }

    // Error state for inline validation
    String? skillError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.only(
            left: 10,
            right: 10,
            top: 0,
            bottom: 20,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title - centered
                const Text(
                  'Add New Skill',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Category label - centered
                Text(
                  'Adding to ${getCategoryDisplayName(category)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Skill Name Field
                _buildCompactTextField(
                  controller: controller,
                  label: 'Skill Name *',
                  maxLength: 50,
                  hint: getHintForCategory(category),
                  errorText: skillError,
                  onChanged: () {
                    if (skillError != null) {
                      setDialogState(() => skillError = null);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Add button
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          final skillName = controller.text.trim();
                          if (skillName.isEmpty) {
                            setDialogState(() {
                              skillError = 'Skill name is required';
                            });
                            return;
                          }

                          _notifier.addSkill(skillName, category: category);
                          Navigator.of(context).pop();

                          showSuccessSnackBar(
                            context: context,
                            message:
                                'Added "$skillName" to ${getCategoryDisplayName(category)}',
                          );
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Add Skill',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
    );
  }

  void _removeSkill(String skill) {
    _notifier.removeSkill(skill);
  }

  void _editPersonalDetails() {
    final personal = _editableResumeData.resumeData?.personal;

    final nameController = TextEditingController(text: personal?.name ?? '');
    final emailController = TextEditingController(text: personal?.email ?? '');
    final phoneController = TextEditingController(text: personal?.phone ?? '');
    final linkedinController = TextEditingController(
      text: personal?.linkedin ?? '',
    );
    final websiteController = TextEditingController(
      text: personal?.personalWebsite ?? '',
    );

    // Error state for inline validation
    String? nameError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.only(
            left: 10,
            right: 10,
            top: 0,
            bottom: 20,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title - centered
                const Text(
                  'Edit Personal Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 16),

                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Field
                        _buildCompactTextField(
                          controller: nameController,
                          label: 'Full Name *',
                          hint: 'John Doe',
                          errorText: nameError,
                          onChanged: () {
                            if (nameError != null) {
                              setDialogState(() => nameError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Email Field
                        _buildCompactTextField(
                          controller: emailController,
                          label: 'Email',
                          hint: 'your.email@example.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),

                        // Phone Field
                        _buildCompactTextField(
                          controller: phoneController,
                          label: 'Phone',
                          hint: '+1 (123) 456-7890',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),

                        // LinkedIn Field
                        _buildCompactTextField(
                          controller: linkedinController,
                          label: 'LinkedIn',
                          hint: 'linkedin.com/in/yourprofile',
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 12),

                        // Website Field
                        _buildCompactTextField(
                          controller: websiteController,
                          label: 'Website / Portfolio',
                          hint: 'www.yourwebsite.com',
                          keyboardType: TextInputType.url,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          // Validation with inline error
                          if (nameController.text.trim().isEmpty) {
                            setDialogState(() {
                              nameError = 'Name is required';
                            });
                            return;
                          }

                          final updatedPersonal = Personal(
                            name: nameController.text.trim(),
                            email: emailController.text.trim().isEmpty
                                ? null
                                : emailController.text.trim(),
                            phone: phoneController.text.trim().isEmpty
                                ? null
                                : phoneController.text.trim(),
                            linkedin: linkedinController.text.trim().isEmpty
                                ? null
                                : linkedinController.text.trim(),
                            personalWebsite:
                                websiteController.text.trim().isEmpty
                                ? null
                                : websiteController.text.trim(),
                          );

                          _notifier.updatePersonalDetails(updatedPersonal);
                          Navigator.of(context).pop();

                          showSuccessSnackBar(
                            context: context,
                            message: 'Personal details updated',
                          );
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
    );
  }

  /// Accept the AI suggestion and update the resume
  void _acceptSuggestion() {
    _notifier.acceptSuggestion();
    showSuccessSnackBar(context: context, message: 'AI suggestion applied');
  }

  /// Dismiss the AI suggestion and keep the original content
  void _dismissSuggestion() {
    _notifier.hideAISuggestions();
  }

  /// Handle close button tap - show confirmation if there are unsaved changes
  Future<void> _handleCloseButton() async {
    if (!_hasChanges) {
      // No changes, just close
      Navigator.of(context).pop();
      return;
    }

    // Show confirmation dialog for unsaved changes
    final result = await showConfirmationDialog(
      context: context,
      title: 'Discard Changes?',
      subtitle:
          'You have unsaved changes. Are you sure you want to discard them?',
      icon: Icons.warning_amber_rounded,
      iconBackgroundColor: Colors.orange,
      confirmText: 'Discard',
      cancelText: 'Keep Editing',
      confirmButtonColor: AppColors.error,
      confirmTextColor: Colors.white,
    );

    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveChanges() async {
    // Prevent multiple simultaneous saves
    if (_isSavingChanges) return;

    _notifier.setSavingChanges(true);

    try {
      // If no changes, just close the modal silently
      if (!_hasChanges) {
        debugPrint('📄 No changes detected, closing modal');
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      debugPrint('📄 Changes detected, regenerating PDF...');
      debugPrint(
        '📋 Current editable data PDF length: ${_editableResumeData.pdfBase64?.length ?? 0}',
      );

      // Regenerate PDF with current complete resume data
      final pdfBase64 = await ref
          .read(resumeProvider.notifier)
          .convertResumeToPdf(
            currentResumeData: _editableResumeData,
            template: widget.template,
          );

      if (pdfBase64 != null && pdfBase64.isNotEmpty) {
        debugPrint('📑 Setting new PDF Base64 length: ${pdfBase64.length}');
        // Update only the PDF base64, keep all current resume data intact
        _notifier.updatePdfBase64(pdfBase64);
        debugPrint(
          '📋 Updated editable data PDF length: ${_editableResumeData.pdfBase64?.length ?? 0}',
        );

        // Pass the updated data back to parent
        debugPrint('🔄 Calling onResumeUpdated with updated data');
        widget.onResumeUpdated(_editableResumeData);

        // Close the modal
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // PDF generation failed - close modal silently
        // Don't update parent - keep existing PDF intact
        debugPrint('❌ PDF generation returned null/empty');
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('❌ Error during save: $e');
      // PDF generation failed - close modal silently
      // Don't update parent - keep existing PDF intact
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        _notifier.setSavingChanges(false);
      }
    }
  }

  Widget _buildEducationSection() {
    final education = _editableResumeData.resumeData?.education ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9C27B0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Education',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _addEducation(),
              child: const Icon(
                Icons.add_circle,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (education.isNotEmpty)
          ...education.asMap().entries.map(
            (entry) => _buildEducationItem(entry.value, entry.key),
          )
        else
          GestureDetector(
            onTap: _addEducation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF9C27B0),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.purple.shade50,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: const Color(0xFF9C27B0),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add Your Education',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9C27B0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to add your educational background',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEducationItem(Education education, int index) {
    final educationList = _editableResumeData.resumeData?.education ?? [];
    final isFirst = index == 0;
    final isLast = index == educationList.length - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isFirst)
                GestureDetector(
                  onTap: () => _notifier.moveEducationUp(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_upward,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              if (!isLast)
                GestureDetector(
                  onTap: () => _notifier.moveEducationDown(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_downward,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () => _editEducation(education, index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit, size: 18, color: AppColors.primary),
                ),
              ),
              GestureDetector(
                onTap: () => _deleteEducation(index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete, size: 18, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            education.degree ?? 'Degree',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            education.university ?? 'University',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          if (education.fromDate != null || education.toDate != null) ...[
            const SizedBox(height: 2),
            Text(
              '${education.fromDate ?? ''} - ${education.toDate ?? ''}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (education.courses != null && education.courses!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Relevant Courses:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 3),
            ...education.courses!.map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Text(
                        course,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addEducation() {
    _showEducationDialog(null, null);
  }

  void _editEducation(Education education, int index) {
    _showEducationDialog(education, index);
  }

  void _showEducationDialog(Education? education, int? index) {
    final isEditing = education != null && index != null;

    final degreeController = TextEditingController(
      text: education?.degree ?? '',
    );
    final universityController = TextEditingController(
      text: education?.university ?? '',
    );

    // Parse dates from string format
    DateTime? selectedFromDate;
    DateTime? selectedToDate;

    if (education?.fromDate != null && education!.fromDate!.isNotEmpty) {
      selectedFromDate = _parseFlexibleDate(education.fromDate!);
    }

    if (education?.toDate != null && education!.toDate!.isNotEmpty) {
      selectedToDate = _parseFlexibleDate(education.toDate!);
    }

    // Create controllers list for courses (auto-add pattern)
    // Always include one empty field at the end for easy adding
    final coursesList = List<String>.from(education?.courses ?? []);
    final coursesControllers = [
      ...coursesList.map((course) => TextEditingController(text: course)),
      TextEditingController(), // Always show one empty field for adding
    ];

    // Validation error states
    String? degreeError;
    String? universityError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.only(
            left: 10,
            right: 10,
            top: 0,
            bottom: 20,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title - centered
                  Text(
                    isEditing ? 'Edit Education' : 'Add Education',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Degree Field
                  _buildCompactTextField(
                    controller: degreeController,
                    label: 'Degree *',
                    hint: 'e.g., Bachelor of Science',
                    errorText: degreeError,
                    onChanged: () {
                      if (degreeError != null) {
                        setDialogState(() => degreeError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // University Field
                  _buildCompactTextField(
                    controller: universityController,
                    label: 'University / Institution *',
                    hint: 'e.g., Stanford University',
                    errorText: universityError,
                    onChanged: () {
                      if (universityError != null) {
                        setDialogState(() => universityError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Date Fields Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Start Date',
                          value: selectedFromDate,
                          placeholder: 'MM/YYYY',
                          onTap: () async {
                            final picked = await _showMonthYearPicker(
                              context: context,
                              initialDate: selectedFromDate ?? DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedFromDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          label: 'End Date',
                          value: selectedToDate,
                          placeholder: 'MM/YYYY',
                          onTap: () async {
                            final picked = await _showMonthYearPicker(
                              context: context,
                              initialDate: selectedToDate ?? DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedToDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Courses Section - Auto-add pattern
                  _buildCoursesSection(
                    controllers: coursesControllers,
                    setDialogState: setDialogState,
                  ),

                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            // Validation with inline errors
                            bool hasError = false;

                            if (degreeController.text.trim().isEmpty) {
                              setDialogState(() {
                                degreeError = 'Degree is required';
                              });
                              hasError = true;
                            }
                            if (universityController.text.trim().isEmpty) {
                              setDialogState(() {
                                universityError = 'University is required';
                              });
                              hasError = true;
                            }

                            if (hasError) return;

                            // Collect courses
                            final courses = coursesControllers
                                .map((c) => c.text.trim())
                                .where((text) => text.isNotEmpty)
                                .toList();

                            // Create education object
                            final educationObj = Education(
                              degree: degreeController.text.trim(),
                              university: universityController.text.trim(),
                              fromDate: selectedFromDate != null
                                  ? DateFormat(
                                      'MMM yyyy',
                                    ).format(selectedFromDate!)
                                  : null,
                              toDate: selectedToDate != null
                                  ? DateFormat(
                                      'MMM yyyy',
                                    ).format(selectedToDate!)
                                  : null,
                              courses: courses.isEmpty ? null : courses,
                            );

                            // Add or update
                            if (isEditing) {
                              _notifier.updateEducation(index, educationObj);
                              showSuccessSnackBar(
                                context: context,
                                message: 'Education updated',
                              );
                            } else {
                              _notifier.addEducation(educationObj);
                              showSuccessSnackBar(
                                context: context,
                                message: 'Education added',
                              );
                            }

                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                isEditing ? 'Save Changes' : 'Add Education',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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
    );
  }

  Future<void> _deleteEducation(int index) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Education?',
      subtitle: 'This action cannot be undone.',
      icon: Icons.delete_outline,
      iconBackgroundColor: Colors.red,
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmButtonColor: Colors.red,
    );

    if (confirmed == true) {
      _notifier.deleteEducation(index);
      showSuccessSnackBar(context: context, message: 'Education deleted');
    }
  }
}
