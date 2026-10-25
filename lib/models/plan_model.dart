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
      id: 'weekend_warrior',
      name: 'Weekend Warrior',
      description: 'Quick resume polish & practice',
      price: 10.99,
      features: ['3 AI Custom Resumes', '3 AI Interview Sessions', '10 Ask Scout Questions'],
    ),
    PlanModel(
      id: 'just_scouting',
      name: 'Just Scouting',
      description: 'For active job seekers',
      price: 14.99,
      features: ['5 AI Custom Resumes', '3 AI Interview Sessions', '20 Ask Scout Questions'],
    ),
    PlanModel(
      id: 'serious_seeker',
      name: 'Serious Seeker',
      description: 'Most popular for serious candidates',
      price: 24.99,
      features: ['12 AI Custom Resumes', '8 AI Interview Sessions', '45 Ask Scout Questions'],
      isRecommended: true,
    ),
    PlanModel(
      id: 'job_hunter',
      name: 'Job Hunter',
      description: 'Maximum power for full job search',
      price: 49.99,
      features: ['25 AI Custom Resumes', '15 AI Interview Sessions', '100 Ask Scout Questions'],
    ),
  ];
}
