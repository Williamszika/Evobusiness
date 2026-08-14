import '../coeur/argent.dart';
import '../coeur/constantes.dart';

/// Tous les montants sont des entiers en **centimes** (voir `coeur/argent.dart`).

// ─────────────────────────────────────────────────────────────── paramètres

class Parametres {
  const Parametres({
    // Volontairement vides : c'est à la vendeuse d'inscrire sa marque. Tant
    // que le nom manque, l'application sait qu'elle n'a jamais été configurée
    // et propose l'accueil de première ouverture.
    this.nomBoutique = '',
    this.slogan = '',
    this.logo = 'couronne',
    this.palette = 'prune',
    this.telephone = '',
    this.whatsapp = '',
    this.email = '',
    this.adresse = '',
    this.ville = '',
    this.instagram = '',
    this.devise = 'FCFA',
    this.deviseAvant = false,
    this.prefixeRecu = 'REC',
    this.compteurRecu = 1,
    this.messageRecu = 'Merci pour votre confiance 💕',
    this.politiqueRetour =
        'Échange possible sous 48 h sur présentation du reçu, article non porté '
        'et emballage d\'origine.',
    this.tauxTva = 0,
    this.venduPar = '',
    this.ticketParDefaut = false,
    this.objectifMensuel = 50000000,
    this.derniereSortieLe = '',
  });

  final String nomBoutique;
  final String slogan;
  final String logo;
  final String palette;
  final String telephone;
  final String whatsapp;
  final String email;
  final String adresse;
  final String ville;
  final String instagram;
  final String devise;
  final bool deviseAvant;
  final String prefixeRecu;
  final int compteurRecu;
  final String messageRecu;
  final String politiqueRetour;
  final double tauxTva;
  final String venduPar;
  final bool ticketParDefaut;
  final int objectifMensuel;

  /// Date ISO de la dernière sauvegarde sortie de l'application (Drive,
  /// iCloud, WhatsApp). Vide tant qu'aucune n'a été faite.
  final String derniereSortieLe;

  int get decimales => devises[devise] ?? 2;

  /// `false` tant que la boutique n'a pas été nommée. C'est ce qui distingue
  /// une toute première ouverture d'une boutique déjà en service — le nom
  /// s'imprime sur chaque reçu, il ne peut pas rester à deviner.
  bool get estConfiguree => nomBoutique.trim().isNotEmpty;

  /// Montant prêt à afficher : « 38 000 FCFA » ou « 38,00 € ».
  String format(int centimes) {
    final nombre = Argent.nombre(centimes, decimales);
    return deviseAvant ? '$devise $nombre' : '$nombre $devise';
  }

  /// Version abrégée pour les graphiques : « 1,2 M », « 340 k ».
  String formatCourt(int centimes) {
    final unites = centimes / 100;
    if (unites.abs() >= 1000000) {
      return '${(unites / 1000000).toStringAsFixed(1).replaceAll('.', ',')} M';
    }
    if (unites.abs() >= 1000) {
      return '${(unites / 1000).round()} k';
    }
    return unites.round().toString();
  }

  /// Numéro du prochain reçu : `REC-2026-0001`.
  String prochainNumero() =>
      '$prefixeRecu-${DateTime.now().year}-${compteurRecu.toString().padLeft(4, '0')}';

