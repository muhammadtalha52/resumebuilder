import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../constants/app_colors.dart';
import '../../models/resume_parse_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/resume_service_provider.dart';
import '../../providers/user_provider.dart';
import '../../screens/common/main_screen.dart';
import '../../services/resume_service.dart';
import '../../utils/date_helpers.dart';
import '../../utils/snackbar_utils.dart';

/// Provider to track resume upload state in banner
final resumeUploadStateProvider =
    StateNotifierProvider<ResumeUploadNotifier, ResumeUploadState>((ref) {
      return ResumeUploadNotifier();
    });

class ResumeUploadState {
  final bool isLoading;
  final String loadingMessage;
  final String? errorMessage;

  const ResumeUploadState({
    this.isLoading = false,
    this.loadingMessage = 'Processing resume...',
    this.errorMessage,
  });

  ResumeUploadState copyWith({
    bool? isLoading,
    String? loadingMessage,
    String? errorMessage,
  }) {
    return ResumeUploadState(
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      errorMessage: errorMessage,
    );
  }
}

class ResumeUploadNotifier extends StateNotifier<ResumeUploadState> {
  ResumeUploadNotifier() : super(const ResumeUploadState());

  void setLoading(bool loading, {String message = 'Processing resume...'}) {
    state = state.copyWith(isLoading: loading, loadingMessage: message);
  }

  void setLoadingMessage(String message) {
    state = state.copyWith(loadingMessage: message);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }

  void reset() {
    state = const ResumeUploadState();
  }
}

class ProfileCompletionBanner extends ConsumerWidget {
  final bool isProfileScreen;

