import 'package:climbing_notes/data_structures.dart';
import 'package:climbing_notes/main.dart';
import 'package:flutter/material.dart';
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
      smallDateFormatArg: SmallDateFormat.fromString(map['date_format'] as String),
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
    int? res = await AppServices.of(context).dbs.settingsUpdate(AppServices.of(context).settings);
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
                      selected: {AppServices.of(context).settings.smallDateFormat},
                      onSelectionChanged: (set) => (setState(() =>
                          (AppServices.of(context).settings.smallDateFormat =
                              set.first))),
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
