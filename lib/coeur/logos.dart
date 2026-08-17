/// Les huit pistes de logo proposées, dessinées en SVG.
///
/// Le même texte SVG sert à l'écran (`flutter_svg`) et sur le reçu imprimé
/// (`pdf`), ce qui garantit un logo identique partout. Le monogramme est le
/// seul cas particulier : sa lettre est ajoutée par-dessus le dessin, car le
/// texte SVG ne se rend pas de façon fiable dans un PDF.
library;

class PisteLogo {
  const PisteLogo(this.cle, this.nom, this.pour);
  final String cle;
  final String nom;
  final String pour;
}

const pistesLogo = <PisteLogo>[
  PisteLogo('couronne', 'La Couronne', 'Belle Couronne, Reine d\'Ébène'),
  PisteLogo('monogramme', 'Le Monogramme', 'Zuri, Nyla, Maison Kora'),
  PisteLogo('boucle', 'La Boucle', 'Lova, Glow Hair Bar'),
  PisteLogo('cascade', 'La Cascade', 'Nyla, L\'Atelier des Mèches'),
  PisteLogo('tresse', 'La Tresse', 'Tresse & Toi, Racines & Reines'),
  PisteLogo('peigne', 'Le Peigne', 'Racines & Reines, Fille de Reine'),
  PisteLogo('arche', 'L\'Arche', 'Maison Kora, Perruque Prestige'),
  PisteLogo('miroir', 'Le Miroir', 'Mèches & Merveilles, Slay Studio'),
];

/// `true` si cette piste attend les initiales de la boutique par-dessus.
bool logoPorteInitiales(String cle) => cle == 'monogramme';

/// Retourne le SVG d'une piste, colorié avec les deux couleurs de la marque.
String logoSvg(String cle, {required String primaire, required String accent}) {
  final corps = switch (cle) {
    'monogramme' => '''
  <circle cx="48" cy="48" r="44" fill="$primaire"/>
  <circle cx="48" cy="48" r="37" fill="none" stroke="$accent" stroke-width="1.6"/>''',
    'boucle' => '''
  <path d="M20 78 C20 44 38 22 60 22 C76 22 86 33 86 47 C86 60 76 69 64 69 C55 69 48 62 48 54 C48 47 53 42 59 42"
        fill="none" stroke="$primaire" stroke-width="9" stroke-linecap="round"/>
  <circle cx="59" cy="42" r="6" fill="$accent"/>''',
    'cascade' => '''
  <path d="M16 80 C16 46 28 20 46 14" fill="none" stroke="$primaire" stroke-width="8" stroke-linecap="round"/>
  <path d="M36 82 C36 48 48 22 66 16" fill="none" stroke="$accent" stroke-width="8" stroke-linecap="round"/>
  <path d="M56 84 C56 50 68 24 86 18" fill="none" stroke="$primaire" stroke-width="8" stroke-linecap="round"/>''',
    'tresse' => '''
  <path d="M34 12 C34 28 62 32 62 48 C62 64 34 68 34 82" fill="none" stroke="$primaire" stroke-width="9" stroke-linecap="round"/>
  <path d="M62 12 C62 28 34 32 34 48 C34 64 62 68 62 82" fill="none" stroke="$accent" stroke-width="9" stroke-linecap="round"/>
  <rect x="36" y="80" width="24" height="9" rx="4.5" fill="$accent"/>''',
    'peigne' => '''
  <rect x="18" y="14" width="7" height="34" rx="3.5" fill="$primaire"/>
  <rect x="32" y="14" width="7" height="34" rx="3.5" fill="$primaire"/>
  <rect x="46" y="14" width="7" height="34" rx="3.5" fill="$primaire"/>
  <rect x="60" y="14" width="7" height="34" rx="3.5" fill="$primaire"/>
  <rect x="74" y="14" width="7" height="34" rx="3.5" fill="$primaire"/>
  <rect x="14" y="44" width="71" height="10" rx="5" fill="$primaire"/>
  <rect x="44" y="54" width="11" height="26" rx="5" fill="$primaire"/>
  <circle cx="49.5" cy="82" r="8" fill="$accent"/>''',
    'arche' => '''
  <path d="M18 84 L18 46 A30 30 0 0 1 78 46 L78 84" fill="none" stroke="$primaire"
        stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M38 48 C44 56 32 62 38 72" fill="none" stroke="$accent" stroke-width="7" stroke-linecap="round"/>
  <path d="M58 48 C64 56 52 62 58 72" fill="none" stroke="$accent" stroke-width="7" stroke-linecap="round"/>''',
    'miroir' => '''
  <circle cx="48" cy="38" r="27" fill="none" stroke="$primaire" stroke-width="8"/>
  <circle cx="48" cy="38" r="15" fill="$accent"/>
  <rect x="42" y="63" width="12" height="26" rx="6" fill="$primaire"/>''',
    _ => '''
  <path d="M14 68 L20 30 C24 40 30 46 34 46 C40 46 42 22 48 22 C54 22 56 46 62 46 C66 46 72 40 76 30 L82 68 Z" fill="$primaire"/>
  <rect x="14" y="71" width="68" height="9" rx="4.5" fill="$primaire"/>
  <circle cx="48" cy="18" r="4.5" fill="$accent"/>
  <circle cx="20" cy="26" r="3.5" fill="$accent"/>
  <circle cx="76" cy="26" r="3.5" fill="$accent"/>''',
  };

  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96">\n$corps\n</svg>';
}

/// Le même logo, mais en **icône carrée pleine** : dessin blanc sur le fond de
/// la marque, comme l'exige une icône d'écran d'accueil.
///
/// Deux contraintes d'Apple sont respectées ici : aucune transparence — le
/// fond est un carré plein — et aucun coin arrondi, iOS applique son propre
/// masque. Le logo n'occupe que 62 % du carré, parce que ce masque rogne.
///
/// Les initiales sont dessinées en SVG plutôt que superposées comme à l'écran :
/// une icône doit tenir en un seul fichier.
String logoSvgIcone(
  String cle, {
  required String fond,
  required String accent,
  String initiales = '',
  int taille = 180,
}) {
  final corps = logoSvg(cle, primaire: '#FFFFFF', accent: accent)
      .replaceFirst('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96">', '')
      .replaceFirst('</svg>', '')
      .trim();

  // 62 % de 96, centré : le dessin va de 18,24 à 77,76 dans le carré.
  const marge = 18.24;
  const cote = 59.52;
  final lettres = logoPorteInitiales(cle) && initiales.isNotEmpty
      ? '<text x="48" y="48" text-anchor="middle" dominant-baseline="central" '
          'font-family="Georgia, serif" font-weight="700" font-size="20" '
          'fill="$fond">$initiales</text>'
      : '';

  return '<svg xmlns="http://www.w3.org/2000/svg" width="$taille" height="$taille" '
      'viewBox="0 0 96 96">'
      '<rect width="96" height="96" fill="$fond"/>'
      '<svg x="$marge" y="$marge" width="$cote" height="$cote" viewBox="0 0 96 96">'
      '$corps$lettres'
      '</svg>'
      '</svg>';
}

/// Initiales de la boutique, pour le monogramme (« Belle Couronne » → « BC »).
///
/// Sur une boutique pas encore nommée — l'écran de première ouverture, avant
/// la première frappe — on ne renvoie rien : afficher les initiales d'une
/// enseigne inventée donnerait à croire qu'elle est déjà la sienne.
String initialesDe(String nom) {
  final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
  if (mots.isEmpty) return '';
  return mots.take(2).map((m) => m[0].toUpperCase()).join();
}
