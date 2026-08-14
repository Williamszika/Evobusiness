# Evobusiness — Application de gestion « mèches & perruques »

Application mobile pour une boutique de mèches, perruques et accessoires
capillaires : catalogue, stock, ventes, **reçus imprimables**, clientes,
dépenses, rapports et **comptabilité éditable en PDF pour les impôts**.
**Fonctionne entièrement hors-ligne.**

Développée en **Flutter** — un seul code source pour **iPhone, Android et le
web**.

---

## Démarrer

```bash
flutter pub get               # installer les dépendances
flutter run                   # lancer sur un téléphone branché ou un émulateur
flutter test                  # les 98 tests
flutter analyze               # l'analyse statique
flutter build apk --release --split-per-abi   # produire les APK à installer
```

Les APK se retrouvent dans `build/app/outputs/flutter-apk/`. Pour un téléphone
Android récent, prends `app-arm64-v8a-release.apk`.

**Sur iPhone**, l'application s'installe en **version web** : on ouvre son
adresse dans Safari, puis « Partager → Sur l'écran d'accueil ». L'icône se
place parmi les autres applications, l'app s'ouvre en plein écran et fonctionne
sans connexion. Aucun compte Apple, aucun App Store, rien à payer — voir
[`docs/07-installer-sur-iphone.md`](docs/07-installer-sur-iphone.md).

```bash
flutter build web --release --no-web-resources-cdn \
  --pwa-strategy offline-first --base-href /Evobusiness/
```

Le workflow [`publier-web.yml`](.github/workflows/publier-web.yml) le fait tout
seul à chaque poussée et publie sur la branche `gh-pages`. Pour que GitHub
serve le site, une activation unique est nécessaire dans les réglages du
dépôt — **Settings → Pages → Source : « Deploy from a branch » → `gh-pages`,
dossier `/ (root)`** — voir
[`docs/07-installer-sur-iphone.md`](docs/07-installer-sur-iphone.md).

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

**La comptabilité et les impôts**
Un **livre de recettes et de dépenses** par mois, trimestre ou année, tenu
**à l'encaissement** : une recette est datée du jour où l'argent arrive, pas du
jour de la vente. Un acompte en janvier et son solde en mars comptent donc dans
deux mois différents, et un mois déjà clos ne se réécrit jamais.

Le bouton **« Éditer le document pour les impôts »** produit un PDF paginé et
signable : récapitulatif, livre des recettes (date, n° de reçu, cliente, mode de
paiement), registre des dépenses, ventilation par catégorie, recettes par mode
de paiement, récapitulatif mois par mois. À imprimer, à archiver, ou à envoyer
au comptable — voir [`docs/10-comptabilite.md`](docs/10-comptabilite.md).

**La marque**
Huit logos et trois palettes livrés dans l'application : le choix se fait dans
Réglages et repeint aussitôt l'app **et le reçu imprimé**. Nom, slogan,
coordonnées, devise, message de remerciement et politique d'échange sont tous
modifiables.

**Les photos**
Chaque article peut porter sa photo. Elle est réduite puis rangée **dans la
base**, donc elle suit la sauvegarde : un téléphone remplacé retrouve son
catalogue en images.

**La sauvegarde**
Sur téléphone, l'application se sauvegarde **toute seule à chaque ouverture**
et garde les cinq dernières copies : une fausse manœuvre se rattrape en deux
touches. Et tant qu'aucune copie n'a été mise à l'abri hors de l'appareil,
l'accueil le rappelle — un bouton, et le fichier part vers Drive, iCloud ou
WhatsApp. En version web le rappel revient tous les trois jours au lieu de
sept, parce que le navigateur peut faire le ménage dans ses données.
Un téléphone perdu ne doit pas être un business perdu.

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
| [`docs/07-installer-sur-iphone.md`](docs/07-installer-sur-iphone.md) | Les trois chemins pour installer sur iPhone, et leur coût |
| [`docs/08-supabase.md`](docs/08-supabase.md) | Synchronisation cloud : architecture, sécurité, ce qui reste à écrire |
| [`docs/09-serveur-ou-pas.md`](docs/09-serveur-ou-pas.md) | Pourquoi un seul téléphone n'a pas besoin de serveur, et quoi choisir le jour venu |
| [`docs/10-comptabilite.md`](docs/10-comptabilite.md) | La règle de l'encaissement, le contenu du document fiscal, ce qu'il est et ce qu'il n'est pas |
| [`docs/11-application-iphone.md`](docs/11-application-iphone.md) | Version web ou vraie application iPhone : ce que ça change, ce que ça coûte, ce que je recommande |
| [`docs/12-installer-depuis-un-mac.md`](docs/12-installer-depuis-un-mac.md) | Installer l'application native depuis un Mac, gratuitement, et transférer les données |
| [`docs/13-donner-l-application-a-quelqu-un.md`](docs/13-donner-l-application-a-quelqu-un.md) | **La remettre à quelqu'un d'autre** : le message à lui envoyer, et ce qu'elle doit savoir |
| [`docs/logos/`](docs/logos/) | Les 8 logos en SVG |

---

## Sous le capot

Flutter · Riverpod · SQLite (`sqflite`, SQL écrit à la main, sans génération de
code) · `pdf` + `printing` pour les reçus · `fl_chart` · `flutter_svg`.

Six règles tenues dans tout le code :

1. **L'argent est stocké en entiers** (centimes). Jamais de décimaux sur une caisse.
2. **Le prix d'achat est figé sur chaque ligne de vente**, pour que la marge
   d'hier reste juste quand le prix d'achat change demain.
3. **Une vente ne se supprime pas, elle s'annule** : le stock revient, le numéro
   de reçu reste réservé, la numérotation n'a jamais de trou.
4. **Rien ne part à l'imprimante sans être assaini** : les polices du PDF ne
   couvrent que le latin, un émoji laissé tel quel disparaîtrait du reçu.
5. **Chaque encaissement porte sa propre date** : c'est lui, et non la vente,
   qui date une recette. Sans quoi le document fiscal serait faux.
6. **Aucune dépendance à un serveur extérieur** : moteur graphique, pdf.js et
   SQLite sont livrés avec l'application. Elle ne contacte personne.

`flutter analyze` : aucun problème. `flutter test` : 98 tests, dont le parcours
complet de vente, la fabrication réelle du reçu PDF dans les deux formats, et
celle du document comptable sur plusieurs pages.

Détails dans [`docs/06-plan-flutter.md`](docs/06-plan-flutter.md).

---

## Ce qui reste à faire

- Impression thermique **Bluetooth** (le format ticket est déjà généré, il
  manque le pilote)
- Relances d'impayés automatiques, commandes et arrivages, programme de
  fidélité, plusieurs vendeuses
- Un serveur : inutile tant qu'un seul téléphone vend — voir
  [`docs/09-serveur-ou-pas.md`](docs/09-serveur-ou-pas.md)
- Polices de marque embarquées pour les titres et le reçu

Voir [`docs/05-fonctionnalites.md`](docs/05-fonctionnalites.md).
