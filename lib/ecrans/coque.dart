import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'accueil.dart';
import 'clients/liste_clients.dart';
import 'produits/liste_produits.dart';
import 'rapports/rapports.dart';
import 'ventes/liste_ventes.dart';
import 'ventes/nouvelle_vente.dart';

/// Structure principale : cinq onglets et un bouton de vente toujours visible.
class Coque extends ConsumerStatefulWidget {
  const Coque({super.key});

  @override
  ConsumerState<Coque> createState() => _CoqueState();
}

class _CoqueState extends ConsumerState<Coque> {
  int _onglet = 0;

  static const _ecrans = <Widget>[
    Accueil(),
    ListeProduits(),
    ListeVentes(),
    ListeClients(),
    Rapports(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _onglet, children: _ecrans),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NouvelleVente()),
        ),
        icon: const Icon(Icons.point_of_sale_outlined),
        label: const Text('Vendre'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (i) => setState(() => _onglet = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Ventes',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Rapports',
          ),
        ],
      ),
    );
  }
}
