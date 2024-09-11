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
  List<DBAscent>? tableData;

  _AscentsPageState(this.route);

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

  TableRow buildAscentsTableRow(DBAscent data) {
    return TableRow(
      children: [
        buildAscentsTableCell(Text(timeDisplayFromTimestamp(data.date)), null),
        buildAscentsTableCell(
            Icon(intToBool(data.finished) ?? false ? Icons.check : Icons.close),
            null),
        buildAscentsTableCell(
            Icon(intToBool(data.rested) ?? false ? Icons.check : Icons.close),
            null),
        buildAscentsTableCell(Text(data.notes ?? ""), null),
      ].map(padCell).toList(),
    );
  }

  Widget buildAscentsTableCell(
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

  Table buildAscentsTable() {
    return Table(
      border: TableBorder.all(color: themeTextColor(context)),
      children: [
            TableRow(
                // header row
                children: <Widget>[
                  const Text("Date"),
                  const Text("Finished"),
                  const Text("Rested"),
                  const Text("Notes"),
                ].map(padCell).toList(),
                decoration: BoxDecoration(color: contrastingSurface(context))),
          ] +
          (tableData?.map(buildAscentsTableRow).toList() ?? []),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Ascents"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Column(
              children: <Widget>[
                buildLockedInputRow(
                  context,
                  "Rope #:",
                  route.rope.toString(),
                ),
                buildLockedInputRow(
                  context,
                  "Set date:",
                  timeDisplayFromTimestamp(route.date),
                ),
                buildLockedInputRow(
                  context,
                  "Grade:",
                  RouteGrade.fromDBValues(route.grade_num, route.grade_let)
                      .toString(),
                ),
                buildLockedDropdownRow(
                  context,
                  RouteColor.fromString(route.color ?? ""),
                ),
                buildLabel(
                  context,
                  "Notes:",
                ),
                buildLockedNotes(
                  context,
                  route.notes ?? "",
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    child: buildAscentsTable(),
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
              heroTag: "addFloatBtn",
              onPressed: () => (Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AddAscentPage(route: route)))),
              tooltip: 'Add ascent',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      drawer: buildDrawer(context),
    );
  }
}
