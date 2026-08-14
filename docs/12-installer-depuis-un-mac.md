# Installer la vraie application sur l'iPhone, depuis un Mac

Ce document suppose un Mac et un câble. C'est la configuration la plus
confortable : elle permet d'installer l'application **gratuitement**, et de
rendre la limite des 7 jours presque invisible.

---

## D'abord, la règle d'or

> **Avant toute installation, réinstallation ou re-signature : enregistrer une
> sauvegarde.**
>
> Dans l'application : **Paramètres → Sauvegarde → « Mettre à l'abri »**.
> Envoie le fichier sur WhatsApp ou dans iCloud Drive.

Une application *rafraîchie* garde ses données. Une application *supprimée
puis réinstallée* les perd toutes — ventes, clientes, comptabilité. La
sauvegarde est ce qui rend cette différence sans conséquence.

---

## Deux chemins. Le premier est le bon.

### Chemin A — AltStore (recommandé)

AltStore installe l'application **et la re-signe toute seule** dès que
l'iPhone se trouve sur le même Wi-Fi que le Mac. C'est ce qui neutralise le
problème des 7 jours : tant que le Mac s'allume une fois par semaine à la
maison, l'application ne s'arrête jamais.

1. Sur le Mac, télécharger **AltServer** depuis [altstore.io](https://altstore.io)
   (gratuit) et le lancer.
2. Brancher l'iPhone au câble. Sur l'iPhone, répondre **« Se fier »** à la
   question *« Faire confiance à cet ordinateur ? »*.
3. Dans la barre de menus du Mac, icône AltServer → **Install AltStore** →
   choisir l'iPhone. Saisir un identifiant Apple (un identifiant **gratuit**
   suffit).
4. Sur l'iPhone : **Réglages → Général → VPN et gestion de l'appareil** →
   sélectionner le profil à ton nom → **Faire confiance**.
5. Télécharger le fichier de l'application (voir plus bas), puis dans
   **AltStore** sur l'iPhone : onglet **My Apps → +** → choisir le `.ipa`.

Ensuite, plus rien à faire : garder l'iPhone et le Mac sur le même Wi-Fi de
temps en temps suffit. AltStore prévient quand une re-signature approche.

### Chemin B — Xcode, en direct

Si Xcode est déjà installé, ou si le Mac sert aussi à modifier l'application :

```bash
git clone https://github.com/Williamszika/Evobusiness.git
cd Evobusiness
flutter pub get
open ios/Runner.xcworkspace
```

Dans Xcode : sélectionner la cible **Runner** → onglet **Signing &
Capabilities** → cocher **Automatically manage signing** → choisir son
identifiant Apple dans **Team**. Brancher l'iPhone, le sélectionner en haut,
puis **▶︎**.

Plus lourd à installer (Xcode pèse une quinzaine de gigaoctets), mais aucun
outil tiers, et l'application se réinstalle d'un clic.

---

## Où trouver le fichier de l'application

Une seule adresse, qui pointe toujours sur la dernière version :

    https://github.com/Williamszika/Evobusiness/releases/latest

Le fichier **`MaBoutique-non-signee.ipa`** (10,4 Mo) se télécharge d'un clic,
**sans compte GitHub** et sans rien à décompresser.

Une nouvelle version se fabrique en cinq minutes : onglet **Actions** →
**Construire l'application iPhone** → **Run workflow**. Elle apparaît à la
même adresse.

---

## Ce que la version gratuite impose vraiment

| | Identifiant Apple gratuit | Compte développeur (99 $/an) |
| --- | --- | --- |
| Validité de la signature | **7 jours** | 1 an |
| Re-signature | automatique par AltStore, sur le même Wi-Fi | aucune |
| Applications installées ainsi | 3 au maximum | 100 |

La limite des 7 jours n'est pas une limite d'usage : l'application fonctionne
normalement, hors connexion comprise. C'est uniquement sa **signature** qui
expire. Si elle expire, l'application refuse de s'ouvrir — **mais les données
restent intactes** et reviennent dès la re-signature.

Ne jamais la supprimer pour « réparer » : c'est là, et seulement là, que les
données se perdent.

---

## Faire passer les données de la version web à l'application

Les deux versions ne partagent pas leur stockage : l'application native
démarre vide. Le transfert prend une minute.

1. Dans la **version web** (l'icône actuelle sur l'écran d'accueil) :
   **Paramètres → Sauvegarde → « Mettre à l'abri »**. Enregistrer le fichier
   dans iCloud Drive ou se l'envoyer sur WhatsApp.
2. Ouvrir l'**application native** → **Paramètres → Sauvegarde → « Depuis un
   fichier »** → **« Choisir le fichier »** → sélectionner la sauvegarde.

Tout revient : articles, stock, clientes, ventes, reçus déjà numérotés,
dépenses, encaissements et comptabilité.

**Garder les deux quelque temps.** Rien n'oblige à retirer l'icône web tout de
suite ; elle sert de filet le temps de vérifier que la native se comporte bien.
Attention toutefois à ne pas saisir des ventes dans les deux : elles ne se
parlent pas, et il faudrait choisir laquelle jeter.

---

## Ce que l'application native apporte en plus

- **Cinq sauvegardes tournantes automatiques**, que la version web ne fait pas
  (voir [`docs/11-application-iphone.md`](11-application-iphone.md)) ;
- les données incluses dans la **sauvegarde iCloud** du téléphone ;
- un démarrage un peu plus rapide.

Pour le reste — ventes, reçus, impression, comptabilité, PDF pour les impôts —
c'est exactement le même code, donc exactement le même comportement.
