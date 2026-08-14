import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/argent.dart';
import '../../coeur/composants.dart';
import '../../coeur/constantes.dart';
import '../../donnees/modeles.dart';
import '../../etat/boutique.dart';
import '../../etat/indicateurs.dart';

/// Les dépenses : sans elles, le « bénéfice » affiché serait un mensonge.
class EcranDepenses extends ConsumerStatefulWidget {
  const EcranDepenses({super.key});

  @override
  ConsumerState<EcranDepenses> createState() => _EcranDepensesState();
}

class _EcranDepensesState extends ConsumerState<EcranDepenses> {
  String _periode = 'Ce mois';

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(boutiqueProvider);
    final p = etat.parametres;
    final theme = Theme.of(context);
    final moisCourant = Dates.cleMois(Dates.aujourdhui());

    final liste = etat.depenses.where((d) {
      if (_periode == 'Ce mois') return Dates.cleMois(d.date) == moisCourant;
      if (_periode == '90 jours') return d.date.compareTo(Dates.ilYaJours(90)) >= 0;
      return true;
    }).toList();

    final total = Indicateurs.totalDepenses(liste);

    // Répartition par catégorie, la plus lourde en premier.
    final parCategorie = <String, int>{};
    for (final d in liste) {
      parCategorie[d.categorie] = (parCategorie[d.categorie] ?? 0) + d.montant;
    }
    final categoriesTriees = parCategorie.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dépenses'),
            Text('${liste.length} ligne(s) · ${p.format(total)}',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _saisir(context),
        icon: const Icon(Icons.add),
        label: const Text('Dépense'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          PucesChoix(
            options: const ['Ce mois', '90 jours', 'Tout'],
            selection: _periode,
            onChange: (v) => setState(() => _periode = v),
          ),
          const SizedBox(height: 16),
          Tuile(
            libelle: 'Total $_periode'.toLowerCase(),
            valeur: p.format(total),
            detail: 'Ce montant est déduit du bénéfice net affiché sur l\'accueil.',
          ),
          if (categoriesTriees.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Etiquette('Où part l\'argent'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    for (final e in categoriesTriees)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(e.key, style: theme.textTheme.bodyMedium),
                                ),
                                Text(p.format(e.value),
                                    style: theme.textTheme.titleMedium),
                              ],
                            ),
                            const SizedBox(height: 5),
                            BarreObjectif(
                              progression: total == 0 ? 0 : e.value / total,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Etiquette('Détail'),
          if (liste.isEmpty)
            const Bloc(
              enfant: Text(
                'Aucune dépense sur cette période. Pense à saisir les achats de '
                'marchandise, le fret, la douane et la publicité : c\'est ce qui '
                'donne un vrai bénéfice.',
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final depense in liste)
                    ListTile(
                      title: Text(depense.libelle),
                      subtitle: Text(
                        '${depense.categorie} · ${Dates.court(depense.date)} · '
                        '${depense.moyenPaiement}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(p.format(depense.montant),
                              style: theme.textTheme.titleMedium),
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 18),
                            onPressed: () => _actions(context, depense),
                          ),
                        ],
                      ),
                      onTap: () => _saisir(context, depense: depense),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _actions(BuildContext context, Depense depense) async {
    final choix = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifier'),
              onTap: () => Navigator.pop(c, 'modifier'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Supprimer'),
              onTap: () => Navigator.pop(c, 'supprimer'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choix == 'modifier') {
      await _saisir(context, depense: depense);
    } else if (choix == 'supprimer') {
      await ref.read(boutiqueProvider.notifier).supprimerDepense(depense.id);
      if (context.mounted) message(context, 'Dépense supprimée.');
    }
  }

  Future<void> _saisir(BuildContext context, {Depense? depense}) async {
    final p = ref.read(boutiqueProvider).parametres;
    final libelle = TextEditingController(text: depense?.libelle ?? '');
    final montant = TextEditingController(
      text: depense == null ? '' : Argent.versSaisie(depense.montant, p.decimales),
    );
    var categorie = depense?.categorie ?? categoriesDepense.first;
    var moyen = depense?.moyenPaiement ?? moyensPaiement.first;
    var date = depense?.date ?? Dates.aujourdhui();

    final valide = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (c) => StatefulBuilder(
        builder: (c, majFeuille) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(c).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  depense == null ? 'Nouvelle dépense' : 'Modifier la dépense',
                  style: Theme.of(c).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: libelle,
                  autofocus: depense == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Libellé *',
                    hintText: 'Ex. Commande 10 mèches brésiliennes',
                  ),
                ),
                const SizedBox(height: 12),
                ChampMontant(
                  controleur: montant,
                  libelle: 'Montant *',
                  parametres: p,
                ),
                const SizedBox(height: 12),
                ChampChoix(
                  libelle: 'Catégorie',
                  valeur: categorie,
                  options: categoriesDepense,
                  onChange: (v) => majFeuille(() => categorie = v ?? categorie),
                ),
                const SizedBox(height: 12),
                ChampChoix(
                  libelle: 'Payée par',
                  valeur: moyen,
                  options: moyensPaiement,
                  onChange: (v) => majFeuille(() => moyen = v ?? moyen),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final choix = await choisirDate(c, date);
                    if (choix != null) majFeuille(() => date = choix);
                  },
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(Dates.court(date)),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Enregistrer'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );

    final texte = libelle.text.trim();
    final valeur = Argent.depuisSaisie(montant.text) ?? 0;
    libelle.dispose();
    montant.dispose();

    if (valide != true) return;
    if (texte.isEmpty || valeur <= 0) {
      if (context.mounted) {
        message(context, 'Il faut un libellé et un montant.', erreur: true);
      }
      return;
    }

    final notifier = ref.read(boutiqueProvider.notifier);
    if (depense == null) {
      await notifier.ajouterDepense(
        Depense(
          id: nouvelId('dep'),
          date: date,
          categorie: categorie,
          libelle: texte,
          montant: valeur,
          moyenPaiement: moyen,
          creeLe: DateTime.now().toIso8601String(),
        ),
      );
    } else {
      await notifier.modifierDepense(
        depense.copie(
          date: date,
          categorie: categorie,
          libelle: texte,
          montant: valeur,
          moyenPaiement: moyen,
        ),
      );
    }
    if (context.mounted) message(context, 'Dépense enregistrée.');
  }
}
