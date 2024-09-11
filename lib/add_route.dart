import 'package:climbing_notes/add_ascent.dart';
import 'package:climbing_notes/main.dart';
import 'package:flutter/material.dart';
import 'builders.dart';
import 'ascents.dart';
import 'data_structures.dart';
import 'package:climbing_notes/utility.dart';

class AddRoutePage extends StatefulWidget {
  const AddRoutePage({super.key});

  @override
  State<AddRoutePage> createState() => _AddRoutePageState();
}

class _AddRoutePageState extends State<AddRoutePage> with RouteAware {
  List<DBRoute>? matchingRoutes;
  DBRoute route = DBRoute("", "", "", null, null, null, null, null, null);
  DBAscent ascent = DBAscent(0, "", "", "", null, null, null, null);

  _AddRoutePageState();

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
    List<DBRoute>? r1 = await AppServices.of(context).dbs.queryRoutes(route);
    setState(() {
      matchingRoutes = r1;
    });
  }

  TableRow buildRoutesTableRow(DBRoute data) {
    return TableRow(
      children: [
        buildRoutesTableCell(
            Text(data.rope.toString()), (context) => AscentsPage(route: data)),
        buildRoutesTableCell(Text(timeDisplayFromTimestamp(data.date)),
            (context) => AscentsPage(route: data)),
        buildRoutesTableCell(
            Text(RouteGrade.fromDBValues(data.grade_num, data.grade_let)
                .toString()),
            (context) => AscentsPage(route: data)),
        buildRoutesTableCell(
            Text(RouteColor.fromString(data.color ?? "").string),
            (context) => AscentsPage(route: data)),
        // buildRoutesTableCell(Icon(data.finished ? Icons.check : Icons.close),
        //     (context) => AscentsPage(route: data)),
        InkWell(
          onTap: () => {
            Navigator.pop(context),
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddAscentPage(route: data))),
          },
          child: const Icon(Icons.add_box_rounded),
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
                  // Text("Finished"),
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

  void submitRoute() {
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
      errorPopup("Invalid grade");
      return;
    }

    DateTime? likelySetDate;
    String? canBePromoted = route.date;
    if (canBePromoted == null) {
      errorPopup("Date is null.");
      return;
    }
    likelySetDate = likelyTimeFromTimeDisplay(canBePromoted);
    if (likelySetDate == null) {
      errorPopup("Could not get likely date.");
      return;
    }

    route.date = likelySetDate.toUtc().toIso8601String();

    route.id = "${route.rope}+${route.date}";
    ascent.route = route.id;
    AppServices.of(context).dbs.routeInsert(route);

    if (ascent.finished != null || ascent.rested != null) {
      AppServices.of(context).dbs.ascentInsert(ascent);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Add Route"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Column(
              children: <Widget>[
                buildInputRow(context, "Rope #:",
                    inputType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputCallback: (String? value) {
                  setState(() {
                    route.rope = stringToInt(value);
                    updateTableData();
                  });
                }),
                buildInputRow(context, "Set date:",
                    inputType: TextInputType.datetime,
                    inputCallback: (String? value) {
                  setState(() {
                    route.date = value;
                    updateTableData();
                  });
                }),
                buildInputRow(context, "Grade:",
                    inputType: TextInputType.text,
                    inputCallback: (String? value) {
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
                buildDropdownRow(
                    context, RouteColor.fromString(route.color ?? ""),
                    (RouteColor? value) {
                  setState(() {
                    route.color =
                        value == RouteColor.nocolor ? null : value?.string;
                    updateTableData();
                  });
                }),
                buildLabel(
                  context,
                  "Route notes:",
                ),
                buildNotes(context),
                buildCheckboxRow(
                  context,
                  intToBool(ascent.finished) ?? false,
                  intToBool(ascent.rested) ?? false,
                  (newValue) {
                    setState(
                      () => (ascent.finished = boolToInt(newValue)),
                    );
                  },
                  (newValue) {
                    setState(
                      () => (ascent.rested = boolToInt(newValue)),
                    );
                  },
                ),
                buildLabel(
                  context,
                  "Ascent notes:",
                ),
                buildNotes(context),
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
      drawer: buildDrawer(context),
    );
  }
}
