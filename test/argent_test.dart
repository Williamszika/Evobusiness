import 'package:evobusiness/coeur/argent.dart';
import 'package:evobusiness/donnees/modeles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('fr_FR'));

  group('Saisie des montants', () {
    test('lit un montant simple', () {
      expect(Argent.depuisSaisie('38000'), 3800000);
    });

    test('accepte la virgule et les espaces de saisie', () {
      expect(Argent.depuisSaisie('38 000,50'), 3800050);
      expect(Argent.depuisSaisie('12.75'), 1275);
    });

    test('refuse ce qui n\'est pas un nombre', () {
      expect(Argent.depuisSaisie(''), isNull);
      expect(Argent.depuisSaisie('abc'), isNull);
    });

    test('ne perd pas de centimes en aller-retour', () {
      const centimes = 1234567;
      expect(Argent.depuisSaisie(Argent.versSaisie(centimes, 2)), centimes);
    });
  });

  group('Affichage selon la devise', () {
    test('le franc CFA s\'écrit sans centimes, devise après', () {
      const p = Parametres(devise: 'FCFA');
      expect(p.format(3800000), '38 000 FCFA');
    });

    test('l\'euro garde deux décimales', () {
      const p = Parametres(devise: '€', deviseAvant: true);
      expect(p.format(1250), '€ 12,50');
    });

    test('les grands nombres sont abrégés pour les graphiques', () {
      const p = Parametres(devise: 'FCFA');
      expect(p.formatCourt(642000000), '6,4 M');
      expect(p.formatCourt(34000000), '340 k');
    });
  });

  group('Numérotation des reçus', () {
    test('le numéro est préfixé, daté et sur quatre chiffres', () {
      const p = Parametres(prefixeRecu: 'REC', compteurRecu: 7);
      expect(p.prochainNumero(), 'REC-${DateTime.now().year}-0007');
    });
  });

  group('Dates', () {
    test('les jours écoulés se comptent depuis une date ISO', () {
      expect(Dates.joursDepuis(Dates.ilYaJours(12)), 12);
    });

    test('la clé de regroupement mensuel garde année et mois', () {
      expect(Dates.cleMois('2026-08-14'), '2026-08');
    });
  });
}
