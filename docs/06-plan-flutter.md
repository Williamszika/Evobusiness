# L'application Flutter — comment elle est construite

> Ce document décrivait le plan avant le développement. Il décrit maintenant
> **ce qui a réellement été construit**. Les écarts avec le plan initial sont
> signalés.

Un seul code source, deux applications : **Android et iPhone**. Tous les
paquets utilisés sont éprouvés et gratuits.

---

## Les paquets retenus

| Besoin | Solution | Pourquoi celle-là |
| --- | --- | --- |
| Base de données locale | `sqflite` (SQLite), SQL écrit à la main | Marche sans internet. **Écart avec le plan** : `drift` était prévu, mais il impose une génération de code (`build_runner`) à chaque modification ; avec `sqflite`, un simple `flutter pub get` suffit pour compiler le projet |
| Organisation de l'app | `flutter_riverpod` | La référence actuelle pour tenir l'état d'une app Flutter quand elle grandit |
| Reçu PDF & impression | `pdf` + `printing` | Le duo standard : fabrique le A5, montre l'aperçu, parle à l'imprimante et à AirPrint |
| Partage du reçu | `printing` (`Printing.sharePdf`) | Ouvre la feuille de partage du téléphone — WhatsApp, mail, Drive |
| Message WhatsApp | `url_launcher` (`wa.me`) | Ouvre la conversation avec le détail de la vente déjà rédigé |
| Graphiques | `fl_chart` | Léger, et il se colore avec la palette de la marque |
| Logos | `flutter_svg` | Le **même** texte SVG sert à l'écran et au PDF : un seul logo, jamais deux versions à maintenir |
| Photos d'articles | `image_picker` + `path_provider` | Photo prise avec l'appareil, recopiée dans l'app pour survivre au ménage de la galerie |
| Français & devises | `intl` + `flutter_localizations` | Dates et montants au format local |
| Sauvegarde | `file_picker` | Enregistre et relit le fichier JSON de sauvegarde |

**Écart avec le plan** : `share_plus` et `esc_pos_utils_plus` ne sont pas
installés. Le partage passe par `printing`, qui fait le même travail sans
dépendance supplémentaire. L'impression thermique Bluetooth reste prévue pour
une version ultérieure ; en attendant, le **format ticket 80 mm est déjà
produit** et s'imprime sur toute imprimante compatible.

---

## Le modèle de données

Base SQLite locale, huit tables :

| Table | Colonnes principales |
| --- | --- |
| `produits` | référence, nom, catégorie, texture, longueur, couleur, origine, densité, prix d'achat, prix de vente, stock, seuil d'alerte, photo, fournisseur, actif |
| `clients` | nom, téléphone, WhatsApp, e-mail, ville, adresse, anniversaire, note |
| `fournisseurs` | nom, pays, contact, note |
| `ventes` | numéro, date, cliente, remise globale, frais de livraison, moyen de paiement, canal, montant payé, statut, note, vendu par |
| `lignes_vente` | vente, article, désignation figée, quantité, prix unitaire, remise, **coût d'achat figé** |
| `depenses` | date, catégorie, libellé, montant, moyen de paiement, fournisseur |
| `mouvements_stock` | date, article, type (entrée / vente / retour / perte / ajustement), quantité, stock après, motif, vente liée |
| `parametres` | une seule ligne, en JSON : marque, logo, palette, coordonnées, devise, préfixe et compteur de reçus, message, politique d'échange, TVA, objectif mensuel |

### Quatre règles posées dans le code

1. **L'argent en entiers.** Tout est stocké en centimes (`38 000 FCFA` → `3800000`).
   Les décimaux font perdre un franc de temps en temps — inacceptable sur une caisse.
2. **Le coût figé sur la ligne de vente.** Chaque ligne garde le prix d'achat du
   jour. Sinon un réapprovisionnement plus cher réécrirait toute l'histoire des marges.
3. **Aucune suppression de vente en usage normal.** On annule : le stock revient,
   le numéro de reçu reste réservé, le reçu porte la mention « vente annulée ».
