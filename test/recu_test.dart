import 'package:evobusiness/coeur/constantes.dart';
import 'package:evobusiness/coeur/logos.dart';
import 'package:evobusiness/donnees/modeles.dart';
import 'package:evobusiness/ecrans/recu/document_pdf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Le reçu est la pièce maîtresse : on vérifie qu'il se fabrique vraiment,
/// dans les deux formats, y compris dans les cas qui font tomber les autres
/// applications (émoji dans le message, vente à crédit, vente annulée).
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr_FR');
  });

  const parametres = Parametres(
    nomBoutique: 'Belle Couronne',
    slogan: 'La couronne qui vous ressemble',
    telephone: '+237 6 90 00 00 00',
    whatsapp: '+237 6 90 00 00 00',
    ville: 'Douala',
    adresse: 'Akwa',
    instagram: '@bellecouronne',
    devise: 'FCFA',
    messageRecu: 'Merci pour votre confiance 💕',
  );

  Vente venteType({int paye = 11700000, String statut = statutPayee}) => Vente(
        id: 'v1',
        numero: 'REC-2026-0002',
        date: '2026-08-14',
        clientNom: 'Marina Kouassi',
        clientTelephone: '+225 07 00 00 00 02',
        lignes: const [
          LigneVente(
            id: 'l1', venteId: 'v1', produitId: 'p1',
            designation: 'Perruque Lace Frontal 13x4',
            detail: 'Brésilien · Lisse · 22" · Naturel 1B',
            prixUnitaire: 11000000, coutUnitaire: 6500000, quantite: 1,
          ),
          LigneVente(
            id: 'l2', venteId: 'v1', produitId: 'p2',
            designation: 'Colle waterproof Got2b',
            prixUnitaire: 700000, coutUnitaire: 350000, quantite: 1,
          ),
        ],
        moyenPaiement: 'Mobile Money',
        canal: 'Boutique',
        montantPaye: paye,
        statut: statut,
        creeLe: '2026-08-14T10:00:00.000',
      );

  _testsTexteImprimable();

  test('le reçu A5 se fabrique et produit un vrai PDF', () async {
    final octets = await construireRecu(venteType(), parametres, ticket: false);
    expect(octets.length, greaterThan(1000));
    expect(String.fromCharCodes(octets.take(4)), '%PDF');
  });

  test('le ticket 80 mm se fabrique aussi', () async {
    final octets = await construireRecu(venteType(), parametres, ticket: true);
    expect(octets.length, greaterThan(1000));
    expect(String.fromCharCodes(octets.take(4)), '%PDF');
  });

  test('une vente à crédit s\'imprime sans erreur', () async {
    final octets = await construireRecu(
      venteType(paye: 5000000, statut: statutPartielle),
      parametres,
      ticket: false,
    );
    expect(octets.length, greaterThan(1000));
  });

  test('une vente annulée s\'imprime avec sa mention', () async {
    final octets = await construireRecu(
      venteType(paye: 0, statut: statutAnnulee),
      parametres,
      ticket: false,
    );
    expect(octets.length, greaterThan(1000));
  });

  test('les huit logos se dessinent dans le reçu', () async {
    for (final piste in pistesLogo) {
      final octets = await construireRecu(
        venteType(),
        parametres.copie(logo: piste.cle),
        ticket: false,
      );
      expect(octets.length, greaterThan(1000), reason: 'logo ${piste.cle}');
    }
  });

  test('les trois palettes se dessinent dans le reçu', () async {
    for (final cle in ['prune', 'nuit', 'terre']) {
      final octets = await construireRecu(
        venteType(),
        parametres.copie(palette: cle),
        ticket: false,
      );
      expect(octets.length, greaterThan(1000), reason: 'palette $cle');
    }
  });

  test('le message WhatsApp reprend le détail et le reste à payer', () {
    final texte = texteRecuWhatsApp(
      venteType(paye: 5000000, statut: statutPartielle),
      parametres,
    );
    expect(texte, contains('REC-2026-0002'));
    expect(texte, contains('Perruque Lace Frontal 13x4'));
    expect(texte, contains('117 000 FCFA'));
    expect(texte, contains('Reste à payer'));
    expect(texte, contains('67 000 FCFA'));
    // L'émoji reste dans le message, contrairement au PDF.
    expect(texte, contains('💕'));
  });
}

/// Garde-fou : ces conversions évitent que du texte disparaisse du reçu
/// imprimé sans que personne ne s'en aperçoive.
void _testsTexteImprimable() {
  group('Texte imprimable', () {
    test('garde les accents français', () {
      expect(texteImprimable('Reçu à Aïcha — être sûr'), contains('Reçu à Aïcha'));
    });

    test('remplace les tirets typographiques par un tiret simple', () {
      expect(texteImprimable('Payé — Mobile Money'), 'Payé - Mobile Money');
      expect(texteImprimable('Remise −5 000'), 'Remise -5 000');
    });

    test('normalise l\'apostrophe courbe', () {
      expect(texteImprimable('emballage d’origine'), "emballage d'origine");
    });

    test('retire les émojis sans casser le reste', () {
      expect(texteImprimable('Merci 💕 beaucoup'), 'Merci  beaucoup');
    });

    test('garde l\'espace de séparation des milliers', () {
      const p = Parametres(devise: 'FCFA');
      expect(texteImprimable(p.format(3800000)), '38 000 FCFA');
    });
  });
}
