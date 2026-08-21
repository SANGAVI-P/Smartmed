export interface DatabaseMedicine {
  name: string;
  synonyms: string[];
  defaultStrength: string;
  defaultDosage: string;
  defaultTiming: 'before_food' | 'after_food';
  defaultDuration: string;
}

export const MEDICINE_DATABASE: DatabaseMedicine[] = [
  {
    name: 'Paracetamol',
    synonyms: ['acetaminophen', 'panadol', 'paracitamol', 'pyregesic', 'calpol', 'para', 'paracetol'],
    defaultStrength: '500 mg',
    defaultDosage: '1 Tablet',
    defaultTiming: 'after_food',
    defaultDuration: '5 days'
  },
  {
    name: 'Disprin',
    synonyms: ['aspirin', 'acetylsalicylic acid', 'disprin', 'dispirin'],
    defaultStrength: '325 mg',
    defaultDosage: '1 Tablet',
    defaultTiming: 'after_food',
    defaultDuration: '3 days'
  },
  {
    name: 'Loperamide',
    synonyms: ['lopramide', 'imodium', 'loperamide hydrochloride'],
    defaultStrength: '2 mg',
    defaultDosage: '1 Capsule',
    defaultTiming: 'before_food',
    defaultDuration: '2 days'
  },
  {
    name: 'Lisinopril',
    synonyms: ['lisinopril', 'zestril', 'prinivil'],
    defaultStrength: '10 mg',
    defaultDosage: '1 Tablet',
    defaultTiming: 'after_food',
    defaultDuration: '30 days'
  },
  {
    name: 'Metformin',
    synonyms: ['metformin', 'glucophage', 'metformin hydrochloride'],
    defaultStrength: '500 mg',
    defaultDosage: '1 Tablet',
    defaultTiming: 'after_food',
    defaultDuration: '60 days'
  },
  {
    name: 'Atorvastatin',
    synonyms: ['atorvastatin', 'lipitor', 'atorva'],
    defaultStrength: '20 mg',
    defaultDosage: '1 Tablet',
    defaultTiming: 'before_food',
    defaultDuration: '30 days'
  },
  {
    name: 'Eliquis',
    synonyms: ['eliquis', 'apixaban'],
    defaultStrength: '5 mg',
    defaultDosage: '1 Tablet',
    defaultTiming: 'after_food',
    defaultDuration: '30 days'
  },
  {
    name: 'Amoxicillin',
    synonyms: ['amoxicillin', 'amoxil', 'amoxycillin', 'amox'],
    defaultStrength: '500 mg',
    defaultDosage: '1 Capsule',
    defaultTiming: 'after_food',
    defaultDuration: '7 days'
  },
  {
    name: 'Ibuprofen',
    synonyms: ['ibuprofen', 'advil', 'motrin', 'brufen'],
    defaultStrength: '400 mg',
    defaultDosage: '1 Tablet',
    defaultTiming: 'after_food',
    defaultDuration: '5 days'
  },
  {
    name: 'Gabapentin',
    synonyms: ['gabapentin', 'neurontin'],
    defaultStrength: '300 mg',
    defaultDosage: '1 Capsule',
    defaultTiming: 'after_food',
    defaultDuration: '15 days'
  },
  {
    name: 'Albuterol',
    synonyms: ['albuterol', 'ventolin', 'salbutamol'],
    defaultStrength: '90 mcg',
    defaultDosage: '1 Inhalation',
    defaultTiming: 'before_food',
    defaultDuration: '30 days'
  },
  {
    name: 'Xanax',
    synonyms: ['xanax', 'alprazolam'],
    defaultStrength: '0.5 mg',
    defaultDosage: '1 Tablet',
    defaultTiming: 'before_food',
    defaultDuration: '10 days'
  },
  {
    name: 'Synthroid',
    synonyms: ['synthroid', 'levothyroxine', 'thyronorm'],
    defaultStrength: '50 mcg',
    defaultDosage: '1 Tablet',
    defaultTiming: 'before_food',
    defaultDuration: '30 days'
  },
  {
    name: 'Nexium',
    synonyms: ['nexium', 'esomeprazole'],
    defaultStrength: '40 mg',
    defaultDosage: '1 Tablet',
    defaultTiming: 'before_food',
    defaultDuration: '14 days'
  },
  {
    name: 'Vitamin D3',
    synonyms: ['vitamin d3', 'cholecalciferol', 'd3'],
    defaultStrength: '60000 IU',
    defaultDosage: '1 Capsule',
    defaultTiming: 'after_food',
    defaultDuration: '30 days'
  },
  {
    name: 'Cetirizine',
    synonyms: ['cetirizine', 'zyrtec', 'okacet'],
    defaultStrength: '10 mg',
    defaultDosage: '1 Tablet',
    defaultTiming: 'after_food',
    defaultDuration: '7 days'
  },
  {
    name: 'Toothpaste (Oralhealth)',
    synonyms: ['toothpaste', 'toothpaste (oralhealth)', 'oralhealth', 'oralhealth toothpaste'],
    defaultStrength: 'Standard',
    defaultDosage: 'Apply to teeth',
    defaultTiming: 'after_food',
    defaultDuration: 'Continuous'
  }
];

