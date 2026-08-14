import 'package:evobusiness/app.dart';
import 'package:evobusiness/donnees/depot.dart';
import 'package:evobusiness/etat/boutique.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Vérifie que l'application se lance vraiment et que chaque onglet
/// se dessine sur un écran de téléphone, sans débordement de mise en page.
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
    // La démonstration s'installe toute seule sur une base vide : les écrans
    // sont donc testés avec du contenu réaliste.
    await boutique.demarrer(depotForce: depot);
  });

  // Pas de `dispose()` ici : le ProviderScope du test possède le notifier
  // et le libère lui-même en fin de test.

  Future<void> lancer(WidgetTester tester) async {
    // Taille d'un téléphone courant plutôt que la fenêtre de test par défaut.
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

  testWidgets('l\'accueil affiche la marque et le chiffre du jour',
      (tester) async {
    await lancer(tester);
    expect(find.text('Belle Couronne'), findsWidgets);
    expect(find.text('ENCAISSÉ AUJOURD\'HUI'), findsOneWidget);
    expect(find.text('Vendre'), findsOneWidget);
  });

  testWidgets('l\'accueil signale les articles en stock bas', (tester) async {
    await lancer(tester);
    // La démonstration contient une mèche indienne à 2 pièces pour un seuil de 3.
    expect(find.text('À SURVEILLER'), findsOneWidget);
  });

  testWidgets('l\'accueil rappelle de mettre la boutique à l\'abri',
      (tester) async {
    await lancer(tester);
    // Aucune copie n'a encore été sortie : le rappel doit être là.
    await tester.scrollUntilVisible(
      find.text('Mets ta boutique à l\'abri'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sauvegarder maintenant'), findsOneWidget);
  });

  testWidgets('les cinq onglets se dessinent sans erreur', (tester) async {
    await lancer(tester);
    for (final onglet in ['Stock', 'Ventes', 'Clientes', 'Rapports', 'Accueil']) {
      await tester.tap(find.text(onglet));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'onglet $onglet');
    }
  });

  testWidgets('le stock remonte d\'abord ce qui manque', (tester) async {
    await lancer(tester);
    await tester.tap(find.text('Stock'));
    await tester.pumpAndSettle();
    expect(find.text('Mon stock'), findsOneWidget);
    // Le tri se fait par urgence : la mèche indienne (2 pièces pour un seuil
    // de 3) doit être visible sans avoir à faire défiler la liste.
    expect(find.text('Mèche indienne Bone Straight'), findsOneWidget);
    expect(find.textContaining('Reste 2'), findsWidgets);
  });

  testWidgets('la recherche du stock filtre les articles', (tester) async {
    await lancer(tester);
    await tester.tap(find.text('Stock'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'body wave');
    await tester.pumpAndSettle();
    expect(find.text('Mèche brésilienne Body Wave'), findsOneWidget);
    expect(find.text('Mèche indienne Bone Straight'), findsNothing);
  });

  testWidgets('la vente s\'ouvre sur le choix des articles', (tester) async {
    await lancer(tester);
    await tester.tap(find.text('Vendre'));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle vente'), findsOneWidget);
    expect(find.text('Étape 1 — les articles'), findsOneWidget);
  });

  testWidgets('ajouter un article ouvre la barre de total', (tester) async {
    await lancer(tester);
    await tester.tap(find.text('Vendre'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'lace frontal');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perruque Lace Frontal 13x4'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 article(s)'), findsOneWidget);
    expect(find.textContaining('110 000 FCFA'), findsWidgets);
    expect(find.text('Suivant'), findsOneWidget);
  });

  testWidgets('les ventes affichent les reçus de démonstration',
      (tester) async {
    await lancer(tester);
    await tester.tap(find.text('Ventes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('REC-'), findsWidgets);
  });

  /// L'écran d'encaissement est plus long qu'un téléphone : on fait défiler
  /// jusqu'à l'élément cherché comme le ferait l'utilisatrice.
  Future<void> defilerVers(WidgetTester tester, Finder cible) async {
    await tester.scrollUntilVisible(
      cible,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> allerAEncaissement(WidgetTester tester) async {
    await tester.tap(find.text('Vendre'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'lace frontal');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perruque Lace Frontal 13x4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
  }

  testWidgets('parcours complet : vendre, encaisser, enregistrer la vente',
      (tester) async {
    await lancer(tester);
    final ventesAvant = boutique.state.ventes.length;
    final stockAvant = boutique.state.produits
        .firstWhere((p) => p.nom == 'Perruque Lace Frontal 13x4')
        .stock;

    await allerAEncaissement(tester);
    expect(find.text('Encaisser'), findsOneWidget);
    expect(find.text('TOTAL À PAYER'), findsOneWidget);

    await defilerVers(tester, find.text('MONTANT REÇU'));
    expect(find.text('Tout payé'), findsOneWidget);

    // `runAsync` : l'enregistrement écrit vraiment dans SQLite, ce que le
    // temps simulé d'un test de widget ne ferait pas avancer tout seul.
    await tester.runAsync(() async {
      await tester.tap(find.textContaining('Valider et faire le reçu'));
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });

    // La vente est enregistrée, numérotée, et le stock a bougé.
    expect(boutique.state.ventes.length, ventesAvant + 1);
    final vente = boutique.state.ventes.first;
    expect(vente.total, 11000000);
    expect(vente.statut, 'Payée');
    expect(vente.numero, startsWith('REC-'));
    expect(
      boutique.state.produits
          .firstWhere((p) => p.nom == 'Perruque Lace Frontal 13x4')
          .stock,
      stockAvant - 1,
    );
  });

  testWidgets('un acompte laisse un reste à payer visible', (tester) async {
    await lancer(tester);
    await allerAEncaissement(tester);

    await defilerVers(tester, find.text('MONTANT REÇU'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Montant reçu').first,
      '50000',
    );
    await tester.pumpAndSettle();

    expect(find.text('Reste à payer'), findsOneWidget);
    expect(find.text('60 000 FCFA'), findsWidgets);
  });
}
