import 'dart:js_interop';

import '../donnees/modeles.dart';
import 'logos.dart';
import 'theme.dart';

@JS('majIconeAccueil')
external JSAny? _majIconeAccueil(JSString svg, JSString nom);

/// Fabrique l'icône à partir du logo et de la palette, et la donne au
/// navigateur.
///
/// La conversion SVG → PNG revient à `web/index.html` : iOS refuse une icône
/// d'écran d'accueil en SVG, et le navigateur sait la rastériser lui-même bien
/// mieux que nous.
void appliquerIcone(Parametres parametres, Palette palette) {
  final svg = logoSvgIcone(
    parametres.logo,
    fond: palette.primaireHex,
    accent: palette.accentHex,
    initiales: initialesDe(parametres.nomBoutique),
  );
  final nom = parametres.estConfiguree ? parametres.nomBoutique : 'Ma Boutique';
  try {
    _majIconeAccueil(svg.toJS, nom.toJS);
  } catch (_) {
    // Une icône ratée ne doit jamais empêcher d'ouvrir la boutique.
  }
}
