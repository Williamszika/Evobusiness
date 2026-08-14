import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/composants.dart';
import '../../etat/boutique.dart';
import '../../etat/indicateurs.dart';
import 'edition_client.dart';
import 'fiche_client.dart';

class ListeClients extends ConsumerStatefulWidget {
  const ListeClients({super.key});

  @override
  ConsumerState<ListeClients> createState() => _ListeClientsState();
}

class _ListeClientsState extends ConsumerState<ListeClients> {
  final _recherche = TextEditingController();
  bool _seulementDebitrices = false;

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

    final fiches = etat.clients.map((client) {
      final bilan = Indicateurs.bilanClient(etat, client.id);
      return (client: client, total: bilan.$1, commandes: bilan.$2, reste: bilan.$3);
    }).where((f) {
      if (_seulementDebitrices && f.reste <= 0) return false;
      if (motsCles.isEmpty) return true;
      return '${f.client.nom} ${f.client.telephone ?? ''} ${f.client.ville ?? ''}'
          .toLowerCase()
          .contains(motsCles);
    }).toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final nbDebitrices = etat.clients
        .where((c) => Indicateurs.bilanClient(etat, c.id).$3 > 0)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Clientes'),
            Text(
              '${etat.clients.length} fiche(s)'
              '${nbDebitrices > 0 ? " · $nbDebitrices avec un solde dû" : ""}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Nouvelle cliente',
            icon: const Icon(Icons.person_add_alt),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditionClient()),
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
                hintText: 'Nom, téléphone, ville…',
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
          if (nbDebitrices > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  label: Text('Avec un solde dû · $nbDebitrices'),
                  selected: _seulementDebitrices,
                  onSelected: (v) => setState(() => _seulementDebitrices = v),
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    color: _seulementDebitrices
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: .8),
                  ),
                ),
              ),
            ),
          Expanded(
            child: fiches.isEmpty
                ? Vide(
                    titre: motsCles.isEmpty ? 'Aucune cliente' : 'Rien trouvé',
                    texte: motsCles.isEmpty
                        ? 'Crée une fiche pour suivre l\'historique et les '
                            'soldes de tes clientes.'
                        : 'Essaie un autre nom.',
                    icone: Icons.people_outline,
                    action: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditionClient()),
                      ),
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Nouvelle cliente'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    itemCount: fiches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final f = fiches[i];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FicheClient(clientId: f.client.id),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(13),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      theme.colorScheme.primary.withValues(alpha: .12),
                                  child: Text(
                                    f.client.nom.isEmpty
                                        ? '?'
                                        : f.client.nom[0].toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        f.client.nom,
                                        style: theme.textTheme.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        [
                                          if (f.client.telephone != null &&
                                              f.client.telephone!.isNotEmpty)
                                            f.client.telephone!,
                                          '${f.commandes} commande(s)',
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
                                      p.format(f.total),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    if (f.reste > 0)
                                      Pastille('Doit ${p.format(f.reste)}',
                                          ton: Ton.attention),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
