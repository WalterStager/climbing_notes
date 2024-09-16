import 'package:climbing_notes/main.dart';
import 'package:flutter/material.dart';
import 'builders.dart';
import 'data_structures.dart';
import 'package:climbing_notes/utility.dart';

class AscentPage extends StatefulWidget {
  const AscentPage({super.key, required this.providedRoute, required this.providedAscent});

  final DBRoute providedRoute;
  final DBAscent providedAscent;

  @override
  State<AscentPage> createState() => _AscentPageState(providedRoute, providedAscent);
}

class _AscentPageState extends State<AscentPage> with RouteAware {
  bool lockInputs = true;
  DBRoute route = DBRoute(0, "", "", null, null, null, null, null, null);
  DBAscent ascent = DBAscent(0, "", "", 0, null, null, null, null);
  DBAscent cancelUpdateAscent;
  List<GlobalKey<InputRowState>> inputRowKeys = [
    GlobalKey<InputRowState>(),
    GlobalKey<InputRowState>(),
  ];

  _AscentPageState(DBRoute providedRoute, DBAscent providedAscent) :
    route = providedRoute,
    ascent = providedAscent,
    cancelUpdateAscent = DBAscent.of(providedAscent);

  void errorPopup(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void updateAscent() async {
    if (!lockInputs) {
      cancelUpdateAscent = DBAscent.of(ascent);
      DateTime? likelySetDate;
      String? canBePromoted = ascent.date;
      if (canBePromoted == null) {
        errorPopup("Date is not set.");
        return;
      }
      likelySetDate = likelyTimeFromTimeDisplay(
          AppServices.of(context).settings.smallDateFormat, canBePromoted);
      if (likelySetDate == null) {
        errorPopup("Invalid date.");
        return;
      }

      if (likelySetDate.isAfter(DateTime.now())) {
        errorPopup("Date cannot be in the future.");
        return;
      }

      ascent.date = likelySetDate.toUtc().toIso8601String();

      int? res = await AppServices.of(context).dbs.ascentUpdate(ascent);
      if (res == null || res == 0) {
        errorPopup("Update unsuccessful");
      } else if (res == -1) {
        errorPopup("Nothing to update");
      }
      else {
        errorPopup("Updated");
      }
    }

    setState(() {
      lockInputs = !lockInputs;
      for (var key in inputRowKeys) {
        key.currentState
            ?.setState(() => (key.currentState?.locked = lockInputs));
      }
    });
  }

  Future<bool> deleteAscent(DBAscent ascent) async {
    int? res = await AppServices.of(context).dbs.deleteAscents([ascent.id]);
    if (res == null || res < 1) {
      return false;
    }
    return true;
  }

  // TODO fix update cancel (and probably make a lot of stuff easier, by changing InputRow to Stateless)
  void cancelUpdate() {
    setState(() {
      lockInputs = !lockInputs;
      ascent = DBAscent.of(cancelUpdateAscent);
      inputRowKeys[0].currentState?.setState(() {
        inputRowKeys[0].currentState?.locked = lockInputs;
        inputRowKeys[0].currentState?.controller.text = ascent.notes ?? "";
      });
      inputRowKeys[1].currentState?.setState(() {
        inputRowKeys[1].currentState?.locked = lockInputs;
        inputRowKeys[1].currentState?.controller.text = timeDisplayFromTimestampSafe(AppServices.of(context).settings.smallDateFormat, ascent.date);
      });
    });
  }

  Future<void> deleteAscentDialog() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Delete Ascent"),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Are you sure?'),
                ],
              ),
            ),
            actions: [
              OutlinedButton(
                child: const Icon(Icons.check),
                onPressed: () async {
                  bool res = await deleteAscent(ascent);
                  Navigator.of(context).pop();
                  if (res) {
                    errorPopup("Ascent deleted");
                    Navigator.of(context).pop();
                  } else {
                    errorPopup("Error deleting ascent");
                  }
                },
              ),
              OutlinedButton(
                child: const Icon(Icons.clear),
                onPressed: () => (Navigator.of(context).pop()),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ClimbingNotesAppBar(pageTitle: "Ascent"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Column(
              children: <Widget>[
                InputRow(label: "Rope #:",
                    inputType: TextInputType.datetime,
                    initialValue: route.rope?.toString(),
                    locked: true,
                ),
                InputRow(label: "Set date:",
                    inputType: TextInputType.datetime,
                    initialValue: timeDisplayFromTimestampSafe(AppServices.of(context).settings.smallDateFormat, route.date),
                    locked: true,
                ),
                InputRow(label: "Grade:",
                    inputType: TextInputType.text,
                    initialValue:
                        "${route.grade_num ?? ""}${route.grade_let ?? ""}",
                    locked: true,
                ),
                DropdownRow(
                  value: RouteColor.fromString(route.color ?? ""),
                  locked: true,
                ),
                const ClimbingNotesLabel("Route notes:"),
                InputRow(
                  inputType: TextInputType.text,
                  initialValue: route.notes ?? "",
                  locked: true,
                ),
                InputRow(
                  key: inputRowKeys[1],
                  label: "Ascent date:",
                  initialValue: timeDisplayFromTimestampSafe(AppServices.of(context).settings.smallDateFormat, ascent.date),
                  locked: lockInputs,
                  onChanged: (String? value) {
                    setState(() {
                      ascent.date = value;
                    });
                  },
                ),
                const Divider(),
                CheckboxRow(
                  "Finished:",
                  "Rested:",
                  locked: lockInputs,
                  initialValue1: intToBool(ascent.finished) ?? false,
                  initialValue2: intToBool(ascent.rested) ?? false,
                  onChanged1: (newValue) {
                    setState(
                      () => (ascent.finished = boolToInt(newValue)),
                    );
                  },
                  onChanged2: (newValue) {
                    setState(
                      () => (ascent.rested = boolToInt(newValue)),
                    );
                  },
                ),
                const ClimbingNotesLabel("Ascent notes:"),
                InputRow(
                  key: inputRowKeys[0],
                  inputType: TextInputType.text,
                  initialValue: ascent.notes ?? "",
                  locked: lockInputs,
                  onChanged: (String? value) {
                    setState(() {
                      ascent.notes = value;
                    });
                  },
                ),
                Row(
                  children: [
                    OutlinedButton(
                      child: Icon(lockInputs ? Icons.edit : Icons.check),
                      onPressed: updateAscent,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      child: const Icon(Icons.close),
                      onPressed: lockInputs ? null : cancelUpdate,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      child: const Icon(Icons.delete),
                      onPressed: lockInputs ? deleteAscentDialog : null,
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
            //   heroTag: "submitFloatBtn",
            //   onPressed: updateAscent,
            //   tooltip: 'Submit',
            //   child: const Icon(Icons.check),
            // ),
          ],
        ),
      ),
      drawer: const ClimbingNotesDrawer(),
    );
  }
}
