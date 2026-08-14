import '../coeur/argent.dart';
import '../donnees/modeles.dart';
import 'boutique.dart';

/// Une période comptable, bornes incluses.
class Periode {
  const Periode({required this.debut, required this.fin, required this.libelle});

  /// Dates ISO `AAAA-MM-JJ`.
  final String debut;
  final String fin;
  final String libelle;

  bool contient(String dateIso) =>
      dateIso.compareTo(debut) >= 0 && dateIso.compareTo(fin) <= 0;

  static String _iso(DateTime d) => Dates.jourIso(d);

  static Periode mois(int annee, int mois) {
    final premier = DateTime(annee, mois, 1);
    final dernier = DateTime(annee, mois + 1, 0);
    const noms = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return Periode(
      debut: _iso(premier),
      fin: _iso(dernier),
      libelle: '${noms[mois - 1]} $annee',
    );
  }

  static Periode trimestre(int annee, int numero) {
    final premierMois = (numero - 1) * 3 + 1;
    return Periode(
      debut: _iso(DateTime(annee, premierMois, 1)),
      fin: _iso(DateTime(annee, premierMois + 3, 0)),
      libelle: '$numeroᵉ trimestre $annee',
    );
  }

  static Periode annee(int annee) => Periode(
        debut: '$annee-01-01',
        fin: '$annee-12-31',
        libelle: 'Année $annee',
      );

  static Periode moisCourant() {
    final d = DateTime.now();
    return mois(d.year, d.month);
  }

  static Periode anneeCourante() => annee(DateTime.now().year);
}

/// Une ligne du livre des recettes.
class LigneRecette {
  const LigneRecette({
    required this.date,
    required this.numero,
    required this.client,
    required this.moyenPaiement,
    required this.montant,
    this.motif,
  });

  final String date;
  final String numero;
  final String client;
  final String moyenPaiement;
  final int montant;
  final String? motif;

  bool get estRemboursement => montant < 0;
}

/// Ce que contient le document remis à l'administration.
class BilanComptable {
  const BilanComptable({
    required this.periode,
    required this.recettes,
    required this.depenses,
    required this.totalRecettes,
    required this.totalDepenses,
    required this.factureSurPeriode,
    required this.creancesEnFinDePeriode,
    required this.depensesParCategorie,
    required this.recettesParMoyen,
    required this.moisParMois,
    required this.nombreVentes,
  });

  final Periode periode;

  /// Encaissements de la période, du plus ancien au plus récent.
  final List<LigneRecette> recettes;
  final List<Depense> depenses;

  /// Somme réellement encaissée : c'est elle qui fait foi.
  final int totalRecettes;
  final int totalDepenses;

  /// Somme des ventes émises sur la période — pour information seulement.
  final int factureSurPeriode;

  /// Ce qui reste dû par les clientes à la fin de la période.
  final int creancesEnFinDePeriode;

  final List<({String categorie, int montant})> depensesParCategorie;
  final List<({String moyen, int montant})> recettesParMoyen;
  final List<({String cle, String libelle, int recettes, int depenses})> moisParMois;
  final int nombreVentes;

  int get resultat => totalRecettes - totalDepenses;
}

/// Calcule le livre de recettes et de dépenses d'une période.
///
/// Règle tenue de bout en bout : **les recettes sont comptées à
/// l'encaissement**, pas à la facturation. C'est la convention des petites
/// entreprises, et celle qui correspond à la réalité de la caisse. Le montant
/// facturé et les créances restent affichés, mais à titre indicatif.
class Comptabilite {
  const Comptabilite._();