4. **Rien ne part à l'imprimante sans être assaini.** Les polices intégrées au
   PDF ne couvrent que le latin : un émoji ou un tiret cadratin disparaîtrait
   silencieusement du reçu. `texteImprimable()` convertit ce qui a un
   équivalent et retire le reste — l'émoji, lui, reste dans le message WhatsApp.

---

## L'organisation des fichiers

```
lib/
  main.dart              point d'entrée, initialisation du français
  app.dart               thème, langue, écran de démarrage
  coeur/
    argent.dart          montants en centimes, dates, identifiants
    constantes.dart      catégories, textures, longueurs, couleurs, devises
    theme.dart           les trois palettes et le thème Material 3
    logos.dart           les huit logos en SVG
    composants.dart      tuiles, pastilles, champs, blocs partagés
  donnees/
    modeles.dart         Produit, Client, Vente, LigneVente, Dépense…
    depot.dart           SQLite : schéma, requêtes, sauvegarde JSON
    demo.dart            catalogue de démonstration du premier lancement
  etat/
    boutique.dart        l'état de la boutique et toutes les opérations
    indicateurs.dart     chiffre d'affaires, marges, classements, séries
  ecrans/
    coque.dart           les cinq onglets et le bouton « Vendre »
    accueil.dart
    produits/            liste, fiche, édition
    ventes/              choix des articles, encaissement, liste, détail
    recu/                document PDF + aperçu, impression, partage
    clients/             liste, fiche, édition, sélecteur de vente
    depenses/
    rapports/
    parametres/
```

L'état complet de la boutique est tenu **en mémoire** et rechargé depuis SQLite
au démarrage. Une boutique de mèches manipule des centaines d'articles et
quelques milliers de ventes : tout y tient largement, les écrans et les rapports
sont donc instantanés, et SQLite reste la source de vérité qui reçoit chaque
modification.

---

## Les tests

`flutter test` — **60 tests**, tous au vert.

| Fichier | Ce qu'il vérifie |
| --- | --- |
| `test/argent_test.dart` | Saisie et affichage des montants, devises sans centimes, numérotation des reçus, calculs de dates |
| `test/vente_test.dart` | Totaux, remises, marge (la livraison n'est pas un bénéfice), statuts de paiement, reste à payer, marge d'un article |
| `test/boutique_test.dart` | Sur une vraie base SQLite : sortie de stock à la vente, numérotation continue, acompte puis solde, services sans stock, annulation qui rend le stock, bénéfice net, classement au bénéfice, aller-retour sauvegarde |
| `test/recu_test.dart` | Le PDF se fabrique vraiment en A5 et en ticket, pour les huit logos et les trois palettes, à crédit comme annulé ; assainissement du texte imprimé ; message WhatsApp |
| `test/ecrans_test.dart` | L'application se lance, les cinq onglets se dessinent sur un écran de téléphone, la recherche filtre, et le **parcours complet de vente** enregistre bien la vente et décrémente le stock |

Deux bugs réels ont été trouvés par ces tests pendant le développement :
l'espace fine insécable des milliers qui disparaissait du reçu imprimé
(« 38 000 » devenait « 38000 »), et deux débordements de mise en page sur écran
étroit.

---

## Lancer et construire

```bash
flutter pub get          # installer les dépendances
flutter run              # lancer sur un téléphone branché ou un émulateur
flutter test             # les 60 tests
flutter analyze          # l'analyse statique
flutter build apk --release   # produire l'APK à installer sur Android
```

L'APK se retrouve dans `build/app/outputs/flutter-apk/app-release.apk`.

---

## Ce qui reste à faire

- **Impression thermique Bluetooth** (`esc_pos_utils_plus`) — le format ticket
  est déjà généré, il manque le pilote Bluetooth
- Relances d'impayés automatiques, commandes et arrivages, fidélité,
  sauvegarde en ligne, plusieurs vendeuses — voir `05-fonctionnalites.md`
- Polices de marque embarquées (Playfair Display) pour les titres et le reçu :
  aujourd'hui l'application utilise la serif du système et le PDF les polices
  standard, ce qui garantit un fonctionnement hors-ligne total
