import 'sauvegarde.dart';

StockSauvegardes creerStock() => const StockIndisponible();

/// Dans la version web, aucun endroit n'est assez durable pour y laisser des
/// copies automatiques : le navigateur peut faire le ménage dans son stockage
/// après plusieurs semaines sans usage.
///
/// Plutôt que de donner une fausse impression de sécurité, la version web
/// n'écrit pas de copie locale, et l'application rappelle plus souvent — tous
/// les trois jours — d'enregistrer une sauvegarde hors du navigateur.
class StockIndisponible implements StockSauvegardes {
  const StockIndisponible();

  @override
  bool get disponible => false;

  @override
  Future<void> preparer() async {}

  @override
  Future<List<CopieSauvegarde>> lister() async => const [];

  @override
  Future<CopieSauvegarde?> ecrire(Map<String, dynamic> donnees) async => null;

  @override
  Future<Map<String, dynamic>> lire(CopieSauvegarde copie) async =>
      throw UnsupportedError(
        'La version web ne conserve pas de copies locales.',
      );

  @override
  Future<bool> faudraitSauvegarder() async => false;
}
