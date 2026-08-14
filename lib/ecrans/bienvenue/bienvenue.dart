import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/composants.dart';
import '../../coeur/constantes.dart';
import '../../coeur/logos.dart';
import '../../coeur/theme.dart';
import '../../etat/boutique.dart';

/// Ce que voit la vendeuse à la toute première ouverture.
///
/// On ne demande ici que ce qui s'imprime sur un reçu et qu'on ne peut pas
/// deviner : le nom, de quoi la joindre, et la monnaie. Tout le reste — slogan,
/// logo, mentions, objectif — attend dans les paramètres, et n'empêche pas de
/// vendre dès la première minute.
class EcranBienvenue extends ConsumerStatefulWidget {
  const EcranBienvenue({super.key});

  @override
  ConsumerState<EcranBienvenue> createState() => _EcranBienvenueState();
}

class _EcranBienvenueState extends ConsumerState<EcranBienvenue> {
  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  final _ville = TextEditingController();
  String _devise = 'FCFA';
  String _logo = 'couronne';
  bool _memeWhatsapp = true;
  bool _enCours = false;

  @override
  void dispose() {
    _nom.dispose();
    _telephone.dispose();
    _ville.dispose();
    super.dispose();
  }

  bool get _pretAOuvrir => _nom.text.trim().isNotEmpty;

  Future<void> _ouvrirLaBoutique() async {
    if (!_pretAOuvrir || _enCours) return;
    setState(() => _enCours = true);
    final telephone = _telephone.text.trim();
    await ref.read(boutiqueProvider.notifier).majParametres(
          ref.read(boutiqueProvider).parametres.copie(
                nomBoutique: _nom.text.trim(),
                telephone: telephone,
                whatsapp: _memeWhatsapp ? telephone : '',
                ville: _ville.text.trim(),
                devise: _devise,
                logo: _logo,
              ),
        );
    // Aucune navigation : l'application observe `estConfiguree` et bascule
    // d'elle-même sur la boutique.
  }

  Future<void> _voirUnExemple() async {
    if (_enCours) return;
    setState(() => _enCours = true);
    await ref.read(boutiqueProvider.notifier).reinstallerDemo();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parametres = ref.watch(boutiqueProvider).parametres;
    final palette = paletteParCle(parametres.palette);

    // Un aperçu vivant : le logo porte déjà le nom en cours de frappe, comme
    // il le portera en haut des reçus.
    final apercu = parametres.copie(logo: _logo, nomBoutique: _nom.text);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            Center(
              child: LogoBoutique(
                parametres: apercu,
                palette: palette,
                taille: 88,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Bienvenue',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ta boutique est vide, et c\'est normal : tu vas la remplir '
              'toi-même. Deux ou trois réponses, et tu peux vendre.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),

            TextField(
              controller: _nom,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Nom de ton business *',
                helperText: 'Il s\'imprime en haut de chaque reçu.',
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _telephone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Ton téléphone',
                helperText: 'Pour que tes clientes puissent te rappeler.',
              ),
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              value: _memeWhatsapp,
              onChanged: (v) => setState(() => _memeWhatsapp = v ?? true),
              title: const Text('C\'est aussi mon WhatsApp'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ville,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ta ville'),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _devise,
              decoration: const InputDecoration(labelText: 'Ta monnaie'),
              items: [
                for (final code in devises.keys)
                  DropdownMenuItem(value: code, child: Text(code)),
              ],
              onChanged: (v) => setState(() => _devise = v ?? _devise),
            ),
            const SizedBox(height: 24),

            Text('Ton logo', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Changeable à tout moment dans les paramètres.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 84,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final piste in pistesLogo)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _logo = piste.cle),
                        child: Container(
                          width: 78,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _logo == piste.cle
                                  ? palette.primaire
                                  : theme.dividerColor,
                              width: _logo == piste.cle ? 2 : 1,
                            ),
                          ),
                          child: LogoBoutique(
                            parametres: apercu.copie(logo: piste.cle),
                            palette: palette,
                            taille: 58,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'L\'exemple installe une boutique de démonstration, avec des '
              'articles et des ventes fictifs. Il s\'efface ensuite d\'un '
              'bouton, dans Paramètres → Repartir de zéro.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      // Les deux actions restent sous les yeux : sur un téléphone, le
      // formulaire est plus long que l'écran, et le bouton principal ne doit
      // pas se mériter au défilement.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: _pretAOuvrir && !_enCours ? _ouvrirLaBoutique : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(_enCours ? 'Un instant…' : 'Ouvrir ma boutique'),
            ),
            TextButton(
              onPressed: _enCours ? null : _voirUnExemple,
              child: const Text('Voir d\'abord un exemple rempli'),
            ),
          ],
        ),
      ),
    );
  }
}
