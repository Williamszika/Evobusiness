import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/argent.dart';
import '../../coeur/composants.dart';
import '../../coeur/theme.dart';
import '../../etat/boutique.dart';
import '../../etat/indicateurs.dart';
import '../clients/fiche_client.dart';
import '../comptabilite/comptabilite.dart';
import '../depenses/depenses.dart';
import '../produits/fiche_produit.dart';

class Rapports extends ConsumerStatefulWidget {
  const Rapports({super.key});

  @override
  ConsumerState<Rapports> createState() => _RapportsState();
}

class _RapportsState extends ConsumerState<Rapports> {
  String _periode = '30 jours';

  static const _periodes = ['7 jours', '30 jours', '6 mois', 'Année'];

  (String debut, String fin) _bornes() {
    final fin = Dates.aujourdhui();
    final debut = switch (_periode) {
      '7 jours' => Dates.ilYaJours(7),
      '30 jours' => Dates.ilYaJours(30),
      '6 mois' => Dates.ilYaJours(182),
      _ => '${DateTime.now().year}-01-01',
    };
    return (debut, fin);
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(boutiqueProvider);
    final p = etat.parametres;
    final theme = Theme.of(context);
    final palette = paletteParCle(p.palette);

    final (debut, fin) = _bornes();
    final ventes = Indicateurs.entre(etat, debut, fin).toList();
    final depenses = Indicateurs.depensesEntre(etat, debut, fin).toList();

    final ca = Indicateurs.chiffreAffaires(ventes);
    final benefice = Indicateurs.beneficeNet(ventes, depenses);
    final serie = Indicateurs.serieMensuelle(etat);
    final topProduits = Indicateurs.meilleursProduits(etat, ventes);
    final topClientes = Indicateurs.meilleuresClientes(etat, ventes);
    final canaux = Indicateurs.parCanal(ventes);
    final maxSerie = serie.fold<int>(0, (m, e) => e.$2 > m ? e.$2 : m);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rapports'),
            Text('${ventes.length} vente(s) sur la période',
                style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Comptabilité',
            icon: const Icon(Icons.account_balance_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EcranComptabilite()),
            ),
          ),
          IconButton(
            tooltip: 'Dépenses',
            icon: const Icon(Icons.payments_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EcranDepenses()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          PucesChoix(
            options: _periodes,
            selection: _periode,
            onChange: (v) => setState(() => _periode = v),
          ),
          const SizedBox(height: 16),

          Tuile(
            libelle: 'Chiffre d\'affaires',
            valeur: p.format(ca),
            detail: 'Encaissé : ${p.format(Indicateurs.encaisse(ventes))}'
                '${Indicateurs.chiffreAffaires(ventes) > Indicateurs.encaisse(ventes) ? " — le reste est en crédit" : ""}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Tuile(
                  libelle: 'Bénéfice net',
                  valeur: p.format(benefice),
                  detail: '− ${p.format(Indicateurs.totalDepenses(depenses))} de dépenses',
                  couleurValeur: benefice >= 0 ? Etats.ok : Etats.critique,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tuile(
                  libelle: 'Panier moyen',
                  valeur: p.format(Indicateurs.panierMoyen(ventes)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Courbe des six derniers mois
          const Etiquette('Six derniers mois'),
          Bloc(
            enfant: SizedBox(
              height: 180,
              child: maxSerie == 0
                  ? Center(
                      child: Text('Pas encore assez de ventes.',
                          style: theme.textTheme.bodySmall),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxSerie * 1.18,
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxSerie / 3,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: theme.dividerColor,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              interval: maxSerie / 3,
                              getTitlesWidget: (valeur, _) => Text(
                                p.formatCourt(valeur.round()),
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 26,
                              getTitlesWidget: (valeur, _) {
                                final i = valeur.toInt();
                                if (i < 0 || i >= serie.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    Dates.moisCourt(serie[i].$1),
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(fontSize: 10.5),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < serie.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: serie[i].$2.toDouble(),
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                  color: i == serie.length - 1
                                      ? palette.primaire
                                      : palette.primaire.withValues(alpha: .35),
                                ),
                              ],
                            ),
                        ],
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (groupe, _, tige, __) => BarTooltipItem(
                              p.format(tige.toY.round()),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Ce qui rapporte
          const Etiquette('Ce qui rapporte le plus'),
          if (topProduits.isEmpty)
            const Bloc(enfant: Text('Aucune vente sur la période.'))
          else
            Card(
              child: Column(
                children: [
                  for (final entree in topProduits)
                    ListTile(
                      title: Text(entree.designation,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${entree.quantite} vendu(s) · '
                        'chiffre ${p.format(entree.chiffre)}',
                      ),
                      trailing: Text(
                        '+${p.format(entree.marge)}',
                        style: theme.textTheme.titleMedium?.copyWith(color: Etats.ok),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FicheProduit(produitId: entree.produitId),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // ── Meilleures clientes
          const Etiquette('Meilleures clientes'),
          if (topClientes.isEmpty)
            const Bloc(enfant: Text('Aucune vente sur la période.'))
          else
            Card(
              child: Column(
                children: [
                  for (final entree in topClientes)
                    ListTile(
                      title: Text(entree.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${entree.commandes} commande(s)'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(p.format(entree.chiffre),
                              style: theme.textTheme.titleMedium),
                          if (entree.reste > 0)
                            Text(
                              'doit ${p.format(entree.reste)}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Etats.attention),
                            ),
                        ],
                      ),
                      onTap: entree.clientId == null
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FicheClient(clientId: entree.clientId!),
                                ),
                              ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // ── Canaux
          const Etiquette('D\'où viennent les ventes'),
          if (canaux.isEmpty)
            const Bloc(enfant: Text('Aucune vente sur la période.'))
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  children: [
                    for (final (canal, montant, part) in canaux)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(canal)),
                                Text('${(part * 100).round()} %',
                                    style: theme.textTheme.titleMedium),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 96,
                                  child: Text(
                                    p.format(montant),
                                    textAlign: TextAlign.right,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            BarreObjectif(progression: part),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // ── Stock
          const Etiquette('Stock'),
          Row(
            children: [
              Expanded(
                child: Tuile(
                  libelle: 'Valeur du stock',
                  valeur: p.format(Indicateurs.valeurStock(etat)),
                  detail: 'au prix d\'achat',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tuile(
                  libelle: 'Pièces en stock',
                  valeur: '${Indicateurs.articlesEnStock(etat)}',
                  detail: '${etat.alertesStock.length} à surveiller',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
