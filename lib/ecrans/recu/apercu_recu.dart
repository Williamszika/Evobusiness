import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../coeur/argent.dart';
import '../../coeur/composants.dart';
import '../../coeur/theme.dart';
import '../../donnees/modeles.dart';
import '../../etat/boutique.dart';
import 'document_pdf.dart';

/// Aperçu du reçu, avec ses trois sorties : imprimante, PDF, WhatsApp.
class ApercuRecu extends ConsumerStatefulWidget {
  const ApercuRecu({super.key, required this.venteId, this.nouvelle = false});

  final String venteId;

  /// `true` juste après l'enregistrement d'une vente : on affiche la
  /// confirmation et un bouton « Terminer ».
  final bool nouvelle;

  @override
  ConsumerState<ApercuRecu> createState() => _ApercuRecuState();
}

class _ApercuRecuState extends ConsumerState<ApercuRecu> {
  late bool _ticket;
  bool _initialise = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialise) {
      _ticket = ref.read(boutiqueProvider).parametres.ticketParDefaut;
      _initialise = true;
    }
  }

  Future<void> _partagerPdf(Vente vente, Parametres p) async {
    final octets = await construireRecu(vente, p, ticket: _ticket);
    await Printing.sharePdf(bytes: octets, filename: '${vente.numero}.pdf');
  }

  Future<void> _messageWhatsApp(Vente vente, Parametres p) async {
    final numero = (vente.clientTelephone?.isNotEmpty ?? false)
        ? vente.clientTelephone!
        : p.whatsapp;
    final chiffres = numero.replaceAll(RegExp(r'[^0-9]'), '');
    final texte = Uri.encodeComponent(texteRecuWhatsApp(vente, p));
    final lien = Uri.parse(
      chiffres.isEmpty
          ? 'https://wa.me/?text=$texte'
          : 'https://wa.me/$chiffres?text=$texte',
    );
    final ouvert = await launchUrl(lien, mode: LaunchMode.externalApplication);
    if (!ouvert && mounted) {
      message(context, 'WhatsApp n\'a pas pu être ouvert.', erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(boutiqueProvider);
    final vente = etat.vente(widget.venteId);
    final p = etat.parametres;
    final theme = Theme.of(context);

    if (vente == null) {
      return const Scaffold(
        body: Vide(
          titre: 'Reçu introuvable',
          texte: 'Cette vente n\'existe plus.',
          icone: Icons.receipt_long_outlined,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.nouvelle ? 'Reçu prêt' : 'Reçu ${vente.numero}'),
            Text(
              widget.nouvelle ? vente.numero : Dates.court(vente.date),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (widget.nouvelle)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: Pastille('Enregistrée', ton: Ton.ok, icone: Icons.check),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('A5 / A4'), icon: Icon(Icons.description_outlined, size: 17)),
                ButtonSegment(value: true, label: Text('Ticket 80 mm'), icon: Icon(Icons.receipt_outlined, size: 17)),
              ],
              selected: {_ticket},
              onSelectionChanged: (s) => setState(() => _ticket = s.first),
              showSelectedIcon: false,
            ),
          ),
          Expanded(
            child: PdfPreview(
              // Le PDF est reconstruit à chaque changement de format.
              key: ValueKey('${vente.id}-$_ticket-${vente.statut}'),
              build: (_) => construireRecu(vente, p, ticket: _ticket),
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: false,
              allowSharing: false,
              useActions: false,
              maxPageWidth: 520,
              pdfFileName: '${vente.numero}.pdf',
              loadingWidget: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _partagerPdf(vente, p),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 19),
                      label: const Text('Envoyer le PDF'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _messageWhatsApp(vente, p),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Etats.ok,
                        side: const BorderSide(color: Etats.ok),
                      ),
                      icon: const Icon(Icons.chat_outlined, size: 19),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () async {
                  final octets = await construireRecu(vente, p, ticket: _ticket);
                  await Printing.layoutPdf(
                    onLayout: (_) async => octets,
                    name: vente.numero,
                  );
                },
                icon: const Icon(Icons.print_outlined),
                label: const Text('Imprimer le reçu'),
              ),
              if (widget.nouvelle) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Terminer'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
