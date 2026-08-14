import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/argent.dart';
import '../../coeur/composants.dart';
import '../../coeur/constantes.dart';
import '../../coeur/theme.dart';
import '../../donnees/modeles.dart';
import '../../etat/boutique.dart';
import '../../etat/indicateurs.dart';
import 'edition_produit.dart';

class FicheProduit extends ConsumerWidget {
  const FicheProduit({super.key, required this.produitId});

  final String produitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(boutiqueProvider);
    final produit = etat.produit(produitId);
    final p = etat.parametres;
    final theme = Theme.of(context);

    if (produit == null) {
      return const Scaffold(
        body: Vide(
          titre: 'Article introuvable',
          texte: 'Il a peut-être été supprimé.',
          icone: Icons.help_outline,
        ),
      );
    }

    final mouvements = Indicateurs.mouvementsDe(etat, produitId);
    final vendus = Indicateurs.venduSur(etat, produitId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Fiche article'),
            Text(produit.reference, style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditionProduit(produit: produit)),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (choix) async {
              if (choix == 'supprimer') {
                final ok = await confirmer(
                  context,
                  titre: 'Supprimer cet article ?',
                  texte:
                      'Les reçus déjà émis gardent le détail de l\'article. '
                      'Pour le retirer de la vente sans rien perdre, préfère '
                      'l\'archiver depuis « Modifier ».',
                  valider: 'Supprimer',
                  dangereux: true,
                );
                if (!ok || !context.mounted) return;
                await ref.read(boutiqueProvider.notifier).supprimerProduit(produitId);
                if (context.mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (produit.photo != null && File(produit.photo!).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(produit.photo!),
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 14),
          Text(produit.nom, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            produit.detail.isEmpty ? produit.categorie : produit.detail,
            style: theme.textTheme.bodySmall,
          ),
          if (produit.densite != null && produit.densite!.isNotEmpty)
            Text('Densité ${produit.densite}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pastille(produit.categorie, ton: Ton.marque),
              if (!produit.actif) const Pastille('Archivé', ton: Ton.neutre),
              if (produit.estService)
                const Pastille('Service — pas de stock', ton: Ton.neutre)
              else if (produit.enRupture)
                const Pastille('Rupture', ton: Ton.critique)
              else if (produit.stockBas)
                const Pastille('Stock bas', ton: Ton.attention),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Tuile(
                  libelle: 'Prix d\'achat',
                  valeur: p.format(produit.prixAchat),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tuile(
                  libelle: 'Prix de vente',
                  valeur: p.format(produit.prixVente),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Tuile(
            libelle: 'Marge par pièce',
            valeur: '${p.format(produit.marge)}'
                '${produit.prixVente > 0 ? "   ·   ${produit.tauxMarge.round()} %" : ""}',
            detail: 'C\'est ce chiffre qui dit quoi racheter, et quoi arrêter.',
            couleurValeur: produit.marge >= 0 ? Etats.ok : Etats.critique,
            fond: produit.marge >= 0 ? Etats.okFond : Etats.critiqueFond,
          ),
          const SizedBox(height: 12),

          if (!produit.estService)
            Row(
              children: [
                Expanded(
                  child: Tuile(
                    libelle: 'En stock',
                    valeur: '${produit.stock}',
                    detail: 'alerte à ${produit.seuilAlerte}',
                    couleurValeur: produit.enRupture
                        ? Etats.critique
                        : produit.stockBas
                            ? Etats.attention
                            : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Tuile(
                    libelle: 'Vendus (30 j)',
                    valeur: '$vendus',
                    detail: vendus > 0 && produit.stock > 0
                        ? '≈ ${(produit.stock / (vendus / 30)).round()} jours de stock'
                        : null,
                  ),
                ),
              ],
            ),

          if (!produit.estService) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mouvement(context, ref, produit, entree: true),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Entrée de stock'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mouvement(context, ref, produit, entree: false),
                    icon: const Icon(Icons.remove, size: 18),
                    label: const Text('Sortie / perte'),
                  ),
                ),
              ],
            ),
          ],

          if (produit.description != null && produit.description!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Etiquette('Note interne'),
            Bloc(enfant: Text(produit.description!)),
          ],

          const SizedBox(height: 20),
          const Etiquette('Mouvements de stock'),
          if (mouvements.isEmpty)
            const Bloc(enfant: Text('Aucun mouvement enregistré pour l\'instant.'))
          else
            Card(
              child: Column(
                children: [
                  for (final m in mouvements.take(20))
                    ListTile(
                      dense: true,
                      leading: Icon(
                        m.quantite >= 0 ? Icons.south_west : Icons.north_east,
                        size: 18,
                        color: m.quantite >= 0 ? Etats.ok : Etats.critique,
                      ),
                      title: Text(m.motif ?? m.type),
                      subtitle: Text('${m.type} · ${Dates.court(m.date)}'),
                      trailing: Text(
                        '${m.quantite >= 0 ? "+" : ""}${m.quantite}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: m.quantite >= 0 ? Etats.ok : Etats.critique,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Saisie d'une entrée (arrivage) ou d'une sortie (perte, casse, cadeau).
  Future<void> _mouvement(
    BuildContext context,
    WidgetRef ref,
    Produit produit, {
    required bool entree,
  }) async {
    final quantite = TextEditingController();
    final motif = TextEditingController(
      text: entree ? 'Arrivage' : 'Perte',
    );

    final valide = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(entree ? 'Entrée de stock' : 'Sortie de stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantite,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantité'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motif,
              decoration: const InputDecoration(labelText: 'Motif'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Valider')),
        ],
      ),
    );

    final n = int.tryParse(quantite.text.trim()) ?? 0;
    quantite.dispose();
    final texteMotif = motif.text.trim();
    motif.dispose();

    if (valide != true || n <= 0) return;
    await ref.read(boutiqueProvider.notifier).ajusterStock(
          produit.id,
          entree ? n : -n,
          entree ? mvtEntree : mvtPerte,
          motif: texteMotif.isEmpty ? null : texteMotif,
        );
    if (context.mounted) {
      message(context, entree ? '$n pièce(s) ajoutée(s).' : '$n pièce(s) retirée(s).');
    }
  }
}
