import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/composants.dart';
import '../../coeur/constantes.dart';
import '../../donnees/modeles.dart';
import '../../etat/boutique.dart';
import 'encaissement.dart';

/// Une ligne du panier en cours de composition.
class LignePanier {
  LignePanier({required this.produit, this.quantite = 1, this.remise = 0});

  final Produit produit;
  int quantite;
  int remise;

  int get total {
    final brut = produit.prixVente * quantite - remise;
    return brut < 0 ? 0 : brut;
  }
}

/// Étape 1 de la vente : choisir les articles.
class NouvelleVente extends ConsumerStatefulWidget {
  const NouvelleVente({super.key});

  @override
  ConsumerState<NouvelleVente> createState() => _NouvelleVenteState();
}

class _NouvelleVenteState extends ConsumerState<NouvelleVente> {
  final _recherche = TextEditingController();
  final _panier = <String, LignePanier>{};
  String _filtre = 'Tout';

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  int get _nombreArticles => _panier.values.fold(0, (s, l) => s + l.quantite);
  int get _total => _panier.values.fold(0, (s, l) => s + l.total);

  void _ajouter(Produit produit) {
    final ligne = _panier[produit.id];
    // On ne vend pas ce qu'on n'a pas : le stock disponible fait la limite,
    // sauf pour les services qui ne se comptent pas.
    if (!produit.estService) {
      final dejaAu = ligne?.quantite ?? 0;
      if (dejaAu >= produit.stock) {
        message(
          context,
          produit.stock == 0
              ? '${produit.nom} est en rupture.'
              : 'Il ne reste que ${produit.stock} pièce(s) de ${produit.nom}.',
          erreur: true,
        );
        return;
      }
    }
    setState(() {
      if (ligne == null) {
        _panier[produit.id] = LignePanier(produit: produit);
      } else {
        ligne.quantite++;
      }
    });
  }

  void _retirer(Produit produit) {
    final ligne = _panier[produit.id];
    if (ligne == null) return;
    setState(() {
      if (ligne.quantite <= 1) {
        _panier.remove(produit.id);
      } else {
        ligne.quantite--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(boutiqueProvider);
    final p = etat.parametres;
    final theme = Theme.of(context);
    final motsCles = _recherche.text.trim().toLowerCase();

    final liste = etat.produitsActifs.where((produit) {
      if (categories.contains(_filtre) && produit.categorie != _filtre) return false;
      if (motsCles.isEmpty) return true;
      return '${produit.nom} ${produit.reference} ${produit.detail}'
          .toLowerCase()
          .contains(motsCles);
    }).toList()
      ..sort((a, b) {
        // Les articles déjà au panier restent en haut, puis les disponibles.
        final auPanierA = _panier.containsKey(a.id) ? 0 : 1;
        final auPanierB = _panier.containsKey(b.id) ? 0 : 1;
        if (auPanierA != auPanierB) return auPanierA.compareTo(auPanierB);
        final dispoA = (!a.estService && a.enRupture) ? 1 : 0;
        final dispoB = (!b.estService && b.enRupture) ? 1 : 0;
        if (dispoA != dispoB) return dispoA.compareTo(dispoB);
        return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
      });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nouvelle vente'),
            Text('Étape 1 — les articles', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _recherche,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Chercher : nom, longueur, référence…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _recherche.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(_recherche.clear),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in ['Tout', ...categories])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _filtre == f,
                      onSelected: (_) => setState(() => _filtre = f),
                      selectedColor: theme.colorScheme.primary,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        color: _filtre == f
                            ? Colors.white
                            : theme.colorScheme.onSurface.withValues(alpha: .8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: liste.isEmpty
                ? const Vide(
                    titre: 'Aucun article',
                    texte: 'Ajoute d\'abord des articles dans ton stock.',
                    icone: Icons.inventory_2_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: liste.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final produit = liste[i];
                      final ligne = _panier[produit.id];
                      final indisponible = !produit.estService && produit.enRupture;
                      return Opacity(
                        opacity: indisponible ? .45 : 1,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: ligne != null
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                              width: ligne != null ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: indisponible ? null : () => _ajouter(produit),
                            child: Padding(
                              padding: const EdgeInsets.all(11),
                              child: Row(
                                children: [
                                  VignetteProduit(produit: produit, taille: 42),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          produit.nom,
                                          style: theme.textTheme.titleMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          [
                                            if (produit.detail.isNotEmpty) produit.detail,
                                            if (produit.estService)
                                              'service'
                                            else
                                              'stock ${produit.stock}',
                                          ].join(' · '),
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        p.format(produit.prixVente),
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      if (indisponible)
                                        const Pastille('Rupture', ton: Ton.critique)
                                      else if (ligne == null)
                                        _BoutonRond(
                                          icone: Icons.add,
                                          onTap: () => _ajouter(produit),
                                        )
                                      else
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _BoutonRond(
                                              icone: Icons.remove,
                                              doux: true,
                                              onTap: () => _retirer(produit),
                                            ),
                                            SizedBox(
                                              width: 30,
                                              child: Text(
                                                '${ligne.quantite}',
                                                textAlign: TextAlign.center,
                                                style: theme.textTheme.titleMedium,
                                              ),
                                            ),
                                            _BoutonRond(
                                              icone: Icons.add,
                                              onTap: () => _ajouter(produit),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _panier.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Encaissement(
                        lignes: _panier.values.toList(),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Flexible : avec de gros montants, c'est le récapitulatif
                      // qui se resserre, jamais le bouton « Suivant ».
                      Flexible(
                        child: Text(
                          '$_nombreArticles article(s) · ${p.format(_total)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Suivant', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _BoutonRond extends StatelessWidget {
  const _BoutonRond({required this.icone, required this.onTap, this.doux = false});

  final IconData icone;
  final VoidCallback onTap;
  final bool doux;

  @override
  Widget build(BuildContext context) {
    final couleur = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: doux ? couleur.withValues(alpha: .12) : couleur,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icone, size: 17, color: doux ? couleur : Colors.white),
      ),
    );
  }
}
