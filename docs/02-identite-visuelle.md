# Décision 2 — Identité visuelle

## Les palettes

### A · Prune & Laiton — *recommandée*

| Rôle | Couleur |
| --- | --- |
| Principale | `#6E1F46` |
| Principale claire | `#93356B` |
| Accent | `#A9732E` (laiton) |
| Douce | `#E8B4C0` (rose poudré) |
| Fond | `#F7F2F4` |
| Encre | `#241823` |

Féminin sans être enfantin. Le laiton apporte la valeur sans le cliché du doré brillant, et
l'ensemble reste lisible en noir et blanc sur un reçu imprimé.

### B · Nuit & Or

| Rôle | Couleur |
| --- | --- |
| Principale | `#14110F` |
| Secondaire | `#2A241F` |
| Accent | `#C9A227` (or) |
| Douce | `#E5D8B8` |
| Fond | `#FAF7F0` |

Pour un positionnement franchement luxe : perruques à forte valeur, clientèle plus âgée,
prix assumés. Très photogénique, mais coûteux à imprimer en noir plein.

### C · Terre & Rose poudré

| Rôle | Couleur |
| --- | --- |
| Principale | `#8C4A3F` |
| Secondaire | `#B5705F` |
| Accent | `#E8B4C0` |
| Douce | `#D9C3A5` |
| Fond | `#FBF4F1` |
| Encre | `#2E211C` |

Douce, naturelle, rassurante. Parfaite si tu ajoutes des soins, du karité et un discours
« cheveu sain ». Moins premium, plus proche.

### Couleurs d'état — communes aux trois palettes

Elles ne sont **jamais** décoratives, sinon on ne repère plus les alertes.

| État | Couleur | Usage |
| --- | --- | --- |
| Payé / OK | `#2F7D5B` | vente soldée, stock suffisant |
| Attention | `#9A6612` | stock bas, paiement partiel |
| Critique | `#A93B2C` | rupture, impayé en retard |

---

## La typographie

- **Titres** — une serif à contraste : *Playfair Display* ou *Cormorant Garamond*.
  En Flutter : paquet `google_fonts`.
- **Textes et chiffres** — une sans-serif neutre : *Inter* ou *DM Sans*, avec **chiffres
  tabulaires** pour que les montants s'alignent en colonne.

## Deux règles à ne jamais casser

1. **Un seul accent.** La couleur forte sert aux boutons d'action et au total du reçu.
   Partout ailleurs : du calme.
2. **Le reçu doit survivre au noir et blanc.** Beaucoup d'imprimantes ne font pas la couleur ;
   le logo et le total doivent rester lisibles en gris.

---

## Les huit pistes de logo

Fichiers SVG dans [`logos/`](logos/). Chacun est dessiné en deux couleurs (prune + laiton)
et fonctionne aussi en une seule encre.

| Fichier | Piste | Pourquoi | Va bien avec |
| --- | --- | --- | --- |
| `01-la-couronne.svg` | **La Couronne** | Les pointes sont des vagues de cheveux, pas des piques. Reconnaissable à 20 mètres sur une devanture. | Belle Couronne · Couronne d'Or · Reine d'Ébène |
| `02-le-monogramme.svg` | **Le Monogramme** | Le plus économique et le plus durable : une lettre, un cercle, un filet. Se brode, se grave, se tamponne. | Zuri · Nyla · Maison Kora · Sublime & Co |
| `03-la-boucle.svg` | **La Boucle** | Un seul geste continu, comme une mèche qui s'enroule. Le plus moderne, et le plus facile à animer dans l'app. | Lova · Glow Hair Bar · Amani |
| `04-la-cascade.svg` | **La Cascade** | Trois longueurs qui tombent. Abstrait, élégant, et il parle exactement de ce que tu vends : de la longueur. | Nyla · Sublime & Co · L'Atelier des Mèches |
| `05-la-tresse.svg` | **La Tresse** | Deux mèches entrelacées : le savoir-faire, le lien entre toi et la cliente. Très juste si tu proposes la pose. | Tresse & Toi · Racines & Reines · Karité & Kinky |
| `06-le-peigne.svg` | **Le Peigne** | Le peigne afro : l'objet le plus chargé de sens du métier. Fort, culturel, immédiatement identifiable. Le plus audacieux. | Racines & Reines · Fille de Reine · Karité & Kinky |
| `07-l-arche.svg` | **L'Arche** | Une porte, une maison — et deux mèches ondulées à l'intérieur. Institutionnel, rassurant, fait plus grand que sa taille réelle. | Maison Kora · L'Atelier des Mèches · Perruque Prestige |
| `08-le-miroir.svg` | **Le Miroir** | Le moment qui compte vraiment : celui où la cliente se regarde. Doux, féminin, et le rond central peut accueillir une photo. | Mèches & Merveilles · Glow Hair Bar · Slay Studio |

### Comment juger un logo en 30 secondes

- Réduis-le à la taille d'un ongle. S'il devient une tache, il est trop détaillé.
- Imprime-le en noir : il doit rester lisible sans couleur, c'est ce que verra le reçu.
- Dessine-le de mémoire cinq minutes après l'avoir vu. Si tu n'y arrives pas, ta cliente
  non plus.
- Il doit fonctionner **en rond** (photo de profil) *et* **en bande** (en-tête de reçu).
