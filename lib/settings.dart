import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:climbing_notes/data_structures.dart';
import 'package:climbing_notes/main.dart';
import 'package:climbing_notes/utility.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'builders.dart';

class AppSettings {
  int id = 0;
  SmallDateFormat smallDateFormat = SmallDateFormat.mmdd;

  AppSettings({int? idArg, SmallDateFormat? smallDateFormatArg}) {
    if (smallDateFormatArg != null) {
      smallDateFormat = smallDateFormatArg;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_format': smallDateFormat.string,
    };
  }

  factory AppSettings.fromMap(Map<String, Object?> map) {
    return AppSettings(
      idArg: map['id'] as int,
      smallDateFormatArg:
          SmallDateFormat.fromString(map['date_format'] as String),
    );
  }

  void setTo(AppSettings newSettings) {
    id = newSettings.id;
    smallDateFormat = newSettings.smallDateFormat;
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  _SettingsPageState();

  Future<void> saveSettings() async {
    int? res = await AppServices.of(context)
        .dbs
        .settingsUpdate(AppServices.of(context).settings);
    if (res == null) {
      errorPopup("Failed to save settings");
      return;
    }
    if (res < 1) {
      errorPopup("Failed to save settings");
    }
    errorPopup("Saved settings");
  }

  void errorPopup(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void importXLSX() {
    
    errorPopup("Not implemented");
  }

  void exportXLSX() async {
    Excel excelObj = Excel.createExcel();
    excelObj.rename(excelObj.sheets.keys.first, "Routes");
    excelObj.copy("Routes", "Ascents");

    List<DBRoute>? allRoutes = (await AppServices.of(context).dbs.query("Routes", null, null))?.map(DBRoute.fromMap).toList();
    List<DBAscent>? allAscents = (await AppServices.of(context).dbs.query("Ascents", null, null))?.map(DBAscent.fromMap).toList();

    if (allRoutes == null || allAscents == null) {
      errorPopup("Could not read data from database");
      return;
    }

    // TODO add (export as local / export as utc) option

    List<List<CellValue?>> allRouteRows = allRoutes.map((DBRoute r) {
      return <CellValue?>[
        IntCellValue(r.id),
        dateTimeCellValueFromDateTime(timeFromTimestampNullable(r.created)?.toLocal()),
        dateTimeCellValueFromDateTime(timeFromTimestampNullable(r.updated)?.toLocal()),
        r.rope == null ? null :IntCellValue(r.rope ?? 0),
        dateTimeCellValueFromDateTime(timeFromTimestampNullable(r.date)?.toLocal()),
        TextCellValue(r.color ?? ""),
        TextCellValue(RouteGrade.fromDBValues(r.gradeNum, r.gradeLet).toString()),
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
        dateTimeCellValueFromDateTime(timeFromTimestampNullable(a.created)?.toLocal()),
        dateTimeCellValueFromDateTime(timeFromTimestampNullable(a.updated)?.toLocal()),
        IntCellValue(a.route),
        dateTimeCellValueFromDateTime(timeFromTimestampNullable(a.date)?.toLocal()),
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
      errorPopup("Could not save file");
      return null;
    }

    await FilePicker.platform.saveFile(dialogTitle: "Select where to save the file", fileName: "climbing_data.xlsx", bytes: bytes as Uint8List);
    errorPopup("Successful export");
  }

  Future<void> exportDB() async {
    Directory? downloadsDir;

    if (Platform.isAndroid) {
      downloadsDir = Directory("/storage/emulated/0/Download/");
    } else {
      downloadsDir = await getDownloadsDirectory();
    }
    if (downloadsDir == null) {
      errorPopup("Couldn't save database1");
      return;
    }

    String databaseDir = await getDatabasesPath();
    String databsePath = path.join(databaseDir, "climbing_notes.db");
    String savePath = path.join(downloadsDir.path, "climbing_notes.db");
    log(databsePath);
    log(savePath);

    await Permission.manageExternalStorage.onDeniedCallback(() {
      errorPopup("Couldn't save database, permissions denied");
    }).onGrantedCallback(() async {
      await File(databsePath).copy(savePath);
      errorPopup("Database saved");
    }).onPermanentlyDeniedCallback(() {
      errorPopup("Couldn't save database, permissions denied");
    }).onRestrictedCallback(() {
      errorPopup("Couldn't save database, permissions denied");
    }).onLimitedCallback(() {
      errorPopup("Couldn't save database, permissions denied");
    }).onProvisionalCallback(() {
      errorPopup("Couldn't save database, permissions denied");
    }).request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ClimbingNotesAppBar(pageTitle: "Settings"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    const ClimbingNotesLabel("Date format: "),
                    SegmentedButton<SmallDateFormat>(
                      segments: const [
                        ButtonSegment(
                            value: SmallDateFormat.ddmm,
                            label: Text("day-month")),
                        ButtonSegment(
                            value: SmallDateFormat.mmdd,
                            label: Text("month-day")),
                      ],
                      selected: {
                        AppServices.of(context).settings.smallDateFormat
                      },
                      onSelectionChanged: (set) => (setState(() =>
                          (AppServices.of(context).settings.smallDateFormat =
                              set.first))),
                    ),
                  ],
                ),
                const Divider(
                  thickness: 3,
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: importXLSX,
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_upward),
                          Text("Import .xlsx"),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: exportXLSX,
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_downward),
                          Text("Export .xlsx"),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: exportDB,
                      child: const Row(
                        children: [
                          Icon(Icons.account_tree_sharp),
                          Text("Export .db"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              heroTag: "backFloatBtn",
              onPressed: () => {
                Navigator.pop(context),
              },
              tooltip: 'Back',
              child: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: "saveFloatBtn",
              onPressed: saveSettings,
              tooltip: 'Save settings',
              child: const Icon(Icons.save),
            ),
          ],
        ),
      ),
      drawer: const ClimbingNotesDrawer(),
    );
  }
}