  Parametres copie({
    String? nomBoutique,
    String? slogan,
    String? logo,
    String? palette,
    String? telephone,
    String? whatsapp,
    String? email,
    String? adresse,
    String? ville,
    String? instagram,
    String? devise,
    bool? deviseAvant,
    String? prefixeRecu,
    int? compteurRecu,
    String? messageRecu,
    String? politiqueRetour,
    double? tauxTva,
    String? venduPar,
    bool? ticketParDefaut,
    int? objectifMensuel,
    String? derniereSortieLe,
  }) =>
      Parametres(
        nomBoutique: nomBoutique ?? this.nomBoutique,
        slogan: slogan ?? this.slogan,
        logo: logo ?? this.logo,
        palette: palette ?? this.palette,
        telephone: telephone ?? this.telephone,
        whatsapp: whatsapp ?? this.whatsapp,
        email: email ?? this.email,
        adresse: adresse ?? this.adresse,
        ville: ville ?? this.ville,
        instagram: instagram ?? this.instagram,
        devise: devise ?? this.devise,
        deviseAvant: deviseAvant ?? this.deviseAvant,
        prefixeRecu: prefixeRecu ?? this.prefixeRecu,
        compteurRecu: compteurRecu ?? this.compteurRecu,
        messageRecu: messageRecu ?? this.messageRecu,
        politiqueRetour: politiqueRetour ?? this.politiqueRetour,
        tauxTva: tauxTva ?? this.tauxTva,
        venduPar: venduPar ?? this.venduPar,
        ticketParDefaut: ticketParDefaut ?? this.ticketParDefaut,
        objectifMensuel: objectifMensuel ?? this.objectifMensuel,
        derniereSortieLe: derniereSortieLe ?? this.derniereSortieLe,
      );

  Map<String, dynamic> versJson() => {
        'nomBoutique': nomBoutique,
        'slogan': slogan,
        'logo': logo,
        'palette': palette,
        'telephone': telephone,
        'whatsapp': whatsapp,
        'email': email,
        'adresse': adresse,
        'ville': ville,
        'instagram': instagram,
        'devise': devise,
        'deviseAvant': deviseAvant,
        'prefixeRecu': prefixeRecu,
        'compteurRecu': compteurRecu,
        'messageRecu': messageRecu,
        'politiqueRetour': politiqueRetour,
        'tauxTva': tauxTva,
        'venduPar': venduPar,
        'ticketParDefaut': ticketParDefaut,
        'objectifMensuel': objectifMensuel,
        'derniereSortieLe': derniereSortieLe,
      };

  factory Parametres.depuisJson(Map<String, dynamic> j) {
    const defaut = Parametres();
    return Parametres(
      nomBoutique: j['nomBoutique'] as String? ?? defaut.nomBoutique,
      slogan: j['slogan'] as String? ?? defaut.slogan,
      logo: j['logo'] as String? ?? defaut.logo,
      palette: j['palette'] as String? ?? defaut.palette,
      telephone: j['telephone'] as String? ?? '',
      whatsapp: j['whatsapp'] as String? ?? '',
      email: j['email'] as String? ?? '',
      adresse: j['adresse'] as String? ?? '',
      ville: j['ville'] as String? ?? '',
      instagram: j['instagram'] as String? ?? '',
      devise: j['devise'] as String? ?? defaut.devise,
      deviseAvant: j['deviseAvant'] as bool? ?? false,
      prefixeRecu: j['prefixeRecu'] as String? ?? defaut.prefixeRecu,
      compteurRecu: (j['compteurRecu'] as num?)?.toInt() ?? 1,
      messageRecu: j['messageRecu'] as String? ?? defaut.messageRecu,
      politiqueRetour: j['politiqueRetour'] as String? ?? defaut.politiqueRetour,
      tauxTva: (j['tauxTva'] as num?)?.toDouble() ?? 0,
      venduPar: j['venduPar'] as String? ?? '',
      ticketParDefaut: j['ticketParDefaut'] as bool? ?? false,
      objectifMensuel:
          (j['objectifMensuel'] as num?)?.toInt() ?? defaut.objectifMensuel,
      derniereSortieLe: j['derniereSortieLe'] as String? ?? '',
    );
  }
}

// ──────────────────────────────────────────────────────────────── produits

class Produit {
  const Produit({
    required this.id,
    required this.reference,
    required this.nom,
    required this.categorie,
    required this.prixAchat,
    required this.prixVente,
    required this.stock,
    required this.seuilAlerte,
    required this.creeLe,
    this.texture,
    this.longueur,
    this.couleur,
    this.origine,
    this.densite,
    this.fournisseurId,
    this.photo,
    this.description,
    this.actif = true,
  });

  final String id;
  final String reference;
  final String nom;
  final String categorie;
  final String? texture;
  final String? longueur;
  final String? couleur;
  final String? origine;
  final String? densite;
  final int prixAchat;
  final int prixVente;
  final int stock;
  final int seuilAlerte;
  final String? fournisseurId;

  /// Photo de l'article, encodée en base64 et stockée dans la base — voir
  /// `coeur/images.dart`. Elle suit donc la sauvegarde.
  final String? photo;

  final String? description;
  final bool actif;
  final String creeLe;

  /// Bénéfice sur une pièce.
  int get marge => prixVente - prixAchat;

  /// Marge en pourcentage du prix de vente.
  double get tauxMarge => prixVente <= 0 ? 0 : marge / prixVente * 100;

  /// Valeur du stock au prix d'achat.
  int get valeurStock => prixAchat * stock;

  bool get enRupture => stock <= 0;
  bool get stockBas => stock > 0 && stock <= seuilAlerte;

  /// Un service (une pose) ne se compte pas en stock.
  bool get estService => categorie == 'Service (pose, coiffure)';

  /// Ligne de description : « Brésilien · Body wave · 18" · Naturel 1B ».
  String get detail =>
      [origine, texture, longueur, couleur].where((v) => v != null && v.isNotEmpty).join(' · ');

  Produit copie({
    String? reference,
    String? nom,
    String? categorie,
    String? texture,
    String? longueur,
    String? couleur,
    String? origine,
    String? densite,
    int? prixAchat,
    int? prixVente,
    int? stock,
    int? seuilAlerte,
    String? fournisseurId,
    String? photo,
    String? description,
    bool? actif,
  }) =>
      Produit(
        id: id,
        creeLe: creeLe,
        reference: reference ?? this.reference,
        nom: nom ?? this.nom,
        categorie: categorie ?? this.categorie,
        texture: texture ?? this.texture,
        longueur: longueur ?? this.longueur,
        couleur: couleur ?? this.couleur,
        origine: origine ?? this.origine,
        densite: densite ?? this.densite,
        prixAchat: prixAchat ?? this.prixAchat,
        prixVente: prixVente ?? this.prixVente,
        stock: stock ?? this.stock,
        seuilAlerte: seuilAlerte ?? this.seuilAlerte,
        fournisseurId: fournisseurId ?? this.fournisseurId,
        photo: photo ?? this.photo,
        description: description ?? this.description,
        actif: actif ?? this.actif,
      );

  Map<String, Object?> versLigne() => {
        'id': id,
        'reference': reference,
        'nom': nom,
        'categorie': categorie,
        'texture': texture,
        'longueur': longueur,
        'couleur': couleur,
        'origine': origine,
        'densite': densite,
        'prix_achat': prixAchat,
        'prix_vente': prixVente,
        'stock': stock,
        'seuil_alerte': seuilAlerte,
        'fournisseur_id': fournisseurId,
        'photo': photo,
        'description': description,
        'actif': actif ? 1 : 0,
        'cree_le': creeLe,
      };

  factory Produit.depuisLigne(Map<String, Object?> l) => Produit(
        id: l['id'] as String,
        reference: l['reference'] as String? ?? '',
        nom: l['nom'] as String? ?? '',
        categorie: l['categorie'] as String? ?? 'Autre',
        texture: l['texture'] as String?,
        longueur: l['longueur'] as String?,
        couleur: l['couleur'] as String?,
        origine: l['origine'] as String?,
        densite: l['densite'] as String?,
        prixAchat: (l['prix_achat'] as num?)?.toInt() ?? 0,
        prixVente: (l['prix_vente'] as num?)?.toInt() ?? 0,
        stock: (l['stock'] as num?)?.toInt() ?? 0,
        seuilAlerte: (l['seuil_alerte'] as num?)?.toInt() ?? 0,
        fournisseurId: l['fournisseur_id'] as String?,
        photo: l['photo'] as String?,
        description: l['description'] as String?,
        actif: (l['actif'] as num?)?.toInt() != 0,
        creeLe: l['cree_le'] as String? ?? '',
      );
}

