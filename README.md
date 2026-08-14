# Evobusiness — Application de gestion « mèches & perruques »

Application mobile de gestion pour une boutique de mèches, perruques et accessoires
capillaires : catalogue, stock, ventes, **reçus imprimables**, clientes, dépenses et rapports.

> **État du projet : proposition — aucun code applicatif n'est encore écrit.**
> Ce dépôt contient pour l'instant la planche de proposition (noms, logos, palettes,
> maquette, plan technique). L'application sera développée **en Flutter** une fois les
> choix validés.

---

## Par où commencer

Ouvre **[`docs/planche-de-proposition.html`](docs/planche-de-proposition.html)** dans un
navigateur : c'est la version visuelle et cliquable de tout ce qui suit (les logos y sont
dessinés, les écrans maquettés, et les choix se cochent).

| Document | Contenu |
| --- | --- |
| [`docs/01-noms.md`](docs/01-noms.md) | 20 noms de business classés par intention, recommandations, checklist de vérification |
| [`docs/02-identite-visuelle.md`](docs/02-identite-visuelle.md) | 3 palettes, typographie, 8 pistes de logo |
| [`docs/03-maquette.md`](docs/03-maquette.md) | Les 8 écrans de l'application, décrits un par un |
| [`docs/04-le-recu.md`](docs/04-le-recu.md) | Les deux formats de reçu et les mentions obligatoires |
| [`docs/05-fonctionnalites.md`](docs/05-fonctionnalites.md) | Périmètre version 1 / plus tard |
| [`docs/06-plan-flutter.md`](docs/06-plan-flutter.md) | Paquets, modèle de données, règles de code, étapes |
| [`docs/logos/`](docs/logos/) | Les 8 logos en SVG, prêts à l'emploi |

---

## Les décisions à prendre

1. **Le nom** du business — voir `docs/01-noms.md`
2. **La palette et le logo** — voir `docs/02-identite-visuelle.md`
3. **Le périmètre de la version 1** — voir `docs/05-fonctionnalites.md`

Et les informations à fournir pour démarrer : devise, ville, téléphone/WhatsApp du reçu,
message de remerciement, politique d'échange, imprimante disponible.

---

## Ce que fera l'application (proposition)

- Catalogue : mèches, perruques, closures/frontals, accessoires, soins, services de pose —
  avec longueur, texture, couleur, origine, densité et photo
- Stock en direct, seuils d'alerte, ruptures, historique des mouvements
- Prix d'achat + prix de vente → **marge calculée automatiquement**
- Vente à plusieurs articles, remises, frais de livraison
- **Paiement partiel** (acompte) et suivi des impayés
- **Reçu numéroté, imprimable en A5 ou en ticket 80 mm, exportable en PDF, envoyable par WhatsApp**
- Fiches clientes avec historique, total dépensé, solde dû et préférences
- Dépenses (marchandise, fret, douane, publicité, loyer…)
- Tableau de bord, objectif mensuel, rapports et articles les plus rentables
- **100 % hors-ligne**, sauvegarde et restauration par fichier

## Pile technique retenue

Flutter (Android + iOS) · Drift/SQLite en local · Riverpod · `pdf` + `printing` pour les
reçus · `esc_pos_utils_plus` pour le ticket thermique Bluetooth. Détails dans
`docs/06-plan-flutter.md`.
