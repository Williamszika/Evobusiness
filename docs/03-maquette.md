# La maquette — les 8 écrans

Version visuelle : ouvre [`planche-de-proposition.html`](planche-de-proposition.html), les
écrans y sont dessinés à taille réelle de téléphone.

Barre de navigation basse, cinq entrées : **Accueil · Stock · Vendre · Clientes · Rapports**.

---

## 1 · Accueil

Répond à la question du matin — « combien j'ai fait, qu'est-ce qui cloche » — sans scroller.

- Bandeau principal : **encaissé aujourd'hui**, nombre de ventes, bénéfice du jour
- Deux tuiles : chiffre d'affaires du mois, bénéfice du mois
- Objectif du mois avec barre de progression et le reste à faire en jours
- **À surveiller** : articles en stock bas, impayés en retard (avec bouton de relance)
- Dernières ventes, avec accès direct au reçu

## 2 · Nouvelle vente — les articles

- Recherche par nom, longueur ou référence
- Filtres par catégorie : Mèches, Perruques, Closure, Accessoires
- Chaque ligne montre **le stock restant en direct** : impossible de vendre ce qu'on n'a plus
- Les articles en rupture apparaissent grisés, ceux en stock bas signalés
- Barre du bas permanente : nombre d'articles, total, bouton « Suivant »

## 3 · Encaisser

- Cliente : sélection dans le répertoire, ou vente au comptant sans fiche
- Récapitulatif des lignes, remise, frais de livraison, **total**
- Moyen de paiement : espèces, mobile money, virement, carte
- Montant reçu — avec **paiement partiel** prévu dès le départ, car c'est la réalité du
  terrain, pas une option
- Note libre sur la vente
- Bouton final : « Valider la vente et faire le reçu »

## 4 · Le reçu

- Aperçu réel du document avant impression
- Bascule **A5 / A4** ou **ticket 80 mm**
- Trois sorties, sans quitter l'écran : **Imprimer**, **PDF**, **WhatsApp**
- Détail complet dans [`04-le-recu.md`](04-le-recu.md)

## 5 · Mon stock

- En-tête : nombre d'articles et **valeur totale du stock**
- Filtres rapides : Tout · Stock bas · Rupture · par catégorie
- Trié par urgence, pas par ordre alphabétique : ce qui manque remonte tout seul
- Chaque ligne : longueur, couleur, marge unitaire, quantité, état (OK / Bas / Rupture)

## 6 · Fiche article

- Photo, désignation complète : origine · texture · longueur · couleur · densité
- Prix d'achat et prix de vente côte à côte
- **Marge par pièce en valeur et en pourcentage** — le chiffre qui dit quoi racheter et
  quoi arrêter
- Stock actuel et quantité vendue sur 30 jours
- Historique des mouvements : ventes, arrivages, retours, ajustements

## 7 · Fiche cliente

- Total dépensé et nombre de commandes
- **Reste à payer** mis en évidence, avec l'ancienneté de la dette
- Boutons Relancer (WhatsApp) et Appeler
- Historique des reçus avec leur statut (Payé / Partiel)
- Note libre : préférences, longueurs habituelles, anniversaire — c'est ce qui fait revenir

## 8 · Rapports

- Période : 7 jours · 30 jours · 6 mois · année
- Chiffre d'affaires avec évolution vs période précédente et histogramme mensuel
- Bénéfice net et panier moyen
- **Ce qui rapporte le plus** — classé par bénéfice, pas par quantité vendue
- Ce qui dort : articles peu vendus, avec le nombre de mois de stock
- D'où viennent les ventes : WhatsApp, Instagram, boutique, bouche-à-oreille

---

## Écrans secondaires

- **Dépenses** — saisie rapide par catégorie, liste mensuelle, total
- **Fournisseurs** — contacts, pays, délais, historique des commandes
- **Paramètres** — marque, logo, coordonnées du reçu, devise, préfixe et compteur de reçus,
  message de remerciement, politique d'échange, objectif mensuel, sauvegarde/restauration
