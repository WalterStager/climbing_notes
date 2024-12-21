import 'dart:async';
import 'dart:developer';
import 'package:sqflite/sqflite.dart';


Future<void> createTables(Database db, int version) async {
  List<String> createTablesStatements = [
    """
    CREATE TABLE IF NOT EXISTS Settings (
      id            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      date_format   TEXT NOT NULL,
      export_format TEXT NOT NULL,
      theme         TEXT NOT NULL
    );""",
      """
    CREATE TABLE IF NOT EXISTS Routes (
      id        INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      created   TEXT NOT NULL,
      updated   TEXT NOT NULL,
      rope      INT NOT NULL,
      date      TEXT NOT NULL,
      color     TEXT,
      grade_num INT,
      grade_let TEXT,
      notes     TEXT
    );""",
      """
    CREATE TABLE IF NOT EXISTS Ascents (
      id        INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      created   TEXT NOT NULL,
      updated   TEXT NOT NULL,
      route     INTEGER NOT NULL REFERENCES Routes(id),
      date      TEXT,
      finished  INT,
      rested    INT,
      notes     TEXT
    );
    """
  ];

  // ignore: avoid_function_literals_in_foreach_calls
  createTablesStatements.forEach((statement) async {
    await db.execute(statement);
  });
}

const Map<int, void Function(Database)> migrations = {
  2:migrationToVersion2,
};

Future<void> allMigrations(Database db, int prevVer, int curVer) async {
  log("allMigrations $prevVer to $curVer");
  for (int i = prevVer+1; i <= curVer; i++) {
    if (migrations.containsKey(i)) {
      migrations[i]!(db);
    }
  }
}
Future<void> allDowngrades(Database db, int prevVer, int curVer) async {
  throw StateError("Database version is newer than app version.");
}

void migrationToVersion2(Database db) {
  log("migrationToVersion2");
  List<String> migrationStatements = [
    """
    ALTER TABLE Settings
    ADD export_format TEXT NOT NULL
    DEFAULT 'local'
    """,
    """
    ALTER TABLE Settings
    ADD theme TEXT NOT NULL
    DEFAULT 'Follow System'
    """
  ];

  // ignore: avoid_function_literals_in_foreach_calls
  migrationStatements.forEach((statement) async {
    await db.execute(statement);
  });
}