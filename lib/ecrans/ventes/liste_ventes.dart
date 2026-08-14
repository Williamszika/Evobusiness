import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/argent.dart';
import '../../coeur/composants.dart';
import '../../coeur/constantes.dart';
import '../../donnees/modeles.dart';
import '../../etat/boutique.dart';
import '../../etat/indicateurs.dart';
import 'detail_vente.dart';

class ListeVentes extends ConsumerStatefulWidget {
  const ListeVentes({super.key});

  @override
  ConsumerState<ListeVentes> createState() => _ListeVentesState();
}

class _ListeVentesState extends ConsumerState<ListeVentes> {
  final _recherche = TextEditingController();
  String _filtre = 'Toutes';

  static const _filtres = ['Toutes', 'Aujourd\'hui', 'Ce mois', 'Impayées', 'Annulées'];

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(boutiqueProvider);
    final p = etat.parametres;
    final theme = Theme.of(context);
    final motsCles = _recherche.text.trim().toLowerCase();
    final moisCourant = Dates.cleMois(Dates.aujourdhui());

    final liste = etat.ventes.where((v) {
      switch (_filtre) {
        case 'Aujourd\'hui':
          if (v.date != Dates.aujourdhui() || v.estAnnulee) return false;
        case 'Ce mois':
          if (Dates.cleMois(v.date) != moisCourant || v.estAnnulee) return false;
        case 'Impayées':
          if (v.estAnnulee || v.reste <= 0) return false;
        case 'Annulées':
          if (!v.estAnnulee) return false;
        default:
          break;
      }
      if (motsCles.isEmpty) return true;
      return '${v.numero} ${v.clientNom} ${v.moyenPaiement} ${v.canal}'
          .toLowerCase()
          .contains(motsCles);
    }).toList();

    final totalAffiche = Indicateurs.chiffreAffaires(
      liste.where((v) => v.compteDansLeCa),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ventes'),
            Text(
              '${liste.length} reçu(s) · ${p.format(totalAffiche)}',
              style: theme.textTheme.bodySmall,
            ),
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
                hintText: 'Numéro de reçu, cliente…',
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
                for (final f in _filtres)
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
                    titre: 'Aucune vente',
                    texte: 'Appuie sur « Vendre » pour enregistrer une vente '
                        'et imprimer son reçu.',
                    icone: Icons.receipt_long_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    itemCount: liste.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _LigneVenteCarte(vente: liste[i], parametres: p),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LigneVenteCarte extends StatelessWidget {
  const _LigneVenteCarte({required this.vente, required this.parametres});

  final Vente vente;
  final Parametres parametres;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ton = switch (vente.statut) {
      statutPayee => Ton.ok,
      statutPartielle => Ton.attention,
      statutImpayee => Ton.critique,
      _ => Ton.neutre,
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailVente(venteId: vente.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vente.clientNom,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(parametres.format(vente.total), style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${vente.numero} · ${Dates.court(vente.date)} · '
                      '${vente.nombreArticles} article(s) · ${vente.moyenPaiement}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pastille(vente.statut, ton: ton),
                ],
              ),
              if (vente.reste > 0 && !vente.estAnnulee) ...[
                const SizedBox(height: 6),
                Text(
                  'Reste ${parametres.format(vente.reste)} · '
                  'depuis ${Dates.joursDepuis(vente.date)} jours',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
