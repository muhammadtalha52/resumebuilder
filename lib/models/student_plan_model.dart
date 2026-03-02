class StudentPlanModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> features;
  final bool isRecommended;

  // Promotional pricing
  static const double discountAmount = 5.0;

  double get discountedPrice => price - discountAmount;

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
      id: 'basic',
      name: 'Basic Plan',
      description: 'For Students who want to Ace their Academic Careers',
      price: 20.99,
      features: [
        '1 Guided Study Session with Custom Quiz',
        'Ability to upload 5 documents',
      ],
    ),
    StudentPlanModel(
      id: 'pro',
      name: 'Pro Plan',
      description: 'For Students who want to Ace their Academic Careers',
      price: 30.99,
      features: [
        '3 Guided Study Sessions with Custom Quizzes',
        'Ability to upload 10 documents',
      ],
    ),
    StudentPlanModel(
      id: 'enterprise',
      name: 'Enterprise Plan',
      description: 'For Students who want to Ace their Academic Careers',
      price: 40.99,
      features: [
        '9 Guided Study Sessions with Custom Quizzes',
        'Ability to upload 20 documents',
      ],
      isRecommended: true,
    ),
  ];
}
