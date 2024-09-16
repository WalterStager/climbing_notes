import 'package:climbing_notes/main.dart';
import 'package:climbing_notes/utility.dart';
import 'package:climbing_notes/add_route.dart';
import 'package:flutter/material.dart';
import 'builders.dart';
import 'data_structures.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> with RouteAware {
  DBRoute queryInfo = DBRoute(0, "", "", null, null, null, null, null, null);
  List<GlobalKey<InputRowState>> inputRowKeys = [GlobalKey<InputRowState>(), GlobalKey<InputRowState>(), GlobalKey<InputRowState>()];
  List<DBRoute>? matchingRoutes;
  List<DBRouteExtra>? routeExtras;

  _RoutesPageState();

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
    List<DBRoute>? r = await AppServices.of(context).dbs.queryRoutes(AppServices.of(context).settings.smallDateFormat, queryInfo);

    setState(() {
      matchingRoutes = r;
    });

    updateFinishes();
  }

  void updateFinishes() async {
    if (matchingRoutes == null) {
      return;
    }
    List<DBRouteExtra>? r = await AppServices.of(context)
        .dbs
        .queryExtra(
            matchingRoutes?.map((route) => (route.id)).toList() ?? []);
    if (r == null) {
      return;
    }
    setState(() {
      routeExtras = r;
    });
  }

  void clearData() {
    setState(() {
      queryInfo.clear();
      for (var key in inputRowKeys) {
        key.currentState?.controller.clear();
      }
      updateTableData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ClimbingNotesAppBar(pageTitle: "Route Search"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Column(
              children: <Widget>[
                InputRow(
                  key: inputRowKeys[0],
                  label: "Rope #:",
                  inputType: TextInputType.datetime,
                    onChanged: (String? value) {
                  setState(() {
                    queryInfo.rope = stringToInt(value);
                    updateTableData();
                  });
                }),
                InputRow(
                  key: inputRowKeys[1],
                  label: "Set date:",
                  inputType: TextInputType.datetime,
                    onChanged: (String? value) {
                  setState(() {
                    queryInfo.date = value;
                    updateTableData();
                  });
                }),
                InputRow(
                  key: inputRowKeys[2],
                  label: "Grade:",
                  inputType: TextInputType.text,
                    onChanged: (String? value) {
                  setState(() {
                    if (value == null) {
                      queryInfo.grade_num = null;
                      queryInfo.grade_let = null;
                    } else {
                      RegExpMatch? match = gradeExp.firstMatch(value);
                      queryInfo.grade_num =
                          stringToInt(match?.namedGroup("num"));
                      queryInfo.grade_let = match?.namedGroup("let");
                    }
                    updateTableData();
                  });
                }),
                DropdownRow(
                    value: RouteColor.fromString(queryInfo.color ?? ""),
                    onSelected: (RouteColor? value) {
                      setState(() {
                        queryInfo.color =
                            value == RouteColor.nocolor ? null : value?.string;
                        updateTableData();
                      });
                    },
                  ),
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
              heroTag: "clearFloatBtn",
              onPressed: clearData,
              tooltip: 'Clear',
              child: const Icon(Icons.clear),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: "addFloatBtn",
              onPressed: () => (
                Navigator.push(
                  context,
                  cnPageTransition(AddRoutePage(providedRoute: DBRoute.of(queryInfo))),
                ),
              ),
              tooltip: 'Add route',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      drawer: const ClimbingNotesDrawer(),
    );
  }
}