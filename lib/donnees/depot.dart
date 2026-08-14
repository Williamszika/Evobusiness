import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'modeles.dart';

/// Accès à la base locale SQLite.
///
/// Tout est écrit à la main, sans génération de code : `flutter pub get`
/// suffit pour compiler le projet.
class Depot {
  Depot._(this._db);

  final Database _db;

  static const _versionSchema = 2;
  static const nomFichier = 'boutique.db';

  static Future<Depot> ouvrir({String? cheminForce}) async {
    final chemin = cheminForce ?? p.join(await getDatabasesPath(), nomFichier);
    final base = await openDatabase(
      chemin,
      version: _versionSchema,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        for (final requete in _schema) {
          await db.execute(requete);
        }
      },
      onUpgrade: (db, ancienne, nouvelle) async {
        // v2 : registre des règlements, pour dater chaque encaissement.
        if (ancienne < 2) {
          for (final requete in _schemaReglements) {
            await db.execute(requete);
          }
          // Les ventes déjà enregistrées reçoivent un règlement daté du jour
          // de la vente : c'est la meilleure information disponible.
          await db.execute('''
            INSERT INTO reglements (id, vente_id, date, montant, moyen_paiement, motif, cree_le)
            SELECT 'rgl_' || id, id, date, montant_paye, moyen_paiement,
                   'Reprise de l''historique', cree_le
            FROM ventes WHERE montant_paye > 0 AND statut != 'Annulée'
          ''');
        }
      },
    );
    return Depot._(base);
  }

  Future<void> fermer() => _db.close();

  static const _schema = <String>[
    '''
    CREATE TABLE parametres (
      id INTEGER PRIMARY KEY,
      json TEXT NOT NULL
    )''',
    '''
    CREATE TABLE fournisseurs (
      id TEXT PRIMARY KEY, nom TEXT NOT NULL, telephone TEXT, email TEXT,
      pays TEXT, note TEXT, cree_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE produits (
      id TEXT PRIMARY KEY, reference TEXT NOT NULL, nom TEXT NOT NULL,
      categorie TEXT NOT NULL, texture TEXT, longueur TEXT, couleur TEXT,
      origine TEXT, densite TEXT,
      prix_achat INTEGER NOT NULL DEFAULT 0, prix_vente INTEGER NOT NULL DEFAULT 0,
      stock INTEGER NOT NULL DEFAULT 0, seuil_alerte INTEGER NOT NULL DEFAULT 0,
      fournisseur_id TEXT, photo TEXT, description TEXT,
      actif INTEGER NOT NULL DEFAULT 1, cree_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE clients (
      id TEXT PRIMARY KEY, nom TEXT NOT NULL, telephone TEXT, whatsapp TEXT,
      email TEXT, ville TEXT, adresse TEXT, anniversaire TEXT, note TEXT,
      cree_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE ventes (
      id TEXT PRIMARY KEY, numero TEXT NOT NULL UNIQUE, date TEXT NOT NULL,
      client_id TEXT, client_nom TEXT NOT NULL, client_telephone TEXT,
      remise_globale INTEGER NOT NULL DEFAULT 0,
      frais_livraison INTEGER NOT NULL DEFAULT 0,
      moyen_paiement TEXT NOT NULL, canal TEXT NOT NULL,
      montant_paye INTEGER NOT NULL DEFAULT 0, statut TEXT NOT NULL,
      note TEXT, vendu_par TEXT, cree_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE lignes_vente (
      id TEXT PRIMARY KEY,
      vente_id TEXT NOT NULL REFERENCES ventes(id) ON DELETE CASCADE,
      produit_id TEXT NOT NULL, designation TEXT NOT NULL, detail TEXT,
      prix_unitaire INTEGER NOT NULL, cout_unitaire INTEGER NOT NULL,
      quantite INTEGER NOT NULL, remise INTEGER NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE depenses (
      id TEXT PRIMARY KEY, date TEXT NOT NULL, categorie TEXT NOT NULL,
      libelle TEXT NOT NULL, montant INTEGER NOT NULL,
      moyen_paiement TEXT NOT NULL, fournisseur_id TEXT, note TEXT,
      cree_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE mouvements_stock (
      id TEXT PRIMARY KEY, date TEXT NOT NULL, produit_id TEXT NOT NULL,
      type TEXT NOT NULL, quantite INTEGER NOT NULL,
      stock_apres INTEGER NOT NULL, motif TEXT, vente_id TEXT
    )''',
    ..._schemaReglements,
    'CREATE INDEX idx_lignes_vente ON lignes_vente(vente_id)',
    'CREATE INDEX idx_ventes_date ON ventes(date)',
    'CREATE INDEX idx_mouvements_produit ON mouvements_stock(produit_id)',
  ];

  static const _schemaReglements = <String>[
    '''
    CREATE TABLE reglements (
      id TEXT PRIMARY KEY,
      vente_id TEXT NOT NULL,
      date TEXT NOT NULL,
      montant INTEGER NOT NULL,
      moyen_paiement TEXT NOT NULL,
      motif TEXT,
      cree_le TEXT NOT NULL
    )''',
    'CREATE INDEX idx_reglements_vente ON reglements(vente_id)',
    'CREATE INDEX idx_reglements_date ON reglements(date)',
  ];

  // ─────────────────────────────────────────────────────────────── lecture

  Future<bool> get estVide async {
    final n = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM produits'),
    );
    return (n ?? 0) == 0;
  }

  Future<Parametres> lireParametres() async {
    final lignes = await _db.query('parametres', where: 'id = 1');
    if (lignes.isEmpty) return const Parametres();
    final brut = jsonDecode(lignes.first['json'] as String) as Map<String, dynamic>;
    return Parametres.depuisJson(brut);
  }

  Future<void> ecrireParametres(Parametres p) async {
    await _db.insert(
      'parametres',
      {'id': 1, 'json': jsonEncode(p.versJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Produit>> lireProduits() async =>
      (await _db.query('produits', orderBy: 'nom COLLATE NOCASE'))
          .map(Produit.depuisLigne)
          .toList();

  Future<List<Client>> lireClients() async =>
      (await _db.query('clients', orderBy: 'nom COLLATE NOCASE'))
          .map(Client.depuisLigne)
          .toList();

  Future<List<Fournisseur>> lireFournisseurs() async =>
      (await _db.query('fournisseurs', orderBy: 'nom COLLATE NOCASE'))
          .map(Fournisseur.depuisLigne)
          .toList();

  Future<List<Reglement>> lireReglements() async =>
      (await _db.query('reglements', orderBy: 'date DESC, cree_le DESC'))
          .map(Reglement.depuisLigne)
          .toList();

  Future<List<Depense>> lireDepenses() async =>
      (await _db.query('depenses', orderBy: 'date DESC, cree_le DESC'))
          .map(Depense.depuisLigne)
          .toList();

  Future<List<MouvementStock>> lireMouvements({int limite = 500}) async =>
      (await _db.query('mouvements_stock', orderBy: 'date DESC', limit: limite))
          .map(MouvementStock.depuisLigne)
          .toList();

  Future<List<Vente>> lireVentes() async {
    final entetes = await _db.query('ventes', orderBy: 'date DESC, cree_le DESC');
    final toutesLignes = await _db.query('lignes_vente');
    final parVente = <String, List<LigneVente>>{};
    for (final l in toutesLignes) {
      final ligne = LigneVente.depuisLigne(l);
      parVente.putIfAbsent(ligne.venteId, () => []).add(ligne);
    }
    return entetes
        .map((e) => Vente.depuisLigne(e, parVente[e['id'] as String] ?? const []))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────── écriture

  Future<void> enregistrerProduit(Produit p) => _db.insert(
        'produits',
        p.versLigne(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> supprimerProduit(String id) =>
      _db.delete('produits', where: 'id = ?', whereArgs: [id]);

  Future<void> enregistrerClient(Client c) => _db.insert(
        'clients',
        c.versLigne(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> supprimerClient(String id) =>
      _db.delete('clients', where: 'id = ?', whereArgs: [id]);

  Future<void> enregistrerFournisseur(Fournisseur f) => _db.insert(
        'fournisseurs',
        f.versLigne(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> supprimerFournisseur(String id) =>
      _db.delete('fournisseurs', where: 'id = ?', whereArgs: [id]);

  Future<void> enregistrerDepense(Depense d) => _db.insert(
        'depenses',
        d.versLigne(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> supprimerDepense(String id) =>
      _db.delete('depenses', where: 'id = ?', whereArgs: [id]);

  Future<void> enregistrerReglement(Reglement r) => _db.insert(
        'reglements',
        r.versLigne(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> supprimerReglementsDeVente(String venteId) =>
      _db.delete('reglements', where: 'vente_id = ?', whereArgs: [venteId]);

  Future<void> enregistrerMouvement(MouvementStock m) => _db.insert(
        'mouvements_stock',
        m.versLigne(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  /// Écrit une vente et ses lignes dans une seule transaction : on ne peut
  /// jamais se retrouver avec un reçu sans articles.
  Future<void> enregistrerVente(Vente v) async {
    await _db.transaction((t) async {
      await t.insert('ventes', v.versLigne(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await t.delete('lignes_vente', where: 'vente_id = ?', whereArgs: [v.id]);
      for (final l in v.lignes) {
        await t.insert('lignes_vente', l.versLigne(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Une vente ne se supprime pas côté métier (on l'annule), mais la
  /// suppression reste disponible pour effacer une saisie de test.
  Future<void> supprimerVente(String id) =>
      _db.delete('ventes', where: 'id = ?', whereArgs: [id]);

  // ────────────────────────────────────────────────── sauvegarde / restauration

  Future<Map<String, dynamic>> exporterJson() async => {
        'version': _versionSchema,
        'exporteLe': DateTime.now().toIso8601String(),
        'parametres': (await lireParametres()).versJson(),
        'fournisseurs': (await _db.query('fournisseurs')),
        'produits': (await _db.query('produits')),
        'clients': (await _db.query('clients')),
        'ventes': (await _db.query('ventes')),
        'lignes_vente': (await _db.query('lignes_vente')),
        'reglements': (await _db.query('reglements')),
        'depenses': (await _db.query('depenses')),
        'mouvements_stock': (await _db.query('mouvements_stock')),
      };

  /// Remplace **tout** le contenu de la base par celui d'une sauvegarde.
  /// En cas d'erreur, la transaction est annulée et rien n'est perdu.
  Future<void> importerJson(Map<String, dynamic> donnees) async {
    const tables = [
      'fournisseurs',
      'produits',
      'clients',
      'ventes',
      'lignes_vente',
      'reglements',
      'depenses',
      'mouvements_stock',
    ];
    await _db.transaction((t) async {
      for (final table in tables.reversed) {
        await t.delete(table);
      }
      for (final table in tables) {
        final lignes = donnees[table];
        if (lignes is! List) continue;
        for (final ligne in lignes) {
          if (ligne is! Map) continue;
          await t.insert(
            table,
            Map<String, Object?>.from(ligne),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      final params = donnees['parametres'];
      if (params is Map) {
        await t.insert(
          'parametres',
          {'id': 1, 'json': jsonEncode(Map<String, dynamic>.from(params))},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Vide la base (les paramètres de marque sont conservés).
  Future<void> viderDonnees() async {
    const tables = [
      'mouvements_stock',
      'reglements',
      'lignes_vente',
      'ventes',
      'depenses',
      'produits',
      'clients',
      'fournisseurs',
    ];
    await _db.transaction((t) async {
      for (final table in tables) {
        await t.delete(table);
      }
    });
  }
}
