# Plan de construction — Flutter

Un seul code source, deux applications : **Android et iPhone**. Tous les paquets retenus
sont éprouvés et gratuits.

---

## Les paquets

| Besoin | Solution | Pourquoi celle-là |
| --- | --- | --- |
| Base de données locale | `drift` (SQLite) | Marche sans internet, et le SQL rend les rapports faciles à calculer même avec des milliers de ventes |
| Organisation de l'app | `flutter_riverpod` | La référence actuelle pour tenir l'état d'une app Flutter proprement quand elle grandit |
| Reçu PDF & impression | `pdf` + `printing` | Le duo standard : fabrique le A5, montre l'aperçu, parle à l'imprimante et à AirPrint |
| Ticket thermique | `esc_pos_utils_plus` + `print_bluetooth_thermal` | Pilote les imprimantes 58 et 80 mm du marché en Bluetooth, sans matériel propriétaire |
| Envoi WhatsApp | `share_plus` + `url_launcher` | Partage le PDF dans n'importe quelle app, ou ouvre la conversation via `wa.me` |
| Graphiques | `fl_chart` | Léger, joli, et il se colore avec la palette de la marque |
| Photos d'articles | `image_picker` + `path_provider` | Photo prise avec l'appareil et rangée dans l'app, compressée |
| Polices de la marque | `google_fonts` | La typographie choisie, embarquée dans l'app |
| Français & devises | `intl` + `flutter_localizations` | Dates et montants au format local |
| Sauvegarde | `file_picker` + export JSON | Un fichier que tu maîtrises, à t'envoyer et à réimporter n'importe quand |

---

## Le modèle de données

| Table | Colonnes principales |
| --- | --- |
| `produits` | référence, nom, catégorie, texture, longueur, couleur, origine, densité, prix d'achat, prix de vente, stock, seuil d'alerte, photo, fournisseur, actif |
| `clients` | nom, téléphone, WhatsApp, e-mail, ville, adresse, anniversaire, note |
| `fournisseurs` | nom, pays, contact, délai, note |
| `ventes` | numéro, date, cliente, remise globale, frais de livraison, moyen de paiement, canal, montant payé, statut, note, vendeuse |
| `lignes_vente` | vente, article, désignation figée, quantité, prix unitaire, remise, **coût d'achat figé** |
| `depenses` | date, catégorie, libellé, montant, moyen de paiement, fournisseur |
| `mouvements_stock` | date, article, type (entrée / vente / retour / perte / ajustement), quantité, stock après, motif, vente liée |
| `parametres` | marque, slogan, logo, coordonnées, devise, préfixe et compteur de reçus, message, politique d'échange, TVA, objectif mensuel |

### Trois règles posées dans le code

1. **L'argent en entiers.** Tout est stocké en centimes. Les décimaux font perdre un franc de
   temps en temps — inacceptable sur une caisse.
2. **Le coût figé sur la ligne de vente.** Chaque ligne garde le prix d'achat du jour. Sinon
   un réapprovisionnement plus cher réécrirait toute l'histoire des marges.
3. **Aucune suppression de vente.** On annule, on ne détruit pas : le numéro de reçu reste
   réservé et la piste comptable reste continue.

### Organisation des dossiers

```
lib/
  core/            thème, formats, devise, extensions, widgets partagés
  data/            base drift, tables, DAO, sauvegarde JSON
  features/
    accueil/       tableau de bord
    produits/      catalogue, fiche article, mouvements
    ventes/        panier, encaissement, reçu
    recu/          génération PDF, ticket ESC/POS, partage
    clients/       fiches, historiques, relances
    depenses/
    rapports/
    parametres/
```

---

## L'ordre de construction

Chaque étape donne une application installable et utilisable. Tu peux t'arrêter, tester,
corriger le tir.

**Étape 1 — Le socle et le stock**
Base de données, thème de la marque, catalogue, saisie des articles, mouvements de stock,
alertes. À la fin : tu peux déjà remplacer ton cahier.

**Étape 2 — La vente et le reçu**
Panier, remises, encaissement, paiement partiel, numérotation, reçu A5 et ticket, PDF,
impression, WhatsApp. C'est le cœur : le reste sert celui-là.

**Étape 3 — Les clientes et les dépenses**
Fiches, historiques, soldes dus, relances. Puis les dépenses, pour que le bénéfice affiché
soit le vrai.

**Étape 4 — Le tableau de bord et les rapports**
Chiffres du jour et du mois, objectif, graphiques, articles rentables, canaux de vente.

**Étape 5 — Finitions et livraison**
Sauvegarde et restauration, icône, écran d'accueil, tests sur un vrai téléphone, puis le
fichier APK à installer — et la mise sur le Play Store si souhaité.
