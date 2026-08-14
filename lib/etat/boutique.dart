import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coeur/argent.dart';
import '../coeur/constantes.dart';
import '../donnees/demo.dart';
import '../donnees/depot.dart';
import '../donnees/modeles.dart';

/// Photographie complète de la boutique, gardée en mémoire.
///
/// Une boutique de mèches manipule des centaines d'articles et quelques
/// milliers de ventes : tout tient largement en mémoire, ce qui rend les
/// écrans et les rapports instantanés. SQLite reste la source de vérité et
/// reçoit chaque modification.
class EtatBoutique {
  const EtatBoutique({
    this.pret = false,
    this.parametres = const Parametres(),
    this.produits = const [],
    this.clients = const [],
    this.fournisseurs = const [],
    this.ventes = const [],
    this.depenses = const [],
    this.mouvements = const [],
  });

  final bool pret;
  final Parametres parametres;
  final List<Produit> produits;
  final List<Client> clients;
  final List<Fournisseur> fournisseurs;
  final List<Vente> ventes;
  final List<Depense> depenses;
  final List<MouvementStock> mouvements;

  EtatBoutique copie({
    bool? pret,
    Parametres? parametres,
    List<Produit>? produits,
    List<Client>? clients,
    List<Fournisseur>? fournisseurs,
    List<Vente>? ventes,
    List<Depense>? depenses,
    List<MouvementStock>? mouvements,
  }) =>
      EtatBoutique(
        pret: pret ?? this.pret,
        parametres: parametres ?? this.parametres,
        produits: produits ?? this.produits,
        clients: clients ?? this.clients,
        fournisseurs: fournisseurs ?? this.fournisseurs,
        ventes: ventes ?? this.ventes,
        depenses: depenses ?? this.depenses,
        mouvements: mouvements ?? this.mouvements,
      );

  Produit? produit(String id) {
    for (final p in produits) {
      if (p.id == id) return p;
    }
    return null;
  }

