import 'package:evobusiness/coeur/argent.dart';
import 'package:evobusiness/coeur/constantes.dart';
import 'package:evobusiness/donnees/depot.dart';
import 'package:evobusiness/donnees/modeles.dart';
import 'package:evobusiness/etat/boutique.dart';
import 'package:evobusiness/etat/indicateurs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Vérifie le cœur métier de bout en bout, sur une vraie base SQLite en mémoire.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late BoutiqueNotifier boutique;

  Future<Produit> ajouterMeche({int stock = 10, int prixVente = 3800000}) {
    return boutique.ajouterProduit(
      Produit(
        id: nouvelId('prod'),
        reference: boutique.referenceLibre(),
        nom: 'Mèche brésilienne Body Wave',
        categorie: 'Mèches',
        origine: 'Brésilien',
        longueur: '18"',
        prixAchat: 2200000,
        prixVente: prixVente,
        stock: stock,
        seuilAlerte: 3,
        creeLe: DateTime.now().toIso8601String(),
      ),
    );
  }

  LigneVente ligneDe(Produit p, int quantite) => LigneVente(
        id: nouvelId('lig'),
        venteId: '',
        produitId: p.id,
        designation: p.nom,
        detail: p.detail,
        prixUnitaire: p.prixVente,
        coutUnitaire: p.prixAchat,
        quantite: quantite,
      );

  setUp(() async {
    boutique = BoutiqueNotifier();
    // `inMemoryDatabasePath` : chaque test repart d'une base neuve, et la
    // démonstration n'est pas installée puisqu'on crée nos propres articles.
    final depot = await Depot.ouvrir(cheminForce: inMemoryDatabasePath);
    await boutique.demarrer(depotForce: depot);
    await boutique.viderDonnees();
  });

  tearDown(() => boutique.dispose());

  group('Catalogue', () {
    test('le stock initial passe par un mouvement d\'entrée', () async {
      final produit = await ajouterMeche(stock: 12);
      expect(boutique.state.produit(produit.id)!.stock, 12);

      final mouvements = Indicateurs.mouvementsDe(boutique.state, produit.id);
      expect(mouvements, hasLength(1));
      expect(mouvements.first.type, mvtEntree);
      expect(mouvements.first.quantite, 12);
    });

    test('les références restent uniques', () async {
      await ajouterMeche();
      await ajouterMeche();
      final references = boutique.state.produits.map((p) => p.reference).toList();
      expect(references.toSet(), hasLength(references.length));
    });

    test('une entrée puis une perte se cumulent correctement', () async {
      final produit = await ajouterMeche(stock: 5);
      await boutique.ajusterStock(produit.id, 10, mvtEntree, motif: 'Arrivage');
      await boutique.ajusterStock(produit.id, -2, mvtPerte, motif: 'Casse');
      expect(boutique.state.produit(produit.id)!.stock, 13);
    });
  });

  group('Vente', () {
    test('sort le stock et numérote le reçu', () async {
      final produit = await ajouterMeche(stock: 10);
      final vente = await boutique.enregistrerVente(
        lignes: [ligneDe(produit, 2)],
        clientNom: 'Aïcha Ndiaye',
        moyenPaiement: 'Mobile Money',
        canal: 'WhatsApp',
        montantPaye: 7600000,
      );

      expect(vente.numero, 'REC-${DateTime.now().year}-0001');
      expect(vente.statut, statutPayee);
      expect(boutique.state.produit(produit.id)!.stock, 8);
    });

    test('deux ventes ne portent jamais le même numéro', () async {
      final produit = await ajouterMeche(stock: 10);
      final a = await boutique.enregistrerVente(
        lignes: [ligneDe(produit, 1)],
        clientNom: 'A',
        moyenPaiement: 'Espèces',
        canal: 'Boutique',
        montantPaye: 3800000,
      );
      final b = await boutique.enregistrerVente(
        lignes: [ligneDe(produit, 1)],
        clientNom: 'B',
        moyenPaiement: 'Espèces',
        canal: 'Boutique',
        montantPaye: 3800000,
      );
      expect(a.numero, isNot(b.numero));
      expect(b.numero, endsWith('0002'));
    });

    test('un acompte laisse la vente partielle avec un reste', () async {
      final produit = await ajouterMeche(stock: 4);
      final vente = await boutique.enregistrerVente(
        lignes: [ligneDe(produit, 1)],
        clientNom: 'Grâce',
        moyenPaiement: 'Mobile Money',
        canal: 'Instagram',
        montantPaye: 1500000,
      );
      expect(vente.statut, statutPartielle);
      expect(vente.reste, 2300000);
      expect(Indicateurs.totalImpayes(boutique.state), 2300000);
    });

    test('encaisser le solde bascule la vente en payée', () async {
      final produit = await ajouterMeche(stock: 4);
      final vente = await boutique.enregistrerVente(
        lignes: [ligneDe(produit, 1)],
        clientNom: 'Grâce',
        moyenPaiement: 'Mobile Money',
        canal: 'Instagram',
        montantPaye: 1500000,
      );
      await boutique.encaisserSolde(vente.id, 2300000);

      final maj = boutique.state.vente(vente.id)!;
      expect(maj.statut, statutPayee);
      expect(maj.reste, 0);
      expect(Indicateurs.totalImpayes(boutique.state), 0);
    });

    test('un service ne consomme pas de stock', () async {
      final pose = await boutique.ajouterProduit(
        Produit(
          id: nouvelId('prod'),
          reference: 'ART-900',
          nom: 'Pose de perruque',
          categorie: 'Service (pose, coiffure)',
          prixAchat: 0,
          prixVente: 1000000,
          stock: 0,
          seuilAlerte: 0,
          creeLe: DateTime.now().toIso8601String(),
        ),
      );
      await boutique.enregistrerVente(
        lignes: [ligneDe(pose, 1)],
        clientNom: 'Marina',
        moyenPaiement: 'Espèces',
        canal: 'Boutique',
        montantPaye: 1000000,
      );
      expect(boutique.state.produit(pose.id)!.stock, 0);
    });
  });

  group('Annulation', () {
    test('rend le stock et garde le numéro de reçu', () async {
      final produit = await ajouterMeche(stock: 10);
      final vente = await boutique.enregistrerVente(
        lignes: [ligneDe(produit, 3)],
        clientNom: 'Aïcha',
        moyenPaiement: 'Espèces',
        canal: 'Boutique',
        montantPaye: 11400000,
      );
      expect(boutique.state.produit(produit.id)!.stock, 7);

      await boutique.annulerVente(vente.id);

      final annulee = boutique.state.vente(vente.id)!;
      expect(annulee.statut, statutAnnulee);
      expect(annulee.numero, vente.numero, reason: 'le numéro reste réservé');
      expect(boutique.state.produit(produit.id)!.stock, 10);
    });

    test('une vente annulée sort du chiffre d\'affaires', () async {
      final produit = await ajouterMeche(stock: 10);
      final vente = await boutique.enregistrerVente(
        lignes: [ligneDe(produit, 2)],
        clientNom: 'Aïcha',
        moyenPaiement: 'Espèces',
        canal: 'Boutique',
        montantPaye: 7600000,
      );
      final avant = Indicateurs.chiffreAffaires(Indicateurs.duJour(boutique.state));
      expect(avant, 7600000);

      await boutique.annulerVente(vente.id);
      expect(Indicateurs.chiffreAffaires(Indicateurs.duJour(boutique.state)), 0);
    });

    test('annuler deux fois ne rend pas le stock en double', () async {
      final produit = await ajouterMeche(stock: 10);
      final vente = await boutique.enregistrerVente(
        lignes: [ligneDe(produit, 2)],
        clientNom: 'Aïcha',
        moyenPaiement: 'Espèces',
        canal: 'Boutique',
        montantPaye: 7600000,
      );
      await boutique.annulerVente(vente.id);
      await boutique.annulerVente(vente.id);
      expect(boutique.state.produit(produit.id)!.stock, 10);
    });
  });

  group('Rapports', () {
    test('le bénéfice net retranche les dépenses de la marge', () async {
      final produit = await ajouterMeche(stock: 10);
      await boutique.enregistrerVente(
        lignes: [ligneDe(produit, 2)],
        clientNom: 'Aïcha',
        moyenPaiement: 'Espèces',
        canal: 'Boutique',
        montantPaye: 7600000,
      );
      await boutique.ajouterDepense(
        Depense(
          id: nouvelId('dep'),
          date: Dates.aujourdhui(),
          categorie: 'Transport / Fret',
          libelle: 'Fret',
          montant: 1000000,
          moyenPaiement: 'Mobile Money',
          creeLe: DateTime.now().toIso8601String(),
        ),
      );

      final ventes = Indicateurs.duMois(boutique.state);
      final depenses = Indicateurs.depensesDuMois(boutique.state);
      // Marge : 2 × (38 000 − 22 000) = 32 000 ; moins 10 000 de fret.
      expect(Indicateurs.margeBrute(ventes), 3200000);
      expect(Indicateurs.beneficeNet(ventes, depenses), 2200000);
    });

    test('le classement des articles se fait au bénéfice', () async {
      final chere = await ajouterMeche(stock: 5, prixVente: 11000000);
      final courante = await ajouterMeche(stock: 20, prixVente: 3000000);
      await boutique.enregistrerVente(
        lignes: [ligneDe(chere, 1), ligneDe(courante, 5)],
        clientNom: 'Marina',
        moyenPaiement: 'Espèces',
        canal: 'Boutique',
        montantPaye: 26000000,
      );

      final classement =
          Indicateurs.meilleursProduits(boutique.state, boutique.state.ventes);
      expect(classement.first.produitId, chere.id,
          reason: 'la pièce chère rapporte plus que cinq pièces courantes');
    });
  });

  group('Sauvegarde', () {
    test('un aller-retour export / import restitue tout', () async {
      final produit = await ajouterMeche(stock: 7);
      await boutique.enregistrerVente(
        lignes: [ligneDe(produit, 2)],
        clientNom: 'Aïcha',
        moyenPaiement: 'Espèces',
        canal: 'Boutique',
        montantPaye: 7600000,
      );
      final sauvegarde = await boutique.exporter();

      await boutique.viderDonnees();
      expect(boutique.state.produits, isEmpty);
      expect(boutique.state.ventes, isEmpty);

      await boutique.importer(sauvegarde);
      expect(boutique.state.produits, hasLength(1));
      expect(boutique.state.ventes, hasLength(1));
      expect(boutique.state.produits.first.stock, 5);
      expect(boutique.state.ventes.first.total, 7600000);
    });
  });
}
