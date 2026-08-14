import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../coeur/argent.dart';
import '../../coeur/composants.dart';
import '../../coeur/constantes.dart';
import '../../coeur/images.dart';
import '../../coeur/theme.dart';
import '../../donnees/modeles.dart';
import '../../etat/boutique.dart';

/// Création et modification d'un article.
class EditionProduit extends ConsumerStatefulWidget {
  const EditionProduit({super.key, this.produit});

  final Produit? produit;

  @override
  ConsumerState<EditionProduit> createState() => _EditionProduitState();
}

class _EditionProduitState extends ConsumerState<EditionProduit> {
  final _formulaire = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _reference;
  late final TextEditingController _prixAchat;
  late final TextEditingController _prixVente;
  late final TextEditingController _stock;
  late final TextEditingController _seuil;
  late final TextEditingController _description;

  String _categorie = categories.first;
  String? _texture;
  String? _longueur;
  String? _couleur;
  String? _origine;
  String? _densite;
  String? _fournisseurId;
  String? _photo;
  bool _actif = true;
  bool _enregistrement = false;

  bool get _modification => widget.produit != null;

  @override
  void initState() {
    super.initState();
    final a = widget.produit;
    final p = ref.read(boutiqueProvider).parametres;
    final decimales = p.decimales;

    _nom = TextEditingController(text: a?.nom ?? '');
    _reference = TextEditingController(
      text: a?.reference ?? ref.read(boutiqueProvider.notifier).referenceLibre(),
    );
    _prixAchat = TextEditingController(
      text: a == null ? '' : Argent.versSaisie(a.prixAchat, decimales),
    );
    _prixVente = TextEditingController(
      text: a == null ? '' : Argent.versSaisie(a.prixVente, decimales),
    );
    _stock = TextEditingController(text: (a?.stock ?? 0).toString());
    _seuil = TextEditingController(text: (a?.seuilAlerte ?? 2).toString());
    _description = TextEditingController(text: a?.description ?? '');

    _categorie = a?.categorie ?? categories.first;
    _texture = a?.texture;
    _longueur = a?.longueur;
    _couleur = a?.couleur;
    _origine = a?.origine;
    _densite = a?.densite;
    _fournisseurId = a?.fournisseurId;
    _photo = a?.photo;
    _actif = a?.actif ?? true;
  }

  @override
  void dispose() {
    _nom.dispose();
    _reference.dispose();
    _prixAchat.dispose();
    _prixVente.dispose();
    _stock.dispose();
    _seuil.dispose();
    _description.dispose();
    super.dispose();
  }

