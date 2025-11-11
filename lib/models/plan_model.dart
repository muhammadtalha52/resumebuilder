class PlanModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> features;
  final bool isRecommended;

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
      price: 15.99,
      features: ['3 AI Custom resumes', '1 AI interview or meeting session'],
    ),
    PlanModel(
      id: 'pro',
      name: 'Pro Plan',
      description: 'For active job seekers',
      price: 25.99,
      features: ['6 AI Custom resumes', '5 AI interview or meeting session'],
    ),
    PlanModel(
      id: 'enterprise',
      name: 'Enterprise Plan',
      description: 'For active job seekers',
      price: 35.99,
      features: ['10 AI Custom resumes', '10 AI interview or meeting session'],
      isRecommended: true,
    ),
  ];
}
