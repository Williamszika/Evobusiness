import 'package:evobusiness/coeur/constantes.dart';
import 'package:evobusiness/donnees/modeles.dart';
import 'package:flutter_test/flutter_test.dart';

LigneVente ligne({
  int prix = 3800000,
  int cout = 2200000,
  int quantite = 1,
  int remise = 0,
}) =>
    LigneVente(
      id: 'l1',
      venteId: 'v1',
      produitId: 'p1',
      designation: 'Mèche brésilienne',
      prixUnitaire: prix,
      coutUnitaire: cout,
      quantite: quantite,
      remise: remise,
    );

Vente vente({
  List<LigneVente>? lignes,
  int remiseGlobale = 0,
  int fraisLivraison = 0,
  int montantPaye = 0,
  String statut = statutPayee,
}) =>
    Vente(
      id: 'v1',
      numero: 'REC-2026-0001',
      date: '2026-08-14',
      clientNom: 'Aïcha',
      lignes: lignes ?? [ligne()],
      remiseGlobale: remiseGlobale,
      fraisLivraison: fraisLivraison,
      moyenPaiement: 'Espèces',
      canal: 'Boutique',
      montantPaye: montantPaye,
      statut: statut,
      creeLe: '2026-08-14T10:00:00.000',
    );

void main() {
  group('Calcul d\'une ligne', () {
    test('multiplie le prix par la quantité', () {
      expect(ligne(quantite: 3).total, 11400000);
    });

    test('soustrait la remise de ligne', () {
      expect(ligne(quantite: 2, remise: 300000).total, 7300000);
    });

    test('ne descend jamais sous zéro', () {
      expect(ligne(prix: 1000, remise: 99999).total, 0);
    });
  });

  group('Total d\'une vente', () {
    test('sous-total, remise globale et livraison s\'enchaînent', () {
      final v = vente(
        lignes: [ligne(quantite: 2), ligne(prix: 300000, cout: 120000)],
        remiseGlobale: 300000,
        fraisLivraison: 200000,
      );
      expect(v.sousTotal, 7900000);
      expect(v.total, 7800000);
    });

    test('le total ne devient pas négatif avec une grosse remise', () {
      expect(vente(remiseGlobale: 99999999).total, 0);
    });
  });

  group('Marge', () {
    test('la livraison n\'est pas un bénéfice', () {
      // 38 000 vendus, 22 000 achetés, 2 000 de livraison encaissés.
      final v = vente(fraisLivraison: 200000);
      expect(v.total, 4000000);
      expect(v.coutTotal, 2200000);
      // Bénéfice = 38 000 − 22 000, la livraison rembourse un frais.
      expect(v.marge, 1600000);
    });

    test('la remise globale ampute la marge', () {
      final v = vente(remiseGlobale: 500000);
      expect(v.marge, 1100000);
    });
  });

  group('Paiement', () {
    test('un paiement complet solde la vente', () {
      expect(Vente.statutPour(4000000, 4000000), statutPayee);
    });

    test('un acompte donne une vente partielle', () {
      expect(Vente.statutPour(4000000, 1500000), statutPartielle);
    });

    test('sans versement la vente est impayée', () {
      expect(Vente.statutPour(4000000, 0), statutImpayee);
    });

    test('le reste à payer suit le montant versé', () {
      final v = vente(montantPaye: 1500000);
      expect(v.reste, 2300000);
    });

    test('un trop-perçu ne crée pas un reste négatif', () {
      expect(vente(montantPaye: 9999999).reste, 0);
    });
  });

  group('Marge d\'un article', () {
    test('se calcule en valeur et en pourcentage', () {
      const produit = Produit(
        id: 'p1',
        reference: 'ART-001',
        nom: 'Perruque',
        categorie: 'Perruques',
        prixAchat: 6500000,
        prixVente: 11000000,
        stock: 4,
        seuilAlerte: 2,
        creeLe: '2026-08-01T00:00:00.000',
      );
      expect(produit.marge, 4500000);
      expect(produit.tauxMarge.round(), 41);
      expect(produit.valeurStock, 26000000);
    });

    test('signale un stock bas et une rupture', () {
      const base = Produit(
        id: 'p1', reference: 'ART-001', nom: 'Mèche', categorie: 'Mèches',
        prixAchat: 100, prixVente: 200, stock: 2, seuilAlerte: 3,
        creeLe: '2026-08-01T00:00:00.000',
      );
      expect(base.stockBas, isTrue);
      expect(base.enRupture, isFalse);
      expect(base.copie(stock: 0).enRupture, isTrue);
      expect(base.copie(stock: 10).stockBas, isFalse);
    });
  });
}
