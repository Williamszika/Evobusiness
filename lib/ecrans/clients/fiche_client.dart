import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../coeur/argent.dart';
import '../../coeur/composants.dart';
import '../../coeur/constantes.dart';
import '../../coeur/theme.dart';
import '../../donnees/modeles.dart';
import '../../etat/boutique.dart';
import '../../etat/indicateurs.dart';
import '../ventes/detail_vente.dart';
import 'edition_client.dart';

class FicheClient extends ConsumerWidget {
  const FicheClient({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(boutiqueProvider);
    final client = etat.client(clientId);
    final p = etat.parametres;
    final theme = Theme.of(context);

    if (client == null) {
      return const Scaffold(
        body: Vide(
          titre: 'Fiche introuvable',
          texte: 'Elle a peut-être été supprimée.',
          icone: Icons.person_outline,
        ),
      );
    }

    final bilan = Indicateurs.bilanClient(etat, clientId);
    final ventes = etat.ventesDe(clientId);
    final impayee = ventes.where((v) => v.compteDansLeCa && v.reste > 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(client.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              [
                'Cliente depuis ${Dates.court(client.creeLe.split("T").first)}',
                if (client.ville != null && client.ville!.isNotEmpty) client.ville!,
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditionClient(client: client)),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (choix) async {
              if (choix != 'supprimer') return;
              final ok = await confirmer(
                context,
                titre: 'Supprimer cette fiche ?',
                texte: 'Ses reçus déjà émis sont conservés, avec son nom.',
                valider: 'Supprimer',
                dangereux: true,
              );
              if (!ok || !context.mounted) return;
              await ref.read(boutiqueProvider.notifier).supprimerClient(clientId);
              if (context.mounted) Navigator.pop(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'supprimer', child: Text('Supprimer la fiche')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Tuile(libelle: 'Total dépensé', valeur: p.format(bilan.$1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tuile(libelle: 'Commandes', valeur: '${bilan.$2}'),
              ),
            ],
          ),
          if (bilan.$3 > 0) ...[
            const SizedBox(height: 12),
            Tuile(
              libelle: 'Reste à payer',
              valeur: p.format(bilan.$3),
              detail: impayee.isEmpty
                  ? null
                  : 'depuis ${Dates.joursDepuis(impayee.first.date)} jours · '
                      '${impayee.first.numero}',
              couleurValeur: Etats.attention,
              fond: Etats.attentionFond,
            ),
          ],
          const SizedBox(height: 14),

          Row(
            children: [
              if (client.numeroWhatsapp != null)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Etats.ok,
                      side: const BorderSide(color: Etats.ok),
                    ),
                    onPressed: () => _relancer(context, client, bilan.$3, impayee, p),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: Text(bilan.$3 > 0 ? 'Relancer' : 'Écrire'),
                  ),
                ),
              if (client.numeroWhatsapp != null && client.telephone != null)
                const SizedBox(width: 12),
              if (client.telephone != null && client.telephone!.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse('tel:${client.telephone!.replaceAll(" ", "")}'),
                    ),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Appeler'),
                  ),
                ),
            ],
          ),

          if (client.note != null && client.note!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Etiquette('Préférences'),
            Bloc(enfant: Text(client.note!)),
          ],

          if (client.anniversaire != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cake_outlined),
                title: const Text('Anniversaire'),
                subtitle: Text(Dates.court(client.anniversaire!)),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Etiquette('Historique'),
          if (ventes.isEmpty)
            const Bloc(enfant: Text('Aucun achat enregistré pour l\'instant.'))
          else
            Card(
              child: Column(
                children: [
                  for (final vente in ventes)
                    ListTile(
                      title: Text(vente.numero),
                      subtitle: Text(
                        '${Dates.court(vente.date)} · '
                        '${vente.lignes.map((l) => l.designation).take(2).join(", ")}'
                        '${vente.lignes.length > 2 ? "…" : ""}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(p.format(vente.total), style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Pastille(
                            vente.statut,
                            ton: switch (vente.statut) {
                              statutPayee => Ton.ok,
                              statutPartielle => Ton.attention,
                              statutImpayee => Ton.critique,
                              _ => Ton.neutre,
                            },
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailVente(venteId: vente.id),
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

  /// Ouvre WhatsApp avec un message poli déjà rédigé.
  Future<void> _relancer(
    BuildContext context,
    Client client,
    int reste,
    List<Vente> impayee,
    Parametres p,
  ) async {
    final numero = client.numeroWhatsapp?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final prenom = client.nom.split(' ').first;
    final texte = reste > 0
        ? 'Bonjour $prenom 😊 J\'espère que vous allez bien. '
            'Petit rappel amical concernant le reçu ${impayee.isEmpty ? "" : impayee.first.numero} : '
            'il reste ${p.format(reste)} à régler. '
            'Merci beaucoup et à très vite ! — ${p.nomBoutique}'
        : 'Bonjour $prenom 😊 Merci pour votre confiance ! '
            'De nouveaux articles viennent d\'arriver, dites-moi si vous voulez '
            'que je vous envoie les photos. — ${p.nomBoutique}';

    final lien = Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(texte)}');
    final ouvert = await launchUrl(lien, mode: LaunchMode.externalApplication);
    if (!ouvert && context.mounted) {
      message(context, 'WhatsApp n\'a pas pu être ouvert.', erreur: true);
    }
  }
}
