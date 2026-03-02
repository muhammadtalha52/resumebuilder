class PlanModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> features;
  final bool isRecommended;

  // Promotional pricing
  static const double discountAmount = 5.0;

  double get discountedPrice => price - discountAmount;

  const PlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.features,
    this.isRecommended = false,
  });

  static const List<PlanModel> allPlans = [
    PlanModel(
      id: 'basic',
      name: 'Basic Plan',
      description: 'For active job seekers',
      price: 20.99,
      features: ['3 AI Custom resumes', '1 AI interview or meeting session'],
    ),
    PlanModel(
      id: 'pro',
      name: 'Pro Plan',
      description: 'For active job seekers',
      price: 30.99,
      features: ['6 AI Custom resumes', '5 AI interview or meeting session'],
    ),
    PlanModel(
      id: 'enterprise',
      name: 'Enterprise Plan',
      description: 'For active job seekers',
      price: 40.99,
      features: ['10 AI Custom resumes', '10 AI interview or meeting session'],
      isRecommended: true,
    ),
  ];
}
