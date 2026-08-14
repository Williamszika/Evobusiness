import '../coeur/argent.dart';
import '../coeur/constantes.dart';
import 'depot.dart';
import 'modeles.dart';

/// Jeu de démonstration inséré au tout premier lancement.
///
/// Il permet de découvrir l'application avec un catalogue réaliste avant de
/// saisir son propre stock. Il se supprime d'un bouton dans Paramètres.
Future<void> installerDemo(Depot depot) async {
  final maintenant = DateTime.now().toIso8601String();
  int fcfa(int montant) => montant * 100;

  final fournisseur = Fournisseur(
    id: nouvelId('four'),
    nom: 'Guangzhou Hair Factory',
    telephone: '+86 138 0000 0000',
    email: 'contact@ghf-hair.com',
    pays: 'Chine',
    note: 'Commande minimum 10 pièces. Délai 12 jours par avion.',
    creeLe: maintenant,
  );
  await depot.enregistrerFournisseur(fournisseur);

  final catalogue = <Produit>[
    Produit(
      id: nouvelId('prod'), reference: 'ART-001', creeLe: maintenant,
      nom: 'Mèche brésilienne Body Wave', categorie: 'Mèches',
      origine: 'Brésilien', texture: 'Ondulé (Body wave)', longueur: '18"',
      couleur: 'Naturel 1B', prixAchat: fcfa(22000), prixVente: fcfa(38000),
      stock: 12, seuilAlerte: 3, fournisseurId: fournisseur.id,
    ),
    Produit(
      id: nouvelId('prod'), reference: 'ART-002', creeLe: maintenant,
      nom: 'Mèche péruvienne Deep Wave', categorie: 'Mèches',
      origine: 'Péruvien', texture: 'Deep wave', longueur: '20"',
      couleur: 'Naturel 1B', prixAchat: fcfa(26000), prixVente: fcfa(45000),
      stock: 8, seuilAlerte: 3, fournisseurId: fournisseur.id,
    ),
    Produit(
      id: nouvelId('prod'), reference: 'ART-003', creeLe: maintenant,
      nom: 'Mèche indienne Bone Straight', categorie: 'Mèches',
      origine: 'Indien', texture: 'Bone straight', longueur: '24"',
      couleur: 'Naturel 1B', prixAchat: fcfa(30000), prixVente: fcfa(52000),
      stock: 2, seuilAlerte: 3, fournisseurId: fournisseur.id,
    ),
    Produit(
      id: nouvelId('prod'), reference: 'ART-004', creeLe: maintenant,
      nom: 'Perruque Lace Frontal 13x4', categorie: 'Perruques',
      origine: 'Brésilien', texture: 'Lisse (Straight)', longueur: '22"',
      couleur: 'Naturel 1B', densite: '180%',
      prixAchat: fcfa(65000), prixVente: fcfa(110000),
      stock: 4, seuilAlerte: 2, fournisseurId: fournisseur.id,
    ),
    Produit(
      id: nouvelId('prod'), reference: 'ART-005', creeLe: maintenant,
      nom: 'Perruque Bob Curly', categorie: 'Perruques',
      origine: 'Malaisien', texture: 'Bouclé (Curly)', longueur: '12"',
      couleur: 'Brun 4', densite: '150%',
      prixAchat: fcfa(35000), prixVente: fcfa(62000),
      stock: 5, seuilAlerte: 2, fournisseurId: fournisseur.id,
    ),
    Produit(
      id: nouvelId('prod'), reference: 'ART-006', creeLe: maintenant,
      nom: 'Perruque synthétique Afro', categorie: 'Perruques',
      origine: 'Synthétique', texture: 'Afro', longueur: '10"',
      couleur: 'Noir Jet 1', densite: '150%',
      prixAchat: fcfa(9000), prixVente: fcfa(18000), stock: 10, seuilAlerte: 3,
    ),
    Produit(
      id: nouvelId('prod'), reference: 'ART-007', creeLe: maintenant,
      nom: 'Closure 4x4 HD Lace', categorie: 'Closure / Frontal',
      origine: 'Brésilien', texture: 'Ondulé (Body wave)', longueur: '16"',
      couleur: 'Naturel 1B', prixAchat: fcfa(15000), prixVente: fcfa(28000),
      stock: 6, seuilAlerte: 2, fournisseurId: fournisseur.id,
    ),
    Produit(
      id: nouvelId('prod'), reference: 'ART-008', creeLe: maintenant,
      nom: 'Frontal 13x4 Transparent Lace', categorie: 'Closure / Frontal',
      origine: 'Vietnamien', texture: 'Lisse (Straight)', longueur: '18"',
      couleur: 'Naturel 1B', prixAchat: fcfa(24000), prixVente: fcfa(42000),
      stock: 3, seuilAlerte: 2, fournisseurId: fournisseur.id,
    ),
    Produit(
      id: nouvelId('prod'), reference: 'ART-009', creeLe: maintenant,
      nom: 'Bonnet perruque en soie', categorie: 'Accessoires',
      prixAchat: fcfa(1200), prixVente: fcfa(3000), stock: 24, seuilAlerte: 6,
    ),
    Produit(
      id: nouvelId('prod'), reference: 'ART-010', creeLe: maintenant,
      nom: 'Colle waterproof Got2b', categorie: 'Accessoires',
      prixAchat: fcfa(3500), prixVente: fcfa(7000), stock: 14, seuilAlerte: 4,
    ),
    Produit(
      id: nouvelId('prod'), reference: 'ART-011', creeLe: maintenant,
      nom: 'Shampoing spécial mèches', categorie: 'Soins & Entretien',
      prixAchat: fcfa(2800), prixVente: fcfa(6500), stock: 9, seuilAlerte: 3,
    ),
    Produit(
      id: nouvelId('prod'), reference: 'ART-012', creeLe: maintenant,
      nom: 'Pose de perruque (à domicile)', categorie: 'Service (pose, coiffure)',
      prixAchat: 0, prixVente: fcfa(10000), stock: 0, seuilAlerte: 0,
    ),
  ];
  for (final produit in catalogue) {
    await depot.enregistrerProduit(produit);
  }

  final clients = <Client>[
    Client(
      id: nouvelId('cli'), nom: 'Aïcha Ndiaye', creeLe: maintenant,
      telephone: '+237 6 90 00 00 01', whatsapp: '+237 6 90 00 00 01',
      ville: 'Douala', note: 'Aime les longueurs 20" et plus.',
    ),
    Client(
      id: nouvelId('cli'), nom: 'Marina Kouassi', creeLe: maintenant,
      telephone: '+225 07 00 00 00 02', ville: 'Abidjan',
    ),
    Client(
      id: nouvelId('cli'), nom: 'Grâce Mbala', creeLe: maintenant,
      telephone: '+237 6 55 00 00 03', whatsapp: '+237 6 55 00 00 03',
      ville: 'Yaoundé', note: 'Cliente fidèle, paie souvent en deux fois.',
    ),
  ];
  for (final client in clients) {
    await depot.enregistrerClient(client);
  }

  Produit parNom(String nom) => catalogue.firstWhere((p) => p.nom == nom);

  LigneVente ligne(String venteId, String nom, int quantite) {
    final produit = parNom(nom);
    return LigneVente(
      id: nouvelId('lig'),
      venteId: venteId,
      produitId: produit.id,
      designation: produit.nom,
      detail: produit.detail,
      prixUnitaire: produit.prixVente,
      coutUnitaire: produit.prixAchat,
      quantite: quantite,
    );
  }

  final vente1 = nouvelId('vte');
  final vente2 = nouvelId('vte');
  final vente3 = nouvelId('vte');

  final ventes = <Vente>[
    Vente(
      id: vente1, numero: 'REC-${DateTime.now().year}-0001',
      date: Dates.ilYaJours(12), creeLe: maintenant,
      clientId: clients[0].id, clientNom: clients[0].nom,
      clientTelephone: clients[0].telephone,
      lignes: [
        ligne(vente1, 'Mèche brésilienne Body Wave', 2),
        ligne(vente1, 'Bonnet perruque en soie', 1),
      ],
      remiseGlobale: fcfa(3000), fraisLivraison: fcfa(2000),
      moyenPaiement: 'Mobile Money', canal: 'WhatsApp',
      montantPaye: fcfa(78000), statut: statutPayee,
    ),
    Vente(
      id: vente2, numero: 'REC-${DateTime.now().year}-0002',
      date: Dates.ilYaJours(6), creeLe: maintenant,
      clientId: clients[1].id, clientNom: clients[1].nom,
      clientTelephone: clients[1].telephone,
      lignes: [
        ligne(vente2, 'Perruque Lace Frontal 13x4', 1),
        ligne(vente2, 'Colle waterproof Got2b', 1),
      ],
      moyenPaiement: 'Espèces', canal: 'Boutique',
      montantPaye: fcfa(117000), statut: statutPayee,
    ),
    Vente(
      id: vente3, numero: 'REC-${DateTime.now().year}-0003',
      date: Dates.ilYaJours(2), creeLe: maintenant,
      clientId: clients[2].id, clientNom: clients[2].nom,
      clientTelephone: clients[2].telephone,
      lignes: [
        ligne(vente3, 'Perruque Bob Curly', 1),
        ligne(vente3, 'Pose de perruque (à domicile)', 1),
      ],
      moyenPaiement: 'Mobile Money', canal: 'Instagram',
      montantPaye: fcfa(50000), statut: statutPartielle,
      note: 'Solde promis pour la fin du mois.',
    ),
  ];
  for (final vente in ventes) {
    await depot.enregistrerVente(vente);
    // Toute vente encaissée doit porter son règlement : c'est lui qui date la
    // recette, et sans lui la comptabilité afficherait zéro.
    if (vente.montantPaye > 0) {
      await depot.enregistrerReglement(
        Reglement(
          id: nouvelId('rgl'),
          venteId: vente.id,
          date: vente.date,
          montant: vente.montantPaye,
          moyenPaiement: vente.moyenPaiement,
          motif: 'Vente ${vente.numero}',
          creeLe: maintenant,
        ),
      );
    }
  }

  final depenses = <Depense>[
    Depense(
      id: nouvelId('dep'), date: Dates.ilYaJours(20), creeLe: maintenant,
      categorie: 'Achat de marchandise',
      libelle: 'Commande 10 mèches brésiliennes',
      montant: fcfa(220000), moyenPaiement: 'Virement bancaire',
      fournisseurId: fournisseur.id,
    ),
    Depense(
      id: nouvelId('dep'), date: Dates.ilYaJours(18), creeLe: maintenant,
      categorie: 'Transport / Fret',
      libelle: 'Fret aérien Guangzhou → Douala',
      montant: fcfa(45000), moyenPaiement: 'Mobile Money',
    ),
    Depense(
      id: nouvelId('dep'), date: Dates.ilYaJours(5), creeLe: maintenant,
      categorie: 'Publicité / Marketing',
      libelle: 'Publication sponsorisée Instagram',
      montant: fcfa(15000), moyenPaiement: 'Carte bancaire',
    ),
  ];
  for (final depense in depenses) {
    await depot.enregistrerDepense(depense);
  }

  // Les trois reçus de démonstration sont déjà émis : le compteur reprend
  // à la suite.
  final parametres = await depot.lireParametres();
  await depot.ecrireParametres(
    parametres.estConfiguree
        // Une vraie boutique recharge la démonstration pour s'en servir de
        // bac à sable : sa marque à elle ne doit surtout pas être écrasée.
        ? parametres.copie(compteurRecu: 4)
        // Boutique jamais nommée : la démonstration se présente sous sa
        // propre enseigne. Sans cela elle resterait « non configurée », et
        // l'application rouvrirait l'écran de bienvenue indéfiniment.
        : parametres.copie(
            compteurRecu: 4,
            nomBoutique: 'Belle Couronne',
            slogan: 'La couronne qui vous ressemble',
            telephone: '+237 6 99 00 00 00',
            whatsapp: '+237 6 99 00 00 00',
            ville: 'Douala',
          ),
  );
}
