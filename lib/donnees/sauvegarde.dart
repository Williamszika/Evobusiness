import 'sauvegarde_io.dart'
    if (dart.library.js_interop) 'sauvegarde_web.dart' as plateforme;

/// Une copie de la boutique déjà écrite.
class CopieSauvegarde {
  const CopieSauvegarde({
    required this.identifiant,
    required this.date,
    required this.taille,
  });

  /// Repère interne : le chemin du fichier sur téléphone.
  final String identifiant;
  final DateTime? date;
  final int taille;

  /// Taille lisible : « 42 Ko ».
  String get tailleLisible {
    if (taille < 1024) return '$taille o';
    if (taille < 1024 * 1024) return '${(taille / 1024).round()} Ko';
    return '${(taille / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  /// « 14/08/2026 à 09h41 ».
  String get quand {
    final d = date;
    if (d == null) return 'Sauvegarde';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year} à '
        '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
  }
}

/// Où l'application dépose ses copies automatiques.
///
/// Sur téléphone, ce sont des fichiers dans le dossier de l'application. Dans
/// la version web, il n'existe pas d'endroit durable pour les poser : le
/// stockage y est déclaré indisponible, et c'est le rappel de mise à l'abri —
/// plus fréquent sur le web — qui protège les données.
abstract class StockSauvegardes {
  /// Nombre de copies conservées. Au-delà, la plus ancienne est effacée.
  static const nombreConserve = 5;

  /// Délai en dessous duquel on ne réécrit pas de copie automatique.
  static const delaiEntreDeux = Duration(hours: 20);

  /// `false` quand la plateforme n'offre aucun endroit où écrire.
  bool get disponible;

  Future<void> preparer();
  Future<List<CopieSauvegarde>> lister();
  Future<CopieSauvegarde?> ecrire(Map<String, dynamic> donnees);
  Future<Map<String, dynamic>> lire(CopieSauvegarde copie);

  /// Vrai si aucune copie n'a été écrite depuis [delaiEntreDeux].
  Future<bool> faudraitSauvegarder();
}

/// Le stock adapté à la plateforme courante.
StockSauvegardes creerStockSauvegardes() => plateforme.creerStock();
