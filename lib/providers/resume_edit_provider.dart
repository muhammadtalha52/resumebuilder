import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/generate_resume_response.dart';

/// State class for resume editing
class ResumeEditState {
  final GenerateResumeResponse editableResumeData;
  final bool showAISuggestions;
  final String? suggestedContent;
  final String? suggestedSection;
  final GenerateResumeResponse? suggestedResumeData;
  final bool isLoadingAISuggestion;
  final bool isSavingChanges;
  final bool hasChanges;

  ResumeEditState({
    required this.editableResumeData,
    this.showAISuggestions = false,
    this.suggestedContent,
    this.suggestedSection,
    this.suggestedResumeData,
    this.isLoadingAISuggestion = false,
    this.isSavingChanges = false,
    this.hasChanges = false,
  });

  ResumeEditState copyWith({
    GenerateResumeResponse? editableResumeData,
    bool? showAISuggestions,
    String? suggestedContent,
    String? suggestedSection,
    GenerateResumeResponse? suggestedResumeData,
    bool? isLoadingAISuggestion,
    bool? isSavingChanges,
    bool? hasChanges,
    bool clearSuggestedContent = false,
    bool clearSuggestedSection = false,
    bool clearSuggestedResumeData = false,
  }) {
    return ResumeEditState(
      editableResumeData: editableResumeData ?? this.editableResumeData,
      showAISuggestions: showAISuggestions ?? this.showAISuggestions,
      suggestedContent: clearSuggestedContent
          ? null
          : (suggestedContent ?? this.suggestedContent),
      suggestedSection: clearSuggestedSection
          ? null
          : (suggestedSection ?? this.suggestedSection),
      suggestedResumeData: clearSuggestedResumeData
          ? null
          : (suggestedResumeData ?? this.suggestedResumeData),
      isLoadingAISuggestion:
          isLoadingAISuggestion ?? this.isLoadingAISuggestion,
      isSavingChanges: isSavingChanges ?? this.isSavingChanges,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }
}

/// Notifier for managing resume edit state
class ResumeEditNotifier extends StateNotifier<ResumeEditState> {
  ResumeEditNotifier(GenerateResumeResponse initialResumeData)
    : super(
        ResumeEditState(editableResumeData: _createDeepCopy(initialResumeData)),
      );

  /// Create a deep copy of resume data
  static GenerateResumeResponse _createDeepCopy(
    GenerateResumeResponse original,
  ) {
    try {
      final originalJson = original.toJson();
      return GenerateResumeResponse.fromJson(originalJson);
    } catch (e) {
      return original;
    }
  }

  /// Update professional summary
  void updateSummary(String summary) {
    if (state.editableResumeData.resumeData != null) {
      state.editableResumeData.resumeData!.summary = summary;
      state = state.copyWith(hasChanges: true);
    }
  }

  /// Update personal details
  void updatePersonalDetails(Personal personalDetails) {
    if (state.editableResumeData.resumeData != null) {
      state.editableResumeData.resumeData!.personal = personalDetails;
      state = state.copyWith(hasChanges: true);
    }
  }

  /// Add a skill
  void addSkill(String skill) {
    // Ensure skills object exists
    state.editableResumeData.resumeData?.skills ??= Skills();

    // Add to hard skills by default
    state.editableResumeData.resumeData?.skills?.hardSkills ??= [];
    state.editableResumeData.resumeData?.skills?.hardSkills!.add(skill);

    state = state.copyWith(hasChanges: true);
  }

  /// Remove a skill
  void removeSkill(String skill) {
    final skills = state.editableResumeData.resumeData?.skills;
    skills?.hardSkills?.remove(skill);
    skills?.softSkills?.remove(skill);
    skills?.toolsAndTechnologies?.remove(skill);

    state = state.copyWith(hasChanges: true);
  }

  // Work Experience CRUD Operations

  /// Add new work experience
  void addWorkExperience(WorkExperience experience) {
    state.editableResumeData.resumeData?.workExperience ??= [];
    state.editableResumeData.resumeData!.workExperience!.insert(0, experience);
    state = state.copyWith(hasChanges: true);
  }

  /// Update work experience at index
  void updateWorkExperience(int index, WorkExperience experience) {
    if (state.editableResumeData.resumeData?.workExperience != null &&
        index >= 0 &&
        index < state.editableResumeData.resumeData!.workExperience!.length) {
      state.editableResumeData.resumeData!.workExperience![index] = experience;
      state = state.copyWith(hasChanges: true);
    }
  }

