import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/argent.dart';
import '../../coeur/composants.dart';
import '../../donnees/modeles.dart';
import '../../etat/boutique.dart';

/// Création et modification d'une fiche cliente.
/// Renvoie la cliente enregistrée à l'écran appelant.
class EditionClient extends ConsumerStatefulWidget {
  const EditionClient({super.key, this.client});

  final Client? client;

  @override
  ConsumerState<EditionClient> createState() => _EditionClientState();
}

class _EditionClientState extends ConsumerState<EditionClient> {
  final _formulaire = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _telephone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  late final TextEditingController _ville;
  late final TextEditingController _adresse;
  late final TextEditingController _note;
  String? _anniversaire;

  bool get _modification => widget.client != null;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nom = TextEditingController(text: c?.nom ?? '');
    _telephone = TextEditingController(text: c?.telephone ?? '');
    _whatsapp = TextEditingController(text: c?.whatsapp ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _ville = TextEditingController(text: c?.ville ?? '');
    _adresse = TextEditingController(text: c?.adresse ?? '');
    _note = TextEditingController(text: c?.note ?? '');
    _anniversaire = c?.anniversaire;
  }

  @override
  void dispose() {
    _nom.dispose();
    _telephone.dispose();
    _whatsapp.dispose();
    _email.dispose();
    _ville.dispose();
    _adresse.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _ouNull(String texte) => texte.trim().isEmpty ? null : texte.trim();

  Future<void> _enregistrer() async {
    if (!_formulaire.currentState!.validate()) return;
    final notifier = ref.read(boutiqueProvider.notifier);

    final client = _modification
        ? widget.client!.copie(
            nom: _nom.text.trim(),
            telephone: _ouNull(_telephone.text),
            whatsapp: _ouNull(_whatsapp.text),
            email: _ouNull(_email.text),
            ville: _ouNull(_ville.text),
            adresse: _ouNull(_adresse.text),
            anniversaire: _anniversaire,
            note: _ouNull(_note.text),
          )
        : Client(
            id: nouvelId('cli'),
            nom: _nom.text.trim(),
            telephone: _ouNull(_telephone.text),
            whatsapp: _ouNull(_whatsapp.text),
            email: _ouNull(_email.text),
            ville: _ouNull(_ville.text),
            adresse: _ouNull(_adresse.text),
            anniversaire: _anniversaire,
            note: _ouNull(_note.text),
            creeLe: DateTime.now().toIso8601String(),
          );

    if (_modification) {
      await notifier.modifierClient(client);
    } else {
      await notifier.ajouterClient(client);
    }
    if (!mounted) return;
    Navigator.pop(context, client);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modification ? 'Modifier la fiche' : 'Nouvelle cliente'),
      ),
      body: Form(
        key: _formulaire,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            TextFormField(
              controller: _nom,
              autofocus: !_modification,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nom complet *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Indique au moins un nom' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telephone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                hintText: '+237 6 90 00 00 00',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _whatsapp,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp',
                helperText: 'Laisse vide si c\'est le même que le téléphone',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 20),
            const Etiquette('Où la livrer'),
            TextFormField(
              controller: _ville,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ville'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adresse,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Adresse / quartier'),
            ),
            const SizedBox(height: 20),
            const Etiquette('Ce qui fait revenir'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cake_outlined),
                title: const Text('Anniversaire'),
                subtitle: Text(
                  _anniversaire == null
                      ? 'Non renseigné'
                      : Dates.court(_anniversaire!),
                ),
                trailing: _anniversaire == null
                    ? const Icon(Icons.chevron_right)
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _anniversaire = null),
                      ),
                onTap: () async {
                  final choix = await choisirDate(
                    context,
                    _anniversaire ?? Dates.aujourdhui(),
                  );
                  if (choix != null) setState(() => _anniversaire = choix);
                },
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Préférences',
                hintText: 'Longueurs habituelles, couleurs, habitudes de paiement…',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _enregistrer,
              child: Text(_modification ? 'Enregistrer' : 'Créer la fiche'),
            ),
          ],
        ),
      ),
    );
  }
}