function getLevenshteinDistance(a: string, b: string): number {
  const matrix = Array.from({ length: a.length + 1 }, () =>
    Array(b.length + 1).fill(0)
  );

  for (let i = 0; i <= a.length; i++) matrix[i][0] = i;
  for (let j = 0; j <= b.length; j++) matrix[0][j] = j;

  for (let i = 1; i <= a.length; i++) {
    for (let j = 1; j <= b.length; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      matrix[i][j] = Math.min(
        matrix[i - 1][j] + 1, // deletion
        matrix[i][j - 1] + 1, // insertion
        matrix[i - 1][j - 1] + cost // substitution
      );
    }
  }
  return matrix[a.length][b.length];
}

export function getSimilarity(s1: string, s2: string): number {
  const str1 = s1.trim().toLowerCase();
  const str2 = s2.trim().toLowerCase();
  const len = Math.max(str1.length, str2.length);
  if (len === 0) return 1.0;
  const dist = getLevenshteinDistance(str1, str2);
  return 1.0 - dist / len;
}

export interface MatchResult {
  matchedName: string;
  similarity: number;
  dbMatch: DatabaseMedicine | null;
}

export function fuzzyMatchMedicine(ocrName: string): MatchResult {
  const term = ocrName.trim().toLowerCase();
  if (!term) {
    return { matchedName: '', similarity: 0, dbMatch: null };
  }

  let bestMatch: DatabaseMedicine | null = null;
  let highestSimilarity = 0;

  for (const med of MEDICINE_DATABASE) {
    // Check exact name match
    if (med.name.toLowerCase() === term) {
      return { matchedName: med.name, similarity: 1.0, dbMatch: med };
    }

    // Check similarity of main name
    const nameSim = getSimilarity(med.name, ocrName);
    if (nameSim > highestSimilarity) {
      highestSimilarity = nameSim;
      bestMatch = med;
    }

    // Check synonyms
    for (const syn of med.synonyms) {
      if (syn.toLowerCase() === term) {
        return { matchedName: med.name, similarity: 1.0, dbMatch: med };
      }
      const synSim = getSimilarity(syn, ocrName);
      if (synSim > highestSimilarity) {
        highestSimilarity = synSim;
        bestMatch = med;
      }
    }
  }

  // Threshold check: only return matched name if similarity is substantial
  if (highestSimilarity >= 0.60 && bestMatch) {
    return {
      matchedName: bestMatch.name,
      similarity: highestSimilarity,
      dbMatch: bestMatch
    };
  }

  return {
    matchedName: ocrName, // keep OCR name as fallback
    similarity: highestSimilarity,
    dbMatch: null
  };
}
