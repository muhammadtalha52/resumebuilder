class SalaryRanges {
  static const List<String> ranges = [
    '\$30,000 - \$50,000',
    '\$50,000 - \$70,000',
    '\$70,000 - \$100,000',
    '\$100,000 - \$130,000',
    '\$130,000 - \$160,000',
    '\$160,000 - \$200,000',
    '\$200,000+',
    'Negotiable',
  ];

  static const Map<String, String> rangeLabels = {
    '\$30,000 - \$50,000': 'Entry Level',
    '\$50,000 - \$70,000': 'Junior',
    '\$70,000 - \$100,000': 'Mid-Level',
    '\$100,000 - \$130,000': 'Senior',
    '\$130,000 - \$160,000': 'Lead/Principal',
    '\$160,000 - \$200,000': 'Manager',
    '\$200,000+': 'Executive',
    'Negotiable': 'Open to Discussion',
  };
}