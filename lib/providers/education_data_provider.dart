import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/education_model.dart';
import '../services/education_service.dart';

// Provider for education service
final educationServiceProvider = Provider<EducationService>((ref) {
  return EducationService();
});

// FutureProvider to fetch and cache education data
final educationDataProvider = FutureProvider<EducationModel>((ref) async {
  final educationService = ref.read(educationServiceProvider);
  return await educationService.getEducationData();
});

// Computed providers for easy access to specific data
final degreeTypesProvider = Provider<List<String>>((ref) {
  final educationDataAsync = ref.watch(educationDataProvider);

  return educationDataAsync.when(
    data: (educationModel) {
      final degreeTypes = educationModel.data?.degreeTypes ?? [];
      // Extract names
      final names = degreeTypes
          .where((dt) => dt.name != null)
          .map((dt) => dt.name!)
          .toSet()
          .toList();

      return names;
    },
    loading: () => _fallbackDegreeTypes,
    error: (_, _) => _fallbackDegreeTypes,
  );
});

final majorsProvider = Provider<List<String>>((ref) {
  final educationDataAsync = ref.watch(educationDataProvider);

  return educationDataAsync.when(
    data: (educationModel) {
      final subjects = educationModel.data?.subjects ?? [];
      // Extract unique subject names
      final names = subjects
          .where((s) => s.name != null)
          .map((s) => s.name!)
          .toSet()
          .toList();

      return names;
    },
    loading: () => _fallbackMajors,
    error: (_, _) => _fallbackMajors,
  );
});

final institutionsProvider = Provider<List<String>>((ref) {
  final educationDataAsync = ref.watch(educationDataProvider);

  return educationDataAsync.when(
    data: (educationModel) {
      final institutes = educationModel.data?.institutes ?? [];
      // Extract institute names
      final names = institutes
          .where((i) => i.name != null)
          .map((i) => i.name!)
          .toSet()
          .toList();

      return names;
    },
    loading: () => _fallbackInstitutions,
    error: (_, _) => _fallbackInstitutions,
  );
});

final certificationsProvider = Provider<List<String>>((ref) {
  final educationDataAsync = ref.watch(educationDataProvider);

  return educationDataAsync.when(
    data: (educationModel) {
      final certificates = educationModel.data?.certificates ?? [];
      // Extract certificate names
      final names = certificates
          .where((c) => c.name != null)
          .map((c) => c.name!)
          .toSet()
          .toList();

      return names;
    },
    loading: () => _fallbackCertifications,
    error: (_, _) => _fallbackCertifications,
  );
});

// Fallback data for offline/error scenarios
const List<String> _fallbackDegreeTypes = [
  'High School Diploma',
  'Associate Degree',
  'Bachelor\'s Degree',
  'Master\'s Degree',
  'Doctoral Degree (PhD)',
  'Professional Degree',
  'Certificate',
  'Other',
];

const List<String> _fallbackMajors = [
  'Computer Science',
  'Information Technology',
  'Software Engineering',
  'Business Administration',
  'Marketing',
  'Finance',
  'Accounting',
  'Mechanical Engineering',
  'Electrical Engineering',
  'Civil Engineering',
  'Psychology',
  'Biology',
  'Chemistry',
  'Physics',
  'Mathematics',
  'English',
  'Communications',
  'Graphic Design',
  'Art',
  'History',
  'Political Science',
  'Economics',
  'Other',
];

const List<String> _fallbackInstitutions = [
  'Harvard University',
  'Stanford University',
  'MIT',
  'University of California, Berkeley',
  'Yale University',
  'Princeton University',
  'Columbia University',
  'University of Chicago',
  'University of Pennsylvania',
  'California Institute of Technology',
  'Johns Hopkins University',
  'Northwestern University',
  'Duke University',
  'Dartmouth College',
  'Brown University',
  'Vanderbilt University',
  'Rice University',
  'Washington University in St. Louis',
  'Cornell University',
  'University of Notre Dame',
  'Other',
];

