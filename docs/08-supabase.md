# Brancher l'application à Supabase

> **Décision prise : pas de serveur pour l'instant.** L'usage est un seul
> téléphone, et la sauvegarde automatique intégrée à l'application couvre le
> risque — voir [`09-serveur-ou-pas.md`](09-serveur-ou-pas.md). Ce document
> reste valable pour le jour où une deuxième personne vendra.

**Réponse courte : oui, et c'est une bonne idée.** Mais pas comme « le
serveur » de l'application — comme sa **sauvegarde vivante**.

---

## Pourquoi Supabase ne doit pas devenir le serveur principal

L'application vend aujourd'hui **sans réseau**. C'est un choix, pas un
raccourci : une cliente au marché, une coupure de connexion, un forfait
épuisé en fin de mois — dans tous ces cas, la vente doit se faire et le reçu
doit sortir.

Si Supabase devenait la source de vérité, chaque vente attendrait une réponse
du serveur. Sans réseau, plus de vente. Ce serait une régression, pas une
amélioration.

**Le bon montage :** SQLite reste la vérité sur le téléphone. Supabase en est
un miroir qui se met à jour dès que la connexion revient.

```
   Téléphone                              Supabase
┌──────────────┐   pousse ce qui a changé  ┌──────────────┐
│   SQLite     │ ────────────────────────► │  PostgreSQL  │
│  (vérité)    │ ◄──────────────────────── │   (miroir)   │
└──────────────┘   tire ce qui a changé    └──────────────┘
      ▲
      │ la vente et le reçu ne dépendent jamais du réseau
```

---

## Ce que ça apporte concrètement

| Besoin | Aujourd'hui | Avec Supabase |
| --- | --- | --- |
| Téléphone perdu ou volé | fichier de sauvegarde à faire à la main | tout est déjà en ligne, on se reconnecte et on retrouve la boutique |
| Deuxième téléphone / une vendeuse | impossible | les deux voient le même stock et les mêmes ventes |
| Consulter ses chiffres depuis un ordinateur | impossible | possible plus tard, sans nouvelle application |
| Catalogue partageable par lien | impossible | possible plus tard |

---

## Comment la synchronisation fonctionne

Trois décisions qui rendent le tout fiable :

1. **Les identifiants sont créés par le téléphone**, pas par le serveur. Une
   vente enregistrée dans un taxi sans réseau a déjà son identifiant définitif
   et son numéro de reçu ; rien à renuméroter à la reconnexion.
2. **Chaque ligne porte `maj_le`.** La synchronisation ne demande jamais
   « donne-moi tout », mais « donne-moi ce qui a changé depuis la dernière
   fois ». C'est rapide et ça consomme très peu de forfait.
3. **Rien n'est effacé pour de bon** : une suppression pose une date dans
   `supprime_le`. Sans cela, l'autre téléphone n'aurait aucun moyen de savoir
   qu'il doit supprimer de son côté — la ligne réapparaîtrait à chaque
   synchronisation.

En cas de conflit — la même fiche modifiée sur deux téléphones — **la
modification la plus récente gagne**. Pour ce métier c'est le bon compromis :
les cas de conflit réel sont rares, et une fusion plus fine coûterait beaucoup
de complexité pour presque rien.

Une précision importante : le **stock** ne se recalcule pas à partir des deux
côtés. Ce sont les **mouvements de stock** qui se synchronisent, et la quantité
se reconstruit à partir d'eux. Sinon deux ventes simultanées sur deux
téléphones écraseraient l'une l'autre.

---

## La sécurité, en premier

Le schéma active la **sécurité par ligne** (Row Level Security) sur toutes les
tables. Sans elle, la clé publique de l'application — qui est dans l'app, donc
lisible par n'importe qui — donnerait accès aux ventes de toutes les boutiques.

Chaque table porte un `boutique_id`, et la règle est la même partout : on ne
voit et on ne modifie que les lignes de la boutique dont on est membre.

Le schéma prévoit déjà **plusieurs personnes par boutique** (tables
`boutiques` et `membres`), pour éviter une migration douloureuse le jour où
elle embauche une vendeuse.

---

## Mettre en place

1. Créer un projet gratuit sur [supabase.com](https://supabase.com).
2. Ouvrir **SQL Editor → New query**, coller le contenu de
   [`supabase/schema.sql`](../supabase/schema.sql), exécuter.
3. Dans **Authentication → Providers**, activer **Email**.
4. Relever dans **Project Settings → API** :
   - l'**URL du projet** (`https://xxxxx.supabase.co`)
   - la clé **anon / public**

Ces deux valeurs sont à me transmettre. La clé `anon` est faite pour être
embarquée dans l'application — ce n'est pas un secret, c'est la sécurité par
ligne qui protège les données. **En revanche la clé `service_role` ne doit
jamais entrer dans l'application** : elle contourne toutes les règles.

### Le coût

L'offre gratuite de Supabase donne 500 Mo de base et 1 Go de stockage. Une
boutique de mèches produit quelques milliers de lignes par an et des photos
compressées : elle y tiendra plusieurs années sans payer.

Le seul point d'attention : un projet gratuit est **mis en pause après une
semaine sans activité**. Une synchronisation quotidienne suffit à l'éviter.

---

## Ce qu'il reste à écrire côté application

Le schéma est prêt, l'application ne l'utilise pas encore. Il manque :

- le paquet `supabase_flutter` et l'écran de connexion (e-mail + mot de passe) ;
- une **file d'attente locale** : chaque modification faite hors ligne s'y
  empile et part à la reconnexion ;
- l'envoi et la récupération des changements par `maj_le` ;
- la reconstruction du stock à partir des mouvements ;
- l'envoi des photos vers le stockage Supabase ;
- un indicateur discret dans l'application : « synchronisé il y a 3 minutes »,
  « 4 ventes en attente d'envoi ».

Compter **deux à trois jours de travail**, et surtout des tests sérieux sur les
cas pénibles : réseau qui coupe au milieu d'un envoi, deux téléphones qui
vendent le même article en même temps, restauration sur un téléphone neuf.

**À décider avant de commencer :** est-ce qu'une deuxième personne utilisera
l'application ? Si oui, il faut soigner la reconstruction du stock. Si c'est
juste elle sur un seul téléphone, la synchronisation devient une simple
sauvegarde automatique — deux fois moins de travail.
