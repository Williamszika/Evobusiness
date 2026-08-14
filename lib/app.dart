import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'coeur/theme.dart';
import 'ecrans/bienvenue/bienvenue.dart';
import 'ecrans/coque.dart';
import 'etat/boutique.dart';

class Application extends ConsumerWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(boutiqueProvider);
    final palette = paletteParCle(etat.parametres.palette);

    return MaterialApp(
      title: etat.parametres.estConfiguree
          ? etat.parametres.nomBoutique
          : 'Ma Boutique',
      debugShowCheckedModeBanner: false,
      theme: construireTheme(palette),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Trois états, dans cet ordre : la base s'ouvre, la boutique n'a jamais
      // été nommée, la boutique est en service.
      home: !etat.pret
          ? _Demarrage(palette: palette)
          : etat.parametres.estConfiguree
              ? const Coque()
              : const EcranBienvenue(),
    );
  }
}

class _Demarrage extends StatelessWidget {
  const _Demarrage({required this.palette});
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.fond,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: palette.primaire),
            const SizedBox(height: 20),
            Text(
              'Ouverture de la boutique…',
              style: TextStyle(color: palette.encre.withValues(alpha: .6)),
            ),
          ],
        ),
      ),
    );
  }
}
