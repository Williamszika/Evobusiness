import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../coeur/argent.dart';
import '../../coeur/theme.dart';
import '../../donnees/modeles.dart';
import '../../etat/comptabilite.dart';
import '../recu/document_pdf.dart' show texteImprimable;

/// Fabrique le **livre de recettes et de dépenses** en PDF : le document à
/// imprimer, à archiver, ou à remettre au comptable et à l'administration.
///
/// Il tient sur autant de pages que nécessaire, avec un en-tête et une
/// pagination sur chacune — une liasse dont il manque une page ne vaut rien.
Future<Uint8List> construireDocumentComptable(
  BilanComptable bilan,
  Parametres p,
) async {
  final palette = paletteParCle(p.palette);
  final prune = PdfColor.fromInt(palette.primaire.toARGB32());
  const gris = PdfColors.grey700;
  const grisClair = PdfColors.grey300;

  final serif = pw.Font.times();
  final serifGras = pw.Font.timesBold();
  final sans = pw.Font.helvetica();
  final sansGras = pw.Font.helveticaBold();

  pw.TextStyle st({double taille = 9, bool gras = false, bool titre = false, PdfColor? couleur}) =>
      pw.TextStyle(
        font: titre ? (gras ? serifGras : serif) : (gras ? sansGras : sans),
        fontSize: taille,
        color: couleur ?? PdfColors.black,
      );

  final doc = pw.Document(
    title: 'Livre de recettes et de dépenses — ${bilan.periode.libelle}',
    author: p.nomBoutique,
  );

  final coordonnees = [
    [p.adresse, p.ville].where((v) => v.isNotEmpty).join(', '),
    p.telephone,
    p.email,
  ].where((v) => v.isNotEmpty).join(' · ');

  final editeLe = Dates.court(Dates.aujourdhui());

  pw.Widget titreSection(String texte) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 18, bottom: 6),
        padding: const pw.EdgeInsets.only(bottom: 3),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: grisClair, width: .8)),
        ),
        child: pw.Text(texteImprimable(texte),
            style: st(taille: 11.5, gras: true, titre: true, couleur: prune)),
      );

  pw.Widget ligneTotal(String libelle, String valeur, {bool fort = false}) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        decoration: fort
            ? const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(width: 1.2)),
              )
            : null,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(texteImprimable(libelle),
                style: st(taille: fort ? 10.5 : 9.5, gras: fort)),
            pw.Text(texteImprimable(valeur),
                style: st(taille: fort ? 10.5 : 9.5, gras: true)),
          ],
        ),
      );

  pw.Widget tableau({
    required List<String> entetes,
    required List<List<String>> lignes,
    required Map<int, pw.Alignment> alignements,
    required Map<int, pw.TableColumnWidth> largeurs,
  }) =>
      pw.TableHelper.fromTextArray(
        headers: entetes.map(texteImprimable).toList(),
        data: lignes.map((l) => l.map(texteImprimable).toList()).toList(),
        border: null,
        headerStyle: st(taille: 8, gras: true, couleur: gris),
        headerDecoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: grisClair, width: .8),
            bottom: pw.BorderSide(color: grisClair, width: .8),
          ),
        ),
        cellStyle: st(taille: 8.5),
        cellHeight: 16,
        cellPadding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
        rowDecoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: .5)),
        ),
        cellAlignments: alignements,
        columnWidths: largeurs,
        headerCount: 1,
      );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginTop: 15 * PdfPageFormat.mm,
        marginBottom: 15 * PdfPageFormat.mm,
        marginLeft: 14 * PdfPageFormat.mm,
        marginRight: 14 * PdfPageFormat.mm,
      ),
      header: (contexte) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.only(bottom: 5),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: grisClair, width: .8)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(texteImprimable(p.nomBoutique),
                style: st(taille: 11, gras: true, titre: true, couleur: prune)),
            pw.Text(
              texteImprimable(
                  'Livre de recettes et de dépenses — ${bilan.periode.libelle}'),
              style: st(taille: 8, couleur: gris),
            ),
          ],
        ),
      ),
      footer: (contexte) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.only(top: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: grisClair, width: .5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(texteImprimable('Édité le $editeLe'), style: st(taille: 7.5, couleur: gris)),
            pw.Text('Page ${contexte.pageNumber} / ${contexte.pagesCount}',
                style: st(taille: 7.5, couleur: gris)),
          ],
        ),
      ),
      build: (contexte) => [
        // ── Identité et période
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(palette.fond.toARGB32()),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LIVRE DE RECETTES ET DE DÉPENSES',
                        style: st(taille: 13, gras: true, titre: true)),
                    pw.SizedBox(height: 3),
                    pw.Text(texteImprimable(bilan.periode.libelle),
                        style: st(taille: 10, gras: true)),
                    pw.Text(
                      texteImprimable(
                          'Du ${Dates.court(bilan.periode.debut)} au ${Dates.court(bilan.periode.fin)}'),
                      style: st(taille: 8.5, couleur: gris),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(texteImprimable(p.nomBoutique), style: st(taille: 10, gras: true)),
                  if (coordonnees.isNotEmpty)
                    pw.Text(texteImprimable(coordonnees), style: st(taille: 8, couleur: gris)),
                  pw.Text(texteImprimable('Devise : ${p.devise}'),
                      style: st(taille: 8, couleur: gris)),
                ],
              ),
            ],
          ),
        ),

        // ── Récapitulatif
        titreSection('Récapitulatif'),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  ligneTotal('Recettes encaissées', p.format(bilan.totalRecettes)),
                  ligneTotal('Dépenses payées', '- ${p.format(bilan.totalDepenses)}'),
                  ligneTotal(
                    bilan.resultat >= 0 ? 'RÉSULTAT (bénéfice)' : 'RÉSULTAT (perte)',
                    p.format(bilan.resultat),
                    fort: true,
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 24),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Pour information', style: st(taille: 8, gras: true, couleur: gris)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    texteImprimable('Ventes facturées sur la période : '
                        '${p.format(bilan.factureSurPeriode)} '
                        '(${bilan.nombreVentes} reçu${bilan.nombreVentes > 1 ? "s" : ""})'),
                    style: st(taille: 8, couleur: gris),
                  ),
                  pw.Text(
                    texteImprimable('Restant dû par les clientes au '
                        '${Dates.court(bilan.periode.fin)} : '
                        '${p.format(bilan.creancesEnFinDePeriode)}'),
                    style: st(taille: 8, couleur: gris),
                  ),
                  if (p.tauxTva > 0)
                    pw.Text(
                      texteImprimable(
                          'TVA appliquée : ${p.tauxTva.toStringAsFixed(0)} % incluse dans les prix'),
                      style: st(taille: 8, couleur: gris),
                    ),
                ],
              ),
            ),
          ],
        ),

        // ── Livre des recettes
        titreSection('Livre des recettes — ${bilan.recettes.length} encaissement'
            '${bilan.recettes.length > 1 ? "s" : ""}'),
        if (bilan.recettes.isEmpty)
          pw.Text('Aucun encaissement sur la période.', style: st(couleur: gris))
        else ...[
          tableau(
            entetes: const ['Date', 'Reçu', 'Client', 'Mode de paiement', 'Montant'],
            lignes: [
              for (final r in bilan.recettes)
                [
                  Dates.court(r.date),
                  r.numero,
                  r.estRemboursement ? '${r.client} (remboursement)' : r.client,
                  r.moyenPaiement,
                  p.format(r.montant),
                ],
            ],
            alignements: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
            },
            largeurs: const {
              0: pw.FlexColumnWidth(1.6),
              1: pw.FlexColumnWidth(2.2),
              2: pw.FlexColumnWidth(3.2),
              3: pw.FlexColumnWidth(2.4),
              4: pw.FlexColumnWidth(2),
            },
          ),
          pw.SizedBox(height: 4),
          ligneTotal('Total des recettes encaissées', p.format(bilan.totalRecettes), fort: true),
        ],

        // ── Registre des dépenses
        titreSection('Registre des dépenses — ${bilan.depenses.length} ligne'
            '${bilan.depenses.length > 1 ? "s" : ""}'),
        if (bilan.depenses.isEmpty)
          pw.Text('Aucune dépense sur la période.', style: st(couleur: gris))
        else ...[
          tableau(
            entetes: const ['Date', 'Libellé', 'Catégorie', 'Mode de paiement', 'Montant'],
            lignes: [
              for (final d in bilan.depenses)
                [
                  Dates.court(d.date),
                  d.libelle,
                  d.categorie,
                  d.moyenPaiement,
                  p.format(d.montant),
                ],
            ],
            alignements: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
            },
            largeurs: const {
              0: pw.FlexColumnWidth(1.6),
              1: pw.FlexColumnWidth(3.4),
              2: pw.FlexColumnWidth(2.4),
              3: pw.FlexColumnWidth(2),
              4: pw.FlexColumnWidth(2),
            },
          ),
          pw.SizedBox(height: 4),
          ligneTotal('Total des dépenses', p.format(bilan.totalDepenses), fort: true),
        ],

        // ── Ventilations
        if (bilan.depensesParCategorie.isNotEmpty) ...[
          titreSection('Ventilation des dépenses par catégorie'),
          tableau(
            entetes: const ['Catégorie', 'Montant', 'Part'],
            lignes: [
              for (final c in bilan.depensesParCategorie)
                [
                  c.categorie,
                  p.format(c.montant),
                  bilan.totalDepenses == 0
                      ? '—'
                      : '${(c.montant / bilan.totalDepenses * 100).round()} %',
                ],
            ],
            alignements: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
            },
            largeurs: const {
              0: pw.FlexColumnWidth(5),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(1.2),
            },
          ),
        ],

        if (bilan.recettesParMoyen.isNotEmpty) ...[
          titreSection('Recettes par mode de paiement'),
          tableau(
            entetes: const ['Mode de paiement', 'Montant encaissé'],
            lignes: [
              for (final m in bilan.recettesParMoyen) [m.moyen, p.format(m.montant)],
            ],
            alignements: const {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
            largeurs: const {0: pw.FlexColumnWidth(5), 1: pw.FlexColumnWidth(2.5)},
          ),
        ],

        if (bilan.moisParMois.length > 1) ...[
          titreSection('Récapitulatif mois par mois'),
          tableau(
            entetes: const ['Mois', 'Recettes', 'Dépenses', 'Résultat'],
            lignes: [
              for (final m in bilan.moisParMois)
                [
                  m.libelle,
                  p.format(m.recettes),
                  p.format(m.depenses),
                  p.format(m.recettes - m.depenses),
                ],
            ],
            alignements: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            largeurs: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
          ),
        ],

        // ── Mentions
        pw.SizedBox(height: 22),
        pw.Container(
          padding: const pw.EdgeInsets.all(9),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: grisClair, width: .8),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                texteImprimable(
                  'Les recettes sont comptabilisées à l\'encaissement : une vente '
                  'n\'apparaît ici qu\'au jour où l\'argent a été reçu, et un solde '
                  'réglé plus tard figure à sa date de règlement. Les ventes '
                  'annulées et remboursées apparaissent en montant négatif à la '
                  'date du remboursement.',
                ),
                style: st(taille: 7.5, couleur: gris),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                texteImprimable(
                  'Document établi le $editeLe à partir des enregistrements de '
                  'l\'application de gestion. Les reçus correspondants, numérotés '
                  'et sans interruption, sont conservés et peuvent être produits.',
                ),
                style: st(taille: 7.5, couleur: gris),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 26),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Date et signature', style: st(taille: 8.5, couleur: gris)),
                pw.SizedBox(height: 32),
                pw.Container(width: 170, height: .8, color: grisClair),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  return doc.save();
}

/// Nom de fichier lisible : `livre-recettes-2026-belle-couronne.pdf`.
String nomFichierComptable(BilanComptable bilan, Parametres p) {
  String propre(String v) => v
      .toLowerCase()
      .replaceAll(RegExp(r'[àâä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[îï]'), 'i')
      .replaceAll(RegExp(r'[ôö]'), 'o')
      .replaceAll(RegExp(r'[ùûü]'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'livre-recettes-${propre(bilan.periode.libelle)}-${propre(p.nomBoutique)}.pdf';
}