// ───────────────────────────────────────────────────────────────── clientes

class Client {
  const Client({
    required this.id,
    required this.nom,
    required this.creeLe,
    this.telephone,
    this.whatsapp,
    this.email,
    this.ville,
    this.adresse,
    this.anniversaire,
    this.note,
  });

  final String id;
  final String nom;
  final String? telephone;
  final String? whatsapp;
  final String? email;
  final String? ville;
  final String? adresse;
  final String? anniversaire;
  final String? note;
  final String creeLe;

  /// Numéro à utiliser pour WhatsApp : le champ dédié, sinon le téléphone.
  String? get numeroWhatsapp =>
      (whatsapp != null && whatsapp!.isNotEmpty) ? whatsapp : telephone;

  Client copie({
    String? nom,
    String? telephone,
    String? whatsapp,
    String? email,
    String? ville,
    String? adresse,
    String? anniversaire,
    String? note,
  }) =>
      Client(
        id: id,
        creeLe: creeLe,
        nom: nom ?? this.nom,
        telephone: telephone ?? this.telephone,
        whatsapp: whatsapp ?? this.whatsapp,
        email: email ?? this.email,
        ville: ville ?? this.ville,
        adresse: adresse ?? this.adresse,
        anniversaire: anniversaire ?? this.anniversaire,
        note: note ?? this.note,
      );

  Map<String, Object?> versLigne() => {
        'id': id,
        'nom': nom,
        'telephone': telephone,
        'whatsapp': whatsapp,
        'email': email,
        'ville': ville,
        'adresse': adresse,
        'anniversaire': anniversaire,
        'note': note,
        'cree_le': creeLe,
      };

  factory Client.depuisLigne(Map<String, Object?> l) => Client(
        id: l['id'] as String,
        nom: l['nom'] as String? ?? '',
        telephone: l['telephone'] as String?,
        whatsapp: l['whatsapp'] as String?,
        email: l['email'] as String?,
        ville: l['ville'] as String?,
        adresse: l['adresse'] as String?,
        anniversaire: l['anniversaire'] as String?,
        note: l['note'] as String?,
        creeLe: l['cree_le'] as String? ?? '',
      );
}

// ───────────────────────────────────────────────────────────── fournisseurs

class Fournisseur {
  const Fournisseur({
    required this.id,
    required this.nom,
    required this.creeLe,
    this.telephone,
    this.email,
    this.pays,
    this.note,
  });

  final String id;
  final String nom;
  final String? telephone;
  final String? email;
  final String? pays;
  final String? note;
  final String creeLe;

  Fournisseur copie({
    String? nom,
    String? telephone,
    String? email,
    String? pays,
    String? note,
  }) =>
      Fournisseur(
        id: id,
        creeLe: creeLe,
        nom: nom ?? this.nom,
        telephone: telephone ?? this.telephone,
        email: email ?? this.email,
        pays: pays ?? this.pays,
        note: note ?? this.note,
      );

  Map<String, Object?> versLigne() => {
        'id': id,
        'nom': nom,
        'telephone': telephone,
        'email': email,
        'pays': pays,
        'note': note,
        'cree_le': creeLe,
      };

  factory Fournisseur.depuisLigne(Map<String, Object?> l) => Fournisseur(
        id: l['id'] as String,
        nom: l['nom'] as String? ?? '',
        telephone: l['telephone'] as String?,
        email: l['email'] as String?,
        pays: l['pays'] as String?,
        note: l['note'] as String?,
        creeLe: l['cree_le'] as String? ?? '',
      );
}