  static BilanComptable bilan(EtatBoutique etat, Periode periode) {
    final ventesParId = {for (final v in etat.ventes) v.id: v};

    // Un règlement rattaché à une vente supprimée n'a plus de sens.
    final reglements = etat.reglements
        .where((r) => periode.contient(r.date) && ventesParId.containsKey(r.venteId))
        .toList()
      ..sort((a, b) {
        final parDate = a.date.compareTo(b.date);
        return parDate != 0 ? parDate : a.creeLe.compareTo(b.creeLe);
      });

    final recettes = <LigneRecette>[];
    final parMoyen = <String, int>{};
    for (final r in reglements) {
      final vente = ventesParId[r.venteId]!;
      recettes.add(LigneRecette(
        date: r.date,
        numero: vente.numero,
        client: vente.clientNom,
        moyenPaiement: r.moyenPaiement,
        montant: r.montant,
        motif: r.motif,
      ));
      parMoyen[r.moyenPaiement] = (parMoyen[r.moyenPaiement] ?? 0) + r.montant;
    }

    final depenses = etat.depenses.where((d) => periode.contient(d.date)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final parCategorie = <String, int>{};
    for (final d in depenses) {
      parCategorie[d.categorie] = (parCategorie[d.categorie] ?? 0) + d.montant;
    }

    final ventesPeriode = etat.ventes
        .where((v) => v.compteDansLeCa && periode.contient(v.date))
        .toList();

    // Créances : ce qui reste dû sur toutes les ventes émises jusqu'à la fin
    // de la période, encaissements de la période compris.
    var creances = 0;
    for (final v in etat.ventes) {
      if (!v.compteDansLeCa || v.date.compareTo(periode.fin) > 0) continue;
      final encaisse = etat.reglements
          .where((r) => r.venteId == v.id && r.date.compareTo(periode.fin) <= 0)
          .fold(0, (s, r) => s + r.montant);
      final reste = v.total - encaisse;
      if (reste > 0) creances += reste;
    }

    return BilanComptable(
      periode: periode,
      recettes: recettes,
      depenses: depenses,
      totalRecettes: recettes.fold(0, (s, r) => s + r.montant),
      totalDepenses: depenses.fold(0, (s, d) => s + d.montant),
      factureSurPeriode: ventesPeriode.fold(0, (s, v) => s + v.total),
      creancesEnFinDePeriode: creances,
      depensesParCategorie: (parCategorie.entries
          .map((e) => (categorie: e.key, montant: e.value))
          .toList()
        ..sort((a, b) => b.montant.compareTo(a.montant))),
      recettesParMoyen: (parMoyen.entries
          .map((e) => (moyen: e.key, montant: e.value))
          .toList()
        ..sort((a, b) => b.montant.compareTo(a.montant))),
      moisParMois: _moisParMois(recettes, depenses),
      nombreVentes: ventesPeriode.length,
    );
  }

  static List<({String cle, String libelle, int recettes, int depenses})> _moisParMois(
    List<LigneRecette> recettes,
    List<Depense> depenses,
  ) {
    final cles = <String>{
      ...recettes.map((r) => Dates.cleMois(r.date)),
      ...depenses.map((d) => Dates.cleMois(d.date)),
    }.toList()
      ..sort();

    return [
      for (final cle in cles)
        (
          cle: cle,
          libelle: _libelleMois(cle),
          recettes: recettes
              .where((r) => Dates.cleMois(r.date) == cle)
              .fold(0, (s, r) => s + r.montant),
          depenses: depenses
              .where((d) => Dates.cleMois(d.date) == cle)
              .fold(0, (s, d) => s + d.montant),
        ),
    ];
  }

  static String _libelleMois(String cle) {
    const noms = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    final parties = cle.split('-');
    if (parties.length < 2) return cle;
    final m = int.tryParse(parties[1]);
    if (m == null || m < 1 || m > 12) return cle;
    return '${noms[m - 1]} ${parties[0]}';
  }

  /// Les années où il s'est passé quelque chose, de la plus récente à la plus
  /// ancienne. L'année en cours y figure toujours.
  static List<int> anneesDisponibles(EtatBoutique etat) {
    final annees = <int>{DateTime.now().year};
    for (final v in etat.ventes) {
      final a = int.tryParse(v.date.split('-').first);
      if (a != null) annees.add(a);
    }
    for (final d in etat.depenses) {
      final a = int.tryParse(d.date.split('-').first);
      if (a != null) annees.add(a);
    }
    return annees.toList()..sort((a, b) => b.compareTo(a));
  }
}
