import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Noms de mois et de jours en français, pour les dates et les rapports.
  await initializeDateFormatting('fr_FR');
  runApp(const ProviderScope(child: Application()));
}
