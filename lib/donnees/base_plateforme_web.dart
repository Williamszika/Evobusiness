import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Dans le navigateur, SQLite tourne en WebAssembly et range ses données
/// dans le stockage du navigateur. Les fichiers `sqlite3.wasm` et
/// `sqflite_sw.js` sont livrés dans le dossier `web/`.
Future<void> configurerBase() async {
  databaseFactory = databaseFactoryFfiWeb;
}
