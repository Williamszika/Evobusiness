# Donner l'application à quelqu'un d'autre

L'application n'est pas pour celui qui la construit : elle est pour la
personne qui vend. Ce document règle la seule question qui compte alors —
**comment elle arrive sur SON téléphone, sans toi.**

---

## La réponse courte : la version web. Ce n'est plus un compromis.

Tant qu'il s'agissait de ton propre iPhone, la vraie application native était
défendable : ton Mac est à côté, le câble aussi.

**Dès que le téléphone appartient à quelqu'un d'autre, cette voie s'effondre.**

| | Ton téléphone | Le téléphone d'une amie |
| --- | --- | --- |
| Application native, identifiant gratuit | tenable | **impossible** |
| Application native, 99 $/an + TestFlight | tenable | tenable |
| Version web, un lien | tenable | **évident** |

### Pourquoi la voie gratuite s'effondre

Une application signée avec un identifiant Apple gratuit expire au bout de
**7 jours**. Elle se re-signe par AltStore — mais AltStore exige que le
téléphone soit **sur le même Wi-Fi que TON Mac**, ou branché à lui.

Concrètement : ton amie devrait passer chez toi **toutes les semaines**, sans
en sauter une, sinon son outil de caisse refuse de s'ouvrir. Ce n'est pas une
solution, c'est une servitude.

### La voie payante, elle, fonctionne à distance

Avec un compte développeur Apple (99 $/an ≈ 65 000 FCFA), **TestFlight** règle
le problème : ton amie reçoit un lien, installe l'application TestFlight, et
l'application arrive. Aucun câble, aucun ordinateur, rien à faire chez toi.

La contrainte restante est légère : chaque version expire au bout de 90 jours
et doit être renvoyée. Trois minutes, quatre fois par an.

### Et la version web ne demande rien du tout

Un lien. Elle l'ouvre dans Safari, fait « Sur l'écran d'accueil », c'est fini.
Icône, plein écran, fonctionne sans connexion, aucune expiration, aucun compte,
aucun ordinateur — et **aucune dépendance à toi**.

C'est exactement le même code, donc exactement les mêmes ventes, les mêmes
reçus, la même comptabilité et le même PDF pour les impôts.

---

## Avant de lui envoyer : une chose à faire, une seule

L'adresse actuelle passe par un relais bénévole (githack), sans garantie de
durée ni de débit. Cela convient pour essayer. **Cela ne convient pas pour
faire tourner le commerce de quelqu'un d'autre.**

L'application est déjà compilée et déposée sur la branche `gh-pages`. Il ne
manque qu'un réglage, que seul le propriétaire du dépôt peut faire :

> **Settings → Pages → Source : « Deploy from a branch » → Branch :
> `gh-pages`, dossier `/ (root)` → Save**

Deux minutes plus tard, l'adresse devient
`https://williamszika.github.io/Evobusiness/` — hébergée par GitHub, stable,
gratuite, mise à jour toute seule à chaque modification. **C'est cette
adresse-là qu'il faut donner à ton amie**, pas l'autre.

---

## Le message à lui envoyer

À copier tel quel sur WhatsApp, en remplaçant l'adresse une fois Pages activé :

> Salut ! Voici ton application de gestion pour la boutique 💇🏾‍♀️
>
> **1.** Ouvre ce lien **avec Safari** (pas Chrome, c'est important) :
> https://williamszika.github.io/Evobusiness/
>
> **2.** Appuie sur le bouton **Partager** (le carré avec la flèche vers le
> haut, en bas de l'écran), puis descends et choisis **« Sur l'écran
> d'accueil »**.
>
> **3.** L'icône apparaît sur ton téléphone comme une vraie application. C'est
> par là que tu ouvres, plus par Safari.
>
> Elle marche **sans connexion internet**. Tu peux vendre en pleine coupure.
>
> **4.** À la première ouverture, il y a des articles d'exemple pour que tu
> voies à quoi ça ressemble. Quand tu es prête à saisir ton vrai stock :
> **Paramètres → Repartir de zéro**.
>
> **5.** Toujours dans **Paramètres**, mets ton nom de business, ton téléphone,
> ton WhatsApp et ta ville : ils s'impriment sur chaque reçu.
>
> ⚠️ **Le plus important :** tous les 2-3 jours, va dans
> **Paramètres → Sauvegarde → « Mettre à l'abri »** et envoie-toi le fichier
> sur WhatsApp. C'est ta seule protection si tu perds le téléphone.

---

## Ce qu'elle doit comprendre, et personne d'autre ne lui dira

**Ses données sont sur son téléphone, nulle part ailleurs.**

Il n'y a pas de serveur, pas de compte, personne d'autre qui possède une copie.
C'est une bonne nouvelle — ses chiffres n'appartiennent qu'à elle — mais cela
signifie aussi :

- si elle retire l'icône de l'écran d'accueil, **tout part** ;
- si elle efface les données de Safari, **tout part** ;
- si le téléphone est perdu, volé ou noyé, **tout part**.

La version web **ne garde pas de copies automatiques** (le navigateur pouvant
faire son ménage, en déposer là aurait été une fausse sécurité). L'application
réclame donc une sauvegarde tous les trois jours, et cette demande n'est pas
décorative : **c'est le seul filet.**

Une sauvegarde envoyée sur WhatsApp se retrouve toujours, même après un
téléphone perdu. C'est l'habitude à lui faire prendre dès le premier jour.

---

## Si un jour elle veut la vraie application

Rien à réécrire : c'est le même code. Il faudra un compte développeur Apple
(99 $/an) et passer par TestFlight — voir
[`docs/11-application-iphone.md`](11-application-iphone.md).

Ses données la suivront : **Paramètres → Sauvegarde → « Mettre à l'abri »** sur
la version web, puis **« Depuis un fichier »** dans la nouvelle. Tout revient,
y compris la numérotation des reçus déjà émis.
