# Faut-il un serveur ? Et si oui, lequel ?

**Avec un seul téléphone : non.** Un serveur de synchronisation existe pour
faire s'accorder plusieurs appareils. S'il n'y en a qu'un, il ne résout qu'un
seul risque réel — le téléphone perdu — et il le résout plus cher, plus
lentement, et en ajoutant une surface de sécurité à surveiller.

Ce risque-là est déjà couvert, sans serveur.

---

## Ce que l'application fait maintenant, toute seule

**À chaque ouverture, elle se sauvegarde.** Une copie complète est déposée dans
son propre dossier, et les **cinq dernières** sont conservées. Une fausse
manœuvre, un « Repartir de zéro » de trop, une saisie catastrophique : on
revient en arrière en deux touches, depuis Réglages → Sauvegarde.

Ces copies sont incluses dans la sauvegarde iCloud ou Google du téléphone —
un appareil remplacé les retrouve. Elles disparaissent en revanche si
l'application est désinstallée.

**D'où le rappel.** Tant qu'aucune copie n'a été mise à l'abri **hors du
téléphone**, l'accueil affiche un bandeau, et il revient tous les 7 jours.
Un bouton, et le fichier part vers Drive, iCloud, Fichiers ou WhatsApp.

C'est un geste hebdomadaire de dix secondes. Il couvre le vol, la casse, la
noyade et la désinstallation — c'est-à-dire tout ce qu'un serveur aurait
couvert, pour un seul téléphone.

---

## Quand un serveur devient vraiment justifié

Trois situations, pas avant :

1. **Une deuxième personne vend.** Deux téléphones qui touchent au même stock
   ont besoin de s'accorder. C'est là que la synchronisation devient
   indispensable — et sérieuse à écrire.
2. **Elle veut voir ses chiffres depuis un ordinateur**, sans passer par le
   téléphone.
3. **Un catalogue en ligne** que les clientes consultent, avec commandes.

---

## Les options, si ce jour arrive

| Solution | Coût | Qui maintient | Pour qui |
| --- | --- | --- | --- |
| **Sauvegarde automatique + copie dans Drive** | 0 € | personne | **un téléphone — la solution actuelle** |
| Petite API sur un hébergement existant (PHP + MySQL) | souvent déjà payé | vous | si vous avez déjà un hébergement mutualisé |
| **PocketBase** sur un petit serveur | ~5 €/mois | vous | contrôle total, aucun enfermement |
| **Firebase** (Google) | gratuit puis à l'usage | Google | hors-ligne excellent, mais facture imprévisible |
| **Supabase** | gratuit puis 25 $/mois | Supabase | SQL standard, sortie facile |
| Nextcloud / WebDAV | ~3 €/mois | vous | simple dépôt de fichiers, pas de synchro |

### Ce qu'il faut savoir sur chacune

**Une petite API sur votre hébergement.** Si vous payez déjà un hébergement
mutualisé, une poignée de fichiers PHP et une base MySQL suffisent à recevoir
la sauvegarde et à la renvoyer. C'est l'option la moins chère du lot, celle
qui n'ajoute aucun fournisseur, et vous maîtrisez tout. En revanche la
sécurité est entièrement à votre charge : sans jeton solide et sans HTTPS,
un point d'entrée public exposerait toutes les ventes.

**PocketBase.** Un seul fichier exécutable qui embarque sa base et son
interface d'administration. On le pose sur un petit serveur à 5 €/mois et il
tourne. Simple, rapide, sans enfermement — le meilleur compromis si vous
voulez un vrai serveur sans dépendre d'un géant.

**Firebase.** La synchronisation hors-ligne y est native et excellente, c'est
son point fort réel. Deux réserves : la base n'est pas du SQL standard, donc
en sortir plus tard demande de tout réécrire ; et la facturation à l'usage
peut surprendre si un bug fait boucler des requêtes.

**Supabase.** Du PostgreSQL standard : si vous partez un jour, vos données
s'emportent telles quelles. Le schéma complet est déjà écrit dans
[`supabase/schema.sql`](../supabase/schema.sql), sécurité par ligne comprise.
Attention : un projet gratuit est **mis en pause après une semaine sans
activité**.

**Nextcloud / WebDAV.** Ce n'est pas de la synchronisation, juste un dossier en
ligne où déposer la sauvegarde automatiquement. Une version plus riche du geste
hebdomadaire actuel, sans base de données ni compte à gérer.

---

## Ma recommandation

Restez sans serveur tant qu'elle vend seule sur un téléphone. Le geste
hebdomadaire de mise à l'abri suffit, ne coûte rien, ne tombe jamais en panne
et ne peut pas être piraté.

Le jour où une deuxième personne vend, ou qu'un catalogue en ligne devient
utile, **Supabase ou PocketBase** — selon que vous préférez ne rien
administrer, ou tout maîtriser. Le schéma Supabase est déjà prêt ; il se
transpose sur PocketBase presque tel quel.

Ce qu'il ne faut **pas** faire : brancher un serveur maintenant « au cas où ».
Ce serait payer un abonnement, entretenir une sécurité, et ajouter un point de
panne — pour résoudre un problème que dix secondes par semaine règlent déjà.
