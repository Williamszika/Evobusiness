import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/composants.dart';
import '../../coeur/constantes.dart';
import '../../coeur/theme.dart';
import '../../donnees/modeles.dart';
import '../../etat/boutique.dart';
import '../../etat/indicateurs.dart';
import 'edition_produit.dart';
import 'fiche_produit.dart';

class ListeProduits extends ConsumerStatefulWidget {
  const ListeProduits({super.key});

  @override
  ConsumerState<ListeProduits> createState() => _ListeProduitsState();
}

class _ListeProduitsState extends ConsumerState<ListeProduits> {
  final _recherche = TextEditingController();
  String _filtre = 'Tout';

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  /// Le stock se lit par urgence : ce qui manque doit remonter tout seul.
  int _urgence(Produit p) {
    if (p.estService) return 3;
    if (p.enRupture) return 0;
    if (p.stockBas) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(boutiqueProvider);
    final p = etat.parametres;
    final theme = Theme.of(context);

    final motsCles = _recherche.text.trim().toLowerCase();
    final nbBas = etat.produits.where((x) => x.actif && !x.estService && x.stockBas).length;
    final nbRupture = etat.produits.where((x) => x.actif && !x.estService && x.enRupture).length;

    var liste = etat.produits.where((produit) {
      if (!produit.actif && _filtre != 'Archivés') return false;
      if (produit.actif && _filtre == 'Archivés') return false;
      if (_filtre == 'Stock bas' && !produit.stockBas) return false;
      if (_filtre == 'Rupture' && !produit.enRupture) return false;
      if (categories.contains(_filtre) && produit.categorie != _filtre) return false;
      if (motsCles.isEmpty) return true;
      return '${produit.nom} ${produit.reference} ${produit.detail} ${produit.categorie}'
          .toLowerCase()
          .contains(motsCles);
    }).toList();

    liste.sort((a, b) {
      final u = _urgence(a).compareTo(_urgence(b));
      return u != 0 ? u : a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mon stock'),
            Text(
              '${Indicateurs.articlesEnStock(etat)} pièces · '
              'valeur ${p.format(Indicateurs.valeurStock(etat))}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Nouvel article',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditionProduit()),
            ),
          ),
          const SizedBox(width: 4),
        ],
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
                for (final f in [
                  'Tout',
                  if (nbBas > 0) 'Stock bas',
                  if (nbRupture > 0) 'Rupture',
                  ...categories,
                  'Archivés',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        f == 'Stock bas'
                            ? 'Stock bas $nbBas'
                            : f == 'Rupture'
                                ? 'Rupture $nbRupture'
                                : f,
                      ),
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
                ? Vide(
                    titre: motsCles.isEmpty ? 'Aucun article' : 'Rien trouvé',
                    texte: motsCles.isEmpty
                        ? 'Ajoute tes mèches, perruques et accessoires pour '
                            'commencer à suivre ton stock.'
                        : 'Essaie un autre mot, ou change de filtre.',
                    icone: Icons.inventory_2_outlined,
                    action: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditionProduit()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un article'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    itemCount: liste.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _LigneProduit(
                      produit: liste[i],
                      parametres: p,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LigneProduit extends StatelessWidget {
  const _LigneProduit({required this.produit, required this.parametres});

  final Produit produit;
  final Parametres parametres;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurBord = produit.estService
        ? null
        : produit.enRupture
            ? Etats.critique
            : produit.stockBas
                ? Etats.attention
                : null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: couleurBord ?? theme.dividerColor,
          width: couleurBord != null ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FicheProduit(produitId: produit.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              VignetteProduit(produit: produit),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      produit.detail.isEmpty ? produit.categorie : produit.detail,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Marge ${parametres.format(produit.marge)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: produit.marge > 0 ? Etats.ok : Etats.critique,
                        fontWeight: FontWeight.w600,
                      ),
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
                    parametres.format(produit.prixVente),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  if (produit.estService)
                    const Pastille('Service', ton: Ton.marque)
                  else if (produit.enRupture)
                    const Pastille('Rupture', ton: Ton.critique)
                  else if (produit.stockBas)
                    Pastille('Reste ${produit.stock}', ton: Ton.attention)
                  else
                    Pastille('${produit.stock} en stock', ton: Ton.ok),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