  /// Delete work experience at index
  void deleteWorkExperience(int index) {
    if (state.editableResumeData.resumeData?.workExperience != null &&
        index >= 0 &&
        index < state.editableResumeData.resumeData!.workExperience!.length) {
      state.editableResumeData.resumeData!.workExperience!.removeAt(index);
      state = state.copyWith(hasChanges: true);
    }
  }

  /// Move work experience up (decrease index)
  void moveWorkExperienceUp(int index) {
    if (state.editableResumeData.resumeData?.workExperience != null &&
        index > 0 &&
        index < state.editableResumeData.resumeData!.workExperience!.length) {
      final item = state.editableResumeData.resumeData!.workExperience!
          .removeAt(index);
      state.editableResumeData.resumeData!.workExperience!.insert(
        index - 1,
        item,
      );
      state = state.copyWith(hasChanges: true);
    }
  }

  /// Move work experience down (increase index)
  void moveWorkExperienceDown(int index) {
    if (state.editableResumeData.resumeData?.workExperience != null &&
        index >= 0 &&
        index <
            state.editableResumeData.resumeData!.workExperience!.length - 1) {
      final item = state.editableResumeData.resumeData!.workExperience!
          .removeAt(index);
      state.editableResumeData.resumeData!.workExperience!.insert(
        index + 1,
        item,
      );
      state = state.copyWith(hasChanges: true);
    }
  }

  // Education CRUD Operations

  /// Add new education
  void addEducation(Education education) {
    state.editableResumeData.resumeData?.education ??= [];
    state.editableResumeData.resumeData!.education!.insert(0, education);
    state = state.copyWith(hasChanges: true);
  }

  /// Update education at index
  void updateEducation(int index, Education education) {
    if (state.editableResumeData.resumeData?.education != null &&
        index >= 0 &&
        index < state.editableResumeData.resumeData!.education!.length) {
      state.editableResumeData.resumeData!.education![index] = education;
      state = state.copyWith(hasChanges: true);
    }
  }

  /// Delete education at index
  void deleteEducation(int index) {
    if (state.editableResumeData.resumeData?.education != null &&
        index >= 0 &&
        index < state.editableResumeData.resumeData!.education!.length) {
      state.editableResumeData.resumeData!.education!.removeAt(index);
      state = state.copyWith(hasChanges: true);
    }
  }

  /// Move education up (decrease index)
  void moveEducationUp(int index) {
    if (state.editableResumeData.resumeData?.education != null &&
        index > 0 &&
        index < state.editableResumeData.resumeData!.education!.length) {
      final item = state.editableResumeData.resumeData!.education!.removeAt(
        index,
      );
      state.editableResumeData.resumeData!.education!.insert(index - 1, item);
      state = state.copyWith(hasChanges: true);
    }
  }

  /// Move education down (increase index)
  void moveEducationDown(int index) {
    if (state.editableResumeData.resumeData?.education != null &&
        index >= 0 &&
        index < state.editableResumeData.resumeData!.education!.length - 1) {
      final item = state.editableResumeData.resumeData!.education!.removeAt(
        index,
      );
      state.editableResumeData.resumeData!.education!.insert(index + 1, item);
      state = state.copyWith(hasChanges: true);
    }
  }

  // Projects CRUD Operations

  /// Add new project
  void addProject(Projects project) {
    state.editableResumeData.resumeData?.projects ??= [];
    state.editableResumeData.resumeData!.projects!.insert(0, project);
    state = state.copyWith(hasChanges: true);
  }

  /// Update project at index
  void updateProject(int index, Projects project) {
    if (state.editableResumeData.resumeData?.projects != null &&
        index >= 0 &&
        index < state.editableResumeData.resumeData!.projects!.length) {
      state.editableResumeData.resumeData!.projects![index] = project;
      state = state.copyWith(hasChanges: true);
    }
  }

  /// Delete project at index
  void deleteProject(int index) {
    if (state.editableResumeData.resumeData?.projects != null &&
        index >= 0 &&
        index < state.editableResumeData.resumeData!.projects!.length) {
      state.editableResumeData.resumeData!.projects!.removeAt(index);
      state = state.copyWith(hasChanges: true);
    }
  }

