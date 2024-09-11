// ignore: unused_import
import 'dart:developer';
import 'package:climbing_notes/utility.dart';

List<DBRoute> exampleRouteData = [
  DBRoute("22+05/26", getTimestamp(), getTimestamp(), 22, "05/26", "Yellow", 11, 'a', "crimpy, the rest of an extremely long note on this climb, AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA sdfs sd sd fd fsdl if jsldf jeihfnsl "),
  DBRoute("102+12/31", getTimestamp(), getTimestamp(), 102, "12/31", "Green", 7, null, "slopers everywhere"),
];

List<DBAscent> exampleAscentData = [
  DBAscent(0, getTimestamp(), getTimestamp(), "102+12/31", "01/01", 1, 0, "was very tough"),
  DBAscent(1, getTimestamp(), getTimestamp(), "102+12/31", "02/23", 0, 1, "EZ now"),
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
  String id;
  String created;
  String updated;
  int? rope;
  String? date;
  String? color;
  int? grade_num;
  String? grade_let;
  String? notes;

  DBRoute(this.id, this.created, this.updated, this.rope, this.date, this.color, this.grade_num, this.grade_let, this.notes);

  // List<dynamic> toList() {
  //   return [
  //     id,
  //     created,
  //     updated,
  //     rope,
  //     date,
  //     color,
  //     grade_num,
  //     grade_let,
  //     notes,
  //   ];
  // }

  factory DBRoute.fromMap(Map<String, Object?> map) {
    return DBRoute(
      map['id'] as String,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created': created,
      'updated': updated,
      'rope': rope ?? 0,
      'date': date ?? '',
      'color': color,
      'grade_num': grade_num,
      'grade_let': grade_let,
      'notes': notes,
    };
  }

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
  String route;
  String? date;
  int? finished;
  int? rested;
  String? notes;

  DBAscent(this.id, this.created, this.updated, this.route, this.date, this.finished, this.rested, this.notes);

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
      map['route'] as String,
      map['date'] as String?,
      map['finished'] as int?,
      map['rested'] as int?,
      map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap({bool? includeId}) {
    Map<String, dynamic> map = {
      'created': created,
      'updated': updated,
      'route': route,
      'date': date,
      'finished': finished,
      'rested': rested,
      'notes': notes,
    };
    if (includeId ?? false) {
      map["id"] = id;
    }
    return map;
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