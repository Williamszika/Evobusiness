import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coeur/argent.dart';
import '../coeur/composants.dart';
import '../coeur/theme.dart';
import '../etat/boutique.dart';
import '../etat/indicateurs.dart';
import 'comptabilite/comptabilite.dart';
import 'depenses/depenses.dart';
import 'parametres/actions_sauvegarde.dart';
import 'parametres/parametres.dart';
import 'produits/fiche_produit.dart';
import 'ventes/detail_vente.dart';

class Accueil extends ConsumerWidget {
  const Accueil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(boutiqueProvider);
    final p = etat.parametres;
    final theme = Theme.of(context);
    final palette = paletteParCle(p.palette);

    final ventesJour = Indicateurs.duJour(etat).toList();
    final ventesMois = Indicateurs.duMois(etat).toList();
    final depensesMois = Indicateurs.depensesDuMois(etat).toList();
    final progression = Indicateurs.progressionObjectif(etat);
    final alertes = etat.alertesStock;
    final impayes = etat.impayes;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: EnteteMarque(parametres: p, palette: palette, taille: 38),
        actions: [
          IconButton(
            tooltip: 'Paramètres',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EcranParametres()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          Text(
            Dates.long(Dates.aujourdhui()),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),

          // ── Le chiffre du jour
          Card(
            color: palette.primaire,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENCAISSÉ AUJOURD\'HUI',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.white.withValues(alpha: .75)),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      p.format(Indicateurs.encaisse(ventesJour)),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: Colors.white, fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Un Wrap plutôt qu'une Row : sur un écran étroit et avec de
                  // gros montants, les deux informations passent à la ligne
                  // au lieu d'être coupées.
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _MiniInfo(
                        texte: ventesJour.length <= 1
                            ? '${ventesJour.length} vente'
                            : '${ventesJour.length} ventes',
                      ),
                      _MiniInfo(
                        texte: 'Bénéfice ${p.format(Indicateurs.margeBrute(ventesJour))}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Le mois
          Row(
            children: [
              Expanded(
                child: Tuile(
                  libelle: 'Ventes du mois',
                  valeur: p.format(Indicateurs.chiffreAffaires(ventesMois)),
                  detail: '${ventesMois.length} reçus',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tuile(
                  libelle: 'Bénéfice net',
                  valeur: p.format(
                    Indicateurs.beneficeNet(ventesMois, depensesMois),
                  ),
                  detail: 'après ${p.format(Indicateurs.totalDepenses(depensesMois))} de dépenses',
                  couleurValeur: Indicateurs.beneficeNet(ventesMois, depensesMois) >= 0
                      ? Etats.ok
                      : Etats.critique,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Objectif
          if (p.objectifMensuel > 0)
            Bloc(
              enfant: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Objectif du mois', style: theme.textTheme.titleMedium),
                      ),
                      Text(
                        '${(progression * 100).round()} %',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: palette.primaire),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  BarreObjectif(progression: progression),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (_) {
                      final reste = p.objectifMensuel -
                          Indicateurs.chiffreAffaires(ventesMois);
                      final jours = Dates.joursRestantsDuMois();
                      return Text(
                        reste <= 0
                            ? 'Objectif atteint. Bravo !'
                            : 'Il reste ${p.format(reste)} à faire '
                                'en ${jours <= 1 ? "1 jour" : "$jours jours"}.',
                        style: theme.textTheme.bodySmall,
                      );
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // ── À surveiller
          if (alertes.isNotEmpty || impayes.isNotEmpty) ...[
            const Etiquette('À surveiller'),
            if (alertes.isNotEmpty)
              Card(
                child: Column(
                  children: [
                    for (final produit in alertes.take(3))
                      ListTile(
                        leading: Icon(
                          produit.enRupture
                              ? Icons.error_outline
                              : Icons.warning_amber_rounded,
                          color: produit.enRupture ? Etats.critique : Etats.attention,
                        ),
                        title: Text(produit.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          produit.detail.isEmpty ? produit.categorie : produit.detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Pastille(
                          produit.enRupture ? 'Rupture' : 'Reste ${produit.stock}',
                          ton: produit.enRupture ? Ton.critique : Ton.attention,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FicheProduit(produitId: produit.id),
                          ),
                        ),
                      ),
                    if (alertes.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'et ${alertes.length - 3} autre(s) article(s) à surveiller',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            if (impayes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    for (final vente in impayes.take(3))
                      ListTile(
                        leading: const Icon(Icons.schedule, color: Etats.attention),
                        title: Text(vente.clientNom, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${vente.numero} · depuis ${Dates.joursDepuis(vente.date)} jours',
                        ),
                        trailing: Text(
                          p.format(vente.reste),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Etats.attention),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailVente(venteId: vente.id),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Text('Total dû', style: theme.textTheme.bodySmall),
                          const Spacer(),
                          Text(
                            p.format(Indicateurs.totalImpayes(etat)),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],

          // ── Rappel de sauvegarde
          //
          // Avec un seul téléphone, c'est le seul vrai risque : tout perdre
          // d'un coup. Le rappel reste discret mais ne disparaît pas tant
          // qu'une copie n'a pas été mise à l'abri.
          if (rappelSauvegardeNecessaire(p.derniereSortieLe)) ...[
            Card(
              color: Etats.attentionFond,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Etats.attention, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_outlined,
                        color: Etats.attention, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.derniereSortieLe.isEmpty
                                ? 'Mets ta boutique à l\'abri'
                                : 'Sauvegarde vieille de '
                                    '${Dates.joursDepuis(p.derniereSortieLe.split("T").first)} jours',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: Etats.attention),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enregistre une copie dans ton Drive ou envoie-la-toi '
                            'sur WhatsApp. Si le téléphone est perdu, c\'est elle '
                            'qui sauve ton business.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Etats.attention),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Etats.attention,
                              minimumSize: const Size(0, 42),
                            ),
                            onPressed: () => sortirSauvegarde(context, ref),
                            icon: const Icon(Icons.save_alt, size: 17),
                            label: const Text('Sauvegarder maintenant'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Dernières ventes
          const Etiquette('Dernières ventes'),
          if (etat.ventes.isEmpty)
            const Bloc(
              enfant: Text(
                'Aucune vente pour l\'instant. Appuie sur « Vendre » pour '
                'enregistrer la première et imprimer son reçu.',
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final vente in etat.ventes.take(5))
                    ListTile(
                      title: Text(vente.clientNom, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${vente.numero} · ${Dates.court(vente.date)} · '
                        '${vente.nombreArticles} article(s)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(p.format(vente.total), style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          _PastilleStatut(statut: vente.statut),
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
          const SizedBox(height: 20),

          // ── Raccourcis
          const Etiquette('Raccourcis'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EcranDepenses()),
                  ),
                  icon: const Icon(Icons.payments_outlined, size: 20),
                  label: const Text('Dépenses'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EcranComptabilite()),
                  ),
                  icon: const Icon(Icons.account_balance_outlined, size: 20),
                  label: const Text('Comptabilité'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EcranParametres()),
            ),
            icon: const Icon(Icons.tune, size: 20),
            label: const Text('Réglages'),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.texte});
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Text(
      texte,
      style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 13),
    );
  }
}

class _PastilleStatut extends StatelessWidget {
  const _PastilleStatut({required this.statut});
  final String statut;

  @override
  Widget build(BuildContext context) {
    final ton = switch (statut) {
      'Payée' => Ton.ok,
      'Partielle' => Ton.attention,
      'Impayée' => Ton.critique,
      _ => Ton.neutre,
    };
    return Pastille(statut, ton: ton);
  }
}
