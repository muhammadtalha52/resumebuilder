import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../models/signup_request.dart';
import '../models/student_signup_request.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import '../services/resume_service.dart';
import '../utils/keys.dart';
import 'auth_service_provider.dart';
import 'continuous_transcription_provider.dart';
import 'dashboard_provider.dart';
import 'documents_provider.dart';
import 'history_provider.dart';
import 'iap_provider.dart';
import 'interview_session_provider.dart';
import 'usage_provider.dart';
import 'interview_summary_provider.dart';
import 'lectures_provider.dart';
import 'meeting_history_provider.dart';
import 'onboarding_provider.dart';
import 'profile_provider.dart';
import 'quiz_history_provider.dart';
import 'quiz_provider.dart';
import 'resume_provider.dart';
import 'scout_chat_provider.dart';
import 'student_signup_provider.dart';
import 'study_space_provider.dart';
import 'subjects_provider.dart';

// Auth State
class AuthState extends Equatable {
  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isLoading, isAuthenticated, user, error];
}

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    _initializeFromStorage();
  }

  final Ref _ref;

  /// Initialize auth state from stored user data on app startup
  Future<void> _initializeFromStorage() async {
    try {
      // Check if user data exists in storage
      if (appLogic.user != null && appLogic.accessToken.isNotEmpty) {
        state = state.copyWith(isAuthenticated: true, user: appLogic.user);
      }
    } catch (e) {
      // If there's any error, just continue with empty state
      print('Error initializing auth from storage: $e');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    // Clear any previous errors when starting a new login attempt
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authService = _ref.read(authServiceProvider);
      final loginResponse = await authService.login(
        email: email,
        password: password,
      );

      if (loginResponse.status == 'success' && loginResponse.data != null) {
        final user = loginResponse.data!.user;
        final token = loginResponse.data!.token;

        if (user != null && token != null) {
          // Store token and user data in AppLogic
          appLogic.accessToken = token;
          appLogic.user = user;

          // Save to local storage
          await appLogic.box.write(AppKeys.accessToken, token);
          await appLogic.box.write(AppKeys.user, jsonEncode(user.toJson()));

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: user,
          );
        } else {
          throw Exception('Invalid response data');
        }
      } else {
        throw Exception(loginResponse.message ?? 'Login failed');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> signUpFromOnboarding(SignUpRequest request) async {
    state = state.copyWith(isLoading: true, error: null);

    // Capture resume file BEFORE resetting onboarding state
    final File? resumeFile = _ref.read(onboardingProvider).resumeFile;

    try {
      final authService = _ref.read(authServiceProvider);
      final registerResponse = await authService.register(request);

      if (registerResponse.status == 'success' &&
          registerResponse.data != null) {
        final user = registerResponse.data!.user;
        final token = registerResponse.data!.token;

        if (user != null && token != null) {
          // Store token and user data in AppLogic
          appLogic.accessToken = token;
          appLogic.user = user;

          // Save to local storage
          await appLogic.box.write(AppKeys.accessToken, token);
          await appLogic.box.write(AppKeys.user, jsonEncode(user.toJson()));

          // Clear onboarding state after successful account creation
          _ref.read(onboardingProvider.notifier).reset();

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: user,
          );

          // Upload resume file to S3 in the background (after signup success)
          if (resumeFile != null && await resumeFile.exists()) {
            _uploadResumeInBackground(resumeFile);
          }
        } else {
          throw Exception('Invalid response data');
        }
      } else {
        throw Exception(registerResponse.message ?? 'Registration failed');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow; // Rethrow to let the UI handle the error
    }
  }

  /// Upload resume file to S3 in background and update user profile
  /// Includes retry mechanism for network failures
  Future<void> _uploadResumeInBackground(
    File resumeFile, {
    int retryCount = 0,
  }) async {
    const maxRetries = 2;
    const retryDelay = Duration(seconds: 3);

    try {
      print(
        '[AuthProvider] Starting background resume upload (attempt ${retryCount + 1})...',
      );

      // Check if file still exists before upload
      if (!await resumeFile.exists()) {
        print('[AuthProvider] Resume file no longer exists, skipping upload');
        return;
      }

      // Upload resume to S3
      final resumeService = ResumeService();
      final saveDocResponse = await resumeService.uploadDocsToS3(resumeFile);
      final s3FileName = saveDocResponse.s3FileName;

      if (s3FileName != null && s3FileName.isNotEmpty) {
        print('[AuthProvider] Resume uploaded to S3: $s3FileName');

        // Update user profile with resume_file_name
        final profileService = ProfileService();
        final updateResponse = await profileService.updateProfile({
          'resume_file_name': s3FileName,
        });

        if (updateResponse.status == 'success' && updateResponse.data != null) {
          // Update local user data with the new resume_file_name
          final updatedUser = updateResponse.data!;
          updateUserData(updatedUser);
          print('[AuthProvider] Profile updated with resume_file_name');
        }
      }
    } catch (e) {
      print('[AuthProvider] Background resume upload failed: $e');

      // Retry on failure if we haven't exceeded max retries
      if (retryCount < maxRetries) {
        print('[AuthProvider] Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
        await _uploadResumeInBackground(resumeFile, retryCount: retryCount + 1);
      } else {
        print('[AuthProvider] Max retries reached, giving up on resume upload');
      }
    }
  }

  Future<void> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authService = _ref.read(authServiceProvider);
      await authService.forgotPassword(email: email);

      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void updateUserData(User updatedUser) async {
    print('[AuthProvider] updateUserData called');
    print('  - Updating user: ${updatedUser.fullName}');
    print('  - Phone: ${updatedUser.phoneNumber}');
    print('  - Professional Summary: ${updatedUser.professionalSummary}');
    print('  - LinkedIn: ${updatedUser.linkedinUrl}');
    print('  - Portfolio: ${updatedUser.portfolioUrl}');
    print('  - Profile Image: ${updatedUser.profileImage}');

    // Update state with new user data
    state = state.copyWith(user: updatedUser);

    // Update AppLogic with new user data
    appLogic.user = updatedUser;

    // Save updated user data to local storage
    await appLogic.box.write(AppKeys.user, jsonEncode(updatedUser.toJson()));
    print('[AuthProvider] User data saved to storage successfully');
  }

  Future<void> signUpStudent(StudentSignupRequest request) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authService = _ref.read(authServiceProvider);
      final registerResponse = await authService.registerStudent(request);

      if (registerResponse.status == 'success' &&
          registerResponse.data != null) {
        final user = registerResponse.data!.user;
        final token = registerResponse.data!.token;

        if (user != null && token != null) {
          // Store token and user data in AppLogic
          appLogic.accessToken = token;
          appLogic.user = user;

          // Save to local storage
          await appLogic.box.write(AppKeys.accessToken, token);
          await appLogic.box.write(AppKeys.user, jsonEncode(user.toJson()));

          // Clear student signup state after successful account creation
          _ref.read(studentSignupProvider.notifier).reset();

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: user,
          );
        } else {
          throw Exception('Invalid response data');
        }
      } else {
        throw Exception(registerResponse.message ?? 'Registration failed');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow; // Rethrow to let the UI handle the error
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authService = _ref.read(authServiceProvider);
      final registerResponse = await authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        role: 1, // Candidate role
      );

      if (registerResponse.status == 'success' &&
          registerResponse.data != null) {
        final user = registerResponse.data!.user;
        final token = registerResponse.data!.token;

        if (user != null && token != null) {
          // Store token and user data in AppLogic
          appLogic.accessToken = token;
          appLogic.user = user;

          // Save to local storage
          await appLogic.box.write(AppKeys.accessToken, token);
          await appLogic.box.write(AppKeys.user, jsonEncode(user.toJson()));

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: user,
          );
        } else {
          throw Exception('Invalid response data');
        }
      } else {
        throw Exception(registerResponse.message ?? 'Registration failed');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  /// Refreshes user data from the server
  /// Call this when entering screens that need fresh user data (e.g., profile screen)
  Future<void> refreshUser() async {
    // Don't refresh if not authenticated or no current user
    if (!state.isAuthenticated || state.user == null) return;

    try {
      final profileService = ProfileService();
      final response = await profileService.getProfile();

      if (response.status == 'success' && response.data != null) {
        final freshUser = response.data!;

        // Validate the response data before updating
        if (!_isValidUserData(freshUser, state.user!)) {
          print('[AuthProvider] Refresh rejected: invalid user data');
          return;
        }

        updateUserData(freshUser);
        print('[AuthProvider] User data refreshed successfully');
      }
    } catch (e) {
      // Silently fail - don't disrupt user experience for refresh failures
      print('[AuthProvider] Failed to refresh user data: $e');
    }
  }

  /// Validates that the refreshed user data is legitimate
  /// Returns false if data appears to be garbage or belongs to a different user
  bool _isValidUserData(User freshUser, User currentUser) {
    // Must have same user ID (prevent wrong user data)
    if (freshUser.id != currentUser.id) {
      print('[AuthProvider] Validation failed: user ID mismatch');
      return false;
    }

    // Must have same email (additional identity check)

    // commented out for now
    // if (freshUser.email != currentUser.email) {
    //   print('[AuthProvider] Validation failed: email mismatch');
    //   return false;
    // }

    // Profile completion percentage must be valid (0-100)
    final percentage = freshUser.profileCompletionPercentage;
    if (percentage != null && (percentage < 0 || percentage > 100)) {
      print('[AuthProvider] Validation failed: invalid profile percentage');
      return false;
    }

    return true;
  }

  void signOut() {
    print('[LOGOUT] Starting logout - clearing all user data and providers');

    // Clear app logic data
    appLogic.accessToken = '';
    appLogic.user = null;
    appLogic.box.erase();

    // Invalidate all user-specific providers to ensure clean state for next login
    // This automatically resets all providers to their initial state
    _ref.invalidate(profileProvider);
    _ref.invalidate(interviewSessionProvider);
    _ref.invalidate(interviewSummaryProvider);
    _ref.invalidate(meetingHistoryProvider);
    _ref.invalidate(continuousTranscriptionProvider);
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(dashboardFilterProvider);
    _ref.invalidate(resumeProvider);
    _ref.invalidate(quizProvider);
    _ref.invalidate(quizHistoryProvider);
    _ref.invalidate(documentsProvider);
    _ref.invalidate(studySpaceProvider);
    _ref.invalidate(lecturesProvider);
    _ref.invalidate(subjectsProvider);
    _ref.invalidate(historyProvider);
    _ref.invalidate(scoutChatProvider);
    _ref.invalidate(onboardingProvider);
    _ref.invalidate(studentSignupProvider);
    _ref.invalidate(iapProvider);
    _ref.invalidate(usageProvider);

    print(
      '[LOGOUT] All providers invalidated - clean state ready for next login',
    );

    // Reset auth state
    state = const AuthState();
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
