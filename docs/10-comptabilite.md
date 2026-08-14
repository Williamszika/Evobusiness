# La comptabilité et le document pour les impôts

L'application tient un **livre de recettes et de dépenses** et l'édite en PDF,
prêt à imprimer, à archiver, ou à remettre au comptable et à l'administration.

Accès : onglet **Rapports → icône Comptabilité**, ou depuis l'accueil.

---

## La règle qui gouverne tout : l'encaissement

**Une recette est comptée le jour où l'argent arrive**, pas le jour de la vente.

C'est la convention des petites entreprises, et surtout c'est la réalité de la
caisse : une perruque vendue à crédit en janvier et payée en mars n'a rien mis
dans le tiroir en janvier.

Concrètement :

| Situation | Ce que fait l'application |
| --- | --- |
| Vente payée comptant | Une recette, à la date de la vente |
| Acompte en janvier, solde en mars | **Deux recettes**, une en janvier et une en mars |
| Vente livrée mais impayée | Aucune recette — elle apparaît en « restant dû » |
| Vente annulée et remboursée | La recette passée **reste**, et un montant négatif est inscrit au jour du remboursement |

Ce dernier point mérite d'être compris : on ne réécrit jamais un mois déjà
clos. Si une vente de février est remboursée en août, février garde sa recette
et août porte le remboursement. C'est ainsi qu'un livre de comptes se tient.

### Ce que ça a demandé au modèle de données

L'application savait *combien* une cliente avait payé, mais pas *quand*. Une
table **`reglements`** a donc été ajoutée : chaque encaissement y porte sa
date, son montant et son mode de paiement. Sans elle, un solde réglé trois mois
plus tard aurait été compté dans le mois de la vente — et le document aurait
été faux.

La date est modifiable au moment d'encaisser un solde : si l'argent a été reçu
mardi et saisi vendredi, c'est mardi qui compte.

---

## Ce que montre l'écran

Trois chiffres, pour une période au choix — **mois, trimestre ou année** :

- **Recettes encaissées** — ce qui est réellement entré
- **Dépenses payées** — marchandise, fret, douane, publicité, loyer…
- **Résultat** — la différence, bénéfice ou perte

Puis, pour éviter les malentendus :

- **Ventes facturées sur la période** — utile à savoir, mais ce n'est pas la recette
- **Restant dû par les clientes** à la fin de la période

Et enfin le détail : mois par mois, ventilation des dépenses par catégorie,
et les derniers encaissements.

---

## Le document PDF

Bouton **« Éditer le document pour les impôts »**. Il contient :

1. **En-tête** — nom, coordonnées, période, devise, date d'édition
2. **Récapitulatif** — recettes, dépenses, résultat, plus les informations complémentaires
3. **Livre des recettes** — chaque encaissement : date, numéro de reçu, cliente, mode de paiement, montant
4. **Registre des dépenses** — date, libellé, catégorie, mode de paiement, montant
5. **Ventilation des dépenses** par catégorie, avec les parts
6. **Recettes par mode de paiement**
7. **Récapitulatif mois par mois**
8. **Mentions** expliquant la méthode, et un emplacement de **date et signature**

Chaque page porte le nom de la boutique, la période et une **pagination
« page N / M »** : une liasse dont il manque une feuille se repère
immédiatement.

Le document se produit sur autant de pages que nécessaire — une année chargée
tient sans problème.

Sorties : **Imprimer** (imprimante ou AirPrint) et **Envoyer ou enregistrer le
PDF** (WhatsApp, mail, Drive, iCloud).

---

## Ce que ce document est, et ce qu'il n'est pas

**C'est** un livre de recettes et de dépenses complet, daté, numéroté, tenu à
l'encaissement, et cohérent avec les reçus émis — ceux-ci étant numérotés sans
interruption et conservés dans l'application.

**Ce n'est pas** une liasse fiscale, ni un bilan, ni une déclaration. Selon le
pays et le régime (micro-entreprise en France, régime simplifié ou SYSCOHADA en
zone OHADA), l'administration peut exiger d'autres pièces ou une présentation
particulière.

**Le bon usage :** montrer ce document à un comptable une première fois, et lui
demander s'il lui convient tel quel. S'il manque une colonne ou une mention,
c'est une modification de quelques lignes.

---

## Ce qui est vérifié par les tests

`test/comptabilite_test.dart` — 18 tests, dont :

- une vente payée comptant tombe dans son mois ;
- **un acompte et son solde tombent dans deux mois différents** ;
- une vente impayée n'est pas une recette, mais figure en créance ;
- un remboursement n'efface pas la recette passée, il l'annule à sa date ;
- sur l'année entière, une vente annulée s'annule bien à zéro ;
- le résultat, les ventilations et le récapitulatif mensuel ;
- le PDF se fabrique, y compris sur une période vide et sur une année à
  60 encaissements (plusieurs pages) ;
- **l'invariant** : toute vente encaissée porte ses règlements — c'est
  précisément ce qui manquait au jeu de démonstration et faisait afficher zéro
  recette au premier lancement.
