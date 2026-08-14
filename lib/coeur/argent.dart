import 'package:intl/intl.dart';

import 'constantes.dart';

/// Tous les montants de l'application sont des **entiers en centimes**.
///
/// On ne stocke jamais d'argent en nombre à virgule : sur une caisse, une
/// erreur d'arrondi d'un franc de temps en temps est inacceptable. La
/// conversion vers l'affichage se fait uniquement ici.
class Argent {
  const Argent._();

  /// Convertit une saisie utilisateur (« 38000 », « 38 000,50 ») en centimes.
  /// Retourne `null` si le texte n'est pas un nombre exploitable.
  static int? depuisSaisie(String texte) {
    final propre = texte
        .replaceAll(RegExp(r'[\s ]'), '')
        .replaceAll(',', '.')
        .trim();
    if (propre.isEmpty) return null;
    final valeur = double.tryParse(propre);
    if (valeur == null) return null;
    return (valeur * 100).round();
  }

  /// Texte à pré-remplir dans un champ de saisie pour un montant donné.
  static String versSaisie(int centimes, int decimales) {
    if (decimales == 0) return (centimes ~/ 100).toString();
    return (centimes / 100).toStringAsFixed(decimales);
  }

  /// Montant formaté sans le symbole de devise.
  ///
  /// Le français sépare les milliers par une espace fine insécable (U+202F),
  /// absente des polices intégrées au PDF : elle disparaîtrait du reçu
  /// imprimé et « 38 000 » deviendrait « 38000 ». On la remplace donc par une
  /// espace ordinaire dès le formatage, pour que l'écran et le papier
  /// affichent exactement la même chose.
  static String nombre(int centimes, int decimales) {
    final format = NumberFormat.decimalPatternDigits(
      locale: 'fr_FR',
      decimalDigits: decimales,
    );
    return format
        .format(centimes / 100)
        .replaceAll('\u202F', ' ') // espace fine insécable
        .replaceAll('\u00A0', ' ');
  }

  /// Nombre de décimales à utiliser pour une devise donnée.
  static int decimalesDe(String devise) => devises[devise] ?? 2;
}

/// Dates : l'application stocke des chaînes ISO (`2026-08-14`) et n'affiche
/// que du français.
class Dates {
  const Dates._();

  static String jourIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String aujourdhui() => jourIso(DateTime.now());

  static String debutDuMois() {
    final d = DateTime.now();
    return jourIso(DateTime(d.year, d.month, 1));
  }

  static String ilYaJours(int n) => jourIso(DateTime.now().subtract(Duration(days: n)));

  static DateTime? lire(String iso) => DateTime.tryParse(iso);

  static String court(String iso) {
    final d = lire(iso);
    if (d == null) return iso;
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(d);
  }

  static String long(String iso) {
    final d = lire(iso);
    if (d == null) return iso;
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(d);
  }

  static String moisCourt(String cleMois) {
    final parties = cleMois.split('-');
    if (parties.length < 2) return cleMois;
    final d = DateTime(int.parse(parties[0]), int.parse(parties[1]));
    return DateFormat('MMM', 'fr_FR').format(d);
  }

  /// Clé de regroupement mensuel : `2026-08`.
  static String cleMois(String iso) => iso.length >= 7 ? iso.substring(0, 7) : iso;

  /// Nombre de jours écoulés depuis une date ISO.
  static int joursDepuis(String iso) {
    final d = lire(iso);
    if (d == null) return 0;
    return DateTime.now().difference(d).inDays;
  }

  /// Nombre de jours restants dans le mois en cours.
  static int joursRestantsDuMois() {
    final maintenant = DateTime.now();
    final dernier = DateTime(maintenant.year, maintenant.month + 1, 0).day;
    return dernier - maintenant.day;
  }
}

int _compteurId = 0;

/// Identifiant court, unique et lisible dans la base.
///
/// Le compteur évite toute collision entre deux appels faits dans la même
/// microseconde (une vente crée plusieurs lignes d'un coup).
String nouvelId(String prefixe) {
  final horodatage = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final suite = (_compteurId++).toRadixString(36);
  return '${prefixe}_${horodatage}_$suite';
}
