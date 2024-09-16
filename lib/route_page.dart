// ignore: unused_import
import 'dart:developer';
import 'package:climbing_notes/add_ascent.dart';
import 'package:climbing_notes/main.dart';
import 'package:flutter/material.dart';
import 'builders.dart';
import 'data_structures.dart';
import 'package:climbing_notes/utility.dart';

class AscentsPage extends StatefulWidget {
  const AscentsPage({super.key, required this.route});

  final DBRoute route;

  @override
  State<AscentsPage> createState() => _AscentsPageState(route);
}

class _AscentsPageState extends State<AscentsPage> with RouteAware {
  DBRoute route;
  DBRoute cancelUpdateRoute;
  List<DBAscent>? tableData;
  bool lockInputs = true;
  List<GlobalKey<InputRowState>> inputRowKeys = [
    GlobalKey<InputRowState>(),
    GlobalKey<InputRowState>(),
    GlobalKey<InputRowState>(),
    GlobalKey<InputRowState>(),
  ];

  _AscentsPageState(this.route) : cancelUpdateRoute = DBRoute.of(route); 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppServices.of(context).robs.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPush() {
    getTableData();
    super.didPush();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didPopNext() {
    getTableData();
    super.didPopNext();
  }

  void getTableData() async {
    List<DBAscent>? r1 =
        await AppServices.of(context).dbs.queryAscents(route.id);
    setState(() {
      tableData = r1;
    });
  }

  void updateRoute() async {
    if (!lockInputs) {
      cancelUpdateRoute = DBRoute.of(route);

      DateTime? likelySetDate;
      String? canBePromoted = route.date;
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

      route.date = likelySetDate.toUtc().toIso8601String();

      int? res = await AppServices.of(context).dbs.routeUpdate(route);
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
      getTableData();
    });
  }

  void cancelUpdate() {
    setState(() {
      lockInputs = !lockInputs;
      route = DBRoute.of(cancelUpdateRoute);
      for (var key in inputRowKeys) {
        key.currentState
            ?.setState(() => (key.currentState?.locked = lockInputs));
      }
      getTableData();
    });
  }

  Future<bool> deleteRoute() async {
    int? res = await AppServices.of(context).dbs.deleteRoute(route.id);
    if (res == null || res < 1) {
      return false;
    }
    return true;
  }

  void errorPopup(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> deleteRouteDialog() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Delete Route"),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                      'Deleting this route will also delete associated ascents.'),
                  Text('Are you sure?'),
                ],
              ),
            ),
            actions: [
              OutlinedButton(
                child: const Icon(Icons.check),
                onPressed: () async {
                  bool res = await deleteRoute();
                  Navigator.of(context).pop();
                  if (res) {
                    errorPopup("Route deleted");
                    Navigator.of(context).pop();
                  } else {
                    errorPopup("Error deleting route");
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
      appBar: const ClimbingNotesAppBar(pageTitle: "Route Info"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Column(
              children: <Widget>[
                InputRow(
                  key: inputRowKeys[0],
                  label: "Rope #:",
                  initialValue: route.rope.toString(),
                  locked: lockInputs,
                  onChanged: (String? value) {
                    setState(() {
                      route.rope = stringToInt(value);
                    });
                  },
                ),
                InputRow(
                  key: inputRowKeys[1],
                  label: "Set date:",
                  initialValue: timeDisplayFromTimestampSafe(AppServices.of(context).settings.smallDateFormat, route.date),
                  locked: lockInputs,
                  onChanged: (String? value) {
                    setState(() {
                      route.date = value;
                    });
                  },
                ),
                InputRow(
                  key: inputRowKeys[2],
                  label: "Grade:",
                  initialValue:
                      RouteGrade.fromDBValues(route.grade_num, route.grade_let)
                          .toString(),
                  locked: lockInputs,
                  onChanged: (String? value) {
                    setState(() {
                      if (value == null) {
                        route.grade_num = null;
                        route.grade_let = null;
                      } else {
                        RegExpMatch? match = gradeExp.firstMatch(value);
                        route.grade_num = stringToInt(match?.namedGroup("num"));
                        route.grade_let = match?.namedGroup("let");
                      }
                    });
                  },
                ),
                DropdownRow(
                  value: RouteColor.fromString(route.color ?? ""),
                  locked: lockInputs,
                  onSelected: (RouteColor? value) {
                    setState(() {
                      route.color =
                          value == RouteColor.nocolor ? null : value?.string;
                    });
                  },
                ),
                const ClimbingNotesLabel("Notes:"),
                InputRow(
                  key: inputRowKeys[3],
                  initialValue: route.notes,
                  locked: lockInputs,
                  onChanged: (String? value) {
                    setState(() {
                      route.notes = value;
                      getTableData();
                    });
                  }
                ),
                Row(
                  children: [
                    OutlinedButton(
                      child: Icon(lockInputs ? Icons.edit : Icons.check),
                      onPressed: updateRoute,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      child: const Icon(Icons.close),
                      onPressed: lockInputs ? null : cancelUpdate,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      child: const Icon(Icons.delete),
                      onPressed: lockInputs ? deleteRouteDialog : null,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: AscentsTable(data: tableData ?? [], route: route,),
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
              heroTag: "addFloatBtn",
              onPressed: () => (
                Navigator.push(
                  context,
                  cnPageTransition(AddAscentPage(route: route)),
                ),
              ),
              tooltip: 'Add ascent',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      drawer: const ClimbingNotesDrawer(),
    );
  }
}
