# Installer l'application sur l'iPhone

**Chemin retenu : la version web installable.** Gratuite, sans compte Apple,
sans App Store. L'icône s'ajoute à l'écran d'accueil depuis Safari et
l'application s'ouvre en plein écran, comme n'importe quelle autre.

---

## Pourquoi ce chemin

Apple impose une règle simple : une vraie application iPhone ne se compile que
sur un Mac, et ne s'installe que si elle est signée par un compte Apple. Il
n'existe aucun équivalent du fichier `.apk` d'Android.

Une application web contourne cette règle entièrement, parce qu'elle n'est pas
« installée » au sens d'Apple : c'est Safari qui la garde.

| Chemin | Coût | Mac | Validité |
| --- | --- | --- | --- |
| **Version web sur l'écran d'accueil** | **0 €** | **non** | **permanente** |
| Mac emprunté + Apple ID gratuit | 0 € | oui | 7 jours |
| Compte développeur + lien privé (TestFlight, Ad Hoc) | 99 $/an | non | 90 jours, renouvelable |
| Publication App Store | 99 $/an | non | permanente |

---

## Mettre l'application en ligne

La compilation et la publication sont automatiques : à chaque poussée, le
workflow [`publier-web.yml`](../.github/workflows/publier-web.yml) analyse le
code, lance les tests, compile la version web et pousse le résultat sur la
branche **`gh-pages`**. C'est déjà fait.

**Il reste un geste, à faire une seule fois**, et seul le propriétaire du dépôt
peut le faire — GitHub refuse qu'un robot active un site à sa place :

> **Settings → Pages → Source : « Deploy from a branch » → Branch : `gh-pages`,
> dossier `/ (root)` → Save**

Une à deux minutes plus tard, l'application répond à l'adresse
`https://<compte>.github.io/Evobusiness/`. Toutes les mises à jour suivantes
seront automatiques.

### Pourquoi une branche plutôt que le mode « GitHub Actions »

Le mode moderne de Pages a été essayé en premier. Il échoue avant même la
compilation : créer un site Pages demande des droits d'administration que le
jeton des workflows n'a pas.

```
Create Pages site failed. Error: Resource not accessible by integration
```

Pousser une branche, en revanche, le jeton sait le faire. Le résultat est
identique pour l'utilisatrice.

### Pour construire à la main

```bash
flutter build web --release --no-web-resources-cdn \
  --pwa-strategy offline-first --base-href /Evobusiness/
```

`--no-web-resources-cdn` n'est pas optionnel : sans lui, Flutter va chercher
son moteur graphique sur un serveur Google et **l'application cesse de
fonctionner sans connexion**.

Netlify, Vercel ou un hébergement classique conviennent aussi : il suffit d'y
déposer le contenu de `build/web`.

---

## L'installer sur l'iPhone

1. Ouvrir l'adresse **dans Safari** (pas Chrome : sur iPhone, seul Safari sait
   ajouter à l'écran d'accueil).
2. Toucher le bouton **Partager** (le carré avec la flèche vers le haut).
3. Choisir **« Sur l'écran d'accueil »**.
4. Valider. L'icône couronne apparaît parmi les applications.

Ouverte depuis cette icône, elle occupe tout l'écran : ni barre d'adresse, ni
onglets. Elle fonctionne **sans connexion** dès la deuxième ouverture, tout
étant enregistré dans le téléphone.

---

## Ce qui a été vérifié

L'application a été lancée dans un navigateur mobile, sur un écran d'iPhone 13,
et pilotée automatiquement :

- SQLite tourne en WebAssembly dans le navigateur ; les données de démonstration
  s'affichent bien
- une vente s'ouvre, le stock se met à jour
- **le reçu se dessine à l'écran, en A5 et en ticket 80 mm**, avec le logo, les
  articles, les totaux et le reste à payer
- **aucun appel réseau externe** : tout est servi par l'application elle-même

Deux défauts ont été trouvés et corrigés lors de cette vérification :

1. Flutter chargeait son moteur graphique depuis un CDN Google — l'application
   n'aurait pas fonctionné hors connexion.
2. L'aperçu du reçu chargeait pdf.js depuis un CDN, dans une version trop
   récente pour beaucoup de navigateurs : l'aperçu restait gris et vide. La
   bibliothèque est maintenant embarquée, dans une version compatible.

---

## Les limites, dites franchement

**Les données vivent dans le navigateur.** iOS peut faire le ménage dans le
stockage d'un site resté plusieurs semaines sans être ouvert. Une application
ajoutée à l'écran d'accueil et utilisée régulièrement est bien mieux traitée,
mais la garantie n'est pas la même qu'une vraie application.

C'est pourquoi, dans la version web, **l'application réclame une sauvegarde
tous les trois jours** au lieu de sept, et n'écrit pas de copie automatique
locale — elle serait effacée en même temps que le reste. La copie qu'elle
enregistre dans iCloud, Drive ou WhatsApp est la seule vraie protection.

**Pas d'imprimante Bluetooth.** L'impression passe par la boîte de dialogue du
navigateur, donc par AirPrint. Le ticket 80 mm est produit, mais une thermique
Bluetooth demanderait une vraie application.

**Premier chargement plus lourd.** Environ 5 Mo à la première ouverture,
ensuite tout est en cache et l'ouverture est immédiate.

---

## Si un jour vous voulez une vraie application iPhone

Le code Flutter est déjà prêt : le projet `ios/` est configuré, les
autorisations appareil photo et photothèque sont déclarées, la version minimale
est iOS 15. Il ne manque que le compte Apple Developer à 99 $/an et une
compilation — que je peux faire lancer dans le cloud, sans Mac.

Rien de ce qui est écrit aujourd'hui ne serait à jeter.