  Client? client(String? id) {
    if (id == null) return null;
    for (final c in clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  Fournisseur? fournisseur(String? id) {
    if (id == null) return null;
    for (final f in fournisseurs) {
      if (f.id == id) return f;
    }
    return null;
  }

  Vente? vente(String id) {
    for (final v in ventes) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Ventes d'une cliente, de la plus récente à la plus ancienne.
  List<Vente> ventesDe(String clientId) =>
      ventes.where((v) => v.clientId == clientId).toList();

  List<Produit> get produitsActifs => produits.where((p) => p.actif).toList();

  List<Produit> get alertesStock => produits
      .where((p) => p.actif && !p.estService && (p.enRupture || p.stockBas))
      .toList()
    ..sort((a, b) => a.stock.compareTo(b.stock));

  /// Ventes non soldées, la plus ancienne d'abord : c'est l'ordre de relance.
  List<Vente> get impayes => ventes
      .where((v) => v.compteDansLeCa && v.reste > 0)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
}

class BoutiqueNotifier extends StateNotifier<EtatBoutique> {
  BoutiqueNotifier() : super(const EtatBoutique());

  Depot? _depot;

  Depot get depot {
    final d = _depot;
    if (d == null) throw StateError('La base n\'est pas encore ouverte.');
    return d;
  }

  /// Ouvre la base, installe la démonstration au premier lancement,
  /// puis charge tout en mémoire.
  Future<void> demarrer({Depot? depotForce}) async {
    final d = depotForce ?? await Depot.ouvrir();
    _depot = d;
    if (await d.estVide) {
      await installerDemo(d);
    }
    await recharger();
  }

  Future<void> recharger() async {
    final d = depot;
    state = EtatBoutique(
      pret: true,
      parametres: await d.lireParametres(),
      produits: await d.lireProduits(),
      clients: await d.lireClients(),
      fournisseurs: await d.lireFournisseurs(),
      ventes: await d.lireVentes(),
      depenses: await d.lireDepenses(),
      mouvements: await d.lireMouvements(),
    );
  }

  // ───────────────────────────────────────────────────────────── paramètres

  Future<void> majParametres(Parametres p) async {
    await depot.ecrireParametres(p);
    state = state.copie(parametres: p);
  }

  // ─────────────────────────────────────────────────────────────── produits

  /// Première référence `ART-xxx` encore libre.
  String referenceLibre() {
    final prises = state.produits.map((p) => p.reference).toSet();
    var n = state.produits.length + 1;
    while (prises.contains('ART-${n.toString().padLeft(3, '0')}')) {
      n++;
    }
    return 'ART-${n.toString().padLeft(3, '0')}';
  }

  Future<Produit> ajouterProduit(Produit p) async {
    final stockInitial = p.stock;
    // Le stock de départ passe par un mouvement, pour apparaître dans
    // l'historique des entrées de l'article.
    final produit = p.copie(stock: 0);
    await depot.enregistrerProduit(produit);
    state = state.copie(produits: [...state.produits, produit]);
    if (stockInitial != 0) {
      await ajusterStock(produit.id, stockInitial, mvtEntree, motif: 'Stock initial');
    }
    return state.produit(produit.id) ?? produit;
  }

  Future<void> modifierProduit(Produit p) async {
    await depot.enregistrerProduit(p);
    state = state.copie(
      produits: [
        for (final x in state.produits) if (x.id == p.id) p else x,
      ],
    );
  }

  Future<void> supprimerProduit(String id) async {
    await depot.supprimerProduit(id);
    state = state.copie(
      produits: state.produits.where((p) => p.id != id).toList(),
    );
  }

  /// Applique une variation de stock et l'inscrit dans l'historique.
  /// `quantite` est positive pour une entrée, négative pour une sortie.
  Future<void> ajusterStock(
    String produitId,
    int quantite,
    String type, {
    String? motif,
    String? venteId,
  }) async {
    final produit = state.produit(produitId);
    if (produit == null) return;
    final maj = produit.copie(stock: produit.stock + quantite);
    final mouvement = MouvementStock(
      id: nouvelId('mvt'),
      date: DateTime.now().toIso8601String(),
      produitId: produitId,
      type: type,
      quantite: quantite,
      stockApres: maj.stock,
      motif: motif,
      venteId: venteId,
    );
    await depot.enregistrerProduit(maj);
    await depot.enregistrerMouvement(mouvement);
    state = state.copie(
      produits: [
        for (final x in state.produits) if (x.id == produitId) maj else x,
      ],
      mouvements: [mouvement, ...state.mouvements],
    );
  }

  // ──────────────────────────────────────────────────────────────── clientes

  Future<Client> ajouterClient(Client c) async {
    await depot.enregistrerClient(c);
    state = state.copie(clients: [...state.clients, c]..sort((a, b) => a.nom.compareTo(b.nom)));
    return c;
  }

  Future<void> modifierClient(Client c) async {
    await depot.enregistrerClient(c);
    state = state.copie(
      clients: [
        for (final x in state.clients) if (x.id == c.id) c else x,
      ],
    );
  }

  Future<void> supprimerClient(String id) async {
    await depot.supprimerClient(id);
    state = state.copie(clients: state.clients.where((c) => c.id != id).toList());
  }

  // ───────────────────────────────────────────────────────────── fournisseurs

  Future<Fournisseur> ajouterFournisseur(Fournisseur f) async {
    await depot.enregistrerFournisseur(f);
    state = state.copie(fournisseurs: [...state.fournisseurs, f]);
    return f;
  }

  Future<void> modifierFournisseur(Fournisseur f) async {
    await depot.enregistrerFournisseur(f);
    state = state.copie(
      fournisseurs: [
        for (final x in state.fournisseurs) if (x.id == f.id) f else x,
      ],
    );
  }

  Future<void> supprimerFournisseur(String id) async {
    await depot.supprimerFournisseur(id);
    state = state.copie(
      fournisseurs: state.fournisseurs.where((f) => f.id != id).toList(),
    );
  }

  // ────────────────────────────────────────────────────────────────── ventes

  /// Enregistre une vente : numéro de reçu, écriture en base, sortie de stock.
  ///
  /// Le numéro est attribué ici et le compteur avance dans la foulée : deux
  /// reçus ne peuvent jamais porter le même numéro.
  Future<Vente> enregistrerVente({
    required List<LigneVente> lignes,
    required String clientNom,
    String? clientId,
    String? clientTelephone,
    int remiseGlobale = 0,
    int fraisLivraison = 0,
    required String moyenPaiement,
    required String canal,
    required int montantPaye,
    String? note,
    String? date,
  }) async {
    final params = state.parametres;
    final id = nouvelId('vte');
    final numero = params.prochainNumero();

    final avecId = lignes.map((l) => l.copie(venteId: id)).toList();
    final provisoire = Vente(
      id: id,
      numero: numero,
      date: date ?? Dates.aujourdhui(),
      clientId: clientId,
      clientNom: clientNom.trim().isEmpty ? 'Client de passage' : clientNom.trim(),
      clientTelephone: clientTelephone,
      lignes: avecId,
      remiseGlobale: remiseGlobale,
      fraisLivraison: fraisLivraison,
      moyenPaiement: moyenPaiement,
      canal: canal,
      montantPaye: montantPaye,
      statut: statutPayee,
      note: note,
      venduPar: params.venduPar.isEmpty ? null : params.venduPar,
      creeLe: DateTime.now().toIso8601String(),
    );
    final vente = provisoire.copie(
      statut: Vente.statutPour(provisoire.total, montantPaye),
    );

    await depot.enregistrerVente(vente);
    state = state.copie(ventes: [vente, ...state.ventes]);
    await majParametres(params.copie(compteurRecu: params.compteurRecu + 1));

    for (final ligne in vente.lignes) {
      final produit = state.produit(ligne.produitId);
      if (produit == null || produit.estService) continue;
      await ajusterStock(
        ligne.produitId,
        -ligne.quantite,
        mvtVente,
        motif: 'Vente $numero',
        venteId: vente.id,
      );
    }
    return vente;
  }

  /// Encaisse un solde restant sur une vente déjà enregistrée.
  Future<void> encaisserSolde(String venteId, int montant) async {
    final vente = state.vente(venteId);
    if (vente == null || vente.estAnnulee) return;
    final paye = vente.montantPaye + montant;
    final maj = vente.copie(
      montantPaye: paye,
      statut: Vente.statutPour(vente.total, paye),
    );
    await depot.enregistrerVente(maj);
    state = state.copie(
      ventes: [
        for (final v in state.ventes) if (v.id == venteId) maj else v,
      ],
    );
  }

  /// Annule une vente : le stock revient, le numéro de reçu reste réservé.
  /// On n'efface jamais une vente, pour garder une numérotation continue.
  Future<void> annulerVente(String venteId) async {
    final vente = state.vente(venteId);
    if (vente == null || vente.estAnnulee) return;
    final maj = vente.copie(statut: statutAnnulee, montantPaye: 0);
    await depot.enregistrerVente(maj);
    state = state.copie(
      ventes: [
        for (final v in state.ventes) if (v.id == venteId) maj else v,
      ],
    );
    for (final ligne in vente.lignes) {
      final produit = state.produit(ligne.produitId);
      if (produit == null || produit.estService) continue;
      await ajusterStock(
        ligne.produitId,
        ligne.quantite,
        mvtRetour,
        motif: 'Annulation ${vente.numero}',
        venteId: vente.id,
      );
    }
  }

  Future<void> supprimerVente(String venteId) async {
    final vente = state.vente(venteId);
    if (vente == null) return;
    if (!vente.estAnnulee) {
      for (final ligne in vente.lignes) {
        final produit = state.produit(ligne.produitId);
        if (produit == null || produit.estService) continue;
        await ajusterStock(
          ligne.produitId,
          ligne.quantite,
          mvtRetour,
          motif: 'Suppression ${vente.numero}',
        );
      }
    }
    await depot.supprimerVente(venteId);
    state = state.copie(
      ventes: state.ventes.where((v) => v.id != venteId).toList(),
    );
  }

  // ──────────────────────────────────────────────────────────────── dépenses

  Future<Depense> ajouterDepense(Depense d) async {
    await depot.enregistrerDepense(d);
    state = state.copie(depenses: [d, ...state.depenses]);
    return d;
  }

  Future<void> modifierDepense(Depense d) async {
    await depot.enregistrerDepense(d);
    state = state.copie(
      depenses: [
        for (final x in state.depenses) if (x.id == d.id) d else x,
      ],
    );
  }

  Future<void> supprimerDepense(String id) async {
    await depot.supprimerDepense(id);
    state = state.copie(
      depenses: state.depenses.where((d) => d.id != id).toList(),
    );
  }

  // ───────────────────────────────────────────────── sauvegarde / restauration

  Future<Map<String, dynamic>> exporter() => depot.exporterJson();

  Future<void> importer(Map<String, dynamic> donnees) async {
    await depot.importerJson(donnees);
    await recharger();
  }

  /// Efface les données de travail. Les paramètres de marque sont conservés.
  ///
  /// Le compteur de reçus repart à 1 : plus aucun reçu n'existe, il ne peut
  /// donc pas y avoir de doublon, et la première vraie vente porte bien le
  /// numéro 0001.
  Future<void> viderDonnees() async {
    await depot.viderDonnees();
    await depot.ecrireParametres(state.parametres.copie(compteurRecu: 1));
    await recharger();
  }

  Future<void> reinstallerDemo() async {
    await depot.viderDonnees();
    await installerDemo(depot);
    await recharger();
  }
}

final boutiqueProvider =
    StateNotifierProvider<BoutiqueNotifier, EtatBoutique>((ref) {
  final notifier = BoutiqueNotifier();
  notifier.demarrer();
  return notifier;
});