  /// Move project up (decrease index)
  void moveProjectUp(int index) {
    if (state.editableResumeData.resumeData?.projects != null &&
        index > 0 &&
        index < state.editableResumeData.resumeData!.projects!.length) {
      final item = state.editableResumeData.resumeData!.projects!.removeAt(
        index,
      );
      state.editableResumeData.resumeData!.projects!.insert(index - 1, item);
      state = state.copyWith(hasChanges: true);
    }
  }

  /// Move project down (increase index)
  void moveProjectDown(int index) {
    if (state.editableResumeData.resumeData?.projects != null &&
        index >= 0 &&
        index < state.editableResumeData.resumeData!.projects!.length - 1) {
      final item = state.editableResumeData.resumeData!.projects!.removeAt(
        index,
      );
      state.editableResumeData.resumeData!.projects!.insert(index + 1, item);
      state = state.copyWith(hasChanges: true);
    }
  }

  /// Show AI suggestions panel with loading state
  void showAISuggestionsLoading(String section) {
    state = state.copyWith(
      suggestedSection: section,
      showAISuggestions: true,
      isLoadingAISuggestion: true,
      clearSuggestedContent: true,
      clearSuggestedResumeData: true,
    );
  }

  /// Update AI suggestions content
  void setAISuggestions({
    required String content,
    required String section,
    required GenerateResumeResponse resumeData,
  }) {
    state = state.copyWith(
      suggestedContent: content,
      suggestedSection: section,
      suggestedResumeData: resumeData,
      showAISuggestions: true,
      isLoadingAISuggestion: false,
    );
  }

  /// Hide AI suggestions panel
  void hideAISuggestions() {
    state = state.copyWith(
      showAISuggestions: false,
      isLoadingAISuggestion: false,
      clearSuggestedContent: true,
      clearSuggestedSection: true,
      clearSuggestedResumeData: true,
    );
  }

  /// Accept AI suggestion for a section
  void acceptSuggestion() {
    if (state.suggestedSection != null && state.suggestedResumeData != null) {
      // Update only the specific section with the regenerated content
      if (state.suggestedSection == 'summary') {
        if (state.editableResumeData.resumeData != null &&
            state.suggestedResumeData!.resumeData != null) {
          state.editableResumeData.resumeData!.summary =
              state.suggestedResumeData!.resumeData!.summary;
        }
      } else if (state.suggestedSection == 'work_experience') {
        if (state.editableResumeData.resumeData != null &&
            state.suggestedResumeData!.resumeData != null) {
          state.editableResumeData.resumeData!.workExperience =
              state.suggestedResumeData!.resumeData!.workExperience;
        }
      } else if (state.suggestedSection == 'projects') {
        if (state.editableResumeData.resumeData != null &&
            state.suggestedResumeData!.resumeData != null) {
          state.editableResumeData.resumeData!.projects =
              state.suggestedResumeData!.resumeData!.projects;
        }
      } else if (state.suggestedSection == 'education') {
        if (state.editableResumeData.resumeData != null &&
            state.suggestedResumeData!.resumeData != null) {
          state.editableResumeData.resumeData!.education =
              state.suggestedResumeData!.resumeData!.education;
        }
      }

      // Hide the suggestions panel and mark as changed
      state = state.copyWith(
        showAISuggestions: false,
        hasChanges: true,
        clearSuggestedContent: true,
        clearSuggestedSection: true,
        clearSuggestedResumeData: true,
      );
    }
  }

  /// Update saving state
  void setSavingChanges(bool isSaving) {
    state = state.copyWith(isSavingChanges: isSaving);
  }

  /// Update PDF base64 - creates new instance to ensure state change detection
  void updatePdfBase64(String pdfBase64) {
    // Create a new instance with updated PDF to trigger state change
    final updatedResumeData = GenerateResumeResponse(
      resumeData: state.editableResumeData.resumeData,
      pdfBase64: pdfBase64,
      regeneratedSections: state.editableResumeData.regeneratedSections,
    );

    // Update state with new instance
    state = state.copyWith(editableResumeData: updatedResumeData);
  }
}

/// Provider factory function
StateNotifierProvider<ResumeEditNotifier, ResumeEditState>
createResumeEditProvider(GenerateResumeResponse initialResumeData) {
  return StateNotifierProvider<ResumeEditNotifier, ResumeEditState>((ref) {
    return ResumeEditNotifier(initialResumeData);
  });
}
