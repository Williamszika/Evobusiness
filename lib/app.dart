import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'coeur/theme.dart';
import 'ecrans/coque.dart';
import 'etat/boutique.dart';

class Application extends ConsumerWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(boutiqueProvider);
    final palette = paletteParCle(etat.parametres.palette);

    return MaterialApp(
      title: etat.parametres.nomBoutique,
      debugShowCheckedModeBanner: false,
      theme: construireTheme(palette),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: etat.pret ? const Coque() : _Demarrage(palette: palette),
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
