import 'dart:io';

import 'package:evobusiness/coeur/argent.dart';
import 'package:evobusiness/donnees/depot.dart';
import 'package:evobusiness/donnees/modeles.dart';
import 'package:evobusiness/donnees/sauvegarde.dart';
import 'package:evobusiness/donnees/sauvegarde_io.dart';
import 'package:evobusiness/donnees/sauvegarde_web.dart';
import 'package:evobusiness/ecrans/parametres/actions_sauvegarde.dart';
import 'package:evobusiness/etat/boutique.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Avec un seul téléphone, la sauvegarde EST le serveur. Ces tests vérifient
/// qu'elle se déclenche, qu'elle tourne, et qu'elle restaure vraiment.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory dossier;
  late BoutiqueNotifier boutique;

  setUp(() async {
    dossier = Directory.systemTemp.createTempSync('sauvegardes_test');
    boutique = BoutiqueNotifier();
    final depot = await Depot.ouvrir(cheminForce: inMemoryDatabasePath);
    await boutique.demarrer(
      depotForce: depot,
      stock: StockFichiers(dossier: dossier),
    );
    // On repart d'une boutique vide : la démonstration fausserait les comptages.
    await boutique.viderDonnees();
  });

  tearDown(() {
    boutique.dispose();
    if (dossier.existsSync()) dossier.deleteSync(recursive: true);
  });

  Future<Produit> ajouterArticle(String nom) => boutique.ajouterProduit(
        Produit(
          id: nouvelId('prod'),
          reference: boutique.referenceLibre(),
          nom: nom,
          categorie: 'Mèches',
          prixAchat: 2200000,
          prixVente: 3800000,
          stock: 5,
          seuilAlerte: 2,
          creeLe: DateTime.now().toIso8601String(),
        ),
      );

  group('Sauvegarde automatique', () {
    test('une copie est déposée dès le premier démarrage', () async {
      final fichiers = await boutique.listerSauvegardes();
      expect(fichiers, hasLength(1));
      expect(fichiers.first.taille, greaterThan(100));
    });

    test('elle ne se réécrit pas à chaque ouverture', () async {
      await boutique.sauvegardeAutomatique();
      await boutique.sauvegardeAutomatique();
      // La dernière est trop récente : rien de nouveau ne doit s'ajouter.
      expect(await boutique.listerSauvegardes(), hasLength(1));
    });

    test('une sauvegarde forcée s\'ajoute quand même', () async {
      await boutique.sauvegarderMaintenant();
      expect((await boutique.listerSauvegardes()).length, greaterThanOrEqualTo(2));
    });

    test('seules les cinq dernières copies sont gardées', () async {
      for (var i = 0; i < 8; i++) {
        await boutique.sauvegarderMaintenant();
        // Les noms de fichiers sont à la seconde : on les espace.
        await Future<void>.delayed(const Duration(milliseconds: 1100));
      }
      final fichiers = await boutique.listerSauvegardes();
      expect(fichiers, hasLength(StockSauvegardes.nombreConserve));
      // Et ce sont bien les plus récentes qui restent.
      final dates = fichiers.map((c) => c.date).whereType<DateTime>().toList();
      expect(dates.first.isAfter(dates.last), isTrue);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('la liste est triée de la plus récente à la plus ancienne', () async {
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await boutique.sauvegarderMaintenant();
      final fichiers = await boutique.listerSauvegardes();
      final dates = fichiers.map((c) => c.date).whereType<DateTime>().toList();
      expect(dates, hasLength(2));
      expect(dates.first.isAfter(dates.last), isTrue);
    });
  });

  group('Restauration', () {
    test('revenir à une copie annule les changements faits depuis', () async {
      await ajouterArticle('Mèche brésilienne');
      final copie = await boutique.sauvegarderMaintenant();
      expect(copie, isNotNull);

      await ajouterArticle('Perruque bob');
      expect(boutique.state.produits, hasLength(2));

      await boutique.restaurerCopie(copie!);
      expect(boutique.state.produits, hasLength(1));
      expect(boutique.state.produits.first.nom, 'Mèche brésilienne');
    });

    test('elle rattrape même un « Repartir de zéro » de trop', () async {
      await ajouterArticle('Mèche brésilienne');
      final copie = await boutique.sauvegarderMaintenant();

      await boutique.viderDonnees();
      expect(boutique.state.produits, isEmpty);

      await boutique.restaurerCopie(copie!);
      expect(boutique.state.produits, hasLength(1));
    });

    test('un fichier illisible lève une erreur claire, sans rien casser',
        () async {
      await ajouterArticle('Mèche brésilienne');
      final abime = File('${dossier.path}/pas-du-json.json')
        ..writeAsStringSync('ceci n\'est pas du JSON');

      final copieAbimee = CopieSauvegarde(
        identifiant: abime.path,
        date: DateTime.now(),
        taille: abime.lengthSync(),
      );
      await expectLater(boutique.restaurerCopie(copieAbimee), throwsA(anything));
      // La boutique est intacte.
      expect(boutique.state.produits, hasLength(1));
    });
  });

  group('Rappel de mise à l\'abri', () {
    test('il s\'affiche tant qu\'aucune copie n\'est sortie', () {
      expect(rappelSauvegardeNecessaire(''), isTrue);
    });

    test('il disparaît juste après une mise à l\'abri', () {
      expect(rappelSauvegardeNecessaire(DateTime.now().toIso8601String()), isFalse);
    });

    test('il revient au bout d\'une semaine', () {
      expect(rappelSauvegardeNecessaire(Dates.ilYaJours(3), delaiJours: 7), isFalse);
      expect(rappelSauvegardeNecessaire(Dates.ilYaJours(7), delaiJours: 7), isTrue);
      expect(rappelSauvegardeNecessaire(Dates.ilYaJours(30), delaiJours: 7), isTrue);
    });

    test('la version web rappelle plus tôt, tous les trois jours', () {
      expect(rappelSauvegardeNecessaire(Dates.ilYaJours(2), delaiJours: 3), isFalse);
      expect(rappelSauvegardeNecessaire(Dates.ilYaJours(4), delaiJours: 3), isTrue);
    });

    test('marquer une sortie enregistre la date dans les réglages', () async {
      expect(boutique.state.parametres.derniereSortieLe, isEmpty);
      await boutique.marquerSortie();
      expect(boutique.state.parametres.derniereSortieLe, isNotEmpty);
      expect(rappelSauvegardeNecessaire(boutique.state.parametres.derniereSortieLe),
          isFalse);
    });
  });

  group('Nom et lecture des fichiers', () {
    test('la date se relit depuis le nom du fichier', () async {
      final copie = (await boutique.listerSauvegardes()).first;
      expect(copie.date, isNotNull);
      expect(copie.date!.difference(DateTime.now()).inMinutes.abs(), lessThan(2));
      expect(copie.quand, matches(RegExp(r'^\d{2}/\d{2}/\d{4} à \d{2}h\d{2}$')));
    });

    test('la taille est affichée lisiblement', () async {
      final copie = (await boutique.listerSauvegardes()).first;
      expect(copie.tailleLisible, matches(RegExp(r'^\d+([.,]\d+)? (o|Ko|Mo)$')));
    });

    test('aucun fichier partiel ne subsiste après écriture', () async {
      await boutique.sauvegarderMaintenant();
      final restes = dossier
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.partiel'));
      expect(restes, isEmpty);
    });
  });

  group('Version web', () {
    test('aucune copie locale n\'est écrite, et c\'est assumé', () async {
      const stock = StockIndisponible();
      expect(stock.disponible, isFalse);
      expect(await stock.faudraitSauvegarder(), isFalse);
      expect(await stock.ecrire({'produits': []}), isNull);
      expect(await stock.lister(), isEmpty);
    });

    test('relire une copie inexistante échoue franchement', () async {
      const stock = StockIndisponible();
      await expectLater(
        stock.lire(const CopieSauvegarde(
            identifiant: 'x', date: null, taille: 0)),
        throwsUnsupportedError,
      );
    });
  });
}
