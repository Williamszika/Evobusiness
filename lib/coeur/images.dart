import 'dart:convert';
import 'dart:typed_data';

/// Les photos d'articles sont rangées **dans la base**, encodées en base64,
/// et non sous forme de fichiers.
///
/// Trois raisons :
///   1. la photo suit la sauvegarde — un téléphone remplacé retrouve son
///      catalogue en images, pas seulement en texte ;
///   2. le même code fonctionne sur téléphone et dans la version web, qui n'a
///      pas de système de fichiers ;
///   3. plus de photo orpheline quand la galerie fait le ménage.
///
/// En contrepartie il faut des images légères : elles sont réduites à
/// 800 pixels et compressées à la prise de vue, soit environ 60 Ko pièce.
class Photos {
  const Photos._();

  /// Largeur maximale d'une photo enregistrée.
  static const largeurMax = 800.0;

  /// Qualité de compression JPEG, de 0 à 100.
  static const qualite = 70;

  // Décoder du base64 à chaque reconstruction d'une liste coûterait cher.
  // Ce petit cache garde les dernières images décodées.
  static final _cache = <String, Uint8List>{};
  static const _tailleCache = 60;

  static Uint8List? decoder(String? base64Texte) {
    if (base64Texte == null || base64Texte.isEmpty) return null;
    final dejaLa = _cache[base64Texte];
    if (dejaLa != null) return dejaLa;
    try {
      final octets = base64Decode(base64Texte);
      if (_cache.length >= _tailleCache) {
        _cache.remove(_cache.keys.first);
      }
      _cache[base64Texte] = octets;
      return octets;
    } catch (_) {
      // Une photo illisible ne doit jamais faire tomber un écran :
      // l'article s'affiche simplement avec son initiale.
      return null;
    }
  }

  static String encoder(Uint8List octets) => base64Encode(octets);
}
