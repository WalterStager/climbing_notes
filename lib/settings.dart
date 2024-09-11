import 'package:climbing_notes/data_structures.dart';
import 'package:climbing_notes/main.dart';
import 'package:flutter/material.dart';
import 'builders.dart';

class AppSettings {
  SmallDateFormat dateFormat = SmallDateFormat.mmdd;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  _SettingsPageState();

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
                      selected: {AppServices.of(context).settings.dateFormat},
                      onSelectionChanged: (set) => (setState(() =>
                          (AppServices.of(context).settings.dateFormat =
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
            // const SizedBox(height: 8),
            // FloatingActionButton(
            //   heroTag: "addFloatBtn",
            //   onPressed: () => (
            //     Navigator.push(
            //       context,
            //       PageTransition(
            //         duration: pageTransitionDuration,
            //         reverseDuration: pageTransitionDuration,
            //         type: PageTransitionType.leftToRight,
            //         child: AddRoutePage(providedRoute: DBRoute.of(queryInfo)),
            //       ),
            //     ),
            //   ),
            //   tooltip: 'Add route',
            //   child: const Icon(Icons.add),
            // ),
          ],
        ),
      ),
      drawer: const ClimbingNotesDrawer(),
    );
  }
}
