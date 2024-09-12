import 'package:climbing_notes/add_ascent.dart';
import 'package:climbing_notes/main.dart';
import 'package:flutter/material.dart';
import 'builders.dart';
import 'ascents.dart';
import 'data_structures.dart';
import 'package:climbing_notes/utility.dart';

class AddRoutePage extends StatefulWidget {
  const AddRoutePage({super.key, this.providedRoute});

  final DBRoute? providedRoute;

  @override
  State<AddRoutePage> createState() => _AddRoutePageState(providedRoute);
}

class _AddRoutePageState extends State<AddRoutePage> with RouteAware {
  List<DBRoute>? matchingRoutes;
  Map<int, bool>? finishedRoutes;
  DBRoute route = DBRoute(0, "", "", null, null, null, null, null, null);
  DBAscent ascent = DBAscent(0, "", "", 0, null, null, null, null);

  _AddRoutePageState(DBRoute? providedRoute) {
    if (providedRoute != null) {
      route = providedRoute;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppServices.of(context).robs.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPush() {
    updateTableData();
    super.didPush();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didPopNext() {
    updateTableData();
    super.didPopNext();
  }

  void updateTableData() async {
    List<DBRoute>? r1 = await AppServices.of(context)
        .dbs
        .queryRoutes(AppServices.of(context).settings.dateFormat, route);
    setState(() {
      matchingRoutes = r1;
    });

    updateFinishes();
  }

  void updateFinishes() async {
    if (matchingRoutes == null) {
      return;
    }
    List<Map<String, Object?>>? r = await AppServices.of(context)
        .dbs
        .queryFinished(
            matchingRoutes?.map((route) => (route.id)).toList() ?? []);
    if (r == null) {
      return;
    }
    Map<int, bool> finishesMap = Map.fromEntries(r.map(
        (map) => (MapEntry(map["route"] as int, map["has_finished"] == 1))));
    setState(() {
      finishedRoutes = finishesMap;
    });
  }

  IconData? getFinishIcon(int routeId) {
    bool? fin = finishedRoutes?[routeId];
    if (fin == null) {
      return null;
    }
    return fin ? Icons.check : Icons.close;
  }

  TableRow buildRoutesTableRow(DBRoute data) {
    return TableRow(
      children: [
        buildRoutesTableCell(
            Text(data.rope.toString()), (context) => AscentsPage(route: data)),
        buildRoutesTableCell(
            Text(timeDisplayFromTimestamp(
                AppServices.of(context).settings.dateFormat, data.date)),
            (context) => AscentsPage(route: data)),
        buildRoutesTableCell(
            Text(RouteGrade.fromDBValues(data.grade_num, data.grade_let)
                .toString()),
            (context) => AscentsPage(route: data)),
        buildRoutesTableCell(
            Text(RouteColor.fromString(data.color ?? "").string),
            (context) => AscentsPage(route: data)),
        buildRoutesTableCell(Icon(getFinishIcon(data.id)),
            (context) => AscentsPage(route: data)),
        InkWell(
          onTap: () => {
            Navigator.pop(context),
            Navigator.push(
              context,
              cnPageTransition(AddAscentPage(route: data)),
            ),
          },
          child: const Icon(Icons.add),
        )
      ].map(padCell).toList(),
    );
  }

  Widget buildRoutesTableCell(
      Widget cellContents, Widget Function(BuildContext)? navBuilder) {
    return InkWell(
      child: cellContents,
      onTap: () => {
        if (navBuilder == null)
          {() => ()}
        else
          {
            Navigator.pop(context),
            Navigator.push(
              context,
              MaterialPageRoute(builder: navBuilder),
            )
          }
      },
    );
  }

  Table buildRoutesTable() {
    return Table(
      border: TableBorder.all(color: themeTextColor(context)),
      children: [
            TableRow(
                // header row
                children: <Widget>[
                  const Text("Rope #"),
                  const Text("Set date"),
                  const Text("Grade"),
                  const Text("Color"),
                  const Text("Finished"),
                  const Text("Ascent"),
                ].map(padCell).toList(),
                decoration: BoxDecoration(color: contrastingSurface(context))),
          ] +
          (matchingRoutes?.map(buildRoutesTableRow).toList() ?? []),
    );
  }

  void errorPopup(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void submitRoute() async {
    String timestamp = getTimestamp();
    route.created = timestamp;
    route.updated = timestamp;
    ascent.created = timestamp;
    ascent.updated = timestamp;
    ascent.date = timestamp;

    if (route.rope == null) {
      errorPopup("Invalid rope #.");
      return;
    }
    if (route.color == null || route.color == RouteColor.nocolor.string) {
      errorPopup("Invalid color.");
      return;
    }
    if (route.grade_num == null) {
      errorPopup("Invalid grade.");
      return;
    }

    DateTime? likelySetDate;
    String? canBePromoted = route.date;
    if (canBePromoted == null) {
      errorPopup("Date is not set.");
      return;
    }
    likelySetDate = likelyTimeFromTimeDisplay(
        AppServices.of(context).settings.dateFormat, canBePromoted);
    if (likelySetDate == null) {
      errorPopup("Invalid date.");
      return;
    }

    if (likelySetDate.isAfter(DateTime.now())) {
      errorPopup("Date cannot be in the future.");
      return;
    }

    route.date = likelySetDate.toUtc().toIso8601String();

    int? insertResult = await AppServices.of(context).dbs.routeInsert(route);
    if (insertResult == null) {
      errorPopup("Route already exists");
      return;
    }
    ascent.route = insertResult;

    if (ascent.finished != null || ascent.rested != null) {
      AppServices.of(context).dbs.ascentInsert(ascent);
    }

    clearData();
    Navigator.pop(context);
  }

  void clearData() {
    setState(() {
      route.clear();
      ascent.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ClimbingNotesAppBar(pageTitle: "Add Route"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Column(
              children: <Widget>[
                InputRow(label: "Rope #:",
                    inputType: TextInputType.datetime,
                    initialValue: route.rope?.toString(),
                    onChanged: (String? value) {
                  setState(() {
                    route.rope = stringToInt(value);
                    updateTableData();
                  });
                }),
                InputRow(label: "Set date:",
                    inputType: TextInputType.datetime,
                    initialValue: route.date, onChanged: (String? value) {
                  setState(() {
                    route.date = value;
                    updateTableData();
                  });
                }),
                InputRow(label: "Grade:",
                    inputType: TextInputType.text,
                    initialValue:
                        "${route.grade_num ?? ""}${route.grade_let ?? ""}",
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
                    updateTableData();
                  });
                }),
                DropdownRow(
                  initialValue: RouteColor.fromString(route.color ?? ""),
                  onSelected: (RouteColor? value) {
                    setState(() {
                      route.color =
                          value == RouteColor.nocolor ? null : value?.string;
                      updateTableData();
                    });
                  },
                ),
                const ClimbingNotesLabel("Route notes:"),
                const InputRow(),
                CheckboxRow(
                  "Finished:",
                  "Rested:",
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
                const InputRow(),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    child: buildRoutesTable(),
                  ),
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
                clearData(),
                Navigator.pop(context),
              },
              tooltip: 'Back',
              child: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: "submitFloatBtn",
              onPressed: submitRoute,
              tooltip: 'Submit',
              child: const Icon(Icons.check),
            ),
          ],
        ),
      ),
      drawer: const ClimbingNotesDrawer(),
    );
  }
}
