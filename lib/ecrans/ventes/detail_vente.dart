import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/argent.dart';
import '../../coeur/composants.dart';
import '../../coeur/theme.dart';
import '../../donnees/modeles.dart';
import '../../etat/boutique.dart';
import '../recu/apercu_recu.dart';

class DetailVente extends ConsumerWidget {
  const DetailVente({super.key, required this.venteId});

  final String venteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(boutiqueProvider);
    final vente = etat.vente(venteId);
    final p = etat.parametres;
    final theme = Theme.of(context);

    if (vente == null) {
      return const Scaffold(
        body: Vide(
          titre: 'Vente introuvable',
          texte: 'Elle a peut-être été supprimée.',
          icone: Icons.receipt_long_outlined,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vente.numero),
            Text(Dates.court(vente.date), style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (choix) async {
              final notifier = ref.read(boutiqueProvider.notifier);
              if (choix == 'annuler') {
                final ok = await confirmer(
                  context,
                  titre: 'Annuler cette vente ?',
                  texte:
                      'Les articles retournent en stock et le reçu porte la '
                      'mention « vente annulée ». Le numéro reste réservé : '
                      'la numérotation ne doit jamais avoir de trou.',
                  valider: 'Annuler la vente',
                  dangereux: true,
                );
                if (!ok) return;
                await notifier.annulerVente(venteId);
                if (context.mounted) message(context, 'Vente annulée, stock rendu.');
              } else if (choix == 'supprimer') {
                final ok = await confirmer(
                  context,
                  titre: 'Supprimer définitivement ?',
                  texte:
                      'À réserver aux saisies de test. Pour une vraie vente, '
                      'préfère l\'annulation, qui garde la trace.',
                  valider: 'Supprimer',
                  dangereux: true,
                );
                if (!ok || !context.mounted) return;
                await notifier.supprimerVente(venteId);
                if (context.mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (_) => [
              if (!vente.estAnnulee)
                const PopupMenuItem(value: 'annuler', child: Text('Annuler la vente')),
              const PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (vente.estAnnulee)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Etats.critiqueFond,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block, color: Etats.critique, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Vente annulée — les articles sont retournés en stock.',
                      style: TextStyle(color: Etats.critique, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          const Etiquette('Cliente'),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: .12),
                child: Text(
                  vente.clientNom.isEmpty ? '?' : vente.clientNom[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(vente.clientNom),
              subtitle: Text(
                [
                  if (vente.clientTelephone != null && vente.clientTelephone!.isNotEmpty)
                    vente.clientTelephone!,
                  vente.canal,
                ].join(' · '),
              ),
            ),
          ),
          const SizedBox(height: 18),

          const Etiquette('Articles'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                children: [
                  for (final ligne in vente.lignes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ligne.designation, style: theme.textTheme.titleMedium),
                                if (ligne.detail != null && ligne.detail!.isNotEmpty)
                                  Text(ligne.detail!, style: theme.textTheme.bodySmall),
                                Text(
                                  '${ligne.quantite} × ${p.format(ligne.prixUnitaire)}'
                                  '${ligne.remise > 0 ? "  ·  remise −${p.format(ligne.remise)}" : ""}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(p.format(ligne.total), style: theme.textTheme.titleMedium),
                        ],
                      ),
                    ),
                  const Divider(height: 20),
                  _Ligne('Sous-total', p.format(vente.sousTotal)),
                  if (vente.remiseGlobale > 0)
                    _Ligne('Remise', '−${p.format(vente.remiseGlobale)}'),
                  if (vente.fraisLivraison > 0)
                    _Ligne('Livraison', p.format(vente.fraisLivraison)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(color: theme.colorScheme.onSurface, width: 1.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text('TOTAL', style: theme.textTheme.titleLarge)),
                        Text(p.format(vente.total), style: theme.textTheme.headlineSmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Ligne('Payé — ${vente.moyenPaiement}', p.format(vente.montantPaye)),
                  const SizedBox(height: 8),
                  if (vente.reste > 0 && !vente.estAnnulee)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Etats.attentionFond,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'RESTE À PAYER',
                              style: TextStyle(
                                color: Etats.attention,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            p.format(vente.reste),
                            style: const TextStyle(
                              color: Etats.attention,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!vente.estAnnulee)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Etats.okFond,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 18, color: Etats.ok),
                          SizedBox(width: 8),
                          Text(
                            'Vente soldée',
                            style: TextStyle(color: Etats.ok, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),

          if (vente.note != null && vente.note!.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Etiquette('Note'),
            Bloc(enfant: Text(vente.note!)),
          ],

          const SizedBox(height: 18),
          const Etiquette('Rentabilité'),
          Row(
            children: [
              Expanded(
                child: Tuile(
                  libelle: 'Coût d\'achat',
                  valeur: p.format(vente.coutTotal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tuile(
                  libelle: 'Bénéfice',
                  valeur: p.format(vente.marge),
                  couleurValeur: vente.marge >= 0 ? Etats.ok : Etats.critique,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Etiquette('Encaissements'),
          Builder(
            builder: (_) {
              final reglements = etat.reglementsDe(vente.id);
              if (reglements.isEmpty) {
                return const Bloc(
                  enfant: Text('Aucun encaissement enregistre pour cette vente.'),
                );
              }
              return Card(
                child: Column(
                  children: [
                    for (final r in reglements)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          r.estRemboursement ? Icons.undo : Icons.south_west,
                          size: 18,
                          color: r.estRemboursement ? Etats.critique : Etats.ok,
                        ),
                        title: Text(r.motif ?? r.moyenPaiement),
                        subtitle: Text('${Dates.court(r.date)} - ${r.moyenPaiement}'),
                        trailing: Text(
                          p.format(r.montant),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: r.estRemboursement ? Etats.critique : Etats.ok,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          if (vente.reste > 0 && !vente.estAnnulee) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _encaisserSolde(context, ref, vente, p),
              icon: const Icon(Icons.payments_outlined),
              label: Text('Encaisser le solde · ${p.format(vente.reste)}'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ApercuRecu(venteId: vente.id)),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Voir et imprimer le reçu'),
          ),
        ),
      ),
    );
  }

  Future<void> _encaisserSolde(
    BuildContext context,
    WidgetRef ref,
    Vente vente,
    Parametres p,
  ) async {
    final controleur = TextEditingController(
      text: Argent.versSaisie(vente.reste, p.decimales),
    );
    var date = Dates.aujourdhui();
    final valide = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, majBoite) => AlertDialog(
          title: const Text('Encaisser le solde'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reste \u00e0 payer : ${p.format(vente.reste)}'),
              const SizedBox(height: 14),
              ChampMontant(
                controleur: controleur,
                libelle: 'Montant re\u00e7u',
                parametres: p,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              // La date de l'encaissement d\u00e9cide du mois o\u00f9 la recette
              // appara\u00eetra dans le livre de comptes.
              OutlinedButton.icon(
                onPressed: () async {
                  final choix = await choisirDate(c, date);
                  if (choix != null) majBoite(() => date = choix);
                },
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text('Re\u00e7u le ${Dates.court(date)}'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Encaisser')),
          ],
        ),
      ),
    );
    final montant = Argent.depuisSaisie(controleur.text) ?? 0;
    controleur.dispose();
    if (valide != true || montant <= 0) return;
    await ref
        .read(boutiqueProvider.notifier)
        .encaisserSolde(vente.id, montant, date: date);
    if (context.mounted) message(context, 'Paiement enregistré.');
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne(this.libelle, this.valeur);
  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(libelle, style: Theme.of(context).textTheme.bodySmall)),
          Text(valeur, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
