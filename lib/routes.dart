import 'package:climbing_notes/main.dart';
import 'package:climbing_notes/utility.dart';
import 'package:climbing_notes/add_ascent.dart';
import 'package:climbing_notes/add_route.dart';
import 'package:flutter/material.dart';
import 'ascents.dart';
import 'builders.dart';
import 'data_structures.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> with RouteAware {
  DBRoute queryInfo = DBRoute("", "", "", null, null, null, null, null, null);
  List<DBRoute>? matchingRoutes;

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
    List<DBRoute>? r1 = await AppServices.of(context).dbs.queryRoutes(queryInfo);
    setState(() {
      matchingRoutes = r1;
    });
  }

  TableRow buildRoutesTableRow(DBRoute data) {
    return TableRow(
      children: [
        buildRoutesTableCell(
            Text(data.rope.toString()), (context) => AscentsPage(route: data)),
        buildRoutesTableCell(
            Text(timeDisplayFromTimestamp(data.date)), (context) => AscentsPage(route: data)),
        buildRoutesTableCell(
            Text(RouteGrade.fromDBValues(data.grade_num, data.grade_let).toString()), (context) => AscentsPage(route: data)),
        buildRoutesTableCell(
            Text(RouteColor.fromString(data.color ?? "").string), (context) => AscentsPage(route: data)),
        // buildRoutesTableCell(Icon(data.finished ? Icons.check : Icons.close),
        //     (context) => AscentsPage(route: data)),
        InkWell(
          onTap: () => (Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddAscentPage(route: data)))),
          child: const Icon(Icons.add_box_rounded),
        )
      ].map(padCell).toList(),
    );
  }

  Widget buildRoutesTableCell(
      Widget cellContents, Widget Function(BuildContext)? navBuilder) {
    return InkWell(
      child: cellContents,
      onTap: () => navBuilder == null
          ? () => ()
          : Navigator.push(
              context,
              MaterialPageRoute(builder: navBuilder),
            ),
    );
  }

  Table buildRoutesTable() {
    return Table(
      border: TableBorder.all(color: themeTextColor(context)),
      children: [
            TableRow(
                // header row
                children: <Widget>[
                  Text("Rope #"),
                  Text("Set date"),
                  Text("Grade"),
                  Text("Color"),
                  // Text("Finished"),
                  Text("Ascent"),
                ].map(padCell).toList(),
                decoration: BoxDecoration(color: contrastingSurface(context))),
          ] +
          (matchingRoutes?.map(buildRoutesTableRow).toList() ?? []),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Routes"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Container(
              child: Column(
                children: <Widget>[
                  buildInputRow(context, "Rope #:",
                      inputType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputCallback: (String? value) {
                    setState(() {
                      queryInfo.rope = stringToInt(value);
                      updateTableData();
                    });
                  }),
                  buildInputRow(context, "Set date:",
                      inputType: TextInputType.datetime,
                      inputCallback: (String? value) {
                    setState(() {
                      queryInfo.date = value;
                      updateTableData();
                    });
                  }),
                  buildInputRow(context, "Grade:",
                      inputType: TextInputType.text,
                      inputCallback: (String? value) {
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
                  buildDropdownRow(
                      context, RouteColor.fromString(queryInfo.color ?? ""),
                      (RouteColor? value) {
                    setState(() {
                      queryInfo.color =
                          value == RouteColor.nocolor ? null : value?.string;
                      updateTableData();
                    });
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      child: buildRoutesTable(),
                    ),
                  ),
                ],
              ),
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
              heroTag: "addFloatBtn",
              onPressed: () => (Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddRoutePage()))),
              tooltip: 'Add route',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      drawer: buildDrawer(context),
    );
  }
}