// ─────────────────────────────────────────────────────────────────── ventes

class LigneVente {
  const LigneVente({
    required this.id,
    required this.venteId,
    required this.produitId,
    required this.designation,
    required this.prixUnitaire,
    required this.coutUnitaire,
    required this.quantite,
    this.detail,
    this.remise = 0,
  });

  final String id;
  final String venteId;
  final String produitId;
  final String designation;
  final String? detail;

  final int prixUnitaire;

  /// Prix d'achat **figé au moment de la vente**. Si le prix d'achat du
  /// produit change plus tard, la marge d'hier reste juste.
  final int coutUnitaire;

  final int quantite;
  final int remise;

  int get total {
    final brut = prixUnitaire * quantite - remise;
    return brut < 0 ? 0 : brut;
  }

  int get cout => coutUnitaire * quantite;

  LigneVente copie({int? quantite, int? remise, int? prixUnitaire, String? venteId}) =>
      LigneVente(
        id: id,
        venteId: venteId ?? this.venteId,
        produitId: produitId,
        designation: designation,
        detail: detail,
        prixUnitaire: prixUnitaire ?? this.prixUnitaire,
        coutUnitaire: coutUnitaire,
        quantite: quantite ?? this.quantite,
        remise: remise ?? this.remise,
      );

  Map<String, Object?> versLigne() => {
        'id': id,
        'vente_id': venteId,
        'produit_id': produitId,
        'designation': designation,
        'detail': detail,
        'prix_unitaire': prixUnitaire,
        'cout_unitaire': coutUnitaire,
        'quantite': quantite,
        'remise': remise,
      };

  factory LigneVente.depuisLigne(Map<String, Object?> l) => LigneVente(
        id: l['id'] as String,
        venteId: l['vente_id'] as String? ?? '',
        produitId: l['produit_id'] as String? ?? '',
        designation: l['designation'] as String? ?? '',
        detail: l['detail'] as String?,
        prixUnitaire: (l['prix_unitaire'] as num?)?.toInt() ?? 0,
        coutUnitaire: (l['cout_unitaire'] as num?)?.toInt() ?? 0,
        quantite: (l['quantite'] as num?)?.toInt() ?? 0,
        remise: (l['remise'] as num?)?.toInt() ?? 0,
      );
}

class Vente {
  const Vente({
    required this.id,
    required this.numero,
    required this.date,
    required this.clientNom,
    required this.lignes,
    required this.moyenPaiement,
    required this.canal,
    required this.montantPaye,
    required this.statut,
    required this.creeLe,
    this.clientId,
    this.clientTelephone,
    this.remiseGlobale = 0,
    this.fraisLivraison = 0,
    this.note,
    this.venduPar,
  });

  final String id;
  final String numero;
  final String date;
  final String? clientId;
  final String clientNom;
  final String? clientTelephone;
  final List<LigneVente> lignes;
  final int remiseGlobale;
  final int fraisLivraison;
  final String moyenPaiement;
  final String canal;
  final int montantPaye;
  final String statut;
  final String? note;
  final String? venduPar;
  final String creeLe;

  int get sousTotal => lignes.fold(0, (s, l) => s + l.total);

  int get total {
    final brut = sousTotal - remiseGlobale + fraisLivraison;
    return brut < 0 ? 0 : brut;
  }

  int get coutTotal => lignes.fold(0, (s, l) => s + l.cout);

  /// Bénéfice brut : la livraison n'est pas un gain, elle rembourse un frais.
  int get marge => total - fraisLivraison - coutTotal;

  int get reste {
    final r = total - montantPaye;
    return r < 0 ? 0 : r;
  }

  int get nombreArticles => lignes.fold(0, (s, l) => s + l.quantite);

  bool get estAnnulee => statut == statutAnnulee;
  bool get estSoldee => statut == statutPayee;

  /// Une vente annulée ne compte ni dans le chiffre d'affaires ni dans le stock.
  bool get compteDansLeCa => !estAnnulee;

