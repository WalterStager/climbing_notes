// ignore: unused_import
import 'dart:developer';
import 'package:climbing_notes/data_structures.dart';
import 'package:climbing_notes/utility.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite/sqflite.dart';

/* DB plan
Tables:
  Routes
    string id = rope#+set-date
    string created
    string updated
    string? color
    string? grade
    string? notes
  Ascents
    string id = uid
    string created
    string updated
    string route = routeID
    string date
    bool? finished
    bool? rested
    string? notes
*/

const String dbFileName = "climbing_notes.db";

class DatabaseService {
  Database? db;
  bool startedLoad = false;
  PackageInfo? pi;

  DatabaseService();

  Future<void> start() async {
    startedLoad = true;
    db = await openDatabase(dbFileName);
    await createTables();
  }

  void checkDB() {
    if (db == null) {
      throw StateError("Database closed.");
    }
  }

  Future<DatabaseTable?> query(String table, int limit, int offset) async {
    checkDB();
    return await db?.query(
      table,
      limit: limit,
      offset: offset,
    );
  }
  
  Future<DatabaseTable?> queryRecentlyUpdated(String table, int limit, int offset) async {
    checkDB();
    return await db?.query(
      table,
      orderBy: "updated DESC",
      limit: limit,
      offset: offset,
    );
  }

  Future<List<DBAscent>?> queryAscents(String routeId) async {
    checkDB();
    return await db?.query(
      "Ascents",
      where: "route = ?",
      orderBy: "updated DESC",
      limit: 20,
      offset: 0,
      whereArgs: [routeId],
    ).then((value) => (value.map(DBAscent.fromMap).toList()));
  }

  Future<List<Map<String, Object?>>?> queryFinished(List<String> routeIds) async {
    checkDB();
    String q = """
      SELECT route,
            MAX(CASE WHEN finished = 1 THEN 1 ELSE 0 END) AS has_finished
      FROM Ascents
      WHERE route IN (${List.filled(routeIds.length, "?").join(", ")}) 
      GROUP BY route;
    """;
    return await db?.rawQuery(q, routeIds);
  }

  Future<List<DBRoute>?> queryRoutes(DBRoute routeInfo) async {
    checkDB();
    List<String> queryElements = List<String>.empty(growable: true);
    List<Object?> queryParameters = List<Object>.empty(growable: true);
    String queryOrderClause = "updated DESC";
    String? queryWhereClause;

    if (routeInfo.date != null) {
      DateTime? likelySetDate;
      String? canBePromoted = routeInfo.date;
      if (canBePromoted != null) {
        likelySetDate = likelyTimeFromTimeDisplay(canBePromoted);
        if (likelySetDate != null) {
            queryOrderClause = "abs(julianday(date) - julianday('${likelySetDate.toUtc().toIso8601String()}'))";
        }
      }
    }
    if (routeInfo.rope != null) {
      queryElements.add("rope LIKE ?");
      queryParameters.add("%${routeInfo.rope}%");
    }
    if (routeInfo.grade_num != null) {
      queryElements.add("grade_num LIKE ?");
      queryParameters.add("%${routeInfo.grade_num}%");
    }
    String? grade_let = routeInfo.grade_let;
    if (grade_let != null) {
      queryElements.add("grade_let = ?");
      queryParameters.add(grade_let);
    }
    String? color = routeInfo.color;
    if (color != null) {
      queryElements.add("color = ?");
      queryParameters.add(color);
    }

    if (queryElements.isNotEmpty) {
      queryWhereClause = queryElements.join(" AND ");
    }

    return await db?.query(
      "Routes",
      orderBy: queryOrderClause,
      where: queryWhereClause,
      limit: 20,
      offset: 0,
      whereArgs: queryParameters,
    ).then((value) => (value.map(DBRoute.fromMap).toList()));
  }

  Future<bool> routeInsert(DBRoute route) async {
    checkDB();
    List<Map<String, Object?>>? res = await db?.rawQuery("SELECT EXISTS(SELECT 1 FROM Routes WHERE id='${route.id}' LIMIT 1) AS does_exist");
    if (res == null) {
      log("Got null result when checking if route exists. I thought this was impossible.");
      return false;
    }
    if (res.first["does_exist"] == 1) {
      return false;
    }
    
    await db?.insert("Routes", route.toMap());
    return true;
  }

  Future<void> ascentInsert(DBAscent ascent) async {
    checkDB();
    await db?.insert("Ascents", ascent.toMap());
  }

  Future<void> createTables() async {
    checkDB();
    String createTablesStatement0 = """
    PRAGMA user_version = ${pi?.buildNumber ?? 0};
    """;
    String createTablesStatement1 = """
    CREATE TABLE IF NOT EXISTS Routes (
      id        TEXT NOT NULL PRIMARY KEY,
      created   TEXT NOT NULL,
      updated   TEXT NOT NULL,
      rope      INT NOT NULL,
      date      TEXT NOT NULL,
      color     TEXT,
      grade_num INT,
      grade_let TEXT,
      notes     TEXT
    );""";
    String createTablesStatement2 = """
    CREATE TABLE IF NOT EXISTS Ascents (
      id        INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      created   TEXT NOT NULL,
      updated   TEXT NOT NULL,
      route     TEXT NOT NULL REFERENCES Routes(id),
      date      TEXT,
      finished  INT,
      rested    INT,
      notes     TEXT
    );""";
    await db?.execute(createTablesStatement0);
    await db?.execute(createTablesStatement1);
    await db?.execute(createTablesStatement2);
  }
}