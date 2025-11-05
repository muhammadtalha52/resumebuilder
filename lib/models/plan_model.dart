class PlanModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String priceLabel;
  final List<String> features;
  final String buttonText;
  final bool isRecommended;

  const PlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.priceLabel,
    required this.features,
    required this.buttonText,
    this.isRecommended = false,
  });

  static const List<PlanModel> allPlans = [
    PlanModel(
      id: 'basic',
      name: 'Basic Plan',
      description: 'For active job seekers',
      price: 15.99,
      priceLabel: '/month',
      features: ['3 AI Custom resumes', '1 AI interview or meeting session'],
      buttonText: 'Start for Free- 1 Resume Is On Us!',
    ),
    PlanModel(
      id: 'pro',
      name: 'Pro Plan',
      description: 'For active job seekers',
      price: 25.99,
      priceLabel: '/month',
      features: ['6 AI Custom resumes', '5 AI interview or meeting session'],

      buttonText: 'Start for Free - 1 Resume Is On Us',
    ),
    PlanModel(
      id: 'enterprise',
      name: 'Enterprise Plan',
      description: 'For active job seekers',
      price: 35.99,
      priceLabel: '/month',
      features: ['10 AI Custom resumes', '10 AI interview or meeting session'],

      buttonText: 'Get Started for Free',
      isRecommended: true,
    ),
  ];
}
