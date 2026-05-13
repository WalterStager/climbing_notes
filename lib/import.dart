  import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:climbing_notes/builders.dart';
import 'package:climbing_notes/data_structures.dart';
import 'package:climbing_notes/database.dart';
import 'package:climbing_notes/main.dart';
import 'package:climbing_notes/utility.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

Widget importTypePopup(BuildContext context) {
  return FittedBox(
    fit: BoxFit.contain,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          OutlinedButton(
            onPressed: () => (Navigator.pop(context, true)),
            child: const Row(
              children: [
                Icon(Icons.merge),
                Text("Merge data", style: TextStyle()),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => (Navigator.pop(context, false)),
            child: const Row(
              children: [
                Icon(Icons.warning),
                Text("Overwrite data", style: TextStyle()),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void errorPopup(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ),
  );
}

String? cellToString(CellValue? value) => switch (value) {
      TextCellValue v => v.value.text,
      IntCellValue v => v.value.toString(),
      DoubleCellValue v => v.value.toString(),
      DateCellValue v => v.toString(),
      DateTimeCellValue v => v.toString(),
      _ => null,
    };

int? cellToInt(CellValue? value) => switch (value) {
      IntCellValue v => v.value,
      DoubleCellValue v => v.value.round(),
      // DateCellValue v => v.value.toString(),
      // DateTimeCellValue v => v.value.toString(),
      _ => null,
    };

bool? cellToBool(CellValue? value) => switch (value) {
      BoolCellValue v => v.value,
      _ => null,
    };

DateTime? cellToDateTime(CellValue? value) => switch (value) {
      DateTimeCellValue v => dateTimeFromDateTimeCellValue(v),
      DateCellValue v => dateTimeFromDateCellValue(v),
      _ => null,
    };

DateTime? cellToDate(CellValue? value) => switch (value) {
      DateCellValue v => dateTimeFromDateCellValue(v),
      DateTimeCellValue v => dateTimeFromDateTimeCellValue(v),
      _ => null,
    };

void importXLSX(BuildContext context) async {
  FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(
      dialogTitle: "Select file to import",
      type: FileType.custom,
      allowedExtensions: ["xlsx", "xls"],
      allowMultiple: false,
      withReadStream: true);

  if (pickerResult == null) {
    errorPopup(context, "Couldn't open file");
    return;
  }

  List<int>? fileBytes = await pickerResult.files.first.readStream?.expand((x) => x).toList();

  if (fileBytes == null) {
    errorPopup(context, "Couldn't read file");
    return;
  }

  Excel excelObj = Excel.decodeBytes(fileBytes);

  if (!(excelObj.sheets.containsKey("Routes") && excelObj.sheets.containsKey("Ascents"))) {
    errorPopup(context, "Couldn't find the correct sheet names");
    return;
  }

  List<DBRoute> routes = [];
  Map<int, List<DBAscent>> ascents = {};

  String timestamp = getTimestamp();

  for (List<Data?> row in excelObj.sheets["Routes"]!.rows) {
    if (row.isEmpty) {
      continue;
    }

    if ((row[0]?.value is! IntCellValue)) {
      continue;
    }

    String? grade = cellToString(row[6]?.value);
    RegExpMatch? match = strictGradeExp.firstMatch(grade ?? "");
    String? gradeNum = match?.namedGroup("num");
    String? gradeLet = match?.namedGroup("let");

    /*
    0 IntCellValue, int id;
    1 DateTimeCellValue, String created;
    2 DateTimeCellValue, String updated;
    3 IntCellValue, int? rope;
    4 DateCellValue, String? date;
    5 TextCellValue, String? color;
    6 TextCellValue, int? gradeNum; String? gradeLet;
    7 TextCellValue String? notes;
    */ 
    // for (int i = 0; i < row.length; i++) {
    //   var a = row[i]?.value.toString();
    //   var b = row[i]?.value.runtimeType;
    //   log("$i::$a::$b");
    // }
    // break;

    routes.add(DBRoute(
      cellToInt(row[0]?.value) ?? 0,
      cellToDateTime(row[1]?.value)?.toUtc().toIso8601String() ?? timestamp,
      cellToDateTime(row[2]?.value)?.toUtc().toIso8601String() ?? timestamp,
      cellToInt(row[3]?.value),
      cellToDate(row[4]?.value)?.toUtc().toIso8601String(),
      RouteColor.fromStringOrNull(cellToString(row[5]?.value))?.string,
      stringToInt(gradeNum),
      gradeLet,
      cellToString(row[7]?.value),
    ));
  }

  for (List<Data?> row in excelObj.sheets["Ascents"]!.rows) {
    if (row.isEmpty) {
      // errorPopup("Found incorrect row length");
      continue;
    }

    if ((row[0]?.value is! IntCellValue)) {
      // errorPopup("route id column must be integer");
      continue;
    }

    int routeId = (row[0]?.value as IntCellValue).value;

    /*
    0 IntCellValue, int id;
    1 DateTimeCellValue, String created;
    2 DateTimeCellValue, String updated;
    3 IntCellValue, int route;
    4 DateTimeCellValue, String? date;
    5 BoolCellValue, int? finished;
    6 BoolCellValue, int? rested;
    7 TextCellValue String? notes;
    ?? String style;
    */ 
    // for (int i = 0; i < row.length; i++) {
    //   var a = row[i]?.value.toString();
    //   var b = row[i]?.value.runtimeType;
    //   log("$i::$a::$b");
    // }
    // break;

    if (!ascents.containsKey(routeId)) {
      ascents[routeId] = [];
    }
    ascents[routeId]!.add(DBAscent(
      cellToInt(row[0]?.value) ?? 0,
      cellToDateTime(row[1]?.value)?.toUtc().toIso8601String() ?? timestamp,
      cellToDateTime(row[2]?.value)?.toUtc().toIso8601String() ?? timestamp,
      cellToInt(row[3]?.value) ?? 0,
      cellToDateTime(row[4]?.value)?.toUtc().toIso8601String(),
      boolToInt(cellToBool(row[5]?.value)),
      boolToInt(cellToBool(row[6]?.value)),
      cellToString(row[7]?.value),
      cellToString(row.elementAtOrNull(8)?.value) ?? "toprope",
    ));
  }

  bool? importType = await modalBottomPopup<bool>(context, importTypePopup);

  if (importType == null) {
    errorPopup(context, "Didn't get import type");
    return;
  }

  for (DBRoute r in routes) {
    int? id = await AppServices.of(context).dbs.routeInsert(r);
    if (id == null) {
      continue;
    }

    for (DBAscent a in ascents[r.id] ?? []) {
      a.route = id;
      await AppServices.of(context).dbs.ascentInsert(a);
    }
  }
  errorPopup(context, "Successfully imported .xlsx file");
  // if (importType) {
  // }
  // else {

  // }
}

void exportXLSX(BuildContext context) async {
  Excel excelObj = Excel.createExcel();
  excelObj.rename(excelObj.sheets.keys.first, "Routes");
  excelObj.copy("Routes", "Ascents");

  List<DBRoute>? allRoutes =
      (await AppServices.of(context).dbs.query("Routes", null, null))
          ?.map(DBRoute.fromMap)
          .toList();
  List<DBAscent>? allAscents =
      (await AppServices.of(context).dbs.query("Ascents", null, null))
          ?.map(DBAscent.fromMap)
          .toList();

  if (allRoutes == null || allAscents == null) {
    errorPopup(context, "Could not read data from database");
    return;
  }

  ExportDateFormat dateFormat =
      AppServices.of(context).settings.exportDateFormat;

  List<List<CellValue?>> allRouteRows = allRoutes.map((DBRoute r) {
    return <CellValue?>[
      IntCellValue(r.id),
      dateTimeCellValueFromDateTime(toSettingsTimezone(
          dateFormat, timeFromTimestampNullable(r.created))),
      dateTimeCellValueFromDateTime(toSettingsTimezone(
          dateFormat, timeFromTimestampNullable(r.updated))),
      r.rope == null ? null : IntCellValue(r.rope ?? 0),
      dateTimeCellValueFromDateTime(
          toSettingsTimezone(dateFormat, timeFromTimestampNullable(r.date))),
      TextCellValue(r.color ?? ""),
      TextCellValue(
          RouteGrade.fromDBValues(r.gradeNum, r.gradeLet).toString()),
      TextCellValue(r.notes ?? ""),
    ];
  }).toList();

  List<CellValue?> routeHeaders = <CellValue?>[
    TextCellValue("identifier"),
    TextCellValue("created"),
    TextCellValue("updated"),
    TextCellValue("rope number"),
    TextCellValue("set date"),
    TextCellValue("color"),
    TextCellValue("grade"),
    TextCellValue("notes"),
  ];

  List<List<CellValue?>> allAscentRows = allAscents.map((DBAscent a) {
    return <CellValue?>[
      IntCellValue(a.id),
      dateTimeCellValueFromDateTime(toSettingsTimezone(
          dateFormat, timeFromTimestampNullable(a.created))),
      dateTimeCellValueFromDateTime(toSettingsTimezone(
          dateFormat, timeFromTimestampNullable(a.updated))),
      IntCellValue(a.route),
      dateTimeCellValueFromDateTime(
          toSettingsTimezone(dateFormat, timeFromTimestampNullable(a.date))),
      BoolCellValue(intToBool(a.finished) ?? false),
      BoolCellValue(intToBool(a.rested) ?? false),
      TextCellValue(a.notes ?? ""),
      TextCellValue(a.style ?? "toprope"),
    ];
  }).toList();

  List<CellValue?> ascentHeaders = <CellValue?>[
    TextCellValue("identifier"),
    TextCellValue("created"),
    TextCellValue("updated"),
    TextCellValue("route identifier"),
    TextCellValue("ascent date"),
    TextCellValue("finished"),
    TextCellValue("rested"),
    TextCellValue("notes"),
  ];

  excelObj.appendRow("Routes", routeHeaders);
  excelObj.appendRow("Ascents", ascentHeaders);
  for (List<CellValue?> row in allRouteRows) {
    excelObj.appendRow("Routes", row);
  }
  for (List<CellValue?> row in allAscentRows) {
    excelObj.appendRow("Ascents", row);
  }

  List<int>? bytes = excelObj.save(fileName: "climbing_data.xlsx");
  if (bytes == null) {
    errorPopup(context, "Could not save file");
    return null;
  }

  await FilePicker.platform.saveFile(
      dialogTitle: "Select where to save the file",
      fileName: "climbing_data.xlsx",
      bytes: bytes as Uint8List);
  errorPopup(context, "Successfully exported .xlsx file");
}

Future<void> importDB(BuildContext context) async {
  Directory? downloadsDir;

  if (Platform.isAndroid) {
    downloadsDir = Directory("/storage/emulated/0/Download/");
  } else {
    downloadsDir = await getDownloadsDirectory();
  }
  if (downloadsDir == null) {
    errorPopup(context, "Couldn't save database");
    return;
  }

  String databaseDir = await getDatabasesPath();
  String databasePath = path.join(databaseDir, dbFileName);
  FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(
      dialogTitle: "Select file to import",
      type: FileType.any,
      allowMultiple: false,
      withReadStream: true,
    );

  if (pickerResult == null) {
    errorPopup(context, "Couldn't open file");
    return;
  }

  bool? importType = await modalBottomPopup<bool>(context, importTypePopup);

  if (importType == null) {
    errorPopup(context, "Didn't get import type");
    return;
  }

  if (importType) {
    errorPopup(context, "Not implemented");
  }
  else {
    Uint8List databaseBytes = Uint8List.fromList(await pickerResult.files.first.readStream?.expand((x) => x).toList() ?? []);
    if (databaseBytes.isEmpty) {
      errorPopup(context, "Couldn't open file");
      return;
    }

    await File(databasePath).writeAsBytes(databaseBytes, flush: true);
    errorPopup(context, "Successfully imported .db file");
  }
}

Future<void> exportDB(BuildContext context) async {
  Directory? downloadsDir;

  if (Platform.isAndroid) {
    downloadsDir = Directory("/storage/emulated/0/Download/");
  } else {
    downloadsDir = await getDownloadsDirectory();
  }
  if (downloadsDir == null) {
    errorPopup(context, "Couldn't save database");
    return;
  }

  String databaseDir = await getDatabasesPath();
  String databasePath = path.join(databaseDir, dbFileName);
  Uint8List databaseBytes = await File(databasePath).readAsBytes();

  FilePicker.platform.saveFile(
    bytes: databaseBytes,
    fileName: dbFileName,
    initialDirectory: downloadsDir.path,
    dialogTitle: "Select save location",
  );
  errorPopup(context, "Successfully exported .db file");
}

Future <void> prodToDebug(BuildContext context) async {
  String databaseDir = await getDatabasesPath();
  String dbProdFN = path.join(databaseDir, prodDBFileName);
  String dbDebugFN = path.join(databaseDir, debugDBFileName);
  await File(dbProdFN).copy(dbDebugFN);
  log("copied $dbProdFN to $dbDebugFN");
  return;
}