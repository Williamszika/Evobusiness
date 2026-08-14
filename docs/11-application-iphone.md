# La vraie application iPhone : ce que ça change, et ce que ça coûte

L'application existe aujourd'hui sous deux formes, **à partir du même code** :

| | Version web installée | Vraie application iPhone |
| --- | --- | --- |
| Icône sur l'écran d'accueil | oui | oui |
| Plein écran, sans barre Safari | oui | oui |
| Fonctionne sans connexion | oui | oui |
| Reçus PDF, impression, WhatsApp | oui | oui |
| Photos des articles | oui | oui |
| **Coût** | **0** | **99 $/an**, ou gratuit avec une contrainte lourde |
| **Durée de vie** | **illimitée** | 1 an, ou **7 jours** en version gratuite |
| Copies de sauvegarde automatiques | **non** | oui, 5 copies tournantes |
| Sauvegarde iCloud automatique | non | oui |
| Ordinateur nécessaire | non | oui, au moins une fois |

C'est le tableau qui décide, pas la préférence : à l'usage, les deux se
ressemblent au point qu'on ne les distingue pas.

---

## Ce qui est prêt

Tout, sauf la signature. **Et ce n'est pas une supposition : l'application a
été compilée pour de vrai.**

> Construction du 14/08/2026 — analyse, 98 tests, compilation iOS et
> empaquetage : **succès en 4 min 50 s**, paquet de **10,8 Mo**.
> ([exécution n° 1](https://github.com/Williamszika/Evobusiness/actions/runs/31839842266))

C'est le point qui méritait d'être vérifié plutôt qu'affirmé : plusieurs
composants de l'application embarquent du code natif (base de données,
impression, appareil photo, sélecteur de fichiers), et c'est exactement là que
les compilations iOS échouent d'habitude. Aucune n'a bronché.

- Le projet iOS est configuré : nom « Ma Boutique », identifiant
  `com.evobusiness.evobusiness`, autorisations caméra et photothèque rédigées
  en français ;
- les **15 icônes** sont générées à partir du logo « La Couronne », sans canal
  alpha et sans coins arrondis — les deux motifs de refus classiques d'Apple ;
- le workflow [`construire-ios.yml`](../.github/workflows/construire-ios.yml)
  compile l'application **sur un Mac prêté par GitHub** et dépose un `.ipa`
  dans l'onglet **Actions**.

Compiler pour iOS exige macOS et Xcode : aucune machine Linux ou Windows n'en
est capable, quelle que soit la version de Flutter. C'est pourquoi la
construction passe par GitHub — c'est la seule façon d'obtenir un `.ipa` sans
posséder de Mac.

Le paquet produit est **non signé**, volontairement : signer demande un
identifiant Apple et un certificat, qui n'ont rien à faire dans un dépôt
public.

---

## Les trois voies pour l'installer, et leur vrai prix

### 1. Compte développeur Apple — 99 $/an, environ 65 000 FCFA

La voie propre. L'application est signée pour **un an**, s'installe par un
lien, et se comporte comme n'importe quelle application achetée : sauvegarde
iCloud comprise.

Deux façons de la distribuer sans passer par l'App Store :

- **Distribution ad hoc** — l'identifiant du téléphone est enregistré une fois,
  l'application est installée par un lien, et vaut **un an** ;
- **TestFlight** — installation par un simple lien d'invitation, mais chaque
  version **expire au bout de 90 jours** et doit être renvoyée.

### 2. Identifiant Apple gratuit — et l'application meurt tous les 7 jours

Techniquement possible, avec AltStore, SideStore ou Sideloadly, depuis un
ordinateur. Et à déconseiller franchement ici :

> Une application signée avec un identifiant gratuit **cesse de s'ouvrir au
> bout de 7 jours**. Il faut la re-signer chaque semaine, sans exception.

Les données ne sont pas perdues, mais l'application refuse de démarrer. Pour un
outil de caisse, cela signifie : un jour, devant une cliente, plus de reçu.
Un logiciel qu'on doit réparer tous les lundis n'est pas un logiciel de
travail.

### 3. Rester sur la version web installée — 0 F, et rien à renouveler

C'est la solution en place. Icône sur l'écran d'accueil, plein écran, hors
connexion, sans date d'expiration, sans ordinateur, sans compte Apple.

---

## Le vrai avantage technique de la version native

Il tient en un mot : **la durabilité des données**. Et il compte double, car
il joue à deux endroits.

**1. Là où vivent les données.**

- **Version native** — dans l'espace privé de l'application, sauvegardé par
  iCloud. Elles ne disparaissent que si l'application est supprimée.
- **Version web installée** — dans le stockage que Safari réserve à cette
  icône. Elles survivent aux redémarrages et à l'usage normal, mais peuvent
  être perdues dans trois cas : l'icône est retirée de l'écran d'accueil,
  l'historique Safari est effacé pour ce site, ou le téléphone arrive à
  saturation de mémoire.

**2. Les copies automatiques — et c'est le point le moins connu.**

L'application sait garder **cinq sauvegardes tournantes**. Sur iPhone natif,
elle le fait. **Sur la version web, elle ne le fait pas** : le navigateur
pouvant faire le ménage dans son stockage, y déposer des copies aurait donné
une fausse impression de sécurité. La version web a donc un filet en moins —
et, en compensation, elle réclame une mise à l'abri **tous les trois jours**
au lieu d'une fois par semaine (voir
[`docs/09-serveur-ou-pas.md`](09-serveur-ou-pas.md)).

C'est le vrai écart entre les deux versions. Sur des registres de ventes, il
n'est pas anodin.

**Ce qui le comble presque entièrement :** une sauvegarde envoyée sur WhatsApp
ou dans Drive protège **mieux** qu'iCloud et mieux que cinq copies locales —
elle est la seule qui survive à la perte ou au vol du téléphone. La discipline
compte ici davantage que la technique.

---

## Ce que je recommande

**Commencer sur la version web, et payer les 99 $ le jour où le chiffre
d'affaires les rend indolores.** Trois raisons :

1. 65 000 FCFA par an au démarrage d'un commerce, c'est deux mèches
   brésiliennes qu'on ne vend pas encore ;
2. la version gratuite native, qui expire tous les 7 jours, est un piège :
   elle a l'air de la bonne solution jusqu'au premier lundi oublié ;
3. **le code est le même.** Passer à la version native ne demande aucune
   réécriture — c'est tout l'intérêt d'avoir construit en Flutter. Le jour où
   la décision est prise, l'application est compilée et signée le jour même,
   et les données se transfèrent par une sauvegarde.

Le seul risque de la version web — la perte du stockage, sans copies
automatiques pour amortir — se couvre par une habitude : envoyer la sauvegarde
sur WhatsApp quand l'application le demande. Elle le demande tous les trois
jours, précisément parce qu'elle sait qu'elle n'a pas de filet local.

Et si la réponse est « je préfère la vraie application, tant pis pour les
99 $ » : tout est prêt, il n'y a qu'à signer. C'est une décision de budget,
pas une décision technique.

---

## Comment récupérer le `.ipa`

1. Onglet **Actions** du dépôt → **« Construire l'application iPhone »** ;
2. **Run workflow** (ou attendre : il se lance à chaque modification du code) ;
3. cinq minutes plus tard, l'archive **`MaBoutique-iphone-non-signee`** se
   télécharge en bas de la page. Elle reste disponible **90 jours**.

Ce fichier est ensuite signé, soit avec le compte développeur, soit avec
Sideloadly. Il ne s'installe pas tel quel : un iPhone refuse tout paquet non
signé, et c'est une bonne chose.
