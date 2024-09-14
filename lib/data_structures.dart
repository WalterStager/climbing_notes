// ignore: unused_import
import 'dart:developer';
import 'package:climbing_notes/utility.dart';

List<DBRoute> exampleRouteData = [
  DBRoute(0, getTimestamp(), getTimestamp(), 22, "05/26", "Yellow", 11, 'a', "crimpy, the rest of an extremely long note on this climb, AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA sdfs sd sd fd fsdl if jsldf jeihfnsl "),
  DBRoute(1, getTimestamp(), getTimestamp(), 102, "12/31", "Green", 7, null, "slopers everywhere"),
];

List<DBAscent> exampleAscentData = [
  DBAscent(0, getTimestamp(), getTimestamp(), 0, "01/01", 1, 0, "was very tough"),
  DBAscent(1, getTimestamp(), getTimestamp(), 1, "02/23", 0, 1, "EZ now"),
];

// easier to read
typedef DatabaseTable = List<Map<String, Object?>>;

enum RouteColor {
  nocolor(""),
  white("White"),
  purple("Purple"),
  pink("Pink"),
  black("Black"),
  red("Red"),
  blue("Blue"),
  yellow("Yellow"),
  green("Green");

  final String string;

  const RouteColor(this.string);

  factory RouteColor.fromString(String s) {
    try {
      return values.firstWhere((value) => value.string == s);
    }
    on StateError catch (err) {
      log("Error making RouteColor: $err");
      return nocolor;
    }
  }
}

enum SmallDateFormat {
  mmdd("mm-dd"),
  ddmm("dd-mm");

  final String string;

  const SmallDateFormat(this.string);

  factory SmallDateFormat.fromString(String s) {
    try {
      return values.firstWhere((value) => value.string == s);
    }
    on StateError catch (err) {
      log("Error making SmallDateFormat: $err");
      rethrow;
    }
  }
}

class RouteGrade {
  int afterDecimal;
  String letter;

  RouteGrade(this.afterDecimal, this.letter);

  @override
  String toString() {
    return "5.$afterDecimal$letter";
  }

  factory RouteGrade.fromDBValues(int? num, String? let) {
    return RouteGrade(num ?? 0, let ?? "");
  }
}

class DBRoute {
  int id;
  String created;
  String updated;
  int? rope;
  String? date;
  String? color;
  int? grade_num;
  String? grade_let;
  String? notes;

  DBRoute(this.id, this.created, this.updated, this.rope, this.date, this.color, this.grade_num, this.grade_let, this.notes);

  void clear() {
    id = 0;
    created = "";
    updated = "";
    rope = null;
    date = null;
    color = null;
    grade_num = null;
    grade_let = null;
    notes = null;
  }

  factory DBRoute.of(DBRoute original) {
    return DBRoute(
      original.id,
      original.created,
      original.updated,
      original.rope,
      original.date,
      original.color,
      original.grade_num,
      original.grade_let,
      original.notes,
    );
  }

  factory DBRoute.fromMap(Map<String, Object?> map) {
    return DBRoute(
      map['id'] as int,
      map['created'] as String,
      map['updated'] as String,
      map['rope'] as int?,
      map['date'] as String?,
      map['color'] as String?,
      map['grade_num'] as int?,
      map['grade_let'] as String?,
      map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap({bool? includeId}) {
    return {
      'created': created,
      'updated': updated,
      'rope': rope ?? 0,
      'date': date ?? '',
      'color': color,
      'grade_num': grade_num,
      'grade_let': grade_let,
      'notes': notes,
      if (includeId ?? false) 'id': id,
    };
  }

  @override
  String toString() {
    return """
      DBRoute {
        id: $id,
        created: $created,
        updated: $updated,
        rope: $rope,
        date: $date,
        color: $color,
        grade_num: $grade_num,
        grade_let: $grade_let,
        notes: $notes,
      }
    """;
  }
}

class DBAscent {
  int id;
  String created;
  String updated;
  int route;
  String? date;
  int? finished;
  int? rested;
  String? notes;

  DBAscent(this.id, this.created, this.updated, this.route, this.date, this.finished, this.rested, this.notes);

  void clear() {
    id = 0;
    created = "";
    updated = "";
    route = 0;
    date = null;
    date = null;
    finished = null;
    rested = null;
    notes = null;
  }

  factory DBAscent.of(DBAscent original) {
    return DBAscent(
      original.id,
      original.created,
      original.updated,
      original.route,
      original.date,
      original.finished,
      original.rested,
      original.notes,
    );
  }

  List<dynamic> toList({bool? includeId}) {
    List<dynamic> list = ((includeId ?? false) ? [id] : []) + [
      created,
      updated,
      route,
      date,
      finished,
      rested,
      notes,
    ];
    return list;
  }

  factory DBAscent.fromMap(Map<String, Object?> map) {
    return DBAscent(
      map['id'] as int,
      map['created'] as String,
      map['updated'] as String,
      map['route'] as int,
      map['date'] as String?,
      map['finished'] as int?,
      map['rested'] as int?,
      map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap({bool? includeId}) {
    return {
      'created': created,
      'updated': updated,
      'route': route,
      'date': date,
      'finished': finished,
      'rested': rested,
      'notes': notes,
      if (includeId ?? false) 'id': id,
    };
  }
}

class DBSQliteSchema {
  String type;
  String name;
  String tbl_name;
  int rootpage;
  String sql;

  DBSQliteSchema(this.type, this.name, this.tbl_name, this.rootpage, this.sql);

  factory DBSQliteSchema.fromMap(Map<String, Object?> map) {
    return DBSQliteSchema(
      map['type'] as String,
      map['name'] as String,
      map['tbl_name'] as String,
      map['rootpage'] as int,
      map['sql'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'type': type,
      'name': name,
      'tbl_name': tbl_name,
      'rootpage': rootpage,
    };
    return map;
  }
}