import '../coeur/argent.dart';
import '../donnees/modeles.dart';
import 'boutique.dart';

/// Tous les chiffres affichés par le tableau de bord et les rapports.
/// Les ventes annulées sont exclues partout.
class Indicateurs {
  const Indicateurs._();

  static Iterable<Vente> _valides(EtatBoutique e) =>
      e.ventes.where((v) => v.compteDansLeCa);

  static Iterable<Vente> entre(EtatBoutique e, String debut, String fin) =>
      _valides(e).where((v) => v.date.compareTo(debut) >= 0 && v.date.compareTo(fin) <= 0);

  static Iterable<Depense> depensesEntre(EtatBoutique e, String debut, String fin) =>
      e.depenses.where((d) => d.date.compareTo(debut) >= 0 && d.date.compareTo(fin) <= 0);

  // ─────────────────────────────────────────────────────────────── totaux

  static int chiffreAffaires(Iterable<Vente> ventes) =>
      ventes.fold(0, (s, v) => s + v.total);

  /// Ce qui est réellement rentré en caisse (hors crédits non soldés).
  static int encaisse(Iterable<Vente> ventes) =>
      ventes.fold(0, (s, v) => s + v.montantPaye);

  static int margeBrute(Iterable<Vente> ventes) =>
      ventes.fold(0, (s, v) => s + v.marge);

  static int totalDepenses(Iterable<Depense> depenses) =>
      depenses.fold(0, (s, d) => s + d.montant);

  /// Bénéfice net = marge sur les ventes − dépenses de la période.
  ///
  /// Attention : si les achats de marchandise sont saisis en dépenses **et**
  /// comptés dans le prix d'achat des articles, le stock non encore vendu
  /// pèse deux fois. C'est volontaire et prudent — mieux vaut un bénéfice
  /// annoncé trop bas que trop haut.
  static int beneficeNet(Iterable<Vente> ventes, Iterable<Depense> depenses) =>
      margeBrute(ventes) - totalDepenses(depenses);

  static int panierMoyen(Iterable<Vente> ventes) {
    final liste = ventes.toList();
    if (liste.isEmpty) return 0;
    return chiffreAffaires(liste) ~/ liste.length;
  }

  // ─────────────────────────────────────────────────────────── raccourcis

  static Iterable<Vente> duJour(EtatBoutique e) {
    final jour = Dates.aujourdhui();
    return _valides(e).where((v) => v.date == jour);
  }

  static Iterable<Vente> duMois(EtatBoutique e) {
    final mois = Dates.cleMois(Dates.aujourdhui());
    return _valides(e).where((v) => Dates.cleMois(v.date) == mois);
  }

  static Iterable<Depense> depensesDuMois(EtatBoutique e) {
    final mois = Dates.cleMois(Dates.aujourdhui());
    return e.depenses.where((d) => Dates.cleMois(d.date) == mois);
  }

  /// Progression vers l'objectif mensuel, entre 0 et 1.
  static double progressionObjectif(EtatBoutique e) {
    final objectif = e.parametres.objectifMensuel;
    if (objectif <= 0) return 0;
    final ratio = chiffreAffaires(duMois(e)) / objectif;
    return ratio.clamp(0, 1).toDouble();
  }

  static int valeurStock(EtatBoutique e) =>
      e.produits.where((p) => !p.estService).fold(0, (s, p) => s + p.valeurStock);

  static int articlesEnStock(EtatBoutique e) =>
      e.produits.where((p) => !p.estService).fold(0, (s, p) => s + p.stock);

  static int totalImpayes(EtatBoutique e) =>
      e.impayes.fold(0, (s, v) => s + v.reste);

  // ─────────────────────────────────────────────────────── séries & classements

