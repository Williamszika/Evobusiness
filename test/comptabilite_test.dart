import 'package:evobusiness/coeur/argent.dart';
import 'package:evobusiness/coeur/constantes.dart';
import 'package:evobusiness/donnees/depot.dart';
import 'package:evobusiness/donnees/modeles.dart';
import 'package:evobusiness/ecrans/comptabilite/document_comptable.dart';
import 'package:evobusiness/etat/boutique.dart';
import 'package:evobusiness/etat/comptabilite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// La comptabilité produit un document remis à l'administration : chaque
/// chiffre doit être défendable. Ces tests portent sur la règle centrale —
/// **les recettes se comptent à l'encaissement, pas à la facturation**.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('fr_FR');
  });

  late BoutiqueNotifier boutique;
  late Produit article;

  setUp(() async {
    boutique = BoutiqueNotifier();
    final depot = await Depot.ouvrir(cheminForce: inMemoryDatabasePath);
    await boutique.demarrer(depotForce: depot);
    await boutique.viderDonnees();
    article = await boutique.ajouterProduit(
      Produit(
        id: nouvelId('prod'),
        reference: 'ART-001',
        nom: 'Perruque Lace Frontal',
        categorie: 'Perruques',
        prixAchat: 6500000,
        prixVente: 11000000,
        stock: 20,
        seuilAlerte: 2,
        creeLe: DateTime.now().toIso8601String(),
      ),
    );
  });

  tearDown(() => boutique.dispose());

  LigneVente ligne(int quantite) => LigneVente(
        id: nouvelId('lig'),
        venteId: '',
        produitId: article.id,
        designation: article.nom,
        prixUnitaire: article.prixVente,
        coutUnitaire: article.prixAchat,
        quantite: quantite,
      );

  Future<Vente> vendre({
    required String date,
    required int paye,
    int quantite = 1,
    String moyen = 'Espèces',
  }) =>
      boutique.enregistrerVente(
        lignes: [ligne(quantite)],
        clientNom: 'Aïcha',
        moyenPaiement: moyen,
        canal: 'Boutique',
        montantPaye: paye,
        date: date,
      );

  group('Invariant du modèle', () {
    // Ce qui a manqué au jeu de démonstration : ses ventes étaient payées mais
    // sans règlement, et la comptabilité affichait donc zéro recette.
    test('la démonstration installe les règlements de ses ventes', () async {
      await boutique.reinstallerDemo();

      final encaisseSurVentes = boutique.state.ventes
          .where((v) => v.compteDansLeCa)
          .fold(0, (s, v) => s + v.montantPaye);
      final sommeReglements =
          boutique.state.reglements.fold(0, (s, r) => s + r.montant);

      expect(encaisseSurVentes, greaterThan(0),
          reason: 'la démonstration contient des ventes payées');
      expect(sommeReglements, encaisseSurVentes,
          reason: 'chaque franc encaissé doit être daté dans le registre');

      final annee = Comptabilite.bilan(
        boutique.state,
        Periode.annee(DateTime.now().year),
      );
      expect(annee.totalRecettes, encaisseSurVentes);
    });
  });

  group('Recettes comptées à l\'encaissement', () {
    test('une vente payée comptant tombe dans son mois', () async {
      await vendre(date: '2026-03-10', paye: 11000000);

      final mars = Comptabilite.bilan(boutique.state, Periode.mois(2026, 3));
      final avril = Comptabilite.bilan(boutique.state, Periode.mois(2026, 4));

      expect(mars.totalRecettes, 11000000);
      expect(avril.totalRecettes, 0);
    });

    test('un acompte et son solde tombent dans deux mois différents', () async {
      final vente = await vendre(date: '2026-01-20', paye: 4000000);
      await boutique.encaisserSolde(vente.id, 7000000, date: '2026-03-05');

      final janvier = Comptabilite.bilan(boutique.state, Periode.mois(2026, 1));
      final mars = Comptabilite.bilan(boutique.state, Periode.mois(2026, 3));

      expect(janvier.totalRecettes, 4000000,
          reason: 'seul l\'acompte est encaissé en janvier');
      expect(mars.totalRecettes, 7000000, reason: 'le solde est une recette de mars');

      // La vente entière, elle, a bien été facturée en janvier.
      expect(janvier.factureSurPeriode, 11000000);
      expect(mars.factureSurPeriode, 0);
    });

    test('les créances de fin de période reflètent ce qui reste dû', () async {
      final vente = await vendre(date: '2026-01-20', paye: 4000000);

      final janvier = Comptabilite.bilan(boutique.state, Periode.mois(2026, 1));
      expect(janvier.creancesEnFinDePeriode, 7000000);

      await boutique.encaisserSolde(vente.id, 7000000, date: '2026-03-05');

      // Vue depuis janvier, la dette existait toujours à l'époque…
      final janvierRevu = Comptabilite.bilan(boutique.state, Periode.mois(2026, 1));
      expect(janvierRevu.creancesEnFinDePeriode, 7000000);
      // …mais elle est soldée fin mars.
      final mars = Comptabilite.bilan(boutique.state, Periode.mois(2026, 3));
      expect(mars.creancesEnFinDePeriode, 0);
    });

    test('une vente impayée n\'est pas une recette', () async {
      await vendre(date: '2026-05-02', paye: 0);
      final mai = Comptabilite.bilan(boutique.state, Periode.mois(2026, 5));
      expect(mai.totalRecettes, 0);
      expect(mai.factureSurPeriode, 11000000);
      expect(mai.creancesEnFinDePeriode, 11000000);
    });
  });

  group('Annulation et remboursement', () {
    test('le remboursement est une écriture négative, la recette passée reste',
        () async {
      final vente = await vendre(date: '2026-02-10', paye: 11000000);
      final fevrier = Comptabilite.bilan(boutique.state, Periode.mois(2026, 2));
      expect(fevrier.totalRecettes, 11000000);

      await boutique.annulerVente(vente.id);

      // Février n'est pas réécrit : l'argent avait bien été encaissé.
      final fevrierApres = Comptabilite.bilan(boutique.state, Periode.mois(2026, 2));
      expect(fevrierApres.totalRecettes, 11000000);

      // Le remboursement figure au jour où il a lieu.
      final aujourdhui = Comptabilite.bilan(
        boutique.state,
        Periode.mois(DateTime.now().year, DateTime.now().month),
      );
      expect(aujourdhui.totalRecettes, -11000000);
      expect(aujourdhui.recettes.single.estRemboursement, isTrue);
    });

    test('sur l\'année entière, une vente annulée s\'annule à zéro', () async {
      final annee = DateTime.now().year;
      final vente = await vendre(date: '$annee-02-10', paye: 11000000);
      await boutique.annulerVente(vente.id);

      final bilan = Comptabilite.bilan(boutique.state, Periode.annee(annee));
      expect(bilan.totalRecettes, 0);
    });
  });

  group('Résultat', () {
    test('recettes encaissées moins dépenses payées', () async {
      await vendre(date: '2026-04-05', paye: 11000000);
      await boutique.ajouterDepense(
        Depense(
          id: nouvelId('dep'),
          date: '2026-04-12',
          categorie: 'Achat de marchandise',
          libelle: 'Commande perruques',
          montant: 6500000,
          moyenPaiement: 'Virement bancaire',
          creeLe: DateTime.now().toIso8601String(),
        ),
      );

      final avril = Comptabilite.bilan(boutique.state, Periode.mois(2026, 4));
      expect(avril.totalRecettes, 11000000);
      expect(avril.totalDepenses, 6500000);
      expect(avril.resultat, 4500000);
      expect(avril.depensesParCategorie.single.categorie, 'Achat de marchandise');
    });

    test('les recettes sont ventilées par mode de paiement', () async {
      await vendre(date: '2026-06-01', paye: 11000000, moyen: 'Mobile Money');
      await vendre(date: '2026-06-08', paye: 11000000, moyen: 'Espèces');
      await vendre(date: '2026-06-15', paye: 11000000, moyen: 'Mobile Money');

      final juin = Comptabilite.bilan(boutique.state, Periode.mois(2026, 6));
      final parMoyen = {for (final m in juin.recettesParMoyen) m.moyen: m.montant};
      expect(parMoyen['Mobile Money'], 22000000);
      expect(parMoyen['Espèces'], 11000000);
    });

    test('le récapitulatif mensuel couvre chaque mois mouvementé', () async {
      await vendre(date: '2026-01-15', paye: 11000000);
      await vendre(date: '2026-03-20', paye: 11000000);

      final annee = Comptabilite.bilan(boutique.state, Periode.annee(2026));
      expect(annee.moisParMois.map((m) => m.cle), ['2026-01', '2026-03']);
      expect(annee.totalRecettes, 22000000);
    });
  });

  group('Périodes', () {
    test('un trimestre couvre bien ses trois mois', () {
      final t1 = Periode.trimestre(2026, 1);
      expect(t1.debut, '2026-01-01');
      expect(t1.fin, '2026-03-31');
      expect(t1.contient('2026-02-14'), isTrue);
      expect(t1.contient('2026-04-01'), isFalse);
    });

    test('une année va du 1er janvier au 31 décembre', () {
      final a = Periode.annee(2026);
      expect(a.debut, '2026-01-01');
      expect(a.fin, '2026-12-31');
    });

    test('février d\'une année bissextile compte 29 jours', () {
      expect(Periode.mois(2028, 2).fin, '2028-02-29');
    });
  });

  group('Le document', () {
    test('se fabrique en PDF avec les recettes et les dépenses', () async {
      await vendre(date: '2026-07-03', paye: 11000000);
      await boutique.ajouterDepense(
        Depense(
          id: nouvelId('dep'),
          date: '2026-07-10',
          categorie: 'Transport / Fret',
          libelle: 'Fret aérien',
          montant: 4500000,
          moyenPaiement: 'Mobile Money',
          creeLe: DateTime.now().toIso8601String(),
        ),
      );

      final bilan = Comptabilite.bilan(boutique.state, Periode.mois(2026, 7));
      final octets = await construireDocumentComptable(
        bilan,
        boutique.state.parametres,
      );
      expect(String.fromCharCodes(octets.take(4)), '%PDF');
      expect(octets.length, greaterThan(2000));
    });

    test('se fabrique aussi sur une période vide', () async {
      final bilan = Comptabilite.bilan(boutique.state, Periode.mois(2020, 1));
      final octets = await construireDocumentComptable(
        bilan,
        boutique.state.parametres,
      );
      expect(String.fromCharCodes(octets.take(4)), '%PDF');
    });

    test('tient sur plusieurs pages quand l\'année est chargée', () async {
      for (var i = 1; i <= 60; i++) {
        final jour = (i % 28) + 1;
        final mois = (i % 12) + 1;
        await vendre(
          date: '2026-${mois.toString().padLeft(2, "0")}-'
              '${jour.toString().padLeft(2, "0")}',
          paye: 11000000,
        );
      }
      final bilan = Comptabilite.bilan(boutique.state, Periode.annee(2026));
      expect(bilan.recettes, hasLength(60));

      final octets = await construireDocumentComptable(
        bilan,
        boutique.state.parametres,
      );
      expect(String.fromCharCodes(octets.take(4)), '%PDF');
      // Un document d'une seule page ne pourrait pas porter 60 lignes.
      expect(octets.length, greaterThan(8000));
    }, timeout: const Timeout(Duration(seconds: 90)));

    test('le nom de fichier est lisible et sans accent', () {
      final bilan = Comptabilite.bilan(boutique.state, Periode.annee(2026));
      final nom = nomFichierComptable(
        bilan,
        const Parametres(nomBoutique: 'Belle Couronne'),
      );
      expect(nom, 'livre-recettes-annee-2026-belle-couronne.pdf');
    });
  });

  group('Sauvegarde', () {
    test('les encaissements survivent à un aller-retour de sauvegarde', () async {
      final vente = await vendre(date: '2026-08-01', paye: 4000000);
      await boutique.encaisserSolde(vente.id, 7000000, date: '2026-08-20');
      final sauvegarde = await boutique.exporter();

      await boutique.viderDonnees();
      expect(boutique.state.reglements, isEmpty);

      await boutique.importer(sauvegarde);
      expect(boutique.state.reglements, hasLength(2));

      final aout = Comptabilite.bilan(boutique.state, Periode.mois(2026, 8));
      expect(aout.totalRecettes, 11000000);
    });
  });

  group('Statuts', () {
    test('une vente soldée en deux fois finit payée', () async {
      final vente = await vendre(date: '2026-09-01', paye: 4000000);
      expect(boutique.state.vente(vente.id)!.statut, statutPartielle);

      await boutique.encaisserSolde(vente.id, 7000000, date: '2026-09-15');
      expect(boutique.state.vente(vente.id)!.statut, statutPayee);
      expect(boutique.state.reglementsDe(vente.id), hasLength(2));
    });
  });
}