const List<String> _fallbackCertifications = [
  'AWS Certified Solutions Architect',
  'Google Cloud Professional',
  'Microsoft Azure Fundamentals',
  'Certified Information Systems Security Professional (CISSP)',
  'Project Management Professional (PMP)',
  'Certified Public Accountant (CPA)',
  'Chartered Financial Analyst (CFA)',
  'Certified Information Systems Auditor (CISA)',
  'Cisco Certified Network Associate (CCNA)',
  'CompTIA Security+',
  'Certified Scrum Master (CSM)',
  'Google Analytics Certified',
  'HubSpot Content Marketing',
  'Adobe Certified Expert',
  'Other',
];

// Helper providers to get IDs from selected names
final getDegreeTypeIdProvider = Provider.family<int?, String?>((ref, name) {
  if (name == null) return null;
  final educationDataAsync = ref.watch(educationDataProvider);

  return educationDataAsync.when(
    data: (educationModel) {
      final degreeTypes = educationModel.data?.degreeTypes ?? [];
      final degreeType = degreeTypes.firstWhere(
        (dt) => dt.name == name,
        orElse: () => DegreeTypes(),
      );
      return degreeType.id;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

final getMajorIdProvider = Provider.family<int?, String?>((ref, name) {
  if (name == null) return null;
  final educationDataAsync = ref.watch(educationDataProvider);

  return educationDataAsync.when(
    data: (educationModel) {
      final subjects = educationModel.data?.subjects ?? [];
      final subject = subjects.firstWhere(
        (s) => s.name == name,
        orElse: () => Subjects(),
      );
      return subject.id;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

final getInstitutionIdProvider = Provider.family<int?, String?>((ref, name) {
  if (name == null) return null;
  final educationDataAsync = ref.watch(educationDataProvider);

  return educationDataAsync.when(
    data: (educationModel) {
      final institutes = educationModel.data?.institutes ?? [];
      final institute = institutes.firstWhere(
        (i) => i.name == name,
        orElse: () => Institutes(),
      );
      return institute.id;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

final getCertificationIdProvider = Provider.family<int?, String?>((ref, name) {
  if (name == null) return null;
  final educationDataAsync = ref.watch(educationDataProvider);

  return educationDataAsync.when(
    data: (educationModel) {
      final certificates = educationModel.data?.certificates ?? [];
      final certificate = certificates.firstWhere(
        (c) => c.name == name,
        orElse: () => Certificates(),
      );
      return certificate.id;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

// Reverse lookup providers - get names from IDs
final getDegreeTypeNameProvider = Provider.family<String?, int?>((ref, id) {
  if (id == null) return null;
  final educationDataAsync = ref.watch(educationDataProvider);

  return educationDataAsync.when(
    data: (educationModel) {
      final degreeTypes = educationModel.data?.degreeTypes ?? [];
      final degreeType = degreeTypes.firstWhere(
        (dt) => dt.id == id,
        orElse: () => DegreeTypes(),
      );
      return degreeType.name;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

final getMajorNameProvider = Provider.family<String?, int?>((ref, id) {
  if (id == null) return null;
  final educationDataAsync = ref.watch(educationDataProvider);

  return educationDataAsync.when(
    data: (educationModel) {
      final subjects = educationModel.data?.subjects ?? [];
      final subject = subjects.firstWhere(
        (s) => s.id == id,
        orElse: () => Subjects(),
      );
      return subject.name;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

final getInstitutionNameProvider = Provider.family<String?, int?>((ref, id) {
  if (id == null) return null;
  final educationDataAsync = ref.watch(educationDataProvider);

  return educationDataAsync.when(
    data: (educationModel) {
      final institutes = educationModel.data?.institutes ?? [];
      final institute = institutes.firstWhere(
        (i) => i.id == id,
        orElse: () => Institutes(),
      );
      return institute.name;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

final getCertificationNameProvider = Provider.family<String?, int?>((ref, id) {
  if (id == null) return null;
  final educationDataAsync = ref.watch(educationDataProvider);

  return educationDataAsync.when(
    data: (educationModel) {
      final certificates = educationModel.data?.certificates ?? [];
      final certificate = certificates.firstWhere(
        (c) => c.id == id,
        orElse: () => Certificates(),
      );
      return certificate.name;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});
