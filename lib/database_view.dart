import 'dart:developer';

import 'package:climbing_notes/database.dart';
import 'package:flutter/material.dart';
import 'builders.dart';

class DatabaseViewPage extends StatefulWidget {
  const DatabaseViewPage({super.key});

  @override
  State<DatabaseViewPage> createState() => _DatabaseViewState();
}

class _DatabaseViewState extends State<DatabaseViewPage> {
  DatabaseService db = DatabaseService.db;

  Widget buildDatabaseViewTableCell(Object? cellContents) {
    return cellContents == null ? const Text("") : Text(cellContents.toString());
  }

  TableRow buildDatabaseViewTableRow(List<Object?> data) {
    return TableRow(
      children: data.map(buildDatabaseViewTableCell).map(padCell).toList(),
    );
  }

  Table buildDatabaseViewTable(List<String> headers, List<List<Object?>> data) {
    log("headers ${headers.length}");
    data.map((list) => (log("  list ${list.length}"))).toList();

    return Table(
      border: TableBorder.all(color: themeTextColor(context)),
      children: [
        TableRow( // header row
          children: headers.map((header) => (Text(header))).map(padCell).toList(),
          decoration: BoxDecoration(color: contrastingSurface(context))
        ),
      ] + data.map((list) => (buildDatabaseViewTableRow(list))).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Database View"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            buildDatabaseViewTable(["id", "created", "updated", "rope", "date", "color", "num", "let", "notes"], db.queryRecentlyUpdated("Routes", 100, 0)),
            buildDatabaseViewTable(["id", "created", "updated", "route", "date", "finished", "rested", "notes"], db.queryRecentlyUpdated("Ascents", 100, 0)),
          ],
        ),
      ),
      // floatingActionButton: buildfloatingActionButtons(context, backButton: true),
      drawer: buildDrawer(context),
    );
  }
}
