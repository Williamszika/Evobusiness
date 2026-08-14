import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../donnees/modeles.dart';
import 'argent.dart';
import 'logos.dart';
import 'theme.dart';

/// Le logo de la boutique, à la taille demandée.
class LogoBoutique extends StatelessWidget {
  const LogoBoutique({
    super.key,
    required this.parametres,
    required this.palette,
    this.taille = 40,
    this.surFondSombre = false,
  });

  final Parametres parametres;
  final Palette palette;
  final double taille;
  final bool surFondSombre;

  @override
  Widget build(BuildContext context) {
    final primaire = surFondSombre ? '#FFFFFF' : palette.primaireHex;
    final svg = logoSvg(parametres.logo, primaire: primaire, accent: palette.accentHex);
    final dessin = SvgPicture.string(svg, width: taille, height: taille);

    if (!logoPorteInitiales(parametres.logo)) return dessin;

    // Le monogramme reçoit les initiales de la boutique par-dessus.
    return SizedBox(
      width: taille,
      height: taille,
      child: Stack(
        alignment: Alignment.center,
        children: [
          dessin,
          Text(
            initialesDe(parametres.nomBoutique),
            style: TextStyle(
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
              fontSize: taille * .42,
              color: surFondSombre ? palette.primaire : Colors.white,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo + nom + slogan, pour les en-têtes.
class EnteteMarque extends StatelessWidget {
  const EnteteMarque({
    super.key,
    required this.parametres,
    required this.palette,
    this.taille = 42,
  });

  final Parametres parametres;
  final Palette palette;
  final double taille;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LogoBoutique(parametres: parametres, palette: palette, taille: taille),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                parametres.nomBoutique,
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
              if (parametres.slogan.isNotEmpty)
                Text(
                  parametres.slogan,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Petit titre en capitales, utilisé au-dessus des blocs.
class Etiquette extends StatelessWidget {
  const Etiquette(this.texte, {super.key, this.action});
  final String texte;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texte.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Carte blanche avec un titre optionnel.
class Bloc extends StatelessWidget {
  const Bloc({
    super.key,
    required this.enfant,
    this.titre,
    this.action,
    this.remplissage = const EdgeInsets.all(16),
    this.couleur,
  });

  final Widget enfant;
  final String? titre;
  final Widget? action;
  final EdgeInsets remplissage;
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: couleur,
      child: Padding(
        padding: remplissage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (titre != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(titre!, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    if (action != null) action!,
                  ],
                ),
              ),
            enfant,
          ],
        ),
      ),
    );
  }
}

/// Tuile de chiffre clé.
class Tuile extends StatelessWidget {
  const Tuile({
    super.key,
    required this.libelle,
    required this.valeur,
    this.detail,
    this.couleurValeur,
    this.fond,
    this.icone,
    this.onTap,
  });

  final String libelle;
  final String valeur;
  final String? detail;
  final Color? couleurValeur;
  final Color? fond;
  final IconData? icone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: fond,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(libelle.toUpperCase(), style: theme.textTheme.labelSmall),
                  ),
                  if (icone != null)
                    Icon(icone, size: 16, color: couleurValeur ?? theme.colorScheme.primary),
                ],
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valeur,
                  style: theme.textTheme.headlineSmall?.copyWith(color: couleurValeur),
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 3),
                Text(detail!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum Ton { neutre, ok, attention, critique, marque }

/// Pastille d'état : payé, stock bas, impayé…
class Pastille extends StatelessWidget {
  const Pastille(this.texte, {super.key, this.ton = Ton.neutre, this.icone});

  final String texte;
  final Ton ton;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final couleurs = switch (ton) {
      Ton.ok => (Etats.okFond, Etats.ok),
      Ton.attention => (Etats.attentionFond, Etats.attention),
      Ton.critique => (Etats.critiqueFond, Etats.critique),
      Ton.marque => (
          Theme.of(context).colorScheme.primary.withValues(alpha: .12),
          Theme.of(context).colorScheme.primary,
        ),
      Ton.neutre => (
          Theme.of(context).colorScheme.onSurface.withValues(alpha: .07),
          Theme.of(context).colorScheme.onSurface.withValues(alpha: .7),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: couleurs.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 12, color: couleurs.$2),
            const SizedBox(width: 4),
          ],
          Text(
            texte,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: couleurs.$2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Écran ou liste sans contenu.
class Vide extends StatelessWidget {
  const Vide({
    super.key,
    required this.titre,
    required this.texte,
    this.icone = Icons.inbox_outlined,
    this.action,
  });

  final String titre;
  final String texte;
  final IconData icone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icone, size: 30, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(titre, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(texte, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Barre de progression vers l'objectif du mois.
class BarreObjectif extends StatelessWidget {
  const BarreObjectif({super.key, required this.progression});
  final double progression;

  @override
  Widget build(BuildContext context) {
    final couleur = Theme.of(context).colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: progression,
        minHeight: 8,
        backgroundColor: couleur.withValues(alpha: .12),
        valueColor: AlwaysStoppedAnimation(couleur),
      ),
    );
  }
}

/// Vignette d'article : la photo si elle existe, sinon une initiale.
class VignetteProduit extends StatelessWidget {
  const VignetteProduit({super.key, required this.produit, this.taille = 46});

  final Produit produit;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chemin = produit.photo;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: taille,
        height: taille,
        child: chemin != null && chemin.isNotEmpty && File(chemin).existsSync()
            ? Image.file(File(chemin), fit: BoxFit.cover)
            : Container(
                color: theme.colorScheme.primary.withValues(alpha: .1),
                alignment: Alignment.center,
                child: Text(
                  produit.nom.isEmpty ? '?' : produit.nom[0].toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w700,
                    fontSize: taille * .4,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Champ de saisie d'un montant, en unités entières ou avec décimales
/// selon la devise choisie.
class ChampMontant extends StatelessWidget {
  const ChampMontant({
    super.key,
    required this.controleur,
    required this.libelle,
    required this.parametres,
    this.aide,
    this.onChange,
    this.autofocus = false,
  });

  final TextEditingController controleur;
  final String libelle;
  final Parametres parametres;
  final String? aide;
  final ValueChanged<String>? onChange;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final decimales = parametres.decimales;
    return TextFormField(
      controller: controleur,
      autofocus: autofocus,
      onChanged: onChange,
      keyboardType: TextInputType.numberWithOptions(decimal: decimales > 0),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimales > 0 ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: libelle,
        helperText: aide,
        suffixText: parametres.devise,
      ),
    );
  }
}

/// Menu déroulant simple.
class ChampChoix extends StatelessWidget {
  const ChampChoix({
    super.key,
    required this.libelle,
    required this.valeur,
    required this.options,
    required this.onChange,
    this.optionVide,
  });

  final String libelle;
  final String? valeur;
  final List<String> options;
  final ValueChanged<String?> onChange;
  final String? optionVide;

  @override
  Widget build(BuildContext context) {
    final valeurSure = (valeur != null && options.contains(valeur)) ? valeur : null;
    return DropdownButtonFormField<String>(
      initialValue: valeurSure,
      isExpanded: true,
      decoration: InputDecoration(labelText: libelle),
      items: [
        if (optionVide != null)
          DropdownMenuItem<String>(value: null, child: Text(optionVide!)),
        for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: onChange,
    );
  }
}

/// Rangée de puces à choix unique (moyen de paiement, canal, filtres…).
class PucesChoix extends StatelessWidget {
  const PucesChoix({
    super.key,
    required this.options,
    required this.selection,
    required this.onChange,
  });

  final List<String> options;
  final String selection;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Text(o),
            selected: o == selection,
            onSelected: (_) => onChange(o),
            selectedColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: o == selection ? FontWeight.w600 : FontWeight.w400,
              color: o == selection
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: .8),
            ),
            showCheckmark: false,
          ),
      ],
    );
  }
}

/// Affiche un message court en bas de l'écran.
void message(BuildContext context, String texte, {bool erreur = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(texte),
        backgroundColor: erreur ? Etats.critique : null,
        duration: const Duration(seconds: 3),
      ),
    );
}

/// Demande une confirmation avant une action irréversible.
Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String texte,
  String valider = 'Confirmer',
  bool dangereux = false,
}) async {
  final reponse = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(titre),
      content: Text(texte),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: dangereux
              ? FilledButton.styleFrom(backgroundColor: Etats.critique)
              : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(valider),
        ),
      ],
    ),
  );
  return reponse ?? false;
}

/// Sélecteur de date, pré-réglé sur aujourd'hui.
Future<String?> choisirDate(BuildContext context, String isoActuel) async {
  final actuelle = Dates.lire(isoActuel) ?? DateTime.now();
  final choix = await showDatePicker(
    context: context,
    initialDate: actuelle,
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    locale: const Locale('fr', 'FR'),
  );
  return choix == null ? null : Dates.jourIso(choix);
}
