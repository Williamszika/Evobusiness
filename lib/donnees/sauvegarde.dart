import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Sauvegardes automatiques dans le dossier de l'application.
///
/// Avec un seul téléphone, c'est ce qui remplace un serveur : à chaque
/// ouverture, l'application dépose une copie complète de la boutique et garde
/// les cinq dernières. Une fausse manœuvre, un « Repartir de zéro » de trop,
/// une restauration ratée — tout cela se rattrape sans réseau et sans compte.
///
/// Ces fichiers sont inclus dans la sauvegarde iCloud ou Google du téléphone :
/// un appareil remplacé les retrouve. Ils disparaissent en revanche si
/// l'application est désinstallée — d'où le rappel, dans l'application, de
/// sortir régulièrement une copie vers Drive, iCloud ou WhatsApp.
class Sauvegarde {
  const Sauvegarde._();

  /// Nombre de copies gardées. Au-delà, la plus ancienne est effacée.
  static const nombreConserve = 5;

  /// Délai en dessous duquel on ne réécrit pas de sauvegarde automatique.
  static const delaiEntreDeux = Duration(hours: 20);

  static const _prefixe = 'boutique-';
  static const _extension = '.json';

  static Directory dossierDans(Directory racine) =>
      Directory(p.join(racine.path, 'sauvegardes'));

  /// Écrit une sauvegarde horodatée et purge les plus anciennes.
  static Future<File> ecrire(Directory dossier, Map<String, dynamic> donnees) async {
    if (!dossier.existsSync()) dossier.createSync(recursive: true);

    final maintenant = DateTime.now();
    final horodatage = '${maintenant.year.toString().padLeft(4, '0')}'
        '${maintenant.month.toString().padLeft(2, '0')}'
        '${maintenant.day.toString().padLeft(2, '0')}-'
        '${maintenant.hour.toString().padLeft(2, '0')}'
        '${maintenant.minute.toString().padLeft(2, '0')}'
        '${maintenant.second.toString().padLeft(2, '0')}';

    // Le nom est daté à la seconde. Deux sauvegardes lancées dans la même
    // seconde ne doivent pas s'écraser l'une l'autre : on numérote.
    var fichier = File(p.join(dossier.path, '$_prefixe$horodatage$_extension'));
    for (var n = 2; fichier.existsSync() && n < 100; n++) {
      fichier = File(p.join(
        dossier.path,
        '$_prefixe$horodatage-${n.toString().padLeft(2, '0')}$_extension',
      ));
    }

    // On écrit d'abord dans un fichier temporaire : une écriture interrompue
    // ne laisse jamais une sauvegarde tronquée à la place d'une bonne.
    final provisoire = File('${fichier.path}.partiel');
    await provisoire.writeAsString(jsonEncode(donnees), flush: true);
    await provisoire.rename(fichier.path);

    await purger(dossier);
    return fichier;
  }

  /// Les sauvegardes présentes, de la plus récente à la plus ancienne.
  static Future<List<File>> lister(Directory dossier) async {
    if (!dossier.existsSync()) return const [];
    final fichiers = dossier
        .listSync()
        .whereType<File>()
        .where((f) =>
            p.basename(f.path).startsWith(_prefixe) &&
            p.basename(f.path).endsWith(_extension))
        .toList();
    fichiers.sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    return fichiers;
  }

  static Future<File?> laPlusRecente(Directory dossier) async {
    final liste = await lister(dossier);
    return liste.isEmpty ? null : liste.first;
  }

  /// Vrai si aucune sauvegarde n'a été écrite depuis [delaiEntreDeux].
  static Future<bool> faudraitSauvegarder(Directory dossier) async {
    final derniere = await laPlusRecente(dossier);
    if (derniere == null) return true;
    final age = DateTime.now().difference(derniere.lastModifiedSync());
    return age >= delaiEntreDeux;
  }

  static Future<Map<String, dynamic>> lire(File fichier) async {
    final brut = jsonDecode(await fichier.readAsString());
    if (brut is! Map<String, dynamic>) {
      throw const FormatException('Ce fichier n\'est pas une sauvegarde.');
    }
    return brut;
  }

  static Future<void> purger(Directory dossier) async {
    final fichiers = await lister(dossier);
    for (final vieux in fichiers.skip(nombreConserve)) {
      try {
        vieux.deleteSync();
      } catch (_) {
        // Un fichier qu'on n'arrive pas à effacer ne doit jamais empêcher
        // la sauvegarde en cours de réussir.
      }
    }
  }

  /// Date de la sauvegarde, lue depuis son nom de fichier.
  static DateTime? dateDe(File fichier) {
    final nom = p.basenameWithoutExtension(fichier.path);
    if (!nom.startsWith(_prefixe)) return null;
    final brut = nom.substring(_prefixe.length);
    // Un éventuel suffixe de doublon (« -02 ») suit l'horodatage.
    if (brut.length < 15) return null;
    return DateTime.tryParse(
      '${brut.substring(0, 4)}-${brut.substring(4, 6)}-${brut.substring(6, 8)}'
      'T${brut.substring(9, 11)}:${brut.substring(11, 13)}:${brut.substring(13, 15)}',
    );
  }

  /// Taille lisible : « 42 Ko ».
  static String tailleDe(File fichier) {
    final octets = fichier.lengthSync();
    if (octets < 1024) return '$octets o';
    if (octets < 1024 * 1024) return '${(octets / 1024).round()} Ko';
    return '${(octets / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
