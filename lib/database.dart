// ignore: unused_import
import 'dart:developer';
import 'package:climbing_notes/data_structures.dart';
import 'package:climbing_notes/settings.dart';
import 'package:climbing_notes/utility.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite/sqflite.dart';

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

  Future<List<DBAscent>?> queryAscents(int routeId) async {
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

  Future<List<DBRouteExtra>?> queryExtra(List<int> routeIds) async {
    checkDB();
    String q = """
      SELECT
        Routes.*,
        SUM(Ascents.finished) as finished,
        MAX(Ascents.date) as ascent_date,
        MIN(CASE WHEN Ascents.finished = 1 THEN COALESCE(Ascents.rested, 0) ELSE 1 END) AS fin_with_rest
      FROM Routes
      JOIN Ascents
      ON Routes.id = Ascents.route
      WHERE Routes.id IN (${List.filled(routeIds.length, "?").join(", ")})
      GROUP BY Routes.id
    """;
    List<Map<String, Object?>>? res =  await db?.rawQuery(q, routeIds);
    return res?.map(DBRouteExtra.fromMap).toList();
  }

  Future<List<DBRoute>?> queryRoutes(SmallDateFormat format, DBRoute routeInfo) async {
    checkDB();
    List<String> queryElements = List<String>.empty(growable: true);
    List<Object?> queryParameters = List<Object>.empty(growable: true);
    String queryOrderClause = "updated DESC";
    String? queryWhereClause;

    if (routeInfo.date != null) {
      DateTime? likelySetDate;
      String? canBePromoted = routeInfo.date;
      if (canBePromoted != null) {
        likelySetDate = likelyTimeFromTimeDisplay(format, canBePromoted);
        if (likelySetDate != null) {
            queryOrderClause = "abs(julianday(date) - julianday('${likelySetDate.toUtc().toIso8601String()}'))";
        }
      }
    }
    if (routeInfo.rope != null) {
      queryElements.add("rope LIKE ?");
      queryParameters.add("%${routeInfo.rope}%");
    }
    if (routeInfo.gradeNum != null) {
      queryElements.add("grade_num LIKE ?");
      queryParameters.add("%${routeInfo.gradeNum}%");
    }
    String? gradeLet = routeInfo.gradeLet;
    if (gradeLet != null) {
      queryElements.add("grade_let = ?");
      queryParameters.add(gradeLet);
    }
    String? color = routeInfo.color;
    if (color != null) {
      queryElements.add("color = ?");
      queryParameters.add(color);
    }
    String? notes = routeInfo.notes;
    if (notes != null) {
      queryElements.add("notes = ?");
      queryParameters.add("%${routeInfo.notes}%");
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

  Future<AppSettings?> settingsGetOrInsert(AppSettings settings) async {
    checkDB();

    List<Map<String, Object?>>? res = await db?.rawQuery("SELECT * FROM Settings");
    if (res == null) {
      log("Got null result when checking if settings exists. I thought this was impossible.");
      return null;
    }
    if (res.isEmpty) {
      settingsInsert(settings);
      return settings;
    }
    return AppSettings.fromMap(res.first);
  }

  Future<int?> settingsInsert(AppSettings settings) async {
    checkDB();
    return await db?.insert("Settings", settings.toMap());
  }

  Future<int?> settingsUpdate(AppSettings settings) async {
    checkDB();
    return await db?.update("Settings", settings.toMap(), where: "id = ?", whereArgs: [settings.id]);
  }

  Future<int?> routeInsert(DBRoute route) async {
    checkDB();
    List<Map<String, Object?>>? res = await db?.rawQuery("SELECT EXISTS(SELECT 1 FROM Routes WHERE rope='${route.rope}' AND date='${route.date}' LIMIT 1) AS does_exist");
    if (res == null) {
      log("Got null result when checking if route exists. I thought this was impossible.");
      return null;
    }
    if (res.first["does_exist"] == 1) {
      return null;
    }
    
    return await db?.insert("Routes", route.toMap());
  }

  Future<void> ascentInsert(DBAscent ascent) async {
    checkDB();
    await db?.insert("Ascents", ascent.toMap());
  }

  Future<int?> routeUpdate(DBRoute newR) async {
    checkDB();
    DBRoute? oldR = await db?.query("Routes", where: "id = ?", whereArgs: [newR.id]).then((value) => (value.map(DBRoute.fromMap).toList().firstOrNull));
    if (oldR == null) {
      return null;
    }

    Map<String, Object?> updateElements = <String, Object?>{};

    if (newR.rope != oldR.rope) {
      updateElements["rope"] = newR.rope;
    }
    if (newR.date != oldR.date) {
      updateElements["date"] = newR.date;
    }
    if (newR.color != oldR.color) {
      updateElements["color"] = newR.color;
    }
    if (newR.gradeNum != oldR.gradeNum) {
      updateElements["grade_num"] = newR.gradeNum;
    }
    if (newR.gradeLet != oldR.gradeLet) {
      updateElements["grade_let"] = newR.gradeLet;
    }
    if (newR.notes != oldR.notes) {
      updateElements["notes"] = newR.notes;
    }

    if (updateElements.isNotEmpty) {
      updateElements["updated"] = getTimestamp();
      return await db?.update("Routes", updateElements, where: "id = ?", whereArgs: [newR.id]);
    }
    return -1;
  }

  Future<int?> ascentUpdate(DBAscent newA) async {
    checkDB();
    DBAscent? oldA = await db?.query("Ascents", where: "id = ?", whereArgs: [newA.id]).then((value) => (value.map(DBAscent.fromMap).toList().firstOrNull));
    if (oldA == null) {
      return null;
    }

    Map<String, Object?> updateElements = <String, Object?>{};

    if (newA.date != oldA.date) {
      updateElements["date"] = newA.date;
    }
    if (newA.finished != oldA.finished) {
      updateElements["finished"] = newA.finished;
    }
    if (newA.rested != oldA.rested) {
      updateElements["rested"] = newA.rested;
    }
    if (newA.notes != oldA.notes) {
      updateElements["notes"] = newA.notes;
    }

    if (updateElements.isNotEmpty) {
      updateElements["updated"] = getTimestamp();
      return await db?.update("Ascents", updateElements, where: "id = ?", whereArgs: [newA.id]);
    }
    return 0;
  }

  Future<int?> deleteRoute(int routeId) async {
    checkDB();
    List<DBAscent>? relatedAscents = await queryAscents(routeId);
    if (relatedAscents != null) {
      await deleteAscents(relatedAscents.map((ascent) => (ascent.id)).toList());
    }

    return await db?.delete("Routes", where: "id = ?", whereArgs: [routeId]);
  }

  Future<int?> deleteAscents(List<int> ascentIds) async {
    checkDB();
    return await db?.delete("Ascents", where: "id IN (${List.filled(ascentIds.length, "?").join(", ")})", whereArgs: ascentIds);
  }

  Future<void> createTables() async {
    checkDB();
    List<String> createTablesStatements = ["""
    PRAGMA user_version = ${pi?.buildNumber ?? 0};
    """,
    """
    CREATE TABLE IF NOT EXISTS Settings (
      id          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      date_format TEXT
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
    """];

    // ignore: avoid_function_literals_in_foreach_calls
    createTablesStatements.forEach((statement) async {
      await db?.execute(statement);
    });
  }
}