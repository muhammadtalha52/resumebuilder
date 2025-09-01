import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillresy/utils/snackbar_utils.dart';

import '../models/generate_resume_response.dart';
import '../providers/resume_provider.dart';
import '../constants/app_colors.dart';
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
  late GenerateResumeResponse _editableResumeData;
  final ScrollController _scrollController = ScrollController();
  bool _showSkillsBottomSheet = false;

  // Loading states for each section
  bool _isSummaryLoading = false;
  bool _isExperienceLoading = false;
  bool _isSkillsLoading = false;
  bool _isProjectsLoading = false;

  // AI Suggestions state
  bool _showAISuggestions = false;
  String? _suggestedContent;
  String? _suggestedSection;
  GenerateResumeResponse? _suggestedResumeData;
  bool _isLoadingAISuggestion = false;

  // PDF generation state
  bool _isSavingChanges = false;

  // Change tracking
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Create a deep copy of the resume data to avoid modifying the original
    try {
      final originalJson = widget.resumeData.toJson();
      print('🔄 Creating deep copy of resume data...');
      print(
        '📋 Original data has ${originalJson['resume_data']?.keys?.length ?? 0} sections',
      );

      _editableResumeData = GenerateResumeResponse.fromJson(originalJson);

      // Verify the copy was successful
      print('✅ Deep copy created successfully');
      print(
        '📋 Name: ${_editableResumeData.resumeData?.personal?.name ?? "No name"}',
      );
      print(
        '📋 Work experience count: ${_editableResumeData.resumeData?.workExperience?.length ?? 0}',
      );
      print(
        '📋 Skills count: ${(_editableResumeData.resumeData?.skills?.hardSkills?.length ?? 0) + (_editableResumeData.resumeData?.skills?.softSkills?.length ?? 0) + (_editableResumeData.resumeData?.skills?.toolsAndTechnologies?.length ?? 0)}',
      );
    } catch (e) {
      print('❌ Error creating deep copy: $e');
      // Fallback: use the original data directly (not ideal but prevents crash)
      _editableResumeData = widget.resumeData;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: AbsorbPointer(
            absorbing: _isSavingChanges,
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
                            onTap: _isSavingChanges ? null : _saveChanges,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _isSavingChanges
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
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // AI Suggestions bottom panel - only show when there are suggestions
                if (_showAISuggestions) _buildAISuggestionsPanel(),
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
        // Personal Details heading
        const Text(
          'Personal Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),

        // Name and details
        Text(
          personal?.name ?? 'Alex John',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Senior Software Engineer',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          personal?.phone ?? '(123) 456-7890',
          style: TextStyle(fontSize: 14, color: const Color(0xFF4285F4)),
        ),
        Text(
          personal?.personalWebsite ?? 'New York, NY',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
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
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: () => _regenerateSection(['summary']),
                  tooltip: 'Regenerate Summary with AI',
                ),
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
    final skills = _editableResumeData.resumeData?.skills;
    final allSkills = <String>[
      ...(skills?.hardSkills ?? []),
      ...(skills?.softSkills ?? []),
      ...(skills?.toolsAndTechnologies ?? []),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Core Skills',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...allSkills.map((skill) => _buildSkillChip(skill)),
            GestureDetector(
              onTap: _showAddSkillDialog,
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
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: () => _regenerateSection(['work_experience']),
              tooltip: 'Regenerate Work Experience with AI',
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (workExperiences.isNotEmpty)
          ...workExperiences.map(
            (experience) => _buildWorkExperienceItem(experience),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: const Center(
              child: Text(
                'No work experience available',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWorkExperienceItem(WorkExperience experience) {
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
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: () => _regenerateSection(['projects']),
              tooltip: 'Regenerate Projects with AI',
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (projects.isNotEmpty)
          ...projects.map((project) => _buildProjectItem(project))
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: const Center(
              child: Text(
                'No projects available',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProjectItem(Projects project) {
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
          Text(
            project.name ?? 'Project Name',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
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
            Text(
              'AI Suggestion for ${_suggestedSection?.replaceAll('_', ' ').toUpperCase() ?? 'Section'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
        child: Container(
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Edit Professional Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Text Field
              TextField(
                controller: controller,
                maxLines: 5,
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
                        if (_editableResumeData.resumeData != null) {
                          _editableResumeData.resumeData!.summary =
                              controller.text;
                          _hasChanges = true; // Mark as changed
                        }
                        Navigator.of(context).pop();
                        setState(() {});
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

  void _showAddSkillDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
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
                          setState(() {
                            // Ensure skills object exists
                            _editableResumeData.resumeData?.skills ??= Skills();

                            // Add to hard skills by default
                            _editableResumeData
                                    .resumeData
                                    ?.skills
                                    ?.hardSkills ??=
                                [];
                            _editableResumeData.resumeData?.skills?.hardSkills!
                                .add(skillName);
                            _hasChanges = true; // Mark as changed
                          });
                          Navigator.of(context).pop();

                          showSuccessSnackBar(
                            context: context,
                            message: 'Added "$skillName" to your skills',
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
    setState(() {
      final skills = _editableResumeData.resumeData?.skills;
      skills?.hardSkills?.remove(skill);
      skills?.softSkills?.remove(skill);
      skills?.toolsAndTechnologies?.remove(skill);
      _hasChanges = true; // Mark as changed
    });
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
    setState(() {
      _suggestedSection = sections.first;
      _showAISuggestions = true;
      _isLoadingAISuggestion = true;
      _suggestedContent = null;
      _suggestedResumeData = null;
    });

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
          }

          if (suggestedContent != null && sectionName != null) {
            // Show AI suggestions panel with the new content
            setState(() {
              _suggestedContent = suggestedContent;
              _suggestedSection = sectionName;
              _suggestedResumeData =
                  result; // Store the complete regenerated data
              _showAISuggestions = true;
              _isLoadingAISuggestion = false; // Turn off loading state
            });
          } else {
            // CRITICAL: DO NOT overwrite entire data if no specific content found
            // Instead, hide the suggestions panel and show error
            setState(() {
              _showAISuggestions = false;
              _isLoadingAISuggestion = false;
            });
          }
        } else {
          // CRITICAL: DO NOT overwrite entire data if no regenerated sections
          // Instead, hide the suggestions panel and show error
          setState(() {
            _showAISuggestions = false;
            _isLoadingAISuggestion = false;
          });

          showErrorSnackBar(
            context: context,
            message: 'No sections were regenerated. Please try again.',
          );
        }
      }
    } catch (e) {
      showErrorSnackBar(
        context: context,
        message: 'Failed to regenerate: ${e.toString()}.',
      );
    } finally {
      setState(() {
        _isSummaryLoading = false;
        _isExperienceLoading = false;
        _isSkillsLoading = false;
        _isProjectsLoading = false;
        _isLoadingAISuggestion = false;
      });
    }
  }

  /// Accept the AI suggestion and update the resume
  void _acceptSuggestion() {
    if (_suggestedContent != null &&
        _suggestedSection != null &&
        _suggestedResumeData != null) {
      setState(() {
        // Update only the specific section with the regenerated content
        // CRITICAL: Only update the regenerated section, preserve all other data
        if (_suggestedSection == 'summary') {
          if (_editableResumeData.resumeData != null &&
              _suggestedResumeData!.resumeData != null) {
            // Only update the summary, keep everything else intact
            _editableResumeData.resumeData!.summary =
                _suggestedResumeData!.resumeData!.summary;
          }
        } else if (_suggestedSection == 'work_experience') {
          if (_editableResumeData.resumeData != null &&
              _suggestedResumeData!.resumeData != null) {
            // Only update work experience, keep everything else intact
            _editableResumeData.resumeData!.workExperience =
                _suggestedResumeData!.resumeData!.workExperience;
          }
        } else if (_suggestedSection == 'projects') {
          if (_editableResumeData.resumeData != null &&
              _suggestedResumeData!.resumeData != null) {
            // Only update projects, keep everything else intact
            _editableResumeData.resumeData!.projects =
                _suggestedResumeData!.resumeData!.projects;
          }
        }

        // Hide the suggestions panel and clear all suggestion data
        _showAISuggestions = false;
        _suggestedContent = null;
        _suggestedSection = null;
        _suggestedResumeData = null;
        _hasChanges = true; // Mark as changed when accepting AI suggestions
      });

      showSuccessSnackBar(
        context: context,
        message: 'AI suggestion for applied',
      );
    }
  }

  /// Dismiss the AI suggestion and keep the original content
  void _dismissSuggestion() {
    setState(() {
      _showAISuggestions = false;
      _suggestedContent = null;
      _suggestedSection = null;
      _suggestedResumeData = null;
    });
  }

  Future<void> _saveChanges() async {
    // Prevent multiple simultaneous saves
    if (_isSavingChanges) return;

    setState(() {
      _isSavingChanges = true;
    });

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
        _editableResumeData.pdfBase64 = pdfBase64;
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
        setState(() {
          _isSavingChanges = false;
        });
      }
    }
  }
}
