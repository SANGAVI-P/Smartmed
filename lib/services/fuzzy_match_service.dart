import 'dart:math';

class DatabaseMedicine {
  final String name;
  final List<String> synonyms;
  final String defaultStrength;
  final String defaultDosage;
  final String defaultTiming;
  final String defaultDuration;

  const DatabaseMedicine({
    required this.name,
    required this.synonyms,
    required this.defaultStrength,
    required this.defaultDosage,
    required this.defaultTiming,
    required this.defaultDuration,
  });
}

class MatchResult {
  final String matchedName;
  final double similarity;
  final DatabaseMedicine? dbMatch;

  MatchResult({
    required this.matchedName,
    required this.similarity,
    this.dbMatch,
  });
}

class FuzzyMatchService {
  static const List<DatabaseMedicine> medicineDatabase = [
    DatabaseMedicine(
      name: 'Paracetamol',
      synonyms: ['acetaminophen', 'panadol', 'paracitamol', 'pyregesic', 'calpol', 'para', 'paracetol'],
      defaultStrength: '500 mg',
      defaultDosage: '1 Tablet',
      defaultTiming: 'after_food',
      defaultDuration: '5 days',
    ),
    DatabaseMedicine(
      name: 'Disprin',
      synonyms: ['aspirin', 'acetylsalicylic acid', 'disprin', 'dispirin'],
      defaultStrength: '325 mg',
      defaultDosage: '1 Tablet',
      defaultTiming: 'after_food',
      defaultDuration: '3 days',
    ),
    DatabaseMedicine(
      name: 'Loperamide',
      synonyms: ['lopramide', 'imodium', 'loperamide hydrochloride'],
      defaultStrength: '2 mg',
      defaultDosage: '1 Capsule',
      defaultTiming: 'before_food',
      defaultDuration: '2 days',
    ),
    DatabaseMedicine(
      name: 'Lisinopril',
      synonyms: ['lisinopril', 'zestril', 'prinivil'],
      defaultStrength: '10 mg',
      defaultDosage: '1 Tablet',
      defaultTiming: 'after_food',
      defaultDuration: '30 days',
    ),
    DatabaseMedicine(
      name: 'Metformin',
      synonyms: ['metformin', 'glucophage', 'metformin hydrochloride'],
      defaultStrength: '500 mg',
      defaultDosage: '1 Tablet',
      defaultTiming: 'after_food',
      defaultDuration: '60 days',
    ),
    DatabaseMedicine(
      name: 'Atorvastatin',
      synonyms: ['atorvastatin', 'lipitor', 'atorva'],
      defaultStrength: '20 mg',
      defaultDosage: '1 Tablet',
      defaultTiming: 'before_food',
      defaultDuration: '30 days',
    ),
    DatabaseMedicine(
      name: 'Eliquis',
      synonyms: ['eliquis', 'apixaban'],
      defaultStrength: '5 mg',
      defaultDosage: '1 Tablet',
      defaultTiming: 'after_food',
      defaultDuration: '30 days',
    ),
    DatabaseMedicine(
      name: 'Amoxicillin',
      synonyms: ['amoxicillin', 'amoxil', 'amoxycillin', 'amox'],
      defaultStrength: '500 mg',
      defaultDosage: '1 Capsule',
      defaultTiming: 'after_food',
      defaultDuration: '7 days',
    ),
    DatabaseMedicine(
      name: 'Ibuprofen',
      synonyms: ['ibuprofen', 'advil', 'motrin', 'brufen'],
      defaultStrength: '400 mg',
      defaultDosage: '1 Tablet',
      defaultTiming: 'after_food',
      defaultDuration: '5 days',
    ),
    DatabaseMedicine(
      name: 'Gabapentin',
      synonyms: ['gabapentin', 'neurontin'],
      defaultStrength: '300 mg',
      defaultDosage: '1 Capsule',
      defaultTiming: 'after_food',
      defaultDuration: '15 days',
    ),
    DatabaseMedicine(
      name: 'Albuterol',
      synonyms: ['albuterol', 'ventolin', 'salbutamol'],
      defaultStrength: '90 mcg',
      defaultDosage: '1 Inhalation',
      defaultTiming: 'before_food',
      defaultDuration: '30 days',
    ),
    DatabaseMedicine(
      name: 'Xanax',
      synonyms: ['xanax', 'alprazolam'],
      defaultStrength: '0.5 mg',
      defaultDosage: '1 Tablet',
      defaultTiming: 'before_food',
      defaultDuration: '10 days',
    ),
    DatabaseMedicine(
      name: 'Synthroid',
      synonyms: ['synthroid', 'levothyroxine', 'thyronorm'],
      defaultStrength: '50 mcg',
      defaultDosage: '1 Tablet',
      defaultTiming: 'before_food',
      defaultDuration: '30 days',
    ),
    DatabaseMedicine(
      name: 'Nexium',
      synonyms: ['nexium', 'esomeprazole'],
      defaultStrength: '40 mg',
      defaultDosage: '1 Tablet',
      defaultTiming: 'before_food',
      defaultDuration: '14 days',
    ),
    DatabaseMedicine(
      name: 'Vitamin D3',
      synonyms: ['vitamin d3', 'cholecalciferol', 'd3'],
      defaultStrength: '60000 IU',
      defaultDosage: '1 Capsule',
      defaultTiming: 'after_food',
      defaultDuration: '30 days',
    ),
    DatabaseMedicine(
      name: 'Cetirizine',
      synonyms: ['cetirizine', 'zyrtec', 'okacet'],
      defaultStrength: '10 mg',
      defaultDosage: '1 Tablet',
      defaultTiming: 'after_food',
      defaultDuration: '7 days',
    ),
    DatabaseMedicine(
      name: 'Toothpaste (Oralhealth)',
      synonyms: ['toothpaste', 'toothpaste (oralhealth)', 'oralhealth', 'oralhealth toothpaste'],
      defaultStrength: 'Standard',
      defaultDosage: 'Apply to teeth',
      defaultTiming: 'after_food',
      defaultDuration: 'Continuous',
    )
  ];

