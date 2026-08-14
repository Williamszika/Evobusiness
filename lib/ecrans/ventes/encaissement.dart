import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/argent.dart';
import '../../coeur/composants.dart';
import '../../coeur/constantes.dart';
import '../../coeur/theme.dart';
import '../../donnees/modeles.dart';
import '../../etat/boutique.dart';
import '../clients/choix_client.dart';
import '../recu/apercu_recu.dart';
import 'nouvelle_vente.dart';

/// Étape 2 de la vente : la cliente, les remises, le paiement.
class Encaissement extends ConsumerStatefulWidget {
  const Encaissement({super.key, required this.lignes});

  final List<LignePanier> lignes;

  @override
  ConsumerState<Encaissement> createState() => _EncaissementState();
}

class _EncaissementState extends ConsumerState<Encaissement> {
  final _remise = TextEditingController();
  final _livraison = TextEditingController();
  final _paye = TextEditingController();
  final _note = TextEditingController();

  Client? _cliente;
  String _nomLibre = '';
  String _moyen = moyensPaiement.first;
  String _canal = canaux.first;
  String _date = Dates.aujourdhui();
  bool _payeToucheParUtilisateur = false;
  bool _enCours = false;

  @override
  void dispose() {
    _remise.dispose();
    _livraison.dispose();
    _paye.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _sousTotal => widget.lignes.fold(0, (s, l) => s + l.total);
  int get _remiseGlobale => Argent.depuisSaisie(_remise.text) ?? 0;
  int get _fraisLivraison => Argent.depuisSaisie(_livraison.text) ?? 0;
  int get _total {
    final brut = _sousTotal - _remiseGlobale + _fraisLivraison;
    return brut < 0 ? 0 : brut;
  }

  int get _montantPaye =>
      _payeToucheParUtilisateur ? (Argent.depuisSaisie(_paye.text) ?? 0) : _total;

  int get _reste {
    final r = _total - _montantPaye;
    return r < 0 ? 0 : r;
  }

  Future<void> _valider() async {
    if (widget.lignes.isEmpty) return;
    setState(() => _enCours = true);

    final notifier = ref.read(boutiqueProvider.notifier);
    final lignes = widget.lignes
        .map(
          (l) => LigneVente(
            id: nouvelId('lig'),
            venteId: '',
            produitId: l.produit.id,
            designation: l.produit.nom,
            detail: l.produit.detail.isEmpty ? null : l.produit.detail,
            prixUnitaire: l.produit.prixVente,
            // Le prix d'achat est figé ici : la marge de cette vente restera
            // juste même si le prix d'achat change au prochain arrivage.
            coutUnitaire: l.produit.prixAchat,
            quantite: l.quantite,
            remise: l.remise,
          ),
        )
        .toList();

    final vente = await notifier.enregistrerVente(
      lignes: lignes,
      clientId: _cliente?.id,
      clientNom: _cliente?.nom ?? _nomLibre,
      clientTelephone: _cliente?.telephone,
      remiseGlobale: _remiseGlobale,
      fraisLivraison: _fraisLivraison,
      moyenPaiement: _moyen,
      canal: _canal,
      montantPaye: _montantPaye,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      date: _date,
    );

    if (!mounted) return;
    // On remplace les deux écrans de vente : après le reçu, retour à l'accueil.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ApercuRecu(venteId: vente.id, nouvelle: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(boutiqueProvider);
    final p = etat.parametres;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Encaisser'),
            Text('Étape 2 — le paiement', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // ── Cliente
          const Etiquette('Cliente'),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: .12),
                child: Icon(Icons.person_outline, color: theme.colorScheme.primary),
              ),
              title: Text(
                _cliente?.nom ??
                    (_nomLibre.isEmpty ? 'Client de passage' : _nomLibre),
              ),
              subtitle: Text(
                _cliente?.telephone ?? 'Appuie pour choisir ou créer une fiche',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final choix = await choisirClient(context, ref);
                if (choix == null) return;
                setState(() {
                  _cliente = choix.client;
                  _nomLibre = choix.nomLibre;
                });
              },
            ),
          ),
          const SizedBox(height: 18),

          // ── Articles
          const Etiquette('Articles'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  for (final ligne in widget.lignes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ligne.produit.nom,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 2,
                                ),
                                Text(
                                  '${ligne.quantite} × ${p.format(ligne.produit.prixVente)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                if (ligne.remise > 0)
                                  Text(
                                    'Remise −${p.format(ligne.remise)}',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: theme.colorScheme.primary),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(p.format(ligne.total), style: theme.textTheme.titleMedium),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.percent, size: 17),
                            tooltip: 'Remise sur cette ligne',
                            onPressed: () => _remiseLigne(ligne, p),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 18),
                  _LigneTotal(libelle: 'Sous-total', valeur: p.format(_sousTotal)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChampMontant(
                          controleur: _remise,
                          libelle: 'Remise',
                          parametres: p,
                          onChange: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChampMontant(
                          controleur: _livraison,
                          libelle: 'Livraison',
                          parametres: p,
                          onChange: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(color: theme.colorScheme.onSurface, width: 1.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('TOTAL À PAYER', style: theme.textTheme.titleLarge),
                        ),
                        Text(p.format(_total), style: theme.textTheme.headlineSmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Paiement
          const Etiquette('Moyen de paiement'),
          PucesChoix(
            options: moyensPaiement,
            selection: _moyen,
            onChange: (v) => setState(() => _moyen = v),
          ),
          const SizedBox(height: 18),

          const Etiquette('Montant reçu'),
          ChampMontant(
            controleur: _paye,
            libelle: 'Montant reçu',
            parametres: p,
            aide: 'Laisse vide si la cliente paie tout maintenant.',
            onChange: (_) => setState(() => _payeToucheParUtilisateur = true),
          ),
          const SizedBox(height: 10),
          if (_reste > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Etats.attentionFond,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 18, color: Etats.attention),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Reste à payer',
                      style: TextStyle(color: Etats.attention, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    p.format(_reste),
                    style: const TextStyle(
                      color: Etats.attention,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Etats.okFond,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: Etats.ok),
                  SizedBox(width: 10),
                  Text(
                    'Tout payé',
                    style: TextStyle(color: Etats.ok, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          if (_payeToucheParUtilisateur) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _paye.clear();
                  _payeToucheParUtilisateur = false;
                }),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Remettre le montant total'),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // ── Détails
          const Etiquette('D\'où vient cette vente ?'),
          PucesChoix(
            options: canaux,
            selection: _canal,
            onChange: (v) => setState(() => _canal = v),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final choix = await choisirDate(context, _date);
                    if (choix != null) setState(() => _date = choix);
                  },
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(Dates.court(_date)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note sur la vente',
              hintText: 'Ex. solde promis pour la fin du mois',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _enCours ? null : _valider,
            icon: const Icon(Icons.receipt_long_outlined),
            label: Text('Valider et faire le reçu · ${p.format(_total)}'),
          ),
        ),
      ),
    );
  }

  Future<void> _remiseLigne(LignePanier ligne, Parametres p) async {
    final controleur = TextEditingController(
      text: ligne.remise == 0 ? '' : Argent.versSaisie(ligne.remise, p.decimales),
    );
    final valide = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Remise — ${ligne.produit.nom}'),
        content: ChampMontant(
          controleur: controleur,
          libelle: 'Montant de la remise',
          parametres: p,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Appliquer')),
        ],
      ),
    );
    final montant = Argent.depuisSaisie(controleur.text) ?? 0;
    controleur.dispose();
    if (valide != true) return;
    setState(() => ligne.remise = montant);
  }
}

class _LigneTotal extends StatelessWidget {
  const _LigneTotal({required this.libelle, required this.valeur});
  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(libelle, style: Theme.of(context).textTheme.bodySmall)),
        Text(valeur, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