  /// Chiffre d'affaires mois par mois, du plus ancien au plus récent.
  static List<(String cle, int montant)> serieMensuelle(
    EtatBoutique e, {
    int nombreDeMois = 6,
  }) {
    final maintenant = DateTime.now();
    final resultat = <(String, int)>[];
    for (var i = nombreDeMois - 1; i >= 0; i--) {
      final m = DateTime(maintenant.year, maintenant.month - i, 1);
      final cle = '${m.year.toString().padLeft(4, '0')}-'
          '${m.month.toString().padLeft(2, '0')}';
      final montant = _valides(e)
          .where((v) => Dates.cleMois(v.date) == cle)
          .fold(0, (s, v) => s + v.total);
      resultat.add((cle, montant));
    }
    return resultat;
  }

  /// Articles classés par bénéfice généré — pas par quantité vendue.
  static List<ClassementProduit> meilleursProduits(
    EtatBoutique e,
    Iterable<Vente> ventes, {
    int limite = 8,
  }) {
    final parProduit = <String, ClassementProduit>{};
    for (final vente in ventes) {
      for (final ligne in vente.lignes) {
        final entree = parProduit.putIfAbsent(
          ligne.produitId,
          () => ClassementProduit(
            produitId: ligne.produitId,
            designation: ligne.designation,
          ),
        );
        entree.quantite += ligne.quantite;
        entree.chiffre += ligne.total;
        entree.marge += ligne.total - ligne.cout;
      }
    }
    final liste = parProduit.values.toList()
      ..sort((a, b) => b.marge.compareTo(a.marge));
    return liste.take(limite).toList();
  }

  /// Clientes classées par chiffre d'affaires.
  static List<ClassementClient> meilleuresClientes(
    EtatBoutique e,
    Iterable<Vente> ventes, {
    int limite = 8,
  }) {
    final parClient = <String, ClassementClient>{};
    for (final vente in ventes) {
      final cle = vente.clientId ?? 'passage';
      final entree = parClient.putIfAbsent(
        cle,
        () => ClassementClient(clientId: vente.clientId, nom: vente.clientNom),
      );
      entree.commandes += 1;
      entree.chiffre += vente.total;
      entree.reste += vente.reste;
    }
    final liste = parClient.values.toList()
      ..sort((a, b) => b.chiffre.compareTo(a.chiffre));
    return liste.take(limite).toList();
  }

  /// Répartition du chiffre d'affaires par canal de vente.
  static List<(String canal, int montant, double part)> parCanal(
    Iterable<Vente> ventes,
  ) {
    final total = chiffreAffaires(ventes);
    final parCle = <String, int>{};
    for (final v in ventes) {
      parCle[v.canal] = (parCle[v.canal] ?? 0) + v.total;
    }
    final liste = parCle.entries
        .map((e) => (e.key, e.value, total == 0 ? 0.0 : e.value / total))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return liste;
  }

  /// Total dépensé par une cliente, et son solde restant dû.
  static (int total, int commandes, int reste) bilanClient(
    EtatBoutique e,
    String clientId,
  ) {
    final ventes = e.ventesDe(clientId).where((v) => v.compteDansLeCa);
    return (
      ventes.fold(0, (s, v) => s + v.total),
      ventes.length,
      ventes.fold(0, (s, v) => s + v.reste),
    );
  }

  /// Quantité vendue d'un article sur les `jours` derniers jours.
  static int venduSur(EtatBoutique e, String produitId, {int jours = 30}) {
    final debut = Dates.ilYaJours(jours);
    var total = 0;
    for (final vente in _valides(e)) {
      if (vente.date.compareTo(debut) < 0) continue;
      for (final ligne in vente.lignes) {
        if (ligne.produitId == produitId) total += ligne.quantite;
      }
    }
    return total;
  }

  static List<MouvementStock> mouvementsDe(EtatBoutique e, String produitId) =>
      e.mouvements.where((m) => m.produitId == produitId).toList();
}

class ClassementProduit {
  ClassementProduit({required this.produitId, required this.designation});
  final String produitId;
  final String designation;
  int quantite = 0;
  int chiffre = 0;
  int marge = 0;
}

class ClassementClient {
  ClassementClient({required this.clientId, required this.nom});
  final String? clientId;
  final String nom;
  int commandes = 0;
  int chiffre = 0;
  int reste = 0;
}
