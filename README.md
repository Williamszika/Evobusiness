# Evobusiness — Application de gestion « mèches & perruques »

Application mobile pour une boutique de mèches, perruques et accessoires
capillaires : catalogue, stock, ventes, **reçus imprimables**, clientes,
dépenses et rapports. **Fonctionne entièrement hors-ligne.**

Développée en **Flutter** (Android + iOS), un seul code source.

---

## Démarrer

```bash
flutter pub get               # installer les dépendances
flutter run                   # lancer sur un téléphone branché ou un émulateur
flutter test                  # les 60 tests
flutter analyze               # l'analyse statique
flutter build apk --release --split-per-abi   # produire les APK à installer
```

Les APK se retrouvent dans `build/app/outputs/flutter-apk/`. Pour un téléphone
Android récent, prends `app-arm64-v8a-release.apk`.

Aucune génération de code n'est nécessaire : `flutter pub get` suffit.

Au tout premier lancement, l'application installe un **catalogue de
démonstration** (mèches, perruques, closures, clientes, ventes, dépenses) pour
qu'elle soit immédiatement explorable. Il s'efface d'un bouton dans
Réglages → Données → « Repartir de zéro ».

---

## Ce que fait l'application

**Le stock**
Mèches, perruques, closures/frontals, accessoires, soins et services de pose,
avec longueur, texture, couleur, origine, densité et photo. Seuil d'alerte par
article, écran des ruptures, historique de chaque mouvement. La liste est triée
**par urgence** : ce qui manque remonte tout seul.

**La vente**
Panier à plusieurs articles, remise par ligne ou sur le total, frais de
livraison. Le stock disponible s'affiche en direct — impossible de vendre ce
qu'on n'a plus. Le **paiement partiel** est prévu dès le départ : acompte
aujourd'hui, solde plus tard, et l'app garde le compte de qui doit combien et
depuis combien de jours.

**Le reçu** — la pièce maîtresse
Numéroté sans trou (`REC-2026-0001`), en **A5** pour une imprimante de bureau
ou en **ticket 80 mm**, avec aperçu avant impression. Trois sorties : papier,
PDF, WhatsApp.

**Les clientes**
Fiche, historique d'achats, total dépensé, solde dû, préférences, anniversaire.
Relance WhatsApp en un bouton, avec un message poli déjà rédigé.

**L'argent**
Dépenses (marchandise, fret, douane, publicité, loyer), marge calculée
automatiquement sur chaque article et chaque vente, bénéfice net, objectif
mensuel, rapports par période, articles les plus rentables, meilleures
clientes, canal de vente le plus efficace.

**La marque**
Huit logos et trois palettes livrés dans l'application : le choix se fait dans
Réglages et repeint aussitôt l'app **et le reçu imprimé**. Nom, slogan,
coordonnées, devise, message de remerciement et politique d'échange sont tous
modifiables.

**La sauvegarde**
Export et restauration par fichier JSON. Un téléphone perdu ne doit pas être un
business perdu.

---

## Les décisions de marque

Les choix de nom, de logo et de palette n'ont pas encore été tranchés :
l'application démarre sur « Belle Couronne » + palette Prune & Laiton + logo
Couronne, et **tout se change dans Réglages** en quelques secondes.

| Document | Contenu |
| --- | --- |
| [`docs/planche-de-proposition.html`](docs/planche-de-proposition.html) | La planche visuelle : logos dessinés, écrans maquettés, choix cochables |
| [`docs/01-noms.md`](docs/01-noms.md) | 20 noms de business, recommandations, checklist de vérification |
| [`docs/02-identite-visuelle.md`](docs/02-identite-visuelle.md) | Les 3 palettes, la typographie, les 8 pistes de logo |
| [`docs/03-maquette.md`](docs/03-maquette.md) | Les 8 écrans, décrits un par un |
| [`docs/04-le-recu.md`](docs/04-le-recu.md) | Les deux formats de reçu et les mentions obligatoires |
| [`docs/05-fonctionnalites.md`](docs/05-fonctionnalites.md) | Périmètre version 1 / plus tard |
| [`docs/06-plan-flutter.md`](docs/06-plan-flutter.md) | Paquets, modèle de données, règles de code, tests |
| [`docs/logos/`](docs/logos/) | Les 8 logos en SVG |

---

## Sous le capot

Flutter · Riverpod · SQLite (`sqflite`, SQL écrit à la main, sans génération de
code) · `pdf` + `printing` pour les reçus · `fl_chart` · `flutter_svg`.

Quatre règles tenues dans tout le code :

1. **L'argent est stocké en entiers** (centimes). Jamais de décimaux sur une caisse.
2. **Le prix d'achat est figé sur chaque ligne de vente**, pour que la marge
   d'hier reste juste quand le prix d'achat change demain.
3. **Une vente ne se supprime pas, elle s'annule** : le stock revient, le numéro
   de reçu reste réservé, la numérotation n'a jamais de trou.
4. **Rien ne part à l'imprimante sans être assaini** : les polices du PDF ne
   couvrent que le latin, un émoji laissé tel quel disparaîtrait du reçu.

`flutter analyze` : aucun problème. `flutter test` : 60 tests, dont le parcours
complet de vente et la fabrication réelle du PDF dans les deux formats.

Détails dans [`docs/06-plan-flutter.md`](docs/06-plan-flutter.md).

---

## Ce qui reste à faire

- Impression thermique **Bluetooth** (le format ticket est déjà généré, il
  manque le pilote)
- Relances d'impayés automatiques, commandes et arrivages, programme de
  fidélité, sauvegarde en ligne, plusieurs vendeuses
- Polices de marque embarquées pour les titres et le reçu

Voir [`docs/05-fonctionnalites.md`](docs/05-fonctionnalites.md).
