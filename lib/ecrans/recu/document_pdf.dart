import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../coeur/argent.dart';
import '../../coeur/logos.dart';
import '../../coeur/theme.dart';
import '../../donnees/modeles.dart';

/// Fabrique du reçu en PDF, dans les deux formats prévus :
/// A5 pour une imprimante de bureau, rouleau 80 mm pour une thermique.
///
/// Le même document sert à l'aperçu, à l'impression, à l'enregistrement PDF
/// et à l'envoi WhatsApp : il n'existe qu'une seule version du reçu.
Future<Uint8List> construireRecu(
  Vente vente,
  Parametres p, {
  required bool ticket,
}) async {
  final palette = paletteParCle(p.palette);
  final prune = PdfColor.fromInt(_argb(palette.primaire));
  const gris = PdfColors.grey700;

  final doc = pw.Document(
    title: 'Reçu ${vente.numero}',
    author: p.nomBoutique,
  );

  final serif = pw.Font.times();
  final serifGras = pw.Font.timesBold();
  final sans = pw.Font.helvetica();
  final sansGras = pw.Font.helveticaBold();

  final format = ticket
      ? const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
          marginAll: 5 * PdfPageFormat.mm)
      : PdfPageFormat.a5.copyWith(
          marginTop: 12 * PdfPageFormat.mm,
          marginBottom: 12 * PdfPageFormat.mm,
          marginLeft: 12 * PdfPageFormat.mm,
          marginRight: 12 * PdfPageFormat.mm,
        );

  final base = ticket ? 7.5 : 9.0;

  pw.TextStyle st({
    double? taille,
    bool gras = false,
    bool titre = false,
    PdfColor? couleur,
  }) =>
      pw.TextStyle(
        font: titre ? (gras ? serifGras : serif) : (gras ? sansGras : sans),
        fontSize: taille ?? base,
        color: couleur ?? PdfColors.black,
      );

  final logo = pw.SvgImage(
    svg: logoSvg(p.logo, primaire: palette.primaireHex, accent: palette.accentHex),
    width: ticket ? 34 : 44,
    height: ticket ? 34 : 44,
  );

  final coordonnees = [
    [p.adresse, p.ville].where((v) => v.isNotEmpty).join(', '),
    [p.telephone, if (p.whatsapp != p.telephone) p.whatsapp]
        .where((v) => v.isNotEmpty)
        .join(' · '),
    p.email,
    p.instagram,
  ].where((v) => v.isNotEmpty).toList();

  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (contexte) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ── En-tête
          if (ticket)
            pw.Column(
              children: [
                logo,
                pw.SizedBox(height: 4),
                pw.Text(texteImprimable(p.nomBoutique), style: st(taille: 12, gras: true, titre: true, couleur: prune)),
                if (p.slogan.isNotEmpty)
                  pw.Text(texteImprimable(p.slogan), style: st(taille: 6.5, couleur: gris)),
                for (final ligne in coordonnees)
                  pw.Text(texteImprimable(ligne), style: st(taille: 6.5, couleur: gris)),
              ],
            )
          else
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                logo,
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(texteImprimable(p.nomBoutique),
                          style: st(taille: 17, gras: true, titre: true, couleur: prune)),
                      if (p.slogan.isNotEmpty)
                        pw.Text(texteImprimable(p.slogan),
                            style: st(taille: 8, couleur: gris)),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    for (final ligne in coordonnees)
                      pw.Text(texteImprimable(ligne), style: st(taille: 7.5, couleur: gris)),
                  ],
                ),
              ],
            ),
          pw.SizedBox(height: 8),
          pw.Divider(height: 1, thickness: .8, color: PdfColors.grey400),
          pw.SizedBox(height: 8),

          // ── Numéro et cliente
          if (ticket)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('REÇU ${vente.numero}', style: st(taille: 9.5, gras: true, titre: true)),
                pw.Text(
                  '${Dates.court(vente.date)} · ${texteImprimable(vente.clientNom)}',
                  style: st(taille: 7, couleur: gris),
                ),
              ],
            )
          else
            pw.Container(
              padding: const pw.EdgeInsets.all(9),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(_argb(palette.fond)),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('REÇU N° ${vente.numero}',
                            style: st(taille: 12, gras: true, titre: true)),
                        pw.Text('Date : ${Dates.court(vente.date)}',
                            style: st(taille: 8, couleur: gris)),
                        if (vente.venduPar != null && vente.venduPar!.isNotEmpty)
                          pw.Text('Vendu par : ${texteImprimable(vente.venduPar!)}',
                              style: st(taille: 8, couleur: gris)),
                        pw.Text('Canal : ${texteImprimable(vente.canal)}',
                            style: st(taille: 8, couleur: gris)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Client', style: st(taille: 8, gras: true)),
                      pw.Text(texteImprimable(vente.clientNom), style: st(taille: 9)),
                      if (vente.clientTelephone != null && vente.clientTelephone!.isNotEmpty)
                        pw.Text(texteImprimable(vente.clientTelephone!),
                            style: st(taille: 8, couleur: gris)),
                    ],
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 10),

          // ── Articles
          pw.Table(
            columnWidths: ticket
                ? {0: const pw.FlexColumnWidth(5), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(2.4)}
                : {
                    0: const pw.FlexColumnWidth(5),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2.2),
                  },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey400, width: .8),
                    bottom: pw.BorderSide(color: PdfColors.grey400, width: .8),
                  ),
                ),
                children: [
                  _cellule('Article', st(taille: base - 1.2, gras: true, couleur: gris)),
                  _cellule('Qté', st(taille: base - 1.2, gras: true, couleur: gris),
                      alignement: pw.Alignment.center),
                  if (!ticket)
                    _cellule('P.U.', st(taille: base - 1.2, gras: true, couleur: gris),
                        alignement: pw.Alignment.centerRight),
                  _cellule('Total', st(taille: base - 1.2, gras: true, couleur: gris),
                      alignement: pw.Alignment.centerRight),
                ],
              ),
              for (final ligne in vente.lignes)
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300, width: .5),
                    ),
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3.5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(texteImprimable(ligne.designation), style: st(gras: true)),
                          if (ligne.detail != null && ligne.detail!.isNotEmpty)
                            pw.Text(texteImprimable(ligne.detail!),
                                style: st(taille: base - 1.5, couleur: gris)),
                          if (ticket)
                            pw.Text('${p.format(ligne.prixUnitaire)} / unité',
                                style: st(taille: base - 1.5, couleur: gris)),
                          if (ligne.remise > 0)
                            pw.Text('Remise -${p.format(ligne.remise)}',
                                style: st(taille: base - 1.5, couleur: prune)),
                        ],
                      ),
                    ),
                    _cellule('${ligne.quantite}', st(), alignement: pw.Alignment.center),
                    if (!ticket)
                      _cellule(p.format(ligne.prixUnitaire), st(),
                          alignement: pw.Alignment.centerRight),
                    _cellule(p.format(ligne.total), st(gras: true),
                        alignement: pw.Alignment.centerRight),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 8),

          // ── Totaux
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: ticket ? double.infinity : 210,
              child: pw.Column(
                children: [
                  _totalLigne('Sous-total', p.format(vente.sousTotal), st(couleur: gris), st()),
                  if (vente.remiseGlobale > 0)
                    _totalLigne('Remise', '-${p.format(vente.remiseGlobale)}',
                        st(couleur: gris), st()),
                  if (vente.fraisLivraison > 0)
                    _totalLigne('Livraison', p.format(vente.fraisLivraison),
                        st(couleur: gris), st()),
                  if (p.tauxTva > 0)
                    _totalLigne(
                      'Dont TVA (${p.tauxTva.toStringAsFixed(0)} %)',
                      p.format((vente.total * p.tauxTva / (100 + p.tauxTva)).round()),
                      st(couleur: gris),
                      st(),
                    ),
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 4),
                    padding: const pw.EdgeInsets.symmetric(vertical: 5),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(width: 1.4),
                        bottom: pw.BorderSide(width: 1.4),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTAL À PAYER',
                            style: st(taille: ticket ? 9 : 11, gras: true, titre: true)),
                        pw.Text(p.format(vente.total),
                            style: st(taille: ticket ? 9 : 12, gras: true, titre: true)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  _totalLigne('Payé - ${texteImprimable(vente.moyenPaiement)}',
                      p.format(vente.montantPaye), st(couleur: gris), st()),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: vente.reste > 0
                          ? PdfColor.fromInt(_argb(Etats.attentionFond))
                          : PdfColor.fromInt(_argb(Etats.okFond)),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          vente.reste > 0 ? 'RESTE À PAYER' : 'SOLDÉ - MERCI !',
                          style: st(
                            gras: true,
                            couleur: PdfColor.fromInt(
                              _argb(vente.reste > 0 ? Etats.attention : Etats.ok),
                            ),
                          ),
                        ),
                        if (vente.reste > 0)
                          pw.Text(
                            p.format(vente.reste),
                            style: st(
                              gras: true,
                              couleur: PdfColor.fromInt(_argb(Etats.attention)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (vente.note != null && vente.note!.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Note : ${texteImprimable(vente.note!)}', style: st(taille: base - 1, couleur: gris)),
          ],

          if (vente.estAnnulee) ...[
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text('VENTE ANNULÉE',
                  style: st(taille: 13, gras: true, couleur: PdfColors.red800)),
            ),
          ],

          // ── Pied
          pw.SizedBox(height: 12),
          pw.Divider(height: 1, thickness: .8, color: PdfColors.grey400),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Column(
              children: [
                if (p.messageRecu.isNotEmpty)
                  pw.Text(texteImprimable(p.messageRecu),
                      style: st(taille: ticket ? 8 : 10.5, gras: true, titre: true, couleur: prune),
                      textAlign: pw.TextAlign.center),
                if (p.politiqueRetour.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(texteImprimable(p.politiqueRetour),
                      style: st(taille: ticket ? 6 : 7, couleur: gris),
                      textAlign: pw.TextAlign.center),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}

pw.Widget _cellule(String texte, pw.TextStyle style,
    {pw.Alignment alignement = pw.Alignment.centerLeft}) {
  return pw.Container(
    alignment: alignement,
    padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 2),
    child: pw.Text(texte, style: style),
  );
}

pw.Widget _totalLigne(
  String libelle,
  String valeur,
  pw.TextStyle styleLibelle,
  pw.TextStyle styleValeur,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(libelle, style: styleLibelle),
        pw.Text(valeur, style: styleValeur),
      ],
    ),
  );
}