  static String statutPour(int total, int paye) {
    if (paye >= total) return statutPayee;
    if (paye > 0) return statutPartielle;
    return statutImpayee;
  }

  Vente copie({
    String? clientId,
    String? clientNom,
    String? clientTelephone,
    List<LigneVente>? lignes,
    int? remiseGlobale,
    int? fraisLivraison,
    String? moyenPaiement,
    String? canal,
    int? montantPaye,
    String? statut,
    String? note,
    String? venduPar,
    String? date,
  }) =>
      Vente(
        id: id,
        numero: numero,
        creeLe: creeLe,
        date: date ?? this.date,
        clientId: clientId ?? this.clientId,
        clientNom: clientNom ?? this.clientNom,
        clientTelephone: clientTelephone ?? this.clientTelephone,
        lignes: lignes ?? this.lignes,
        remiseGlobale: remiseGlobale ?? this.remiseGlobale,
        fraisLivraison: fraisLivraison ?? this.fraisLivraison,
        moyenPaiement: moyenPaiement ?? this.moyenPaiement,
        canal: canal ?? this.canal,
        montantPaye: montantPaye ?? this.montantPaye,
        statut: statut ?? this.statut,
        note: note ?? this.note,
        venduPar: venduPar ?? this.venduPar,
      );

  Map<String, Object?> versLigne() => {
        'id': id,
        'numero': numero,
        'date': date,
        'client_id': clientId,
        'client_nom': clientNom,
        'client_telephone': clientTelephone,
        'remise_globale': remiseGlobale,
        'frais_livraison': fraisLivraison,
        'moyen_paiement': moyenPaiement,
        'canal': canal,
        'montant_paye': montantPaye,
        'statut': statut,
        'note': note,
        'vendu_par': venduPar,
        'cree_le': creeLe,
      };

  factory Vente.depuisLigne(Map<String, Object?> l, List<LigneVente> lignes) => Vente(
        id: l['id'] as String,
        numero: l['numero'] as String? ?? '',
        date: l['date'] as String? ?? '',
        clientId: l['client_id'] as String?,
        clientNom: l['client_nom'] as String? ?? '',
        clientTelephone: l['client_telephone'] as String?,
        lignes: lignes,
        remiseGlobale: (l['remise_globale'] as num?)?.toInt() ?? 0,
        fraisLivraison: (l['frais_livraison'] as num?)?.toInt() ?? 0,
        moyenPaiement: l['moyen_paiement'] as String? ?? 'Espèces',
        canal: l['canal'] as String? ?? 'Boutique',
        montantPaye: (l['montant_paye'] as num?)?.toInt() ?? 0,
        statut: l['statut'] as String? ?? statutPayee,
        note: l['note'] as String?,
        venduPar: l['vendu_par'] as String?,
        creeLe: l['cree_le'] as String? ?? '',
      );
}

// ───────────────────────────────────────────────────────────── règlements

/// Un encaissement rattaché à une vente.
///
/// Sans cette table, l'application saurait *combien* une cliente a payé, mais
/// pas *quand*. Or un document fiscal se tient à l'encaissement : un acompte
/// versé en janvier et le solde en mars appartiennent à deux exercices
/// différents. C'est ce registre qui permet de dater chaque franc reçu.
///
/// Un remboursement est un règlement de montant négatif : on n'efface jamais
/// un encaissement passé, on l'annule par une écriture datée du jour.
class Reglement {
  const Reglement({
    required this.id,
    required this.venteId,
    required this.date,
    required this.montant,
    required this.moyenPaiement,
    required this.creeLe,
    this.motif,
  });

  final String id;
  final String venteId;
  final String date;
  final int montant;
  final String moyenPaiement;
  final String? motif;
  final String creeLe;

  bool get estRemboursement => montant < 0;

