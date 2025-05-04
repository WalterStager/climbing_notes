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

  List<int>? fileBytes = await pickerResult.files.first.readStream?.single;

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
      // errorPopup("Found incorrect row length");
      continue;
    }

    if ((row[0]?.value is! IntCellValue)) {
      // errorPopup("route id column must be integer");
      continue;
    }

    String? grade = (row[4]?.value as TextCellValue?)?.value.text;

    RegExpMatch? match = strictGradeExp.firstMatch(grade ?? "");
    String? num = match?.namedGroup("num");
    String? let = match?.namedGroup("let");

    routes.add(DBRoute(
      (row[0]?.value as IntCellValue).value,
      timestamp,
      timestamp,
      (row[1]?.value as IntCellValue?)?.value,
      dateTimeFromDateCellValue((row[2]?.value as DateCellValue?))?.toUtc().toIso8601String(),
      RouteColor.fromStringOrNull((row[3]?.value as TextCellValue?)?.value.text)?.string,
      stringToInt(num),
      let,
      (row[5]?.value as TextCellValue?)?.value.text,
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

    if (!ascents.containsKey(routeId)) {
      ascents[routeId] = [];
    }
    ascents[routeId]!.add(DBAscent(
      0,
      timestamp,
      timestamp,
      (row[0]?.value as IntCellValue).value,
      dateTimeFromDateTimeCellValue((row[1]?.value as DateTimeCellValue?))?.toUtc().toIso8601String(),
      boolToInt((row[2]?.value as BoolCellValue?)?.value),
      boolToInt((row[3]?.value as BoolCellValue?)?.value),
      (row[4]?.value as TextCellValue?)?.value.text,
      styleFromNullable((row[5]?.value as TextCellValue?)?.value.text),
    ));
  }

  bool? importType = await modalBottomPopup<bool>(context, importTypePopup);

  if (importType == null) {
    errorPopup(context, "Didn't get import type");
    return;
  }

  if (importType) {
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
  }
  else {

  }
}

String styleFromNullable(String? style) {
  if (style == null) {
    return "toprope";
  }
  else {
    return style;
  }
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
    Uint8List databaseBytes = Uint8List.fromList(await pickerResult.files.first.readStream?.single ?? []);
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
  Uint8List databaseBytes = Uint8List.fromList(await File(databasePath).openRead().single);

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