import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'sauvegarde.dart';

StockSauvegardes creerStock() => StockFichiers();

/// Copies automatiques déposées dans le dossier de l'application.
///
/// Ces fichiers partent avec la sauvegarde iCloud ou Google du téléphone :
/// un appareil remplacé les retrouve. Ils disparaissent en revanche si
/// l'application est désinstallée — d'où le rappel de sortir régulièrement
/// une copie vers Drive, iCloud ou WhatsApp.
class StockFichiers implements StockSauvegardes {
  StockFichiers({Directory? dossier}) : _dossier = dossier;

  static const _prefixe = 'boutique-';
  static const _extension = '.json';

  Directory? _dossier;

  Directory? get dossier => _dossier;

  @override
  bool get disponible => _dossier != null;

  @override
  Future<void> preparer() async {
    if (_dossier != null) return;
    try {
      final racine = await getApplicationDocumentsDirectory();
      _dossier = Directory(p.join(racine.path, 'sauvegardes'));
    } catch (_) {
      // Pas de dossier accessible : on renonce simplement aux copies
      // automatiques, sans jamais empêcher la boutique de s'ouvrir.
      _dossier = null;
    }
  }

  @override
  Future<List<CopieSauvegarde>> lister() async {
    final d = _dossier;
    if (d == null || !d.existsSync()) return const [];
    final fichiers = d
        .listSync()
        .whereType<File>()
        .where((f) =>
            p.basename(f.path).startsWith(_prefixe) &&
            p.basename(f.path).endsWith(_extension))
        .toList()
      ..sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    return fichiers
        .map((f) => CopieSauvegarde(
              identifiant: f.path,
              date: _dateDe(f.path),
              taille: f.lengthSync(),
            ))
        .toList();
  }

  @override
  Future<CopieSauvegarde?> ecrire(Map<String, dynamic> donnees) async {
    final d = _dossier;
    if (d == null) return null;
    if (!d.existsSync()) d.createSync(recursive: true);

    final maintenant = DateTime.now();
    final horodatage = '${maintenant.year.toString().padLeft(4, '0')}'
        '${maintenant.month.toString().padLeft(2, '0')}'
        '${maintenant.day.toString().padLeft(2, '0')}-'
        '${maintenant.hour.toString().padLeft(2, '0')}'
        '${maintenant.minute.toString().padLeft(2, '0')}'
        '${maintenant.second.toString().padLeft(2, '0')}';

    // Le nom est daté à la seconde. Deux sauvegardes lancées dans la même
    // seconde ne doivent pas s'écraser l'une l'autre : on numérote.
    var fichier = File(p.join(d.path, '$_prefixe$horodatage$_extension'));
    for (var n = 2; fichier.existsSync() && n < 100; n++) {
      fichier = File(p.join(
        d.path,
        '$_prefixe$horodatage-${n.toString().padLeft(2, '0')}$_extension',
      ));
    }

    // On écrit d'abord dans un fichier provisoire : une écriture interrompue
    // ne laisse jamais une sauvegarde tronquée à la place d'une bonne.
    final provisoire = File('${fichier.path}.partiel');
    await provisoire.writeAsString(jsonEncode(donnees), flush: true);
    await provisoire.rename(fichier.path);

    await _purger();
    return CopieSauvegarde(
      identifiant: fichier.path,
      date: _dateDe(fichier.path),
      taille: fichier.lengthSync(),
    );
  }

  @override
  Future<Map<String, dynamic>> lire(CopieSauvegarde copie) async {
    final brut = jsonDecode(await File(copie.identifiant).readAsString());
    if (brut is! Map<String, dynamic>) {
      throw const FormatException('Ce fichier n\'est pas une sauvegarde.');
    }
    return brut;
  }

  @override
  Future<bool> faudraitSauvegarder() async {
    final copies = await lister();
    if (copies.isEmpty) return true;
    final quand = copies.first.date;
    if (quand == null) return true;
    return DateTime.now().difference(quand) >= StockSauvegardes.delaiEntreDeux;
  }

  Future<void> _purger() async {
    final copies = await lister();
    for (final vieille in copies.skip(StockSauvegardes.nombreConserve)) {
      try {
        File(vieille.identifiant).deleteSync();
      } catch (_) {
        // Un fichier qu'on n'arrive pas à effacer ne doit jamais empêcher
        // la sauvegarde en cours de réussir.
      }
    }
  }

  /// Date lue depuis le nom du fichier.
  static DateTime? _dateDe(String chemin) {
    final nom = p.basenameWithoutExtension(chemin);
    if (!nom.startsWith(_prefixe)) return null;
    final brut = nom.substring(_prefixe.length);
    // Un éventuel suffixe de doublon (« -02 ») suit l'horodatage.
    if (brut.length < 15) return null;
    return DateTime.tryParse(
      '${brut.substring(0, 4)}-${brut.substring(4, 6)}-${brut.substring(6, 8)}'
      'T${brut.substring(9, 11)}:${brut.substring(11, 13)}:${brut.substring(13, 15)}',
    );
  }
}