  Map<String, Object?> versLigne() => {
        'id': id,
        'vente_id': venteId,
        'date': date,
        'montant': montant,
        'moyen_paiement': moyenPaiement,
        'motif': motif,
        'cree_le': creeLe,
      };

  factory Reglement.depuisLigne(Map<String, Object?> l) => Reglement(
        id: l['id'] as String,
        venteId: l['vente_id'] as String? ?? '',
        date: l['date'] as String? ?? '',
        montant: (l['montant'] as num?)?.toInt() ?? 0,
        moyenPaiement: l['moyen_paiement'] as String? ?? 'Espèces',
        motif: l['motif'] as String?,
        creeLe: l['cree_le'] as String? ?? '',
      );
}

// ────────────────────────────────────────────────────────────────── dépenses

class Depense {
  const Depense({
    required this.id,
    required this.date,
    required this.categorie,
    required this.libelle,
    required this.montant,
    required this.moyenPaiement,
    required this.creeLe,
    this.fournisseurId,
    this.note,
  });

  final String id;
  final String date;
  final String categorie;
  final String libelle;
  final int montant;
  final String moyenPaiement;
  final String? fournisseurId;
  final String? note;
  final String creeLe;

  Depense copie({
    String? date,
    String? categorie,
    String? libelle,
    int? montant,
    String? moyenPaiement,
    String? fournisseurId,
    String? note,
  }) =>
      Depense(
        id: id,
        creeLe: creeLe,
        date: date ?? this.date,
        categorie: categorie ?? this.categorie,
        libelle: libelle ?? this.libelle,
        montant: montant ?? this.montant,
        moyenPaiement: moyenPaiement ?? this.moyenPaiement,
        fournisseurId: fournisseurId ?? this.fournisseurId,
        note: note ?? this.note,
      );

  Map<String, Object?> versLigne() => {
        'id': id,
        'date': date,
        'categorie': categorie,
        'libelle': libelle,
        'montant': montant,
        'moyen_paiement': moyenPaiement,
        'fournisseur_id': fournisseurId,
        'note': note,
        'cree_le': creeLe,
      };

  factory Depense.depuisLigne(Map<String, Object?> l) => Depense(
        id: l['id'] as String,
        date: l['date'] as String? ?? '',
        categorie: l['categorie'] as String? ?? 'Autre',
        libelle: l['libelle'] as String? ?? '',
        montant: (l['montant'] as num?)?.toInt() ?? 0,
        moyenPaiement: l['moyen_paiement'] as String? ?? 'Espèces',
        fournisseurId: l['fournisseur_id'] as String?,
        note: l['note'] as String?,
        creeLe: l['cree_le'] as String? ?? '',
      );
}

// ───────────────────────────────────────────────────────── mouvements stock

class MouvementStock {
  const MouvementStock({
    required this.id,
    required this.date,
    required this.produitId,
    required this.type,
    required this.quantite,
    required this.stockApres,
    this.motif,
    this.venteId,
  });

  final String id;
  final String date;
  final String produitId;
  final String type;

  /// Positif pour une entrée, négatif pour une sortie.
  final int quantite;
  final int stockApres;
  final String? motif;
  final String? venteId;

  Map<String, Object?> versLigne() => {
        'id': id,
        'date': date,
        'produit_id': produitId,
        'type': type,
        'quantite': quantite,
        'stock_apres': stockApres,
        'motif': motif,
        'vente_id': venteId,
      };

  factory MouvementStock.depuisLigne(Map<String, Object?> l) => MouvementStock(
        id: l['id'] as String,
        date: l['date'] as String? ?? '',
        produitId: l['produit_id'] as String? ?? '',
        type: l['type'] as String? ?? mvtAjustement,
        quantite: (l['quantite'] as num?)?.toInt() ?? 0,
        stockApres: (l['stock_apres'] as num?)?.toInt() ?? 0,
        motif: l['motif'] as String?,
        venteId: l['vente_id'] as String?,
      );
}
