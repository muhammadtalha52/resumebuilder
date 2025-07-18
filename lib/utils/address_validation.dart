class ValidationResult {
  ValidationResult({required this.isValid, this.reason});

  final bool isValid;
  final String? reason;
}

const List<String> usStates = [
  'AL',
  'AK',
  'AZ',
  'AR',
  'CA',
  'CO',
  'CT',
  'DE',
  'FL',
  'GA',
  'HI',
  'ID',
  'IL',
  'IN',
  'IA',
  'KS',
  'KY',
  'LA',
  'ME',
  'MD',
  'MA',
  'MI',
  'MN',
  'MS',
  'MO',
  'MT',
  'NE',
  'NV',
  'NH',
  'NJ',
  'NM',
  'NY',
  'NC',
  'ND',
  'OH',
  'OK',
  'OR',
  'PA',
  'RI',
  'SC',
  'SD',
  'TN',
  'TX',
  'UT',
  'VT',
  'VA',
  'WA',
  'WV',
  'WI',
  'WY',
  'DC',
];

bool isUSAddress(String address) {
  if (address.contains('United States')) return true;

  final stateRegex = RegExp('\\b(${usStates.join('|')})\\b');
  final parts = address.split(',');
  final lastPart = parts.isNotEmpty ? parts.last.trim() : '';

  return stateRegex.hasMatch(lastPart);
}

ValidationResult isValidAddressFormat(String address) {
  // Basic validation
  if (address.isEmpty || address.length < 5) {
    return ValidationResult(isValid: false, reason: 'Address is too short');
  }

  if (address.length > 200) {
    return ValidationResult(isValid: false, reason: 'Address is too long');
  }

  // Split into parts and clean
  final parts = address
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .split(',')
      .map((part) => part.trim())
      .toList();

  // Check if we have at least street address and location parts
  if (parts.length < 2) {
    return ValidationResult(
      isValid: false,
      reason: 'Missing city, state, or ZIP code',
    );
  }

  // Validate street address part
  final streetParts = parts[0].split(' ');

  // Check for house number
  if (!RegExp(r'^\d+(-\d+)?$').hasMatch(streetParts[0])) {
    return ValidationResult(
      isValid: false,
      reason: 'Address should start with a number or number range',
    );
  }

  // Check if there's at least one word after the number for street name
  if (streetParts.length < 2) {
    return ValidationResult(isValid: false, reason: 'Missing street name');
  }

  return ValidationResult(isValid: true);
}

String cleanAddressInput(String input) {
  return input
      .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
      .replaceAll(
        RegExp(r'[^\w\s,.-]'),
        '',
      ) // Remove special chars except common address punctuation
      .trim();
}

ValidationResult validateAddress(String input) {
  if (input.isEmpty) {
    return ValidationResult(isValid: false, reason: 'Address is empty');
  }

  // Temporary bypass for testing
  //if (5 > 2) return ValidationResult(isValid: true);

  final cleanedInput = cleanAddressInput(input);
  return isValidAddressFormat(cleanedInput);
}