  static int _getLevenshteinDistance(String a, String b) {
    List<List<int>> matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        int cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
        matrix[i][j] = min(
          matrix[i - 1][j] + 1, // deletion
          min(
            matrix[i][j - 1] + 1, // insertion
            matrix[i - 1][j - 1] + cost, // substitution
          ),
        );
      }
    }
    return matrix[a.length][b.length];
  }

  static double getSimilarity(String s1, String s2) {
    String str1 = s1.trim().toLowerCase();
    String str2 = s2.trim().toLowerCase();
    int len = max(str1.length, str2.length);
    if (len == 0) return 1.0;
    int dist = _getLevenshteinDistance(str1, str2);
    return 1.0 - (dist / len);
  }

  static MatchResult fuzzyMatchMedicine(String ocrName) {
    String term = ocrName.trim().toLowerCase();
    if (term.isEmpty) {
      return MatchResult(matchedName: '', similarity: 0.0);
    }

    DatabaseMedicine? bestMatch;
    double highestSimilarity = 0.0;

    for (var med in medicineDatabase) {
      // Check exact name match
      if (med.name.toLowerCase() == term) {
        return MatchResult(matchedName: med.name, similarity: 1.0, dbMatch: med);
      }

      // Check similarity of main name
      double nameSim = getSimilarity(med.name, ocrName);
      if (nameSim > highestSimilarity) {
        highestSimilarity = nameSim;
        bestMatch = med;
      }

      // Check synonyms
      for (var syn in med.synonyms) {
        if (syn.toLowerCase() == term) {
          return MatchResult(matchedName: med.name, similarity: 1.0, dbMatch: med);
        }
        double synSim = getSimilarity(syn, ocrName);
        if (synSim > highestSimilarity) {
          highestSimilarity = synSim;
          bestMatch = med;
        }
      }
    }

    // Threshold check: only return matched name if similarity is substantial
    if (highestSimilarity >= 0.60 && bestMatch != null) {
      return MatchResult(
        matchedName: bestMatch.name,
        similarity: highestSimilarity,
        dbMatch: bestMatch,
      );
    }

    return MatchResult(
      matchedName: ocrName, // keep OCR name as fallback
      similarity: highestSimilarity,
    );
  }
}
