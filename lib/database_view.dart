// ignore: unused_import
import 'dart:developer';
import 'package:climbing_notes/data_structures.dart';
import 'package:climbing_notes/main.dart';
import 'package:flutter/material.dart';
import 'builders.dart';

class DatabaseViewPage extends StatefulWidget {
  const DatabaseViewPage({super.key});

  @override
  State<DatabaseViewPage> createState() => _DatabaseViewState();
}

class _DatabaseViewState extends State<DatabaseViewPage> with RouteAware {
  Map<String, DatabaseTable?> tables = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppServices.of(context).robs.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPush() {
    updateTables();
    super.didPush();
  }

  Widget buildDatabaseViewTableCell(Object? cellContents) {
    return cellContents == null
        ? const Text("")
        : Text(cellContents.toString());
  }

  TableRow buildDatabaseViewTableRow(Map<String, Object?> data) {
    return TableRow(
      children:
          data.values.map(buildDatabaseViewTableCell).map(padCell).toList(),
    );
  }

  Widget buildDatabaseViewTable(DatabaseTable? table) {
    if (table == null) {
      return const Text("Didn't get table");
    }
    if (table.isEmpty) {
      return const Text("Invalid/empty table");
    }
    return Table(
      border: TableBorder.all(color: themeTextColor(context)),
      children: [
            TableRow(
                // header row
                children: table.first.keys
                    .map((header) => (Text(header)))
                    .map(padCell)
                    .toList(),
                decoration: BoxDecoration(color: contrastingSurface(context))),
          ] +
          table.map((map) => (buildDatabaseViewTableRow(map))).toList(),
    );
  }

  Widget buildDatabaseViewTables() {
    return ListView(
      children: (tables.values.map(buildDatabaseViewTable).toList()),
    );
  }

  void updateTables() async {
    List<String> tableNames = [
      "Settings",
      "sqlite_schema",
      "Routes",
      "Ascents"      
    ];
    DatabaseTable? v = await AppServices.of(context).dbs.getVersion();
    setState(() {
      tables["version"] = v;
    });
    for (int i = 0; i < tableNames.length; i++) {
      DatabaseTable? r =
          await AppServices.of(context).dbs.query(tableNames[i], 100, 0);
      setState(() {
        tables[tableNames[i]] = r;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ClimbingNotesAppBar(pageTitle: "Database View"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: buildDatabaseViewTables(),
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
              heroTag: "updateTablesBtn",
              onPressed: updateTables,
              tooltip: 'Update data',
              child: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      drawer: const ClimbingNotesDrawer(),
    );
  }
}