  /// La photo est réduite puis rangée dans la fiche elle-même : elle suit
  /// donc la sauvegarde, et survit au ménage de la galerie.
  Future<void> _choisirPhoto(ImageSource source) async {
    try {
      final choix = await ImagePicker().pickImage(
        source: source,
        maxWidth: Photos.largeurMax,
        imageQuality: Photos.qualite,
      );
      if (choix == null) return;
      final octets = await choix.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = Photos.encoder(octets));
    } catch (e) {
      if (mounted) message(context, 'Photo impossible : $e', erreur: true);
    }
  }

  Future<void> _enregistrer() async {
    if (!_formulaire.currentState!.validate()) return;
    setState(() => _enregistrement = true);

    final notifier = ref.read(boutiqueProvider.notifier);
    final prixAchat = Argent.depuisSaisie(_prixAchat.text) ?? 0;
    final prixVente = Argent.depuisSaisie(_prixVente.text) ?? 0;
    final stock = int.tryParse(_stock.text.trim()) ?? 0;
    final seuil = int.tryParse(_seuil.text.trim()) ?? 0;

    if (_modification) {
      final ancien = widget.produit!;
      final maj = ancien.copie(
        nom: _nom.text.trim(),
        reference: _reference.text.trim(),
        categorie: _categorie,
        texture: _texture,
        longueur: _longueur,
        couleur: _couleur,
        origine: _origine,
        densite: _densite,
        prixAchat: prixAchat,
        prixVente: prixVente,
        seuilAlerte: seuil,
        fournisseurId: _fournisseurId,
        photo: _photo,
        description: _description.text.trim(),
        actif: _actif,
      );
      await notifier.modifierProduit(maj);
      // Le stock ne se corrige pas ici en silence : tout écart passe par un
      // mouvement, pour rester traçable dans l'historique de l'article.
      final ecart = stock - ancien.stock;
      if (ecart != 0) {
        await notifier.ajusterStock(
          ancien.id,
          ecart,
          mvtAjustement,
          motif: 'Correction depuis la fiche article',
        );
      }
    } else {
      await notifier.ajouterProduit(
        Produit(
          id: nouvelId('prod'),
          reference: _reference.text.trim().isEmpty
              ? notifier.referenceLibre()
              : _reference.text.trim(),
          nom: _nom.text.trim(),
          categorie: _categorie,
          texture: _texture,
          longueur: _longueur,
          couleur: _couleur,
          origine: _origine,
          densite: _densite,
          prixAchat: prixAchat,
          prixVente: prixVente,
          stock: stock,
          seuilAlerte: seuil,
          fournisseurId: _fournisseurId,
          photo: _photo,
          description: _description.text.trim(),
          actif: _actif,
          creeLe: DateTime.now().toIso8601String(),
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    message(context, _modification ? 'Article modifié.' : 'Article ajouté.');
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(boutiqueProvider);
    final p = etat.parametres;
    final theme = Theme.of(context);
    final estService = _categorie == 'Service (pose, coiffure)';

    final achat = Argent.depuisSaisie(_prixAchat.text) ?? 0;
    final vente = Argent.depuisSaisie(_prixVente.text) ?? 0;
    final marge = vente - achat;

    return Scaffold(
      appBar: AppBar(
        title: Text(_modification ? 'Modifier l\'article' : 'Nouvel article'),
      ),
      body: Form(
        key: _formulaire,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            // Photo
            Center(
              child: Column(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Photos.decoder(_photo) != null
                        ? Image.memory(Photos.decoder(_photo)!,
                            fit: BoxFit.cover, gaplessPlayback: true)
                        : Icon(
                            Icons.photo_camera_outlined,
                            size: 34,
                            color: theme.colorScheme.primary.withValues(alpha: .6),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => _choisirPhoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: const Text('Photo'),
                      ),
                      TextButton.icon(
                        onPressed: () => _choisirPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: const Text('Galerie'),
                      ),
                      if (_photo != null)
                        TextButton.icon(
                          onPressed: () => setState(() => _photo = null),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Retirer'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            const Etiquette('Identité'),
            TextFormField(
              controller: _nom,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'article *',
                hintText: 'Ex. Mèche brésilienne Body Wave',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Donne un nom à l\'article' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _reference,
                    decoration: const InputDecoration(labelText: 'Référence'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ChampChoix(
                    libelle: 'Catégorie',
                    valeur: _categorie,
                    options: categories,
                    onChange: (v) => setState(() => _categorie = v ?? categories.first),
                  ),
                ),
              ],
            ),

            if (!estService) ...[
              const SizedBox(height: 20),
              const Etiquette('Caractéristiques'),
              Row(
                children: [
                  Expanded(
                    child: ChampChoix(
                      libelle: 'Origine',
                      valeur: _origine,
                      options: origines,
                      optionVide: '—',
                      onChange: (v) => setState(() => _origine = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChampChoix(
                      libelle: 'Texture',
                      valeur: _texture,
                      options: textures,
                      optionVide: '—',
                      onChange: (v) => setState(() => _texture = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChampChoix(
                      libelle: 'Longueur',
                      valeur: _longueur,
                      options: longueurs,
                      optionVide: '—',
                      onChange: (v) => setState(() => _longueur = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChampChoix(
                      libelle: 'Couleur',
                      valeur: _couleur,
                      options: couleurs,
                      optionVide: '—',
                      onChange: (v) => setState(() => _couleur = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ChampChoix(
                libelle: 'Densité (perruques)',
                valeur: _densite,
                options: densites,
                optionVide: '—',
                onChange: (v) => setState(() => _densite = v),
              ),
            ],

            const SizedBox(height: 20),
            const Etiquette('Prix'),
            Row(
              children: [
                Expanded(
                  child: ChampMontant(
                    controleur: _prixAchat,
                    libelle: 'Prix d\'achat',
                    parametres: p,
                    onChange: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChampMontant(
                    controleur: _prixVente,
                    libelle: 'Prix de vente *',
                    parametres: p,
                    onChange: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: marge >= 0 ? Etats.okFond : Etats.critiqueFond,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    marge >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: marge >= 0 ? Etats.ok : Etats.critique,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Marge par pièce',
                      style: TextStyle(
                        color: marge >= 0 ? Etats.ok : Etats.critique,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${p.format(marge)}'
                    '${vente > 0 ? "  ·  ${(marge / vente * 100).round()} %" : ""}',
                    style: TextStyle(
                      color: marge >= 0 ? Etats.ok : Etats.critique,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            if (!estService) ...[
              const SizedBox(height: 20),
              const Etiquette('Stock'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantité en stock'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _seuil,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Alerte en dessous de',
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            const Etiquette('Complément'),
            if (etat.fournisseurs.isNotEmpty) ...[
              ChampChoix(
                libelle: 'Fournisseur',
                valeur: etat.fournisseur(_fournisseurId)?.nom,
                options: etat.fournisseurs.map((f) => f.nom).toList(),
                optionVide: '—',
                onChange: (nom) => setState(() {
                  _fournisseurId = nom == null
                      ? null
                      : etat.fournisseurs.firstWhere((f) => f.nom == nom).id;
                }),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _description,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note interne',
                hintText: 'Qualité, lot, remarque…',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _actif,
              onChanged: (v) => setState(() => _actif = v),
              title: const Text('Article en vente'),
              subtitle: const Text(
                'Décoche pour l\'archiver : il disparaît de la vente sans '
                'effacer son historique.',
              ),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _enregistrement ? null : _enregistrer,
              child: Text(_modification ? 'Enregistrer les modifications' : 'Ajouter l\'article'),
            ),
          ],
        ),
      ),
    );
  }
}
