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
  DBAscent ascent = DBAscent(0, "", "", 0, null, null, null, null);

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
      appBar: const ClimbingNotesAppBar(pageTitle: "Add Ascent"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Column(
              children: <Widget>[
                InputRow(
                  label: "Rope #:",
                  initialValue: route.rope.toString(),
                  locked: true,
                ),
                InputRow(
                  label: "Set date:",
                  initialValue: timeDisplayFromTimestamp(AppServices.of(context).settings.smallDateFormat, route.date),
                  locked: true,
                ),
                InputRow(
                  label: "Grade:",
                  initialValue: RouteGrade.fromDBValues(route.grade_num, route.grade_let)
                      .toString(),
                  locked: true,
                ),
                DropdownRow(
                  value: RouteColor.fromString(route.color ?? ""),
                  locked: true,
                ),
                const ClimbingNotesLabel("Route notes:"),
                InputRow(
                  initialValue: route.notes ?? "",
                  locked: true),
                const Divider(),
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
                      getTableData();
                    });
                  },
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
              heroTag: "submitFloatBtn",
              onPressed: submitAscent,
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
