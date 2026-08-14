# Installer l'application sur un iPhone

Le code est déjà multiplateforme : aucune ligne à réécrire pour iOS. Ce qui
bloque n'est pas technique, c'est **Apple**.

---

## La règle d'Apple, en une phrase

> Une application iPhone ne peut être **compilée que sur un Mac avec Xcode**,
> et ne peut être **installée que si elle est signée** par un compte Apple.

Il n'existe aucun contournement légal : pas d'équivalent du fichier `.apk`
qu'on installe directement sur Android. Voici les trois chemins possibles,
du moins cher au plus confortable.

---

## Chemin 1 — Un Mac emprunté, gratuit, 7 jours

Pour **essayer** l'application, sans rien payer.

Sur le Mac, avec l'iPhone branché en USB :

```bash
# une seule fois : installer Flutter et Xcode depuis l'App Store
git clone <ce dépôt> && cd Evobusiness
flutter pub get
open ios/Runner.xcworkspace     # ouvre Xcode
```

Dans Xcode : onglet **Signing & Capabilities** → cocher *Automatically manage
signing* → choisir son Apple ID personnel dans *Team* → changer le *Bundle
Identifier* pour quelque chose d'unique (`com.tonnom.boutique`). Puis :

```bash
flutter run --release
```

**La limite :** avec un Apple ID gratuit, l'application **expire au bout de
7 jours** et refuse de s'ouvrir. Il faut rebrancher l'iPhone au Mac et
réinstaller. C'est parfait pour tester, inutilisable au quotidien.

---

## Chemin 2 — Compte développeur + TestFlight, sans posséder de Mac ⭐

**C'est le chemin que je recommande.** Il coûte **99 $ par an** (le compte
Apple Developer) et ne demande aucun Mac.

1. Ouvrir un compte sur [developer.apple.com](https://developer.apple.com) —
   99 $/an, paiement par carte, validation en 24-48 h.
2. Créer un compte gratuit sur [codemagic.io](https://codemagic.io) et y
   connecter ce dépôt. Codemagic loue des Mac dans le cloud et offre
   **500 minutes de compilation par mois** — largement assez, un build prend
   environ 15 minutes.
3. Codemagic compile, signe, et envoie l'application dans **TestFlight**.
4. Sur l'iPhone : installer l'app **TestFlight** depuis l'App Store, et
   l'application y apparaît. Installation en un bouton.

**La limite :** chaque version installée par TestFlight est valable **90 jours**.
Passé ce délai, il suffit de renvoyer un nouveau build (quelques minutes) et
elle se met à jour toute seule. Jusqu'à 100 personnes peuvent l'installer —
donc une vendeuse supplémentaire plus tard, sans rien changer.

---

## Chemin 3 — Publication sur l'App Store

Même compte à 99 $/an, mais l'application est **publiée** : plus de date
d'expiration, installation depuis l'App Store comme n'importe quelle app, et
un lien à partager.

Il faut passer la **revue d'Apple** (1 à 3 jours en général), fournir des
captures d'écran, une description, et une politique de confidentialité — même
si l'app ne collecte rien, Apple exige la page.

À faire quand la marque sera choisie et l'application rodée. Pas maintenant.

---

## Ce qui est déjà prêt côté iOS

- **Version minimum : iOS 15** — couvre tous les iPhone depuis le 6s (2015).
- **Autorisations déclarées** dans `ios/Runner/Info.plist` : appareil photo et
  photothèque, avec un texte en français expliquant pourquoi. Sans elles,
  l'application se fermerait brutalement à la première photo d'article — c'est
  la première cause de rejet à la revue Apple.
- **Impression** : `printing` passe par AirPrint, natif sur iPhone. Aucune
  configuration.
- **Partage du reçu (PDF, WhatsApp)** : feuille de partage iOS standard.
- **Nom affiché sous l'icône : « Ma Boutique »** — provisoire, tant que le nom
  du business n'est pas choisi.

### Changer le nom sous l'icône

Une fois le nom décidé, deux endroits, une ligne chacun :

| Plateforme | Fichier | Clé |
| --- | --- | --- |
| iOS | `ios/Runner/Info.plist` | `CFBundleDisplayName` |
| Android | `android/app/src/main/AndroidManifest.xml` | `android:label` |

Le nom affiché **dans** l'application et sur le reçu, lui, se change
directement dans Réglages — sans recompiler.

---

## Résumé des coûts

| Chemin | Coût | Mac nécessaire | Durée de validité |
| --- | --- | --- | --- |
| Mac emprunté | gratuit | oui | 7 jours |
| **TestFlight + Codemagic** | **99 $/an** | **non** | **90 jours, renouvelable** |
| App Store | 99 $/an | non | permanent |

Pour Android, rien de tout cela : le fichier APK s'installe directement, sans
compte ni abonnement.
