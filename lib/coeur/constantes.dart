/// Listes de référence du métier : elles alimentent tous les menus déroulants
/// de l'application (catalogue, vente, dépenses).
library;

const categories = <String>[
  'Mèches',
  'Perruques',
  'Closure / Frontal',
  'Accessoires',
  'Soins & Entretien',
  'Service (pose, coiffure)',
  'Autre',
];

const textures = <String>[
  'Lisse (Straight)',
  'Ondulé (Body wave)',
  'Bouclé (Curly)',
  'Deep wave',
  'Water wave',
  'Kinky straight',
  'Kinky curly',
  'Afro',
  'Loose wave',
  'Bone straight',
];

const origines = <String>[
  'Brésilien',
  'Péruvien',
  'Indien',
  'Malaisien',
  'Vietnamien',
  'Cambodgien',
  'Naturel africain',
  'Synthétique',
  'Mix',
];

const longueurs = <String>[
  '8"', '10"', '12"', '14"', '16"', '18"',
  '20"', '22"', '24"', '26"', '28"', '30"', '32"',
];

const couleurs = <String>[
  'Naturel 1B',
  'Noir Jet 1',
  'Brun 2',
  'Brun 4',
  'Miel 27',
  'Blond 613',
  'Ombré 1B/27',
  'Ombré 1B/30',
  'Rouge 99J',
  'Gris',
  'Coloré (autre)',
];

const densites = <String>['130%', '150%', '180%', '200%', '250%'];

const moyensPaiement = <String>[
  'Espèces',
  'Mobile Money',
  'Virement bancaire',
  'Carte bancaire',
  'PayPal',
  'Autre',
];

const canaux = <String>[
  'Boutique',
  'WhatsApp',
  'Instagram',
  'Facebook',
  'TikTok',
  'Bouche à oreille',
  'Autre',
];

const categoriesDepense = <String>[
  'Achat de marchandise',
  'Transport / Fret',
  'Douane / Taxes',
  'Publicité / Marketing',
  'Loyer',
  'Salaire',
  'Emballage',
  'Frais bancaires',
  'Autre',
];

/// Devises courantes, avec le nombre de décimales à afficher.
/// Le franc CFA et le naira s'écrivent sans centimes.
const devises = <String, int>{
  'FCFA': 0,
  'XOF': 0,
  'XAF': 0,
  'GNF': 0,
  'CDF': 0,
  'RWF': 0,
  'NGN': 0,
  'GHS': 2,
  'MAD': 2,
  'DZD': 2,
  'TND': 2,
  '€': 2,
  '\$': 2,
  '£': 2,
  'CHF': 2,
  'CAD': 2,
};

// Statuts de vente
const statutPayee = 'Payée';
const statutPartielle = 'Partielle';
const statutImpayee = 'Impayée';
const statutAnnulee = 'Annulée';

// Types de mouvement de stock
const mvtEntree = 'Entrée';
const mvtVente = 'Vente';
const mvtRetour = 'Retour';
const mvtPerte = 'Perte';
const mvtAjustement = 'Ajustement';
