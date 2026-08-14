import 'package:evobusiness/app.dart';
import 'package:evobusiness/donnees/depot.dart';
import 'package:evobusiness/donnees/modeles.dart';
import 'package:evobusiness/etat/boutique.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// La boutique est destinée à être remise à quelqu'un qui la remplira seul.
/// Elle doit donc s'ouvrir **vide**, et réclamer d'abord le seul renseignement
/// qu'aucun réglage par défaut ne peut inventer : le nom qui s'imprimera sur
/// les reçus.
void main() {
  late BoutiqueNotifier boutique;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('fr_FR');
  });

  setUp(() async {
    boutique = BoutiqueNotifier();
    final depot = await Depot.ouvrir(cheminForce: inMemoryDatabasePath);
    await boutique.demarrer(depotForce: depot);
    // `inMemoryDatabasePath` est partagé entre les ouvertures : on repart
    // explicitement de rien, sans quoi un test précédent laisserait ses
    // articles derrière lui.
    await boutique.viderDonnees();
    await boutique.majParametres(const Parametres());
  });

  Future<void> lancer(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [boutiqueProvider.overrideWith((ref) => boutique)],
        child: const Application(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Première ouverture', () {
    test('la boutique démarre sans aucun article ni aucune vente', () {
      expect(boutique.state.produits, isEmpty);
      expect(boutique.state.ventes, isEmpty);
      expect(boutique.state.clients, isEmpty);
      expect(boutique.state.depenses, isEmpty);
    });

    test('sans nom, la boutique n\'est pas considérée comme configurée', () {
      expect(boutique.state.parametres.estConfiguree, isFalse);
    });

    test('un nom fait d\'espaces ne compte pas pour un nom', () {
      expect(const Parametres(nomBoutique: '   ').estConfiguree, isFalse);
    });

    test('nommer la boutique la rend configurée', () async {
      await boutique.majParametres(
        boutique.state.parametres.copie(nomBoutique: 'Chez Aminata'),
      );
      expect(boutique.state.parametres.estConfiguree, isTrue);
    });

    testWidgets('l\'écran de bienvenue s\'affiche au lieu de la boutique',
        (tester) async {
      await lancer(tester);
      expect(find.text('Bienvenue'), findsOneWidget);
      expect(find.text('Ouvrir ma boutique'), findsOneWidget);
      // Les onglets de la boutique ne doivent pas être accessibles tant que
      // rien n'est renseigné.
      expect(find.text('Vendre'), findsNothing);
    });

    testWidgets('le bouton reste inerte tant que le nom manque',
        (tester) async {
      await lancer(tester);
      final bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Ouvrir ma boutique'),
      );
      expect(bouton.onPressed, isNull);
    });

    testWidgets('saisir un nom ouvre la boutique, et elle est vide',
        (tester) async {
      await lancer(tester);
      await tester.enterText(find.byType(TextField).first, 'Chez Aminata');
      await tester.pumpAndSettle();

      // `runAsync` : l'enregistrement écrit vraiment dans SQLite, ce que le
      // temps simulé d'un test de widget ne ferait pas avancer tout seul.
      await tester.runAsync(() async {
        await tester.tap(find.text('Ouvrir ma boutique'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue'), findsNothing);
      expect(boutique.state.parametres.nomBoutique, 'Chez Aminata');
      expect(boutique.state.produits, isEmpty);
      // Le premier reçu portera bien le numéro 1.
      expect(boutique.state.parametres.compteurRecu, 1);
    });

    testWidgets('le téléphone sert aussi de WhatsApp quand la case est cochée',
        (tester) async {
      await lancer(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Chez Aminata');
      await tester.enterText(find.byType(TextField).at(1), '+237 6 90 11 22 33');
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Ouvrir ma boutique'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pumpAndSettle();

      expect(boutique.state.parametres.telephone, '+237 6 90 11 22 33');
      expect(boutique.state.parametres.whatsapp, '+237 6 90 11 22 33');
    });
  });

  group('La démonstration reste disponible', () {
    test('elle se nomme elle-même sur une boutique jamais configurée',
        () async {
      await boutique.reinstallerDemo();
      // Sans nom, l'application rouvrirait l'écran de bienvenue sans fin.
      expect(boutique.state.parametres.estConfiguree, isTrue);
      expect(boutique.state.produits, isNotEmpty);
      expect(boutique.state.ventes, isNotEmpty);
    });

    test('elle n\'écrase jamais la marque d\'une vraie boutique', () async {
      await boutique.majParametres(
        boutique.state.parametres.copie(
          nomBoutique: 'Chez Aminata',
          ville: 'Yaoundé',
        ),
      );
      await boutique.reinstallerDemo();
      expect(boutique.state.parametres.nomBoutique, 'Chez Aminata');
      expect(boutique.state.parametres.ville, 'Yaoundé');
    });

    test('« Repartir de zéro » vide tout mais garde la marque', () async {
      await boutique.reinstallerDemo();
      await boutique.majParametres(
        boutique.state.parametres.copie(nomBoutique: 'Chez Aminata'),
      );
      await boutique.viderDonnees();

      expect(boutique.state.produits, isEmpty);
      expect(boutique.state.ventes, isEmpty);
      expect(boutique.state.parametres.nomBoutique, 'Chez Aminata');
      // La numérotation des reçus repart de 1 sur une boutique remise à zéro.
      expect(boutique.state.parametres.compteurRecu, 1);
    });
  });
}
