import 'package:climbing_notes/utility.dart';

List<DBRoute> exampleRouteData = [
  DBRoute("22+05/26", getTimestamp(), getTimestamp(), 22, "05/26", "Yellow", 11, 'a', "crimpy, the rest of an extremely long note on this climb, AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA sdfs sd sd fd fsdl if jsldf jeihfnsl "),
  DBRoute("102+12/31", getTimestamp(), getTimestamp(), 102, "12/31", "Green", 7, null, "slopers everywhere"),
];

List<DBAscent> exampleAscentData = [
  DBAscent(0, getTimestamp(), getTimestamp(), "102+12/31", "01/01", 1, 0, "was very tough"),
  DBAscent(1, getTimestamp(), getTimestamp(), "102+12/31", "02/23", 0, 1, "EZ now"),
];

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
    return values.firstWhere((value) => value.string == s);
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

// class RouteTableRow {
//   String id;
//   int rope;
//   String date;
//   RouteGrade grade;
//   RouteColor color;
//   bool finished;
//   String notes;

//   RouteTableRow(this.id, this.rope, this.date, this.grade, this.color, this.finished, this.notes);

//   DBRoute toDB() {
//     String timestamp = getTimestamp();
//     return DBRoute(
//       "$rope+$date",
//       timestamp,
//       timestamp,
//       rope,
//       date,
//       color.string,
//       grade.afterDecimal,
//       grade.letter,
//       notes,
//     );
//   }
// }

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

  // RouteTableRow toTableRow({int? finished}) {
  //   return RouteTableRow(
  //     id,
  //     rope ?? 0,
  //     date ?? '',
  //     RouteGrade(grade_num ?? 0, grade_let ?? ''),
  //     RouteColor.fromString(color ?? ''),
  //     (finished ?? 0) == 1 ? true : false,
  //     notes ?? '',
  //   );
  // }

  Map<String, dynamic> toMap() {
    return {
      ':id': id,
      ':created': created,
      ':updated': updated,
      ':rope': rope ?? 0,
      ':date': date ?? '',
      ':grade_num': grade_num,
      ':grade_let': grade_let,
      ':color': color,
      ':notes': notes,
    };
  }

  factory DBRoute.fromList(List<Object?> list) {
    return DBRoute(
      list[0] as String,
      list[1] as String,
      list[2] as String,
      list[3] as int?,
      list[4] as String?,
      list[5] as String?,
      list[6] as int?,
      list[7] as String?,
      list[8] as String?,
    );
  }

  String toString() {
    return """
DBRoute {
  id: $id,
  created: $created,
  updated: $updated,
  rope: $rope,
  date: $date,
  grade_num: $grade_num,
  grade_let: $grade_let,
  color: $color,
  notes: $notes,
}
    """;
  }
}

// class AscentTableRow {
//   int id;
//   String routeId;
//   String date;
//   bool finished;
//   bool rested;
//   String notes;

//   AscentTableRow(this.id, this.routeId, this.date, this.finished, this.rested, this.notes);

//   DBAscent toDB() {
//     String timestamp = getTimestamp();
//     return DBAscent(
//       0,
//       timestamp,
//       timestamp,
//       routeId,
//       date,
//       finished ? 0 : 1,
//       rested ? 0 : 1,
//       notes,
//     );
//   }
// }

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

  // AscentTableRow toTableRow() {
  //   return AscentTableRow(
  //     id,
  //     route,
  //     date ?? "",
  //     (finished ?? 0) == 0 ? true : false,
  //     (rested ?? 0) == 0 ? true : false,
  //     notes ?? "",
  //   );
  // }

  Map<String, dynamic> toMap({bool? includeId}) {
    Map<String, dynamic> map = {
      ':created': created,
      ':updated': updated,
      ':route': route,
      ':date': date,
      ':finished': finished,
      ':rested': rested,
      ':notes': notes,
    };
    if (includeId ?? false) {
      map[":id"] = id;
    }
    return map;
  }

  factory DBAscent.fromList(List<Object?> list) {
    return DBAscent(
      list[0] as int,
      list[1] as String,
      list[2] as String,
      list[3] as String,
      list[4] as String?,
      list[5] as int?,
      list[6] as int?,
      list[7] as String?,
    );
  }
}