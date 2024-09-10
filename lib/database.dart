import 'dart:developer';
import 'dart:io';
import 'package:climbing_notes/data_structures.dart';
import 'package:climbing_notes/utility.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;


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

class DatabaseService {
  Database db = sqlite3.openInMemory();
  bool loaded = false;
  static final DatabaseService db = DatabaseService._internal();
  static PackageInfo? pi;

  DatabaseService._internal() {
    getApplicationSupportDirectory().then((supDir) => {
      db = sqlite3.copyIntoMemory(sqlite3.open(path.join(supDir.path, "climbing_notes.db"))),
      createTables(),
    });
    log("Creating DB tables");
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) => (pi = packageInfo));
    createTables();
    loaded = true;
  }

  factory DatabaseService() {
    return db;
  }

  Future<bool> saveDatabase() async {
    Directory supDir = await getApplicationSupportDirectory();
    String dbPath = path.join(supDir.path, "climbing_notes.db");
    Database fileDB = sqlite3.open(dbPath);
    db.backup(fileDB);
    return true;
  }

  
  List<List<Object?>> queryRecentlyUpdated(String table, int limit, int offset) {
    String queryStatement = """
      SELECT * FROM $table
        ORDER BY updated DESC
        LIMIT $limit
        OFFSET $offset
    """;
    return db.select(queryStatement).rows;
  }

  List<DBAscent> queryAscents(String routeId) {
    String queryStatement = """
      SELECT * FROM Ascents
        WHERE route = :route
        ORDER BY updated DESC
        LIMIT 10
        OFFSET 0
    """;

    PreparedStatement statement = db.prepare(queryStatement);
    return statement.selectWith(StatementParameters.named({":route": routeId})).rows.map(DBAscent.fromList).toList();
  }

  List<DBRoute> queryRoutes(DBRoute routeInfo) {
    List<String> queryElements = List<String>.empty(growable: true);
    Map<String, dynamic> queryParameters = {};
    String queryOrderClause = "ORDER BY updated DESC";

    if (routeInfo.rope != null) {
      queryElements.add("rope LIKE :rope");
      queryParameters[":rope"] = "%${routeInfo.rope}%";
    }
    if (routeInfo.date != null) {
      DateTime? likelySetDate = null;
      String? canBePromoted = routeInfo.date;
      if (canBePromoted != null) {
        likelySetDate = likelyTimeFromTimeDisplay(canBePromoted);
        if (likelySetDate != null) {
            // queryElements.add("date LIKE :date");
            // queryParameters[":date"] = "%${routeInfo.date}%";
            queryOrderClause = "ORDER BY abs(julianday(date) - julianday(:date))";
            queryParameters[":date"] = "${likelySetDate.toUtc().toIso8601String()}";
        }
      }
    }
    if (routeInfo.grade_num != null) {
      queryElements.add("grade_num LIKE :grade_num");
      queryParameters[":grade_num"] = "%${routeInfo.grade_num}%";
    }
    if (routeInfo.grade_let != null) {
      queryElements.add("grade_let = :grade_let");
      queryParameters[":grade_let"] = routeInfo.grade_let;
    }
    if (routeInfo.color != null) {
      queryElements.add("color = :color");
      queryParameters[":color"] = routeInfo.color;
    }

    String queryWhereClause = "WHERE ${queryElements.join(" AND ")}";
    if (queryElements.length == 0) {
      queryWhereClause = "";
    }
      
    String queryStatement = """
      SELECT * FROM Routes
        $queryWhereClause
        $queryOrderClause
        LIMIT 20
        OFFSET 0
    """;
    log(queryStatement);
    PreparedStatement statement = db.prepare(queryStatement);
    List<DBRoute> res = statement.selectWith(StatementParameters.named(queryParameters)).rows.map(DBRoute.fromList).toList();
    log(res.length.toString());
    log(routeInfo.toString());
    return res;
  }

  void routeInsert(DBRoute route) {
    String insertStatement = """
      INSERT INTO Routes (
        id,
        created,
        updated,
        rope,
        date,
        color,
        grade_num,
        grade_let,
        notes
      )
      VALUES (
        :id,
        :created,
        :updated,
        :rope,
        :date,
        :color,
        :grade_num,
        :grade_let,
        :notes
      )
    """;
    PreparedStatement statement = db.prepare(insertStatement);
    statement.selectWith(StatementParameters.named(route.toMap()));
  }
  void ascentInsert(DBAscent ascent) {
    String insertStatement = """
      INSERT INTO Ascents (
        created,
        updated,
        route,
        date,
        finished,
        rested,
        notes
      )
      VALUES (
        :created,
        :updated,
        :route,
        :date,
        :finished,
        :rested,
        :notes
      )
    """;
    PreparedStatement statement = db.prepare(insertStatement);
    statement.selectWith(StatementParameters.named(ascent.toMap()));
  }

  void createTables() {
    String createTablesStatement = """
    PRAGMA user_version = ${pi?.buildNumber ?? 0};
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
    );
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
    db.execute(createTablesStatement);
  }
}