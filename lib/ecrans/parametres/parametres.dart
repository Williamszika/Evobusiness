import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/argent.dart';
import '../../coeur/composants.dart';
import '../../coeur/constantes.dart';
import '../../coeur/logos.dart';
import '../../coeur/theme.dart';
import '../../donnees/modeles.dart';
import '../../donnees/sauvegarde.dart';
import '../../etat/boutique.dart';
import 'actions_sauvegarde.dart';

class EcranParametres extends ConsumerStatefulWidget {
  const EcranParametres({super.key});

  @override
  ConsumerState<EcranParametres> createState() => _EcranParametresState();
}

class _EcranParametresState extends ConsumerState<EcranParametres> {
  late Parametres _p;
  late final TextEditingController _nom;
  late final TextEditingController _slogan;
  late final TextEditingController _telephone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  late final TextEditingController _adresse;
  late final TextEditingController _ville;
  late final TextEditingController _instagram;
  late final TextEditingController _prefixe;
  late final TextEditingController _messageRecu;
  late final TextEditingController _politique;
  late final TextEditingController _venduPar;
  late final TextEditingController _objectif;

  bool _sauvegardeEnCours = false;

  @override
  void initState() {
    super.initState();
    _p = ref.read(boutiqueProvider).parametres;
    _nom = TextEditingController(text: _p.nomBoutique);
    _slogan = TextEditingController(text: _p.slogan);
    _telephone = TextEditingController(text: _p.telephone);
    _whatsapp = TextEditingController(text: _p.whatsapp);
    _email = TextEditingController(text: _p.email);
    _adresse = TextEditingController(text: _p.adresse);
    _ville = TextEditingController(text: _p.ville);
    _instagram = TextEditingController(text: _p.instagram);
    _prefixe = TextEditingController(text: _p.prefixeRecu);
    _messageRecu = TextEditingController(text: _p.messageRecu);
    _politique = TextEditingController(text: _p.politiqueRetour);
    _venduPar = TextEditingController(text: _p.venduPar);
    _objectif = TextEditingController(
      text: Argent.versSaisie(_p.objectifMensuel, _p.decimales),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _nom, _slogan, _telephone, _whatsapp, _email, _adresse, _ville,
      _instagram, _prefixe, _messageRecu, _politique, _venduPar, _objectif,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final maj = _p.copie(
      nomBoutique: _nom.text.trim().isEmpty ? 'Ma boutique' : _nom.text.trim(),
      slogan: _slogan.text.trim(),
      telephone: _telephone.text.trim(),
      whatsapp: _whatsapp.text.trim(),
      email: _email.text.trim(),
      adresse: _adresse.text.trim(),
      ville: _ville.text.trim(),
      instagram: _instagram.text.trim(),
      prefixeRecu: _prefixe.text.trim().isEmpty ? 'REC' : _prefixe.text.trim(),
      messageRecu: _messageRecu.text.trim(),
      politiqueRetour: _politique.text.trim(),
      venduPar: _venduPar.text.trim(),
      objectifMensuel: Argent.depuisSaisie(_objectif.text) ?? 0,
    );
    await ref.read(boutiqueProvider.notifier).majParametres(maj);
    if (!mounted) return;
    setState(() => _p = maj);
    message(context, 'Réglages enregistrés.');
  }

  /// Applique un changement immédiat (logo, palette, devise) sans attendre
  /// le bouton d'enregistrement : le résultat se voit tout de suite.
  Future<void> _appliquer(Parametres maj) async {
    setState(() => _p = maj);
    await ref.read(boutiqueProvider.notifier).majParametres(maj);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = paletteParCle(_p.palette);

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          // ── Aperçu de la marque
          Card(
            color: palette.primaire,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  LogoBoutique(
                    parametres: _p,
                    palette: palette,
                    taille: 52,
                    surFondSombre: true,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nom.text.isEmpty ? 'Ma boutique' : _nom.text,
                          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_slogan.text.isNotEmpty)
                          Text(
                            _slogan.text,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .8),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Etiquette('Ma marque'),
          TextField(
            controller: _nom,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Nom du business'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _slogan,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Slogan'),
          ),
          const SizedBox(height: 16),

          Text('Logo', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Il apparaît dans l\'application et en haut de chaque reçu.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final piste in pistesLogo)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _appliquer(_p.copie(logo: piste.cle)),
                      child: Container(
                        width: 92,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _p.logo == piste.cle
                                ? palette.primaire
                                : theme.dividerColor,
                            width: _p.logo == piste.cle ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LogoBoutique(
                              parametres: _p.copie(logo: piste.cle),
                              palette: palette,
                              taille: 40,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              piste.nom,
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text('Couleurs', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final pal in palettes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _appliquer(_p.copie(palette: pal.cle)),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _p.palette == pal.cle ? pal.primaire : theme.dividerColor,
                      width: _p.palette == pal.cle ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      for (final c in [pal.primaire, pal.primaireClaire, pal.accent, pal.douce])
                        Container(
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(pal.nom, style: theme.textTheme.titleMedium)),
                      if (_p.palette == pal.cle)
                        Icon(Icons.check_circle, color: pal.primaire, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

          const Etiquette('Coordonnées imprimées sur le reçu'),
          TextField(
            controller: _telephone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Téléphone'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _whatsapp,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp',
              helperText: 'Sert aussi de numéro d\'envoi par défaut',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ville,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Ville'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _adresse,
                  decoration: const InputDecoration(labelText: 'Quartier / adresse'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _instagram,
            decoration: const InputDecoration(
              labelText: 'Instagram / TikTok',
              hintText: '@mabelleboutique',
            ),
          ),
          const SizedBox(height: 20),

          const Etiquette('Argent'),
          ChampChoix(
            libelle: 'Devise',
            valeur: _p.devise,
            options: devises.keys.toList(),
            onChange: (v) => _appliquer(_p.copie(devise: v ?? _p.devise)),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _p.deviseAvant,
            onChanged: (v) => _appliquer(_p.copie(deviseAvant: v)),
            title: const Text('Devise avant le montant'),
            subtitle: Text(
              _p.deviseAvant
                  ? '${_p.devise} 38 000'
                  : '38 000 ${_p.devise}',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          ChampMontant(
            controleur: _objectif,
            libelle: 'Objectif de ventes par mois',
            parametres: _p,
            aide: 'Affiché sur l\'accueil. Mets 0 pour le masquer.',
          ),
          const SizedBox(height: 20),

          const Etiquette('Le reçu'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _prefixe,
                  decoration: const InputDecoration(labelText: 'Préfixe'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Prochain numéro'),
                  child: Text(_p.prochainNumero()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _venduPar,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Vendu par',
              hintText: 'Ton nom, imprimé sur le reçu',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageRecu,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Message de remerciement'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _politique,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Politique d\'échange',
              helperText: 'C\'est elle qui coupe court aux discussions plus tard.',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _p.ticketParDefaut,
            onChanged: (v) => _appliquer(_p.copie(ticketParDefaut: v)),
            title: const Text('Ouvrir le reçu en ticket 80 mm'),
            subtitle: const Text(
              'À activer si tu utilises une imprimante thermique.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('TVA sur les reçus'),
            subtitle: Text(
              _p.tauxTva == 0
                  ? 'Désactivée — le reçu n\'affiche aucune TVA'
                  : 'Taux de ${_p.tauxTva.toStringAsFixed(0)} % inclus dans les prix',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _reglerTva,
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _enregistrer,
            child: const Text('Enregistrer les réglages'),
          ),
          const SizedBox(height: 28),

          const Etiquette('Sauvegarde'),
          Bloc(
            enfant: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      rappelSauvegardeNecessaire(_p.derniereSortieLe)
                          ? Icons.warning_amber_rounded
                          : Icons.verified_outlined,
                      size: 20,
                      color: rappelSauvegardeNecessaire(_p.derniereSortieLe)
                          ? Etats.attention
                          : Etats.ok,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _p.derniereSortieLe.isEmpty
                            ? 'Aucune copie mise à l\'abri pour l\'instant'
                            : 'Dernière copie mise à l\'abri il y a '
                                '${Dates.joursDepuis(_p.derniereSortieLe.split("T").first)} jour(s)',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'L\'application se sauvegarde toute seule à chaque ouverture, '
                  'et garde les ${Sauvegarde.nombreConserve} dernières copies. '
                  'Mais ce dossier disparaît si l\'application est désinstallée : '
                  'une fois par semaine, enregistre une copie dans ton Drive, '
                  'ton iCloud, ou envoie-la-toi sur WhatsApp.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _sauvegardeEnCours ? null : _exporter,
                        icon: const Icon(Icons.save_alt, size: 18),
                        label: const Text('Mettre à l\'abri'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _sauvegardeEnCours ? null : _importer,
                        icon: const Icon(Icons.folder_open_outlined, size: 18),
                        label: const Text('Depuis un fichier'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Les copies déposées automatiquement par l'application.
          FutureBuilder<List<File>>(
            future: ref.read(boutiqueProvider.notifier).listerSauvegardes(),
            builder: (context, instantane) {
              final fichiers = instantane.data ?? const <File>[];
              if (fichiers.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Column(
                  children: [
                    for (final fichier in fichiers)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.history, size: 20),
                        title: Builder(
                          builder: (_) {
                            final quand = Sauvegarde.dateDe(fichier);
                            return Text(
                              quand == null
                                  ? 'Sauvegarde'
                                  : '${Dates.court(Dates.jourIso(quand))} à '
                                      '${quand.hour.toString().padLeft(2, '0')}h'
                                      '${quand.minute.toString().padLeft(2, '0')}',
                            );
                          },
                        ),
                        subtitle: Text(Sauvegarde.tailleDe(fichier)),
                        trailing: TextButton(
                          onPressed: () => _restaurerLocale(fichier),
                          child: const Text('Restaurer'),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          const Etiquette('Données'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: const Text('Recharger la démonstration'),
                  subtitle: const Text(
                    'Remplace tout par le catalogue d\'exemple.',
                  ),
                  onTap: () async {
                    final ok = await confirmer(
                      context,
                      titre: 'Recharger la démonstration ?',
                      texte: 'Toutes tes données actuelles seront effacées.',
                      valider: 'Recharger',
                      dangereux: true,
                    );
                    if (!ok) return;
                    await ref.read(boutiqueProvider.notifier).reinstallerDemo();
                    if (context.mounted) message(context, 'Démonstration rechargée.');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: Etats.critique),
                  title: const Text('Repartir de zéro'),
                  subtitle: const Text(
                    'Efface articles, ventes, clientes et dépenses. '
                    'La marque et les réglages sont gardés.',
                  ),
                  onTap: () async {
                    final ok = await confirmer(
                      context,
                      titre: 'Tout effacer ?',
                      texte:
                          'Cette action est définitive. Fais d\'abord une '
                          'sauvegarde si tu as le moindre doute.',
                      valider: 'Tout effacer',
                      dangereux: true,
                    );
                    if (!ok) return;
                    await ref.read(boutiqueProvider.notifier).viderDonnees();
                    if (context.mounted) message(context, 'Données effacées.');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${_p.nomBoutique} · version 1.0',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reglerTva() async {
    final controleur = TextEditingController(
      text: _p.tauxTva == 0 ? '' : _p.tauxTva.toStringAsFixed(0),
    );
    final valide = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('TVA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Renseigne un taux seulement si ton activité est déclarée et '
              'assujettie. Le reçu indiquera alors la TVA comprise dans le total.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controleur,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Taux', suffixText: '%'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Valider')),
        ],
      ),
    );
    final taux = double.tryParse(controleur.text.replaceAll(',', '.')) ?? 0;
    controleur.dispose();
    if (valide != true) return;
    await _appliquer(_p.copie(tauxTva: taux.clamp(0, 40)));
  }

  Future<void> _exporter() async {
    setState(() => _sauvegardeEnCours = true);
    await sortirSauvegarde(context, ref);
    if (mounted) {
      setState(() {
        _p = ref.read(boutiqueProvider).parametres;
        _sauvegardeEnCours = false;
      });
    }
  }

  /// Restaure la boutique depuis l'une des copies déposées automatiquement
  /// par l'application.
  Future<void> _restaurerLocale(File fichier) async {
    final quand = Sauvegarde.dateDe(fichier);
    final ok = await confirmer(
      context,
      titre: 'Revenir à cette sauvegarde ?',
      texte: quand == null
          ? 'Le contenu actuel sera remplacé.'
          : 'Le contenu actuel sera remplacé par celui du '
              '${Dates.court(Dates.jourIso(quand))} à '
              '${quand.hour.toString().padLeft(2, '0')}h'
              '${quand.minute.toString().padLeft(2, '0')}.',
      valider: 'Restaurer',
      dangereux: true,
    );
    if (!ok) return;
    try {
      await ref.read(boutiqueProvider.notifier).restaurerFichier(fichier);
      if (!mounted) return;
      setState(() => _p = ref.read(boutiqueProvider).parametres);
      message(context, 'Boutique restaurée.');
    } catch (e) {
      if (mounted) message(context, 'Restauration impossible : $e', erreur: true);
    }
  }

  Future<void> _importer() async {
    final ok = await confirmer(
      context,
      titre: 'Restaurer une sauvegarde ?',
      texte:
          'Le contenu actuel de l\'application sera remplacé par celui du '
          'fichier choisi.',
      valider: 'Choisir le fichier',
      dangereux: true,
    );
    if (!ok) return;

    setState(() => _sauvegardeEnCours = true);
    try {
      final choix = await FilePicker.platform.pickFiles(withData: true);
      final octets = choix?.files.firstOrNull?.bytes;
      if (octets == null) {
        if (mounted) message(context, 'Aucun fichier choisi.');
        return;
      }
      final donnees = jsonDecode(utf8.decode(octets));
      if (donnees is! Map<String, dynamic> || donnees['produits'] is! List) {
        if (mounted) {
          message(context, 'Ce fichier n\'est pas une sauvegarde valide.', erreur: true);
        }
        return;
      }
      await ref.read(boutiqueProvider.notifier).importer(donnees);
      if (!mounted) return;
      setState(() => _p = ref.read(boutiqueProvider).parametres);
      message(context, 'Sauvegarde restaurée.');
    } catch (e) {
      if (mounted) message(context, 'Restauration impossible : $e', erreur: true);
    } finally {
      if (mounted) setState(() => _sauvegardeEnCours = false);
    }
  }
}
