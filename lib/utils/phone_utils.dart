/// Utility class for phone number operations
class PhoneUtils {
  // Country code mapping for common countries
  // IMPORTANT: Order matters - longer codes must come before shorter ones
  static const Map<String, String> countryCodeMap = {
    // North American specific codes (longer codes first)
    '1684': 'AS', // American Samoa
    '1787': 'PR', // Puerto Rico
    '1939': 'PR', // Puerto Rico
    '1671': 'GU', // Guam
    '1670': 'MP', // Northern Mariana Islands
    '1340': 'VI', // U.S. Virgin Islands
    // Standard codes
    '1': 'US', // United States/Canada (must come after longer 1xxx codes)
    '44': 'GB', // United Kingdom
    '61': 'AU', // Australia
    '64': 'NZ', // New Zealand
    '91': 'IN', // India
    '92': 'PK', // Pakistan
    '880': 'BD', // Bangladesh
    '94': 'LK', // Sri Lanka
    '27': 'ZA', // South Africa
    '234': 'NG', // Nigeria
    '254': 'KE', // Kenya
    '20': 'EG', // Egypt
    '212': 'MA', // Morocco
    '213': 'DZ', // Algeria
    '216': 'TN', // Tunisia
    '218': 'LY', // Libya
    '220': 'GM', // Gambia
    '221': 'SN', // Senegal
    '222': 'MR', // Mauritania
    '223': 'ML', // Mali
    '224': 'GN', // Guinea
    '225': 'CI', // Ivory Coast
    '226': 'BF', // Burkina Faso
    '227': 'NE', // Niger
    '228': 'TG', // Togo
    '229': 'BJ', // Benin
    '230': 'MU', // Mauritius
    '231': 'LR', // Liberia
    '232': 'SL', // Sierra Leone
    '233': 'GH', // Ghana
    '235': 'TD', // Chad
    '236': 'CF', // Central African Republic
    '237': 'CM', // Cameroon
    '238': 'CV', // Cape Verde
    '239': 'ST', // Sao Tome and Principe
    '240': 'GQ', // Equatorial Guinea
    '241': 'GA', // Gabon
    '242': 'CG', // Republic of the Congo
    '243': 'CD', // Democratic Republic of the Congo
    '244': 'AO', // Angola
    '245': 'GW', // Guinea-Bissau
    '246': 'IO', // British Indian Ocean Territory
    '247': 'AC', // Ascension Island
    '248': 'SC', // Seychelles
    '249': 'SD', // Sudan
    '250': 'RW', // Rwanda
    '251': 'ET', // Ethiopia
    '252': 'SO', // Somalia
    '253': 'DJ', // Djibouti
    '255': 'TZ', // Tanzania
    '256': 'UG', // Uganda
    '257': 'BI', // Burundi
    '258': 'MZ', // Mozambique
    '260': 'ZM', // Zambia
    '261': 'MG', // Madagascar
    '262': 'RE', // Reunion
    '263': 'ZW', // Zimbabwe
    '264': 'NA', // Namibia
    '265': 'MW', // Malawi
    '266': 'LS', // Lesotho
    '267': 'BW', // Botswana
    '268': 'SZ', // Eswatini
    '269': 'KM', // Comoros
    // Middle East
    '971': 'AE', // UAE
    '966': 'SA', // Saudi Arabia
    '974': 'QA', // Qatar
    '973': 'BH', // Bahrain
    '968': 'OM', // Oman
    '965': 'KW', // Kuwait
    '962': 'JO', // Jordan
    '961': 'LB', // Lebanon
    '963': 'SY', // Syria
    '964': 'IQ', // Iraq
    '98': 'IR', // Iran
    '972': 'IL', // Israel
    '970': 'PS', // Palestine
    '967': 'YE', // Yemen
    // Asia
    '86': 'CN', // China
    '81': 'JP', // Japan
    '82': 'KR', // South Korea
    '886': 'TW', // Taiwan
    '852': 'HK', // Hong Kong
    '853': 'MO', // Macau
    '60': 'MY', // Malaysia
    '65': 'SG', // Singapore
    '66': 'TH', // Thailand
    '84': 'VN', // Vietnam
    '63': 'PH', // Philippines
    '62': 'ID', // Indonesia
  };

  /// Detect country code from phone number
  static String detectCountryCode(String phoneNumber) {
    if (phoneNumber.isEmpty) return 'US';

    // Remove all non-digit characters except +
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Remove + sign if present
    if (cleanNumber.startsWith('+')) {
      cleanNumber = cleanNumber.substring(1);
    }

    // Try to match country codes (from longest to shortest)
    List<String> codes = countryCodeMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (String code in codes) {
      if (cleanNumber.startsWith(code)) {
        // Verify remaining digits form a reasonable phone number
        String remainingDigits = cleanNumber.substring(code.length);
        if (remainingDigits.length >= 7 && remainingDigits.length <= 12) {
          return countryCodeMap[code]!;
        }
      }
    }

    return 'US'; // Default fallback
  }

  /// Extract phone number without country code
  static String extractPhoneNumber(String fullPhoneNumber) {
    if (fullPhoneNumber.isEmpty) return '';

    // Remove all non-digit characters except +
    String cleanNumber = fullPhoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Remove + sign if present
    if (cleanNumber.startsWith('+')) {
      cleanNumber = cleanNumber.substring(1);
    }

    // Try to match country codes (from longest to shortest)
    List<String> codes = countryCodeMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (String code in codes) {
      if (cleanNumber.startsWith(code)) {
        // Verify remaining digits form a reasonable phone number
        String remainingDigits = cleanNumber.substring(code.length);
        if (remainingDigits.length >= 7 && remainingDigits.length <= 12) {
          return remainingDigits;
        }
      }
    }

    // If no match found, return the original cleaned number
    return cleanNumber;
  }
}
