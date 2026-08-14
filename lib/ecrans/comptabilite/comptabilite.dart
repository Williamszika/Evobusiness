import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../coeur/argent.dart';
import '../../coeur/composants.dart';
import '../../coeur/theme.dart';
import '../../etat/boutique.dart';
import '../../etat/comptabilite.dart';
import 'document_comptable.dart';

/// La comptabilité : ce qui est réellement entré en caisse, ce qui en est
/// sorti, et le document à remettre aux impôts.
class EcranComptabilite extends ConsumerStatefulWidget {
  const EcranComptabilite({super.key});

  @override
  ConsumerState<EcranComptabilite> createState() => _EcranComptabiliteState();
}

class _EcranComptabiliteState extends ConsumerState<EcranComptabilite> {
  static const _mois = [
    'Janv', 'Févr', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc',
  ];

  String _type = 'Année';
  late int _annee = DateTime.now().year;
  late int _moisChoisi = DateTime.now().month;
  late int _trimestre = ((DateTime.now().month - 1) ~/ 3) + 1;

  Periode get _periode => switch (_type) {
        'Mois' => Periode.mois(_annee, _moisChoisi),
        'Trimestre' => Periode.trimestre(_annee, _trimestre),
        _ => Periode.annee(_annee),
      };

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(boutiqueProvider);
    final p = etat.parametres;
    final theme = Theme.of(context);
    final bilan = Comptabilite.bilan(etat, _periode);
    final annees = Comptabilite.anneesDisponibles(etat);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comptabilité'),
            Text(bilan.periode.libelle, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // ── Choix de la période
          PucesChoix(
            options: const ['Mois', 'Trimestre', 'Année'],
            selection: _type,
            onChange: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 116,
                child: ChampChoix(
                  libelle: 'Année',
                  valeur: '$_annee',
                  options: annees.map((a) => '$a').toList(),
                  onChange: (v) => setState(() => _annee = int.tryParse(v ?? '') ?? _annee),
                ),
              ),
              const SizedBox(width: 12),
              if (_type == 'Mois')
                Expanded(
                  child: ChampChoix(
                    libelle: 'Mois',
                    valeur: _mois[_moisChoisi - 1],
                    options: _mois,
                    onChange: (v) => setState(
                      () => _moisChoisi = _mois.indexOf(v ?? _mois[0]) + 1,
                    ),
                  ),
                )
              else if (_type == 'Trimestre')
                Expanded(
                  child: ChampChoix(
                    libelle: 'Trimestre',
                    valeur: 'T$_trimestre',
                    options: const ['T1', 'T2', 'T3', 'T4'],
                    onChange: (v) => setState(
                      () => _trimestre = int.tryParse((v ?? 'T1').substring(1)) ?? 1,
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Du ${Dates.court(bilan.periode.debut)} au ${Dates.court(bilan.periode.fin)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),

          // ── Les trois chiffres qui comptent
          Tuile(
            libelle: 'Recettes encaissées',
            valeur: p.format(bilan.totalRecettes),
            detail: '${bilan.recettes.length} encaissement(s) reçus sur la période',
            fond: Etats.okFond,
            couleurValeur: Etats.ok,
          ),
          const SizedBox(height: 12),
          Tuile(
            libelle: 'Dépenses payées',
            valeur: p.format(bilan.totalDepenses),
            detail: '${bilan.depenses.length} ligne(s)',
          ),
          const SizedBox(height: 12),
          Tuile(
            libelle: bilan.resultat >= 0 ? 'Résultat — bénéfice' : 'Résultat — perte',
            valeur: p.format(bilan.resultat),
            detail: 'Recettes encaissées moins dépenses payées',
            fond: bilan.resultat >= 0 ? Etats.okFond : Etats.critiqueFond,
            couleurValeur: bilan.resultat >= 0 ? Etats.ok : Etats.critique,
          ),
          const SizedBox(height: 18),

          // ── La distinction qui évite les mauvaises surprises
          Bloc(
            enfant: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Encaissé, pas facturé', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Une vente ne compte ici qu\'au jour où l\'argent est arrivé. '
                  'Un acompte en janvier et le solde en mars sont deux recettes, '
                  'dans deux mois différents.',
                  style: theme.textTheme.bodySmall,
                ),
                const Divider(height: 22),
                _LigneInfo(
                  libelle: 'Ventes facturées sur la période',
                  valeur: p.format(bilan.factureSurPeriode),
                ),
                _LigneInfo(
                  libelle: 'Restant dû par les clientes au ${Dates.court(bilan.periode.fin)}',
                  valeur: p.format(bilan.creancesEnFinDePeriode),
                  alerte: bilan.creancesEnFinDePeriode > 0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (bilan.moisParMois.length > 1) ...[
            const Etiquette('Mois par mois'),
            Card(
              child: Column(
                children: [
                  for (final m in bilan.moisParMois)
                    ListTile(
                      dense: true,
                      title: Text(m.libelle),
                      subtitle: Text(
                        '${p.format(m.recettes)} encaissés · '
                        '${p.format(m.depenses)} dépensés',
                      ),
                      trailing: Text(
                        p.format(m.recettes - m.depenses),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: m.recettes - m.depenses >= 0 ? Etats.ok : Etats.critique,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          if (bilan.depensesParCategorie.isNotEmpty) ...[
            const Etiquette('Où part l\'argent'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    for (final c in bilan.depensesParCategorie)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(c.categorie)),
                                Text(p.format(c.montant),
                                    style: theme.textTheme.titleMedium),
                              ],
                            ),
                            const SizedBox(height: 5),
                            BarreObjectif(
                              progression: bilan.totalDepenses == 0
                                  ? 0
                                  : c.montant / bilan.totalDepenses,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          const Etiquette('Livre des recettes'),
          if (bilan.recettes.isEmpty)
            const Bloc(enfant: Text('Aucun encaissement sur cette période.'))
          else
            Card(
              child: Column(
                children: [
                  for (final r in bilan.recettes.reversed.take(8))
                    ListTile(
                      dense: true,
                      title: Text(r.client, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${Dates.court(r.date)} · ${r.numero} · ${r.moyenPaiement}'),
                      trailing: Text(
                        p.format(r.montant),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: r.estRemboursement ? Etats.critique : null,
                        ),
                      ),
                    ),
                  if (bilan.recettes.length > 8)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'et ${bilan.recettes.length - 8} autre(s) — '
                        'tout figure dans le document',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ApercuDocumentComptable(periode: _periode),
              ),
            ),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Éditer le document pour les impôts'),
          ),
        ),
      ),
    );
  }
}

class _LigneInfo extends StatelessWidget {
  const _LigneInfo({required this.libelle, required this.valeur, this.alerte = false});

  final String libelle;
  final String valeur;
  final bool alerte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(libelle, style: theme.textTheme.bodySmall)),
          const SizedBox(width: 10),
          Text(
            valeur,
            style: theme.textTheme.titleMedium?.copyWith(
              color: alerte ? Etats.attention : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Aperçu du livre de recettes avant impression ou envoi.
class ApercuDocumentComptable extends ConsumerWidget {
  const ApercuDocumentComptable({super.key, required this.periode});

  final Periode periode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(boutiqueProvider);
    final p = etat.parametres;
    final bilan = Comptabilite.bilan(etat, periode);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Livre de recettes'),
            Text(periode.libelle, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      body: PdfPreview(
        key: ValueKey('compta-${periode.debut}-${periode.fin}-${etat.reglements.length}'),
        build: (_) => construireDocumentComptable(bilan, p),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        useActions: false,
        maxPageWidth: 560,
        pdfFileName: nomFichierComptable(bilan, p),
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final donnees = await construireDocumentComptable(bilan, p);
                  await Printing.sharePdf(
                    bytes: donnees,
                    filename: nomFichierComptable(bilan, p),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 19),
                label: const Text('Envoyer ou enregistrer le PDF'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () async {
                  final donnees = await construireDocumentComptable(bilan, p);
                  await Printing.layoutPdf(
                    onLayout: (_) async => donnees,
                    name: nomFichierComptable(bilan, p),
                  );
                },
                icon: const Icon(Icons.print_outlined),
                label: const Text('Imprimer le document'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