  const ProfileCompletionBanner({super.key, this.isProfileScreen = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isStudent = ref.watch(isStudentProvider);
    final uploadState = ref.watch(resumeUploadStateProvider);

    final completionPercentage = user?.profileCompletionPercentage ?? 0;

    // Hide banner for students (only show for candidates)
    if (isStudent) {
      return const SizedBox.shrink();
    }

    // Hide banner if profile is 100% complete
    if (completionPercentage >= 100) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: isProfileScreen ? null : () => _navigateToProfile(ref, isStudent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.gradientPurple1, AppColors.gradientPurple2],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Progress indicator
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: completionPercentage / 100,
                        strokeWidth: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                      Text(
                        '$completionPercentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isProfileScreen
                            ? 'Profile $completionPercentage% Complete'
                            : 'Complete Your Profile',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isProfileScreen
                            ? _getProfileScreenMessage(completionPercentage)
                            : _getEncouragingMessage(completionPercentage),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon (only show when not on profile screen)
                if (!isProfileScreen)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
            // Upload resume button (only on profile screen)
            if (isProfileScreen) ...[
              const SizedBox(height: 10),
              _buildUploadButton(context, ref, uploadState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(
    BuildContext context,
    WidgetRef ref,
    ResumeUploadState uploadState,
  ) {
    if (uploadState.isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              uploadState.loadingMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _handleResumeUpload(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Upload Resume to Quick Fill',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleResumeUpload(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(resumeUploadStateProvider.notifier);

    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Validate file first
        try {
          await ResumeService.validateFile(file);
        } on ResumeServiceException catch (e) {
          if (context.mounted) {
            showErrorSnackBar(context: context, message: e.message);
          }
          return;
        }

        notifier.setLoading(true);

        try {
          final resumeService = ref.read(resumeServiceProvider);

          // Run S3 upload and resume extraction in parallel
          // Use separate try-catch for S3 to allow profile update even if S3 fails
          String? s3FileName;
          ResumeParse? parsedData;

          final futures = await Future.wait([
            // Upload to S3 - catch errors separately
            resumeService
                .uploadDocsToS3(file)
                .then((response) => response.s3FileName)
                .catchError((e) => null),
            // Extract resume data
            resumeService.extractResumeData(file),
          ]);

          s3FileName = futures[0] as String?;
          parsedData = futures[1] as ResumeParse;

          // Change loading message for profile update phase
          notifier.setLoadingMessage('Updating profile...');

          // Convert parsed data to profile update format and save
          await _updateProfileFromResume(ref, parsedData, s3FileName);

          notifier.reset();

          if (context.mounted) {
            _showResumeUpdateSuccessDialog(context);
          }
        } on ResumeServiceException catch (e) {
          notifier.setError(e.message);

          if (context.mounted) {
            showErrorSnackBar(context: context, message: e.message);
          }
        }
      }
    } catch (e) {
      notifier.setError('An unexpected error occurred');

      if (context.mounted) {
        showErrorSnackBar(
          context: context,
          message: 'An unexpected error occurred. Please try again.',
        );
      }
    }
  }

  Future<void> _updateProfileFromResume(
    WidgetRef ref,
    ResumeParse parsedData,
    String? s3FileName,
  ) async {
    final updateData = _buildProfileUpdateData(parsedData);

    // Add resume file name if S3 upload was successful
    if (s3FileName != null && s3FileName.isNotEmpty) {
      updateData['resume_file_name'] = s3FileName;
    }

    if (updateData.isEmpty) {
      throw ResumeParsingException(
        'No data could be extracted from the resume',
      );
    }

    // Update profile using profile provider
    await ref.read(profileProvider.notifier).updateProfileFields(updateData);
  }

  Map<String, dynamic> _buildProfileUpdateData(ResumeParse parsedData) {
    final Map<String, dynamic> updateData = {};

    // Each field is wrapped in try-catch so one failure doesn't affect others

    // Full name
    try {
      if (parsedData.name != null && parsedData.name!.trim().isNotEmpty) {
        final name = parsedData.name!.trim();
        // Basic validation: not too long, no weird characters
        if (name.length <= 100) {
          updateData['full_name'] = name;
        }
      }
    } catch (_) {}

    // Phone number
    try {
      if (parsedData.phone != null && parsedData.phone!.isNotEmpty) {
        final sanitizedPhone = _sanitizePhoneNumber(parsedData.phone!);
        if (sanitizedPhone != null) {
          updateData['phone_number'] = sanitizedPhone;
        }
      }
    } catch (_) {}

    // LinkedIn URL
    try {
      if (parsedData.personal?.linkedin != null &&
          parsedData.personal!.linkedin!.isNotEmpty) {
        final linkedinUrl = _sanitizeUrl(parsedData.personal!.linkedin!);
        if (linkedinUrl != null && linkedinUrl.contains('linkedin.com')) {
          updateData['linkedin_url'] = linkedinUrl;
        }
      }
    } catch (_) {}

    // Portfolio URL
    try {
      if (parsedData.personal?.personalWebsite != null &&
          parsedData.personal!.personalWebsite!.isNotEmpty) {
        final portfolioUrl = _sanitizeUrl(
          parsedData.personal!.personalWebsite!,
        );
        if (portfolioUrl != null) {
          updateData['portfolio_url'] = portfolioUrl;
        }
      }
    } catch (_) {}

    // Work Experience
    try {
      if (parsedData.workExperience.isNotEmpty) {
        final validExperiences = parsedData.workExperience
            .where(
              (exp) =>
                  (exp.role != null && exp.role!.trim().isNotEmpty) ||
                  (exp.company != null && exp.company!.trim().isNotEmpty),
            )
            .map((exp) {
              return {
                'job_title': exp.role?.trim() ?? '',
                'company_name': exp.company?.trim() ?? '',
                'work_start_date': exp.parsedFromDate != null
                    ? DateHelpers.formatToApiDate(exp.parsedFromDate!)
                    : null,
                'work_end_date': exp.parsedToDate != null
                    ? DateHelpers.formatToApiDate(exp.parsedToDate!)
                    : null,
                'is_current_job': exp.isCurrent,
                'key_responsibilities': exp.description
                    .where((r) => r.trim().isNotEmpty)
                    .toList(),
              };
            })
            .toList();

        if (validExperiences.isNotEmpty) {
          updateData['work_experience'] = validExperiences;
        }
      }
    } catch (_) {}

    // NOTE: Education data is skipped because education fields use dropdown IDs
    // (degree type, major, institution) and resume parsing returns text strings,
    // not the IDs that the backend expects.

    // Desired Job Titles - extracted from work experience with smart year calculation
    try {
      if (parsedData.workExperience.isNotEmpty) {
        // Group work experiences by job title (case-insensitive matching)
        final Map<String, List<_DateRange>> titleDateRanges = {};

        for (final exp in parsedData.workExperience) {
          if (exp.role == null || exp.role!.trim().isEmpty) continue;

          final title = exp.role!.trim();
          final normalizedTitle = title.toLowerCase();

          // Get date range (use today for current jobs)
          final startDate = exp.parsedFromDate;
          final endDate = exp.parsedToDate ?? DateTime.now();

          if (startDate == null) continue; // Skip if no start date

          // Find existing title (case-insensitive) or use original
          String matchedTitle = title;
          for (final existingTitle in titleDateRanges.keys) {
            if (existingTitle.toLowerCase() == normalizedTitle) {
              matchedTitle = existingTitle;
              break;
            }
          }

          titleDateRanges.putIfAbsent(matchedTitle, () => []);
          titleDateRanges[matchedTitle]!.add(_DateRange(startDate, endDate));
        }

        if (titleDateRanges.isNotEmpty) {
          // Calculate years for each title (merging overlapping ranges)
          final List<Map<String, dynamic>> desiredJobTitles = [];

          for (final entry in titleDateRanges.entries) {
            final mergedRanges = _mergeOverlappingRanges(entry.value);
            final totalYears = _calculateTotalYears(mergedRanges);

            if (totalYears > 0) {
              desiredJobTitles.add({
                'title': entry.key,
                'years_of_experience': totalYears,
              });
            }
          }

          // Sort by years of experience (descending) and limit to top 5
          desiredJobTitles.sort(
            (a, b) => (b['years_of_experience'] as double).compareTo(
              a['years_of_experience'] as double,
            ),
          );

          final limitedTitles = desiredJobTitles.take(5).toList();

          if (limitedTitles.isNotEmpty) {
            updateData['desired_job_titles'] = limitedTitles;
          }
        }
      }
    } catch (_) {}

    // Hard skills
    try {
      if (parsedData.skills != null) {
        final hardSkills = _cleanStringList(parsedData.skills!.hardSkills);
        if (hardSkills.isNotEmpty) {
          updateData['hard_skills'] = hardSkills;
        }
      }
    } catch (_) {}

    // Soft skills
    try {
      if (parsedData.skills != null) {
        final softSkills = _cleanStringList(parsedData.skills!.softSkills);
        if (softSkills.isNotEmpty) {
          updateData['soft_skills'] = softSkills;
        }
      }
    } catch (_) {}

    // Tools & technologies
    try {
      if (parsedData.skills != null) {
        final tools = _cleanStringList(parsedData.skills!.toolsAndTechnologies);
        if (tools.isNotEmpty) {
          updateData['tools_technologies'] = tools;
        }
      }
    } catch (_) {}

    // Languages
    try {
      if (parsedData.optionalInfo != null) {
        final languages = _cleanStringList(parsedData.optionalInfo!.languages);
        if (languages.isNotEmpty) {
          updateData['languages'] = languages;
        }
      }
    } catch (_) {}

    // Volunteer work
    try {
      if (parsedData.optionalInfo?.volunteerWork != null &&
          parsedData.optionalInfo!.volunteerWork!.trim().isNotEmpty) {
        updateData['volunteer_work'] = [
          parsedData.optionalInfo!.volunteerWork!.trim(),
        ];
      }
    } catch (_) {}

    // Hobbies & interests
    try {
      if (parsedData.optionalInfo?.hobbiesAndInterests != null &&
          parsedData.optionalInfo!.hobbiesAndInterests!.isNotEmpty) {
        final hobbies = parsedData.optionalInfo!.hobbiesAndInterests!
            .split(RegExp(r'[,;]'))
            .map((h) => h.trim())
            .where((h) => h.isNotEmpty)
            .toList();
        if (hobbies.isNotEmpty) {
          updateData['hobbies_interests'] = hobbies;
        }
      }
    } catch (_) {}

    // References
    try {
      if (parsedData.optionalInfo?.references != null &&
          parsedData.optionalInfo!.references!.trim().isNotEmpty) {
        updateData['references'] = parsedData.optionalInfo!.references!.trim();
      }
    } catch (_) {}

    return updateData;
  }

  DateTime? _parseDateString(String dateStr) {
    final trimmed = dateStr.trim();

    try {
      // Try just year format (e.g., "2020")
      final yearOnly = int.tryParse(trimmed);
      if (yearOnly != null && yearOnly > 1900 && yearOnly < 2100) {
        return DateTime(yearOnly, 1, 1);
      }

      // Try "Month Year" format (e.g., "May 2020")
      final parts = trimmed.split(' ');
      if (parts.length == 2) {
        final month = _parseMonth(parts[0]);
        final year = int.tryParse(parts[1]);
        if (month != null && year != null) {
          return DateTime(year, month, 1);
        }
      }

      // Try "MM/YYYY" format (e.g., "05/2020")
      if (trimmed.contains('/')) {
        final slashParts = trimmed.split('/');
        if (slashParts.length == 2) {
          final month = int.tryParse(slashParts[0]);
          final year = int.tryParse(slashParts[1]);
          if (month != null && year != null && month >= 1 && month <= 12) {
            return DateTime(year, month, 1);
          }
        }
      }

      // Try "YYYY-MM" format (e.g., "2020-05")
      if (trimmed.contains('-')) {
        final dashParts = trimmed.split('-');
        if (dashParts.length >= 2) {
          final year = int.tryParse(dashParts[0]);
          final month = int.tryParse(dashParts[1]);
          if (year != null && month != null && month >= 1 && month <= 12) {
            return DateTime(year, month, 1);
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  int? _parseMonth(String monthStr) {
    const months = {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };
    return months[monthStr.toLowerCase()];
  }

  /// Sanitize and validate phone number from resume
  /// Returns null if phone number is invalid or can't be sanitized
  String? _sanitizePhoneNumber(String phone) {
    // Remove all spaces, dashes, parentheses, and dots
    String sanitized = phone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

    // Check if it starts with + (international format)
    if (!sanitized.startsWith('+')) {
      // If it's a 10-digit number, assume it might need country code
      // For now, skip phone numbers without country code to avoid errors
      if (sanitized.length == 10 && RegExp(r'^\d+$').hasMatch(sanitized)) {
        // Could be a local number, skip it
        return null;
      }
    }

    // Validate: should be + followed by digits only, min 10 chars, max 15 chars
    if (sanitized.startsWith('+')) {
      final digits = sanitized.substring(1);
      if (RegExp(r'^\d{9,14}$').hasMatch(digits)) {
        return sanitized;
      }
    }

    // If validation fails, skip the phone number
    return null;
  }

  /// Sanitize and validate URL
  /// Returns null if URL is invalid
  String? _sanitizeUrl(String url) {
    String sanitized = url.trim();

    // Add https:// if no protocol
    if (!sanitized.startsWith('http://') && !sanitized.startsWith('https://')) {
      sanitized = 'https://$sanitized';
    }

    // Basic URL validation
    try {
      final uri = Uri.parse(sanitized);
      if (uri.hasScheme && uri.host.isNotEmpty && uri.host.contains('.')) {
        return sanitized;
      }
    } catch (e) {
      // Invalid URL
    }
    return null;
  }

  /// Clean string list - trim, remove empty strings, and remove duplicates
  List<String> _cleanStringList(List<String> items) {
    final seen = <String>{};
    return items
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && seen.add(s.toLowerCase()))
        .toList();
  }

  String _getEncouragingMessage(int percentage) {
    return 'Complete your profile to stand out to recruiters!';
  }

  String _getProfileScreenMessage(int percentage) {
    return 'Fill in the sections below to get noticed!';
  }

  void _navigateToProfile(WidgetRef ref, bool isStudent) {
    // Profile tab index: 3 for candidates, 2 for students
    final profileIndex = isStudent ? 2 : 3;
    ref.read(navigationIndexProvider.notifier).state = profileIndex;
  }

  void _showResumeUpdateSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Profile Updated!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'We\'ve filled your profile with information from your resume. '
                'Please review the sections below and complete any missing details.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Merge overlapping date ranges to avoid double-counting experience
  /// Example: [(2020-2022), (2021-2023)] -> [(2020-2023)]
  List<_DateRange> _mergeOverlappingRanges(List<_DateRange> ranges) {
    if (ranges.isEmpty) return [];
    if (ranges.length == 1) return ranges;

    // Sort by start date
    final sorted = List<_DateRange>.from(ranges)
      ..sort((a, b) => a.start.compareTo(b.start));

    final merged = <_DateRange>[];
    var current = sorted.first;

    for (int i = 1; i < sorted.length; i++) {
      final next = sorted[i];

      // Check if ranges overlap or are adjacent (within 1 day)
      if (next.start.isBefore(current.end) ||
          next.start.difference(current.end).inDays <= 1) {
        // Merge: extend current range if next ends later
        if (next.end.isAfter(current.end)) {
          current = _DateRange(current.start, next.end);
        }
      } else {
        // No overlap: add current to result and move to next
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);

    return merged;
  }

  /// Calculate total years from a list of date ranges
  /// Rounds to nearest whole number
  double _calculateTotalYears(List<_DateRange> ranges) {
    if (ranges.isEmpty) return 0;

    double totalDays = 0;
    for (final range in ranges) {
      totalDays += range.end.difference(range.start).inDays;
    }

    // Convert days to years and round to nearest whole number
    final years = totalDays / 365;
    return years.round().toDouble();
  }
}

/// Helper class to represent a date range for experience calculation
class _DateRange {
  final DateTime start;
  final DateTime end;

  _DateRange(this.start, this.end);
}
