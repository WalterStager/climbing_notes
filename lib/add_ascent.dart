import 'package:climbing_notes/main.dart';
import 'package:flutter/material.dart';
import 'builders.dart';
import 'data_structures.dart';
import 'package:climbing_notes/utility.dart';

class AddAscentPage extends StatefulWidget {
  const AddAscentPage({super.key, required this.route});

  final DBRoute route;

  @override
  State<AddAscentPage> createState() => _AddAscentPageState(route);
}

class _AddAscentPageState extends State<AddAscentPage> with RouteAware {
  DBRoute route;
  List<DBAscent>? tableData;
  DBAscent ascent = DBAscent(0, "", "", "", null, null, null, null);

  _AddAscentPageState(this.route);

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

  void submitAscent() {
    String timestamp = getTimestamp();
    ascent.created = timestamp;
    ascent.updated = timestamp;
    ascent.route = route.id;

    if (ascent.finished == null && ascent.rested == null) {
      return;
    }
    ascent.date = timestamp;

    AppServices.of(context).dbs.ascentInsert(ascent);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Add Ascent"),
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
                  "Route notes:",
                ),
                buildLockedNotes(
                  context,
                  route.notes ?? "",
                ),
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
                buildLabel(context, "Ascent notes:"),
                buildNotes(context),
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
              heroTag: "submitFloatBtn",
              onPressed: submitAscent,
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
