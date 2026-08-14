import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../donnees/modeles.dart';
import '../../etat/boutique.dart';
import 'edition_client.dart';

/// Résultat du sélecteur : soit une fiche existante, soit un simple nom.
class ChoixClient {
  const ChoixClient({this.client, this.nomLibre = ''});
  final Client? client;
  final String nomLibre;
}

/// Feuille de choix d'une cliente : recherche, création rapide, ou vente au
/// comptant sans fiche.
Future<ChoixClient?> choisirClient(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<ChoixClient>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _FeuilleClient(),
  );
}

class _FeuilleClient extends ConsumerStatefulWidget {
  const _FeuilleClient();

  @override
  ConsumerState<_FeuilleClient> createState() => _FeuilleClientState();
}

class _FeuilleClientState extends ConsumerState<_FeuilleClient> {
  final _recherche = TextEditingController();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(boutiqueProvider);
    final theme = Theme.of(context);
    final motsCles = _recherche.text.trim().toLowerCase();

    final liste = etat.clients.where((c) {
      if (motsCles.isEmpty) return true;
      return '${c.nom} ${c.telephone ?? ''} ${c.ville ?? ''}'
          .toLowerCase()
          .contains(motsCles);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choisir la cliente', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _recherche,
                    autofocus: false,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Nom ou téléphone…',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.person_add_alt, color: Colors.white, size: 20),
                    ),
                    title: const Text('Créer une fiche cliente'),
                    subtitle: const Text('Pour suivre son historique et ses soldes'),
                    onTap: () async {
                      final cree = await Navigator.push<Client>(
                        context,
                        MaterialPageRoute(builder: (_) => const EditionClient()),
                      );
                      if (cree != null && context.mounted) {
                        Navigator.pop(context, ChoixClient(client: cree));
                      }
                    },
                  ),
                  if (motsCles.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.bolt, size: 20)),
                      title: Text('Vendre à « ${_recherche.text.trim()} »'),
                      subtitle: const Text('Sans créer de fiche'),
                      onTap: () => Navigator.pop(
                        context,
                        ChoixClient(nomLibre: _recherche.text.trim()),
                      ),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.storefront_outlined, size: 20)),
                    title: const Text('Client de passage'),
                    subtitle: const Text('Vente au comptant, sans nom'),
                    onTap: () => Navigator.pop(context, const ChoixClient()),
                  ),
                  const Divider(height: 28),
                  if (liste.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        motsCles.isEmpty
                            ? 'Aucune cliente enregistrée pour l\'instant.'
                            : 'Aucune cliente ne correspond.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    for (final client in liste)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: .12),
                          child: Text(
                            client.nom.isEmpty ? '?' : client.nom[0].toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(client.nom),
                        subtitle: Text(
                          [client.telephone, client.ville]
                              .where((v) => v != null && v.isNotEmpty)
                              .join(' · '),
                        ),
                        onTap: () => Navigator.pop(context, ChoixClient(client: client)),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
