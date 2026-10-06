import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentSignupState {
  final int currentStep;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? password;
  final String? hometown;
  final String? school;
  final DateTime? expectedGraduationDate;
  final String? major;
  final List<String> idealJobTitles;
  final String? heardAboutUs;

  StudentSignupState({
    this.currentStep = 1,
    this.fullName,
    this.email,
    this.phone,
    this.password,
    this.hometown,
    this.school,
    this.expectedGraduationDate,
    this.major,
    this.idealJobTitles = const [],
    this.heardAboutUs,
  });

  StudentSignupState copyWith({
    int? currentStep,
    String? fullName,
    String? email,
    String? phone,
    String? password,
    String? hometown,
    String? school,
    DateTime? expectedGraduationDate,
    String? major,
    List<String>? idealJobTitles,
    String? heardAboutUs,
  }) {
    return StudentSignupState(
      currentStep: currentStep ?? this.currentStep,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      hometown: hometown ?? this.hometown,
      school: school ?? this.school,
      expectedGraduationDate:
          expectedGraduationDate ?? this.expectedGraduationDate,
      major: major ?? this.major,
      idealJobTitles: idealJobTitles ?? this.idealJobTitles,
      heardAboutUs: heardAboutUs ?? this.heardAboutUs,
    );
  }
}

class StudentSignupNotifier extends StateNotifier<StudentSignupState> {
  StudentSignupNotifier() : super(StudentSignupState());

  void updateStep1({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? heardAboutUs,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      heardAboutUs: heardAboutUs,
    );
  }

  void updateStep2({
    required String hometown,
    required String school,
    required DateTime expectedGraduationDate,
    required String major,
    required List<String> idealJobTitles,
  }) {
    state = state.copyWith(
      hometown: hometown,
      school: school,
      expectedGraduationDate: expectedGraduationDate,
      major: major,
      idealJobTitles: idealJobTitles,
    );
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void reset() {
    state = StudentSignupState();
  }
}

final studentSignupProvider =
    StateNotifierProvider<StudentSignupNotifier, StudentSignupState>((ref) {
      return StudentSignupNotifier();
    });
