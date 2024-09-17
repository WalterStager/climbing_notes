import 'package:climbing_notes/main.dart';
import 'package:flutter/material.dart';
import 'builders.dart';
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
  List<DBRouteExtra>? routeExtras;
  DBRoute route = DBRoute(0, "", "", null, null, null, null, null, null);
  DBAscent ascent = DBAscent(0, "", "", 0, null, null, null, null);
  bool addAscent = false;

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
        .queryRoutes(AppServices.of(context).settings.smallDateFormat, route);
    setState(() {
      matchingRoutes = r1;
    });

    updateFinishes();
  }

  void updateFinishes() async {
    if (matchingRoutes == null) {
      return;
    }
    List<DBRouteExtra>? r = await AppServices.of(context)
        .dbs
        .queryExtra(matchingRoutes?.map((route) => (route.id)).toList() ?? []);
    if (r == null) {
      return;
    }
    setState(() {
      routeExtras = r;
    });
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
    if (route.gradeNum == null) {
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

    int? insertResult = await AppServices.of(context).dbs.routeInsert(route);
    if (insertResult == null) {
      errorPopup("Route already exists");
      return;
    }
    ascent.route = insertResult;

    if (addAscent) {
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

  Widget ascentSection() {
    if (!addAscent) {
      return Row(
        children: [
          FittedBox(
            child: OutlinedButton(
              child: const Row(
                children: [
                  Icon(Icons.add),
                  Text("Also add ascent"),
                ],
              ),
              onPressed: () => (setState(() => (addAscent = true))),
            ),
          ),
        ],
      );
    } else {
      return Column(children: [
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
        InputRow(
          inputType: TextInputType.text,
          initialValue: ascent.notes ?? "",
          onChanged: (String? value) {
            setState(() {
              ascent.notes = value;
              updateTableData();
            });
          },
        )
      ]);
    }
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
                InputRow(
                    label: "Rope #:",
                    inputType: TextInputType.datetime,
                    initialValue: route.rope?.toString(),
                    onChanged: (String? value) {
                      setState(() {
                        route.rope = stringToInt(value);
                        updateTableData();
                      });
                    }),
                InputRow(
                    label: "Set date:",
                    inputType: TextInputType.datetime,
                    initialValue: timeDisplayFromTimestampSafe(
                        AppServices.of(context).settings.smallDateFormat,
                        route.date),
                    onChanged: (String? value) {
                      setState(() {
                        route.date = value;
                        updateTableData();
                      });
                    }),
                InputRow(
                    label: "Grade:",
                    inputType: TextInputType.text,
                    initialValue:
                        "${route.gradeNum ?? ""}${route.gradeLet ?? ""}",
                    onChanged: (String? value) {
                      setState(() {
                        if (value == null) {
                          route.gradeNum = null;
                          route.gradeLet = null;
                        } else {
                          RegExpMatch? match = gradeExp.firstMatch(value);
                          route.gradeNum =
                              stringToInt(match?.namedGroup("num"));
                          route.gradeLet = match?.namedGroup("let");
                        }
                        updateTableData();
                      });
                    }),
                DropdownRow(
                  value: RouteColor.fromString(route.color ?? ""),
                  onSelected: (RouteColor? value) {
                    setState(() {
                      route.color =
                          value == RouteColor.nocolor ? null : value?.string;
                      updateTableData();
                    });
                  },
                ),
                const ClimbingNotesLabel("Route notes:"),
                InputRow(
                  inputType: TextInputType.text,
                  initialValue: route.notes ?? "",
                  onChanged: (String? value) {
                    setState(() {
                      route.notes = value;
                      updateTableData();
                    });
                  },
                ),
                ascentSection(),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: RoutesTableWithExtra(data: routeExtras ?? []),
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
