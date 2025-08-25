import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/generate_resume_response.dart';

class ResumeEditModal extends ConsumerStatefulWidget {
  final GenerateResumeResponse resumeData;
  final Function(GenerateResumeResponse) onResumeUpdated;

  const ResumeEditModal({
    super.key,
    required this.resumeData,
    required this.onResumeUpdated,
  });

  @override
  ConsumerState<ResumeEditModal> createState() => _ResumeEditModalState();
}

class _ResumeEditModalState extends ConsumerState<ResumeEditModal> {
  late GenerateResumeResponse _editableResumeData;
  final ScrollController _scrollController = ScrollController();
  bool _showSkillsBottomSheet = false;

  @override
  void initState() {
    super.initState();
    _editableResumeData = GenerateResumeResponse(
      resumeData: widget.resumeData.resumeData,
      pdfe64: widget.resumeData.pdfBase64,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
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
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      // Refresh button
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {},
                      ),
                      const Spacer(),
                      // Scout AI-Powered chip
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.check, color: Colors.white),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // AI Suggestions bottom panel
            _buildAISuggestionsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final personal = _editableResumeData.resumeData?.personal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture with upload option
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF6B35),
                      width: 3,
                    ),
                    image: const DecorationImage(
                      image: AssetImage('assets/icons/default_avatar.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.add, size: 20, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Upload photo button
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Handle photo upload
                  },
                  icon: const Icon(
                    Icons.upload,
                    color: Color(0xFF4285F4),
                    size: 18,
                  ),
                  label: const Text(
                    'Upload photo',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3F2FD),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
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
        const Text(
          'Professional Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _editProfessionalSummary,
          child: Container(
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

    if (allSkills.isEmpty) {
      allSkills.addAll([
        'UX Design',
        'UI Design',
        'Website Design',
        'Product Design',
        'Interaction Design',
      ]);
    }

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
              onTap: () => _showSkillsBottomSheet,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 16),
        const Text(
          'UX/UI Designer',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 100), // Space for more content
      ],
    );
  }

  Widget _buildAISuggestionsPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ai Suggestions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildSuggestionCard(
                'Lorem Ipsum is simply dummy text of the printing and typesetting industry.Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
              ),
              const SizedBox(height: 12),
              _buildSuggestionCard(
                'Lorem Ipsum is simply dummy text of the printing and typesetting industry.Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFF6B35)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFFF6B35),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Ai Suggestion',
                              style: TextStyle(
                                color: Color(0xFFFF6B35),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Professional Summary'),
        content: TextField(
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter your professional summary...',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(
            text: _editableResumeData.resumeData?.summary ?? '',
          ),
          onChanged: (value) {
            if (_editableResumeData.resumeData != null) {
              _editableResumeData.resumeData!.summary = value;
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeSkill(String skill) {
    setState(() {
      final skills = _editableResumeData.resumeData?.skills;
      skills?.hardSkills?.remove(skill);
      skills?.softSkills?.remove(skill);
      skills?.toolsAndTechnologies?.remove(skill);
    });
  }

  void _saveChanges() {
    widget.onResumeUpdated(_editableResumeData);
    Navigator.of(context).pop();
  }
}
