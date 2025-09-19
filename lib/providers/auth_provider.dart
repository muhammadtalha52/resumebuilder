import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../models/signup_request.dart';
import '../models/user_model.dart';
import '../utils/keys.dart';
import 'auth_service_provider.dart';
import 'onboarding_provider.dart';

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

  Future<void> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Implement actual forgot password logic
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send reset email. Please try again.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void updateUserData(User updatedUser) async {
    // Update state with new user data
    state = state.copyWith(user: updatedUser);

    // Update AppLogic with new user data
    appLogic.user = updatedUser;

    // Save updated user data to local storage
    await appLogic.box.write(AppKeys.user, jsonEncode(updatedUser.toJson()));
  }

  Future<void> updateProfileImage(String imageUrl) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    // Create updated user with new profile image
    final updatedUser = User(
      id: currentUser.id,
      email: currentUser.email,
      username: currentUser.username,
      firstName: currentUser.firstName,
      lastName: currentUser.lastName,
      fullName: currentUser.fullName,
      phoneNumber: currentUser.phoneNumber,
      dateOfBirth: currentUser.dateOfBirth,
      address: currentUser.address,
      city: currentUser.city,
      state: currentUser.state,
      country: currentUser.country,
      postalCode: currentUser.postalCode,
      professionalSummary: currentUser.professionalSummary,
      linkedinUrl: currentUser.linkedinUrl,
      githubUrl: currentUser.githubUrl,
      portfolioUrl: currentUser.portfolioUrl,
      desiredJobTitles: currentUser.desiredJobTitles,
      industryPreferences: currentUser.industryPreferences,
      careerGoals: currentUser.careerGoals,
      degreeType: currentUser.degreeType,
      major: currentUser.major,
      institution: currentUser.institution,
      graduationDate: currentUser.graduationDate,
      certificationsTraining: currentUser.certificationsTraining,
      workExperience: currentUser.workExperience,
      hardSkills: currentUser.hardSkills,
      softSkills: currentUser.softSkills,
      toolsTechnologies: currentUser.toolsTechnologies,
      languages: currentUser.languages,
      volunteerWork: currentUser.volunteerWork,
      hobbiesInterests: currentUser.hobbiesInterests,
      references: currentUser.references,
      profileImage: imageUrl, // Updated profile image
      isProfileComplete: currentUser.isProfileComplete,
      role: currentUser.role,
      signupProgress: currentUser.signupProgress,
      resumeFileName: currentUser.resumeFileName,
      desiredPayRange: currentUser.desiredPayRange,
      locationPreferences: currentUser.locationPreferences,
      createdAt: currentUser.createdAt,
      updatedAt: currentUser.updatedAt,
      profileCompletionPercentage: currentUser.profileCompletionPercentage,
      workStartDate: currentUser.workStartDate,
      workEndDate: currentUser.workEndDate,
    );

    // Update user data
    updateUserData(updatedUser);
  }

  void signOut() {
    // Clear app logic data
    appLogic.accessToken = '';
    appLogic.user = null;
    appLogic.box.erase();

    // Clear onboarding state to ensure fresh forms for new accounts
    _ref.read(onboardingProvider.notifier).reset();

    // Reset auth state
    state = const AuthState();
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
