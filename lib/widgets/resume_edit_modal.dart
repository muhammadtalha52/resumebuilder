import 'package:flutter/material.dart';
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
                    // Header with Scout AI chip
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(
                        children: [
                          const Spacer(),
                          // Scout AI chip - centered
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Scout AI-Powered',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Check button
                          GestureDetector(
                            onTap: state.isSavingChanges ? null : _saveChanges,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: state.isSavingChanges
                                  ? Container(
                                      padding: EdgeInsets.all(5),
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
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
                        padding: const EdgeInsets.all(10),
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
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProfileSection(),
                                const SizedBox(height: 32),
                                _buildProfessionalSummarySection(),
                                const SizedBox(height: 32),
                                _buildCoreSkillsSection(),
                                const SizedBox(height: 32),
                                _buildWorkExperienceSection(),
                                const SizedBox(height: 32),
                                _buildProjectsSection(),
                                const SizedBox(height: 32),
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: _editPersonalDetails,
              tooltip: 'Edit Personal Details',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Name and details
        Text(
          personal?.name ?? 'Your Name',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        if (personal?.email != null && personal!.email!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.email, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                personal.email!,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
            ],
          ),
        ],
        if (personal?.phone != null && personal!.phone!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                personal.phone!,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
            ],
          ),
        ],
        if (personal?.linkedin != null && personal!.linkedin!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.link, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  personal.linkedin!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (personal?.personalWebsite != null &&
            personal!.personalWebsite!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.language, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  personal.personalWebsite!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: _editProfessionalSummary,
                  tooltip: 'Edit Summary',
                ),
                // TODO: Uncomment when regenerate feature is ready
                // IconButton(
                //   icon: const Icon(Icons.refresh, color: AppColors.primary),
                //   onPressed: () => _regenerateSection(['summary']),
                //   tooltip: 'Regenerate Summary with AI',
                // ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _editableResumeData.resumeData?.summary ??
                'Experienced ux/ui designer with 3 years of industry experience. Proven track record of delivering high-quality solutions and collaborating effectively with cross-functional teams. Strong expertise in modern technologies and methodologies.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
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
        const SizedBox(height: 24),
        _buildSkillCategorySection(
          title: 'Soft Skills',
          category: 'soft',
          description: 'Interpersonal and communication abilities',
        ),
        const SizedBox(height: 24),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...categorySkills.map((skill) => _buildSkillChip(skill)),
            GestureDetector(
              onTap: () => _showAddSkillDialog(category: category),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF4285F4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              skill,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeSkill(skill),
            child: const Icon(Icons.close, size: 16, color: Colors.grey),
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
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.work, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Work Experience',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () => _addWorkExperience(),
                  tooltip: 'Add Work Experience',
                ),
                // TODO: Uncomment when regenerate feature is ready
                // IconButton(
                //   icon: const Icon(Icons.refresh, color: AppColors.primary),
                //   onPressed: () => _regenerateSection(['work_experience']),
                //   tooltip: 'Regenerate with AI',
                // ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
                IconButton(
                  icon: const Icon(
                    Icons.arrow_upward,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _notifier.moveWorkExperienceUp(index),
                  tooltip: 'Move Up',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (!isLast)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_downward,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _notifier.moveWorkExperienceDown(index),
                  tooltip: 'Move Down',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 20,
                  color: AppColors.primary,
                ),
                onPressed: () => _editWorkExperience(experience, index),
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _deleteWorkExperience(index),
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            experience.role ?? 'Role',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            experience.company ?? 'Company',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          if (experience.location != null) ...[
            const SizedBox(height: 2),
            Text(
              experience.location!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${experience.fromDate ?? 'Start Date'} - ${experience.toDate ?? 'End Date'}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (experience.description != null &&
              experience.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...experience.description!.map(
              (desc) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        desc,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.4,
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

    // Parse dates from string format (MMM yyyy)
    DateTime? selectedFromDate;
    DateTime? selectedToDate;

    if (experience?.fromDate != null && experience!.fromDate!.isNotEmpty) {
      try {
        selectedFromDate = DateFormat('MM/yyyy').parse(experience.fromDate!);
      } catch (e) {
        // If parsing fails, leave as null
      }
    }

    if (experience?.toDate != null &&
        experience!.toDate!.isNotEmpty &&
        experience!.toDate!.toLowerCase() != 'present') {
      try {
        selectedToDate = DateFormat('MM/yyyy').parse(experience!.toDate!);
      } catch (e) {
        // If parsing fails, leave as null
      }
    }

    final descriptionList = List<String>.from(experience?.description ?? []);
    final descriptionControllers = descriptionList
        .map((desc) => TextEditingController(text: desc))
        .toList();

    bool isCurrentlyWorking = experience?.toDate?.toLowerCase() == 'present';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 24,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    isEditing ? 'Edit Work Experience' : 'Add Work Experience',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Company Field
                  TextField(
                    controller: companyController,
                    decoration: InputDecoration(
                      labelText: 'Company Name *',
                      hintText: 'e.g., Google, Microsoft',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Role Field
                  TextField(
                    controller: roleController,
                    decoration: InputDecoration(
                      labelText: 'Job Title / Role *',
                      hintText: 'e.g., Senior Software Engineer',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Location Field
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g., San Francisco, CA',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Date Fields Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
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
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFF9FAFB),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start Date *',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selectedFromDate != null
                                            ? DateFormat(
                                                'MM/yyyy',
                                              ).format(selectedFromDate!)
                                            : '01/2020',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: selectedFromDate != null
                                              ? const Color(0xFF1A1A1A)
                                              : const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: isCurrentlyWorking
                              ? null
                              : () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        selectedToDate ?? DateTime.now(),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      selectedToDate = picked;
                                    });
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: isCurrentlyWorking
                                  ? const Color(0xFFE5E7EB)
                                  : const Color(0xFFF9FAFB),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'End Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isCurrentlyWorking
                                            ? 'Present'
                                            : (selectedToDate != null
                                                  ? DateFormat(
                                                      'MM/yyyy',
                                                    ).format(selectedToDate!)
                                                  : '12/2023'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              isCurrentlyWorking ||
                                                  selectedToDate != null
                                              ? const Color(0xFF1A1A1A)
                                              : const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: isCurrentlyWorking
                                      ? Colors.grey[400]
                                      : AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Currently Working Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: isCurrentlyWorking,
                        onChanged: (value) {
                          setDialogState(() {
                            isCurrentlyWorking = value ?? false;
                            if (isCurrentlyWorking) {
                              selectedToDate = null;
                            }
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      const Text(
                        'I currently work here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description/Responsibilities Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Key Responsibilities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            descriptionControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description Items
                  ...descriptionControllers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text('• ', style: TextStyle(fontSize: 16)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText:
                                    'Describe your responsibility or achievement',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 13,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                descriptionControllers.removeAt(idx);
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  if (descriptionControllers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: Center(
                        child: Text(
                          'No responsibilities added yet. Click "Add" to add one.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Validation
                            if (companyController.text.trim().isEmpty) {
                              showErrorSnackBar(
                                context: context,
                                message: 'Company name is required',
                              );
                              return;
                            }
                            if (roleController.text.trim().isEmpty) {
                              showErrorSnackBar(
                                context: context,
                                message: 'Job title is required',
                              );
                              return;
                            }
                            if (selectedFromDate == null) {
                              showErrorSnackBar(
                                context: context,
                                message: 'Start date is required',
                              );
                              return;
                            }

                            // Collect descriptions
                            final descriptions = descriptionControllers
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
                                'MM/yyyy',
                              ).format(selectedFromDate!),
                              toDate: isCurrentlyWorking
                                  ? 'Present'
                                  : (selectedToDate != null
                                        ? DateFormat(
                                            'MM/yyyy',
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
                                message: 'Work experience updated',
                              );
                            } else {
                              _notifier.addWorkExperience(workExp);
                              showSuccessSnackBar(
                                context: context,
                                message: 'Work experience added',
                              );
                            }

                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                isEditing ? 'Update' : 'Add',
                                style: const TextStyle(
                                  fontSize: 16,
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
    final typeController = TextEditingController(text: project?.type ?? '');
    final linkController = TextEditingController(text: project?.link ?? '');

    // Parse existing dates for editing
    DateTime? selectedFromDate;
    DateTime? selectedToDate;
    if (project?.fromDate != null && project!.fromDate!.isNotEmpty) {
      try {
        selectedFromDate = DateFormat('MM/yyyy').parse(project.fromDate!);
      } catch (e) {
        selectedFromDate = null;
      }
    }
    if (project?.toDate != null && project!.toDate!.isNotEmpty) {
      try {
        selectedToDate = DateFormat('MM/yyyy').parse(project.toDate!);
      } catch (e) {
        selectedToDate = null;
      }
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
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 24,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 24),

                  // Project Name Field
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Project Name *',
                      hintText: 'e.g., E-commerce Platform',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Project Type Field
                  TextField(
                    controller: typeController,
                    decoration: InputDecoration(
                      labelText: 'Project Type',
                      hintText: 'e.g., Web Application, Mobile App',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Date Fields Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
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
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFF9FAFB),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selectedFromDate != null
                                            ? DateFormat(
                                                'MMM yyyy',
                                              ).format(selectedFromDate!)
                                            : 'Jan 2023',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: selectedFromDate != null
                                              ? const Color(0xFF1A1A1A)
                                              : const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
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
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFF9FAFB),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'End Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selectedToDate != null
                                            ? DateFormat(
                                                'MMM yyyy',
                                              ).format(selectedToDate!)
                                            : 'Mar 2024',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: selectedToDate != null
                                              ? const Color(0xFF1A1A1A)
                                              : const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Link Field
                  TextField(
                    controller: linkController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: 'Project Link',
                      hintText: 'e.g., github.com/username/project',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Project Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            descriptionControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description Items
                  ...descriptionControllers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text('• ', style: TextStyle(fontSize: 16)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText:
                                    'Describe project feature or achievement',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 13,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                descriptionControllers.removeAt(idx);
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  if (descriptionControllers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: Center(
                        child: Text(
                          'No description added yet. Click "Add" to add one.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Validation
                            if (nameController.text.trim().isEmpty) {
                              showErrorSnackBar(
                                context: context,
                                message: 'Project name is required',
                              );
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
                              type: typeController.text.trim().isEmpty
                                  ? null
                                  : typeController.text.trim(),
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
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                isEditing ? 'Update' : 'Add',
                                style: const TextStyle(
                                  fontSize: 16,
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
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.code, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Projects',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () => _addProject(),
                  tooltip: 'Add Project',
                ),
                // TODO: Uncomment when regenerate feature is ready
                // IconButton(
                //   icon: const Icon(Icons.refresh, color: AppColors.primary),
                //   onPressed: () => _regenerateSection(['projects']),
                //   tooltip: 'Regenerate with AI',
                // ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
                IconButton(
                  icon: const Icon(
                    Icons.arrow_upward,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _notifier.moveProjectUp(index),
                  tooltip: 'Move Up',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (!isLast)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_downward,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _notifier.moveProjectDown(index),
                  tooltip: 'Move Down',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 20,
                  color: AppColors.primary,
                ),
                onPressed: () => _editProject(project, index),
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _deleteProject(index),
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project.name ?? 'Project Name',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (project.type != null && project.type!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              project.type!,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
          if (project.fromDate != null || project.toDate != null) ...[
            const SizedBox(height: 4),
            Text(
              '${project.fromDate ?? ''} - ${project.toDate ?? ''}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (project.link != null && project.link!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              project.link!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
          if (project.description != null &&
              project.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...project.description!.map(
              (desc) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        desc,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.4,
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

  Widget _buildSuggestionCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.add, color: Color(0xFF4285F4), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
        child: Container(
          width: MediaQuery.of(context).size.width,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(24),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Edit Professional Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 24),

              // Text Field
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: 'Enter your professional summary...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              ),

              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Save button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _notifier.updateSummary(controller.text);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
        child: Container(
          width: MediaQuery.of(context).size.width,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(24),
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
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_circle,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),

              // Title
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

              // Category label
              Text(
                'Adding to ${getCategoryDisplayName(category)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Text Field
              TextField(
                controller: controller,
                maxLines: 1,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter skill name (e.g., Flutter, JavaScript)',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF4285F4)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Add button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final skillName = controller.text.trim();
                        if (skillName.isNotEmpty) {
                          _notifier.addSkill(skillName, category: category);
                          Navigator.of(context).pop();

                          showSuccessSnackBar(
                            context: context,
                            message:
                                'Added "$skillName" to ${getCategoryDisplayName(category)}',
                          );
                        }
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Add Skill',
                            style: TextStyle(
                              fontSize: 16,
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
        child: Container(
          width: MediaQuery.of(context).size.width,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(24),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Edit Personal Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                const SizedBox(height: 24),

                // Name Field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter your full name',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 16),

                // Email Field
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'your.email@example.com',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                const SizedBox(height: 16),

                // Phone Field
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    hintText: '+1 (123) 456-7890',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                const SizedBox(height: 16),

                // LinkedIn Field
                TextField(
                  controller: linkedinController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'LinkedIn',
                    hintText: 'linkedin.com/in/yourprofile',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(
                      Icons.link,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                const SizedBox(height: 16),

                // Website Field
                TextField(
                  controller: websiteController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Personal Website / Portfolio',
                    hintText: 'www.yourwebsite.com',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(
                      Icons.language,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                const SizedBox(height: 32),

                // Buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Save button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (nameController.text.trim().isEmpty) {
                            showErrorSnackBar(
                              context: context,
                              message: 'Name is required',
                            );
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
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
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

  /// Regenerate specific sections using AI
  Future<void> _regenerateSection(List<String> sections) async {
    // Show confirmation dialog first
    final sectionName = sections.first.replaceAll('_', ' ').toUpperCase();
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Regenerate $sectionName?',
      subtitle:
          'AI will generate new content for this section using your job context. You can review and choose to accept or dismiss the suggestion.',
      icon: Icons.auto_awesome,
      iconBackgroundColor: AppColors.primary,
      confirmText: 'Regenerate',
      cancelText: 'Cancel',
      confirmButtonColor: AppColors.primary,
    );

    // If user cancelled, don't proceed
    if (confirmed != true) return;

    // Show AI suggestions panel immediately with loading state
    _notifier.showAISuggestionsLoading(sections.first);

    try {
      final result = await ref
          .read(resumeProvider.notifier)
          .regenerateSections(
            currentResumeData: _editableResumeData,
            sectionsToRegenerate: sections,
            jobUrl: widget.jobUrl,
            jobDescription: widget.jobDescription,
            template: widget.template,
          );

      if (result != null) {
        // Check if there are regenerated sections in the response
        final regeneratedSections = result.regeneratedSections ?? [];

        if (regeneratedSections.isNotEmpty) {
          // Get the regenerated content based on the section
          String? suggestedContent;
          String? sectionName;

          if (regeneratedSections.contains('summary')) {
            suggestedContent = result.resumeData?.summary;
            sectionName = 'summary';
          } else if (regeneratedSections.contains('work_experience')) {
            // For work experience, convert the list to a formatted string
            if (result.resumeData?.workExperience != null) {
              final workExpList = result.resumeData!.workExperience!;
              suggestedContent = workExpList
                  .map(
                    (exp) =>
                        '${exp.role ?? ''} at ${exp.company ?? ''}\n'
                        '${exp.fromDate ?? ''} - ${exp.toDate ?? 'Present'}\n'
                        '${exp.description?.join('\n• ') ?? ''}',
                  )
                  .join('\n\n');
              sectionName = 'work_experience';
            }
          } else if (regeneratedSections.contains('projects')) {
            // For projects, convert the list to a formatted string
            if (result.resumeData?.projects != null) {
              final projectsList = result.resumeData!.projects!;
              suggestedContent = projectsList
                  .map(
                    (project) =>
                        '${project.name ?? ''} (${project.type ?? ''})\n'
                        '${project.fromDate ?? ''} - ${project.toDate ?? ''}\n'
                        '${project.description?.join('\n• ') ?? ''}',
                  )
                  .join('\n\n');
              sectionName = 'projects';
            }
          } else if (regeneratedSections.contains('education')) {
            // For education, convert the list to a formatted string
            if (result.resumeData?.education != null) {
              final educationList = result.resumeData!.education!;
              suggestedContent = educationList
                  .map(
                    (edu) =>
                        '${edu.degree ?? ''}\n'
                        '${edu.university ?? ''}\n'
                        '${edu.fromDate ?? ''} - ${edu.toDate ?? ''}\n'
                        '${edu.courses != null && edu.courses!.isNotEmpty ? 'Courses: ${edu.courses!.join(', ')}' : ''}',
                  )
                  .join('\n\n');
              sectionName = 'education';
            }
          }

          if (suggestedContent != null && sectionName != null) {
            // Show AI suggestions panel with the new content
            _notifier.setAISuggestions(
              content: suggestedContent,
              section: sectionName,
              resumeData: result,
            );
          } else {
            // CRITICAL: DO NOT overwrite entire data if no specific content found
            // Instead, hide the suggestions panel and show error
            _notifier.hideAISuggestions();
          }
        } else {
          // CRITICAL: DO NOT overwrite entire data if no regenerated sections
          // Instead, hide the suggestions panel and show error
          _notifier.hideAISuggestions();

          showErrorSnackBar(
            context: context,
            message: 'No sections were regenerated. Please try again.',
          );
        }
      }
    } catch (e) {
      _notifier.hideAISuggestions();
      showErrorSnackBar(
        context: context,
        message: 'Failed to regenerate: ${e.toString()}.',
      );
    }
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

  Future<void> _saveChanges() async {
    // Prevent multiple simultaneous saves
    if (_isSavingChanges) return;

    _notifier.setSavingChanges(true);

    try {
      // Only regenerate PDF if there are changes
      if (!_hasChanges) {
        print('📄 No changes detected, skipping PDF regeneration');
        // Still pass the data back to parent and close modal
        widget.onResumeUpdated(_editableResumeData);
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      print('📄 Changes detected, regenerating PDF...');
      print(
        '📋 Current editable data PDF length: ${_editableResumeData.pdfBase64?.length ?? 0}',
      );

      // Regenerate PDF with current complete resume data
      final pdfBase64 = await ref
          .read(resumeProvider.notifier)
          .convertResumeToPdf(
            currentResumeData: _editableResumeData,
            template: widget.template,
          );

      if (pdfBase64 != null) {
        print('📑 Setting new PDF Base64 length: ${pdfBase64.length}');
        // Update only the PDF base64, keep all current resume data intact
        _notifier.updatePdfBase64(pdfBase64);
        print(
          '📋 Updated editable data PDF length: ${_editableResumeData.pdfBase64?.length ?? 0}',
        );

        // Pass the updated data back to parent
        print('🔄 Calling onResumeUpdated with updated data');
        widget.onResumeUpdated(_editableResumeData);

        // Close the modal
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Failed to generate PDF, but still save the data changes
        widget.onResumeUpdated(_editableResumeData);

        if (mounted) {
          // showErrorSnackBar(
          //   context: context,
          //   message: 'Changes saved, but PDF update failed. Please try again.',
          // );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Error occurred, but still save the data changes
      widget.onResumeUpdated(_editableResumeData);

      if (mounted) {
        showErrorSnackBar(
          context: context,
          message: 'Changes saved, but PDF update failed: ${e.toString()}',
        );
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
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9C27B0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Education',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () => _addEducation(),
                  tooltip: 'Add Education',
                ),
                // TODO: Uncomment when regenerate feature is ready
                // IconButton(
                //   icon: const Icon(Icons.refresh, color: AppColors.primary),
                //   onPressed: () => _regenerateSection(['education']),
                //   tooltip: 'Regenerate with AI',
                // ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
                IconButton(
                  icon: const Icon(
                    Icons.arrow_upward,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _notifier.moveEducationUp(index),
                  tooltip: 'Move Up',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (!isLast)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_downward,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _notifier.moveEducationDown(index),
                  tooltip: 'Move Down',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 20,
                  color: AppColors.primary,
                ),
                onPressed: () => _editEducation(education, index),
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _deleteEducation(index),
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            education.degree ?? 'Degree',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            education.university ?? 'University',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          if (education.fromDate != null || education.toDate != null) ...[
            const SizedBox(height: 4),
            Text(
              '${education.fromDate ?? ''} - ${education.toDate ?? ''}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (education.courses != null && education.courses!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Relevant Courses:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            ...education.courses!.map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        course,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.4,
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
      try {
        final year = int.parse(education.fromDate!);
        selectedFromDate = DateTime(year);
      } catch (e) {
        // If parsing fails, leave as null
      }
    }

    if (education?.toDate != null && education!.toDate!.isNotEmpty) {
      try {
        final year = int.parse(education.toDate!);
        selectedToDate = DateTime(year);
      } catch (e) {
        // If parsing fails, leave as null
      }
    }

    final coursesList = List<String>.from(education?.courses ?? []);
    final coursesControllers = coursesList
        .map((course) => TextEditingController(text: course))
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 24,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    isEditing ? 'Edit Education' : 'Add Education',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Degree Field
                  TextField(
                    controller: degreeController,
                    decoration: InputDecoration(
                      labelText: 'Degree *',
                      hintText: 'e.g., Bachelor of Science in Computer Science',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // University Field
                  TextField(
                    controller: universityController,
                    decoration: InputDecoration(
                      labelText: 'University / Institution *',
                      hintText: 'e.g., Stanford University',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Date Fields Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
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
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFF9FAFB),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selectedFromDate != null
                                            ? DateFormat(
                                                'MMM dd, yyyy',
                                              ).format(selectedFromDate!)
                                            : 'Jan 01, 2018',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: selectedFromDate != null
                                              ? const Color(0xFF1A1A1A)
                                              : const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
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
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFF9FAFB),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'End Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selectedToDate != null
                                            ? DateFormat(
                                                'MMM dd, yyyy',
                                              ).format(selectedToDate!)
                                            : 'Jun 01, 2022',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: selectedToDate != null
                                              ? const Color(0xFF1A1A1A)
                                              : const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Courses Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Relevant Courses',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            coursesControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Courses Items
                  ...coursesControllers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text('• ', style: TextStyle(fontSize: 16)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Course name',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 13,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                coursesControllers.removeAt(idx);
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  if (coursesControllers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: Center(
                        child: Text(
                          'No courses added yet. Click "Add" to add one.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Validation
                            if (degreeController.text.trim().isEmpty) {
                              showErrorSnackBar(
                                context: context,
                                message: 'Degree is required',
                              );
                              return;
                            }
                            if (universityController.text.trim().isEmpty) {
                              showErrorSnackBar(
                                context: context,
                                message: 'University is required',
                              );
                              return;
                            }

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
                                  ? '${selectedFromDate!.year}'
                                  : null,
                              toDate: selectedToDate != null
                                  ? '${selectedToDate!.year}'
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
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                isEditing ? 'Update' : 'Add',
                                style: const TextStyle(
                                  fontSize: 16,
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
