class StudentPlanModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> features;
  final bool isRecommended;

  const StudentPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.features,
    this.isRecommended = false,
  });

  static const List<StudentPlanModel> allStudentPlans = [
    StudentPlanModel(
      id: 'cram_session',
      name: 'Cram Session',
      description: 'Quick exam preparation & revision',
      price: 3.99,
      features: [
        '12 Guided Study Sessions & Quizzes',
        '25 Document Uploads',
      ],
    ),
    StudentPlanModel(
      id: 'basic_student',
      name: 'Basic Student',
      description: 'For steady academic support',
      price: 5.00,
      features: [
        '10 Guided Study Sessions & Quizzes',
        '20 Document Uploads',
      ],
    ),
    StudentPlanModel(
      id: 'mid_student',
      name: 'Mid Student',
      description: 'Ideal for semester projects & regular study',
      price: 10.00,
      features: [
        '25 Guided Study Sessions & Quizzes',
        '50 Document Uploads',
      ],
    ),
    StudentPlanModel(
      id: 'nerd_out',
      name: 'Nerd Out',
      description: 'Maximum power for serious academics',
      price: 15.00,
      features: [
        '50 Guided Study Sessions & Quizzes',
        '100 Document Uploads',
      ],
      isRecommended: true,
    ),
  ];
}
