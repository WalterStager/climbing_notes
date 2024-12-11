// ignore: unused_import
import 'dart:developer';
import 'package:climbing_notes/data_structures.dart';
import 'package:climbing_notes/database_view.dart';
import 'package:climbing_notes/import.dart';
import 'package:climbing_notes/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'builders.dart';

class AppSettings {
  int id = 0;
  SmallDateFormat smallDateFormat = SmallDateFormat.mmdd;
  ExportDateFormat exportDateFormat = ExportDateFormat.local;

  AppSettings(
      {int? idArg,
      SmallDateFormat? smallDateFormatArg,
      ExportDateFormat? exportDateFormatArg}) {
    if (smallDateFormatArg != null) {
      smallDateFormat = smallDateFormatArg;
    }
    if (exportDateFormatArg != null) {
      exportDateFormat = exportDateFormatArg;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_format': smallDateFormat.string,
      'export_format': exportDateFormat.string,
    };
  }

  factory AppSettings.fromMap(Map<String, Object?> map) {
    return AppSettings(
        idArg: map['id'] as int,
        smallDateFormatArg:
            SmallDateFormat.fromString(map['date_format'] as String),
        exportDateFormatArg:
            ExportDateFormat.fromString(map['export_format'] as String));
  }

  void setTo(AppSettings newSettings) {
    id = newSettings.id;
    smallDateFormat = newSettings.smallDateFormat;
    exportDateFormat = newSettings.exportDateFormat;
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
                // Row(
                //   children: [
                //     const ClimbingNotesLabel("Timezone: "),
                //     SegmentedButton<ExportDateFormat>(
                //       segments: const [
                //         ButtonSegment(
                //             value: ExportDateFormat.local,
                //             label: Text("local")),
                //         ButtonSegment(
                //             value: ExportDateFormat.utc, label: Text("UTC")),
                //       ],
                //       selected: {
                //         AppServices.of(context).settings.exportDateFormat
                //       },
                //       onSelectionChanged: (set) => (setState(() =>
                //           (AppServices.of(context).settings.exportDateFormat =
                //               set.first))),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => (exportXLSX(context)),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_downward),
                          Text("Export .xlsx"),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => (importXLSX(context)),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_upward),
                          Text("Import .xlsx"),
                        ],
                      ),
                    ),
                    
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => (exportDB(context)),
                      child: const Row(
                        children: [
                          Icon(Icons.account_tree_sharp),
                          Text("Export .db"),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => (importDB(context)),
                      child: const Row(
                        children: [
                          Icon(Icons.account_tree_sharp),
                          Text("Import .db"),
                        ],
                      ),
                    ),
                  ],
                ),
                if (kDebugMode)
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => {
                      Navigator.pop(context),
                      Navigator.push(
                        context,
                        cnPageTransition(const DatabaseViewPage()),
                      ),
                    },
                      child: const Row(
                        children: [
                          Icon(Icons.account_tree_sharp),
                          Text("DB View"),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => (prodToDebug(context)),
                      child: const Row(
                        children: [
                          Icon(Icons.account_tree_sharp),
                          Text("prodToDebug .db"),
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
