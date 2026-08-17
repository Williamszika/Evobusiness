import '../donnees/modeles.dart';
import 'theme.dart';
import 'icone_appareil_io.dart'
    if (dart.library.js_interop) 'icone_appareil_web.dart';

/// Met l'icône d'écran d'accueil en accord avec le logo choisi.
///
/// Sans cela, la boutique porterait sur le téléphone l'icône livrée avec
/// l'application — une couronne — quel que soit le logo retenu. Une vendeuse
/// qui choisit « La Boucle » verrait une couronne sur son écran d'accueil.
///
/// Sur iPhone, l'icône est lue **au moment** où l'on fait « Sur l'écran
/// d'accueil ». Il suffit donc que la page porte la bonne au bon moment ;
/// c'est ce que fait cette fonction à chaque changement de marque.
///
/// N'a d'effet que dans le navigateur : une application installée porte
/// l'icône décidée à la compilation.
void majIconeAppareil(Parametres parametres) {
  final palette = paletteParCle(parametres.palette);
  appliquerIcone(parametres, palette);
}
