// Crowd scores per office > day > time slot index
// Time slots: [8h, 9h, 10h, 11h, 14h, 15h]

const Map<String, Map<String, List<int>>> crowdData = {
  'CNSS Tunis': {
    'Lundi':    [90, 85, 70, 60, 80, 75],
    'Mardi':    [40, 35, 30, 45, 30, 35],
    'Mercredi': [75, 80, 85, 70, 65, 70],
    'Jeudi':    [50, 45, 40, 55, 45, 50],
    'Vendredi': [95, 90, 85, 80, 90, 85],
  },
  'CNAM Tunis': {
    'Lundi':    [80, 75, 65, 55, 70, 65],
    'Mardi':    [35, 30, 25, 40, 30, 30],
    'Mercredi': [70, 75, 80, 65, 60, 65],
    'Jeudi':    [45, 40, 35, 50, 40, 45],
    'Vendredi': [90, 85, 80, 75, 85, 80],
  },
  'Municipalité Tunis': {
    'Lundi':    [85, 80, 72, 60, 75, 70],
    'Mardi':    [45, 38, 32, 48, 35, 38],
    'Mercredi': [68, 72, 78, 65, 60, 63],
    'Jeudi':    [52, 47, 42, 55, 48, 50],
    'Vendredi': [92, 88, 82, 78, 88, 84],
  },
};

// Procedure multipliers — some procedures are busier on certain days
const Map<String, Map<String, double>> procedureWeights = {
  'Renouvellement CIN': {
    'Lundi': 1.4, 'Mardi': 0.8, 'Mercredi': 1.1,
    'Jeudi': 0.9, 'Vendredi': 1.5,
  },
  'Attestation CNSS': {
    'Lundi': 1.2, 'Mardi': 0.9, 'Mercredi': 1.0,
    'Jeudi': 1.0, 'Vendredi': 1.3,
  },
  'Extrait de naissance': {
    'Lundi': 1.1, 'Mardi': 0.85, 'Mercredi': 1.0,
    'Jeudi': 0.95, 'Vendredi': 1.2,
  },
};

const List<String> timeSlotLabels = ['8h', '9h', '10h', '11h', '14h', '15h'];
const List<String> days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'];
