import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'donnees/base_plateforme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Dans le navigateur, SQLite doit être branché sur sa version WebAssembly.
  await configurerBase();
  // Noms de mois et de jours en français, pour les dates et les rapports.
  await initializeDateFormatting('fr_FR');
  runApp(const ProviderScope(child: Application()));
}
