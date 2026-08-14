import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/argent.dart';
import '../../coeur/composants.dart';
import '../../etat/boutique.dart';

/// Nombre de jours au-delà duquel l'accueil rappelle de sortir une copie.
///
/// Plus court dans la version web : le navigateur peut faire le ménage dans
/// ses données après quelques semaines sans usage, alors qu'une application
/// installée garde les siennes.
int get delaiRappelSauvegarde => kIsWeb ? 3 : 7;

/// Faut-il rappeler de mettre une sauvegarde à l'abri ?
///
/// L'application se sauvegarde toute seule dans son propre dossier, mais ce
/// dossier disparaît avec l'application. Une copie sortie vers Drive, iCloud
/// ou WhatsApp est la seule qui survive à un téléphone perdu.
bool rappelSauvegardeNecessaire(String derniereSortieLe, {int? delaiJours}) {
  if (derniereSortieLe.isEmpty) return true;
  return Dates.joursDepuis(derniereSortieLe.split('T').first) >=
      (delaiJours ?? delaiRappelSauvegarde);
}

/// Écrit la boutique dans un fichier que l'utilisatrice range où elle veut :
/// Drive, iCloud, Fichiers, ou une pièce jointe WhatsApp.
Future<void> sortirSauvegarde(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(boutiqueProvider.notifier);
  final p = ref.read(boutiqueProvider).parametres;
  try {
    final donnees = await notifier.exporter();
    final texte = const JsonEncoder.withIndent('  ').convert(donnees);
    final octets = Uint8List.fromList(utf8.encode(texte));
    final nom = 'sauvegarde-'
        '${p.nomBoutique.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "-")}-'
        '${Dates.aujourdhui()}.json';

    final chemin = await FilePicker.platform.saveFile(
      dialogTitle: 'Enregistrer la sauvegarde',
      fileName: nom,
      bytes: octets,
    );
    if (chemin != null) await notifier.marquerSortie();
    if (!context.mounted) return;
    message(
      context,
      chemin == null
          ? 'Sauvegarde annulée.'
          : 'Sauvegarde enregistrée. Garde-la hors du téléphone.',
    );
  } catch (e) {
    if (context.mounted) {
      message(context, 'Sauvegarde impossible : $e', erreur: true);
    }
  }
}