/// Prépare un texte pour l'impression.
///
/// Les polices intégrées au PDF couvrent l'alphabet latin et les accents
/// français, mais rien au-delà : un émoji ou un tiret cadratin laissé tel quel
/// disparaîtrait silencieusement du reçu. On convertit donc ce qui a un
/// équivalent (apostrophes, tirets, points de suspension, signe moins) et on
/// retire le reste. Les émojis restent visibles dans le message WhatsApp,
/// qui n'a pas cette limite.
String texteImprimable(String texte) {
  final tampon = StringBuffer();
  for (final unite in texte.runes) {
    if (unite <= 0xFF || unite == 0x2019 || unite == 0x2018) {
      tampon.writeCharCode(unite == 0x2019 || unite == 0x2018 ? 0x27 : unite);
    } else if (unite == 0x2013 || unite == 0x2014 || unite == 0x2212) {
      tampon.write('-');
    } else if (unite == 0x2022) {
      tampon.write('*');
    } else if (unite == 0x2026) {
      tampon.write('...');
    }
  }
  return tampon.toString().replaceAll(RegExp(r'\s+$'), '');
}

int _argb(Color couleur) => couleur.toARGB32();

/// Message prêt à envoyer sur WhatsApp, avec le détail de la vente.
String texteRecuWhatsApp(Vente vente, Parametres p) {
  final lignes = vente.lignes
      .map((l) => '• ${l.designation}'
          '${l.detail != null && l.detail!.isNotEmpty ? " (${l.detail})" : ""} — '
          '${l.quantite} × ${p.format(l.prixUnitaire)} = ${p.format(l.total)}')
      .join('\n');

  return [
    '*${p.nomBoutique}* — Reçu ${vente.numero}',
    'Date : ${Dates.court(vente.date)}',
    'Client : ${vente.clientNom}',
    '',
    lignes,
    '',
    if (vente.remiseGlobale > 0) 'Remise : −${p.format(vente.remiseGlobale)}',
    if (vente.fraisLivraison > 0) 'Livraison : ${p.format(vente.fraisLivraison)}',
    '*TOTAL : ${p.format(vente.total)}*',
    'Payé : ${p.format(vente.montantPaye)} (${vente.moyenPaiement})',
    if (vente.reste > 0) '*Reste à payer : ${p.format(vente.reste)}*',
    '',
    p.messageRecu,
  ].where((l) => l.isNotEmpty || l == '').join('\n');
}
