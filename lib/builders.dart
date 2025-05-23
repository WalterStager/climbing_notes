// ignore: unused_import
import 'dart:developer';
import 'package:climbing_notes/ascent_page.dart';
import 'package:climbing_notes/route_page.dart';
import 'package:climbing_notes/add_route.dart';
import 'package:climbing_notes/data_structures.dart';
import 'package:climbing_notes/main.dart';
import 'package:climbing_notes/settings.dart';
import 'package:climbing_notes/utility.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:page_transition/page_transition.dart';

const EdgeInsetsGeometry paddingAroundInputBox =
    EdgeInsets.only(top: 4.0, bottom: 4.0);
const EdgeInsetsGeometry paddingInsideInputBox = EdgeInsets.only(left: 8.0);
const Duration pageTransitionDuration = Duration(milliseconds: 200);
const Duration pageTransitionReverseDuration = Duration(milliseconds: 100);

PageTransition<dynamic> cnPageTransition(Widget child) {
  return PageTransition(
    duration: pageTransitionDuration,
    reverseDuration: pageTransitionReverseDuration,
    type: PageTransitionType.leftToRight,
    child: child,
  );
}

class ClimbingNotesDrawer extends StatelessWidget {
  const ClimbingNotesDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                border: const Border(bottom: BorderSide(width: 3.0))),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  SizedBox(height: 50, width: 50, child: getThemeIcon(context)),
                  Text("Climbing Notes",
                      style: TextStyle(
                          fontSize:
                              Theme.of(context).textTheme.titleLarge?.fontSize,
                          color: contrastingThemeTextColor(context))),
                ],
              ),
            ),
          ),
          InkWell(
            child: ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Routes"),
              onTap: () => (Navigator.popUntil(
                context,
                ModalRoute.withName('/'),
              )),
            ),
          ),
          InkWell(
            child: ListTile(
              leading: const Icon(Icons.add),
              title: const Text("Add route"),
              onTap: () => {
                Navigator.pop(context),
                Navigator.push(
                  context,
                  cnPageTransition(const AddRoutePage()),
                ),
              },
            ),
          ),
          InkWell(
            child: ListTile(
              leading: const Icon(Icons.file_copy),
              title: const Text("Add route from file"),
              onTap: () async {
                DBRoute? ocrRes =
                    await AppServices.of(context).ocr.filePickerOcrAdd(context, ImageSource.gallery);
                Navigator.pop(context);
                if (ocrRes != null) {
                  Navigator.push(
                    context,
                    cnPageTransition(AddRoutePage(providedRoute: ocrRes)),
                  );
                }
              },
            ),
          ),
          InkWell(
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () => {
                Navigator.pop(context),
                Navigator.push(
                  context,
                  cnPageTransition(const SettingsPage()),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ClimbingNotesScaffold extends StatelessWidget {
  final Widget body;
  final String pageTitle;
  final Widget floatingActionButton;

  const ClimbingNotesScaffold(this.pageTitle, {required this.body, required this.floatingActionButton, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ClimbingNotesDrawer(),
      appBar: ClimbingNotesAppBar(pageTitle: pageTitle),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class ClimbingNotesAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String pageTitle;
  @override
  final Size preferredSize;

  const ClimbingNotesAppBar({super.key, required this.pageTitle})
      : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  State<ClimbingNotesAppBar> createState() => _ClimbingNotesAppBarState(pageTitle: pageTitle);
}

class _ClimbingNotesAppBarState extends State<ClimbingNotesAppBar> {
  final String pageTitle;
  @override

  _ClimbingNotesAppBarState({required this.pageTitle});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      actionsIconTheme:
          IconThemeData(color: contrastingThemeTextColor(context)),
      iconTheme: IconThemeData(color: contrastingThemeTextColor(context)),
      title: Text(pageTitle,
          style: TextStyle(color: contrastingThemeTextColor(context))),
      actions: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
                value: "toprope",
                label: Text("Top Rope")),
            ButtonSegment(
                value: "lead",
                label: Text("Lead")),
          ],
          selected: { AppServices.of(context).settings.defaultStyleSwitchValue },
          onSelectionChanged: (set) => setState(() {
              AppServices.of(context).settings.defaultStyleSwitchValue = set.first;
              saveSettings(context);
          }),
        ),
      ]
    );
  }
}

// gets a color which is
//    a little bit darker than surface in light theme
//    a little bit lighter than surface in dark theme
Color contrastingSurface(BuildContext context) {
  Color surface = Theme.of(context).colorScheme.surface;
  const modifier = 50;
  if (Theme.of(context).colorScheme.brightness == Brightness.light) {
    return Color.fromARGB(
      surface.alpha,
      (surface.red - modifier).clamp(0, 255),
      (surface.green - modifier).clamp(0, 255),
      (surface.blue - modifier).clamp(0, 255),
    );
  } else {
    return Color.fromARGB(
      surface.alpha,
      (surface.red + modifier).clamp(0, 255),
      (surface.green + modifier).clamp(0, 255),
      (surface.blue + modifier).clamp(0, 255),
    );
  }
}

// inverted for now, since I'm using icon against theme primary color rather than surface
Image getThemeIcon(BuildContext context) {
  if (Theme.of(context).colorScheme.brightness == Brightness.dark) {
    return Image.asset("icon.png");
  } else {
    return Image.asset("icon_inv.png");
  }
}

// returns a textcolor that contrasts against theme surface color (hopefully)
Color themeTextColor(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return ThemeData.dark().textTheme.bodyMedium?.color ?? Colors.white;
  } else {
    return ThemeData.light().textTheme.bodyMedium?.color ?? Colors.black;
  }
}

// returns a textcolor that contrasts against theme primary color (hopefully)
Color contrastingThemeTextColor(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.light) {
    return ThemeData.dark().textTheme.bodyMedium?.color ?? Colors.white;
  } else {
    return ThemeData.light().textTheme.bodyMedium?.color ?? Colors.black;
  }
}

Color disabledThemeTextColor(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.light) {
    return ThemeData.dark().textTheme.titleMedium?.color?.withOpacity(0.38) ?? Colors.grey;
  } else {
    return ThemeData.light().textTheme.titleMedium?.color?.withOpacity(0.38) ?? Colors.grey;
  }
}

class DropdownRow extends StatelessWidget {
  final RouteColor value;
  final Function(RouteColor?)? onSelected;
  final bool? locked;

  const DropdownRow(
      {super.key, required this.value, this.locked, this.onSelected});

  DropdownMenuItem<RouteColor> makeMenuEntry(RouteColor rc) {
    return DropdownMenuItem(
      value: rc,
      child: Text(rc.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<RouteColor>>? itemss = RouteColor.values
        .map<DropdownMenuItem<RouteColor>>(makeMenuEntry)
        .toList();

    return Padding(
      padding: paddingAroundInputBox,
      child: Row(
        children: [
          Text(
            "Color:",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Padding(
            padding: paddingInsideInputBox,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: (locked ?? false)
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<RouteColor>(
                  items: itemss,
                  onChanged: (locked ?? false) ? null : onSelected,
                  value: value,
                  padding: paddingInsideInputBox,
                  style: Theme.of(context).textTheme.bodyLarge,
                  icon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: (locked ?? false)
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InputRow extends StatefulWidget {
  final String? label;
  final TextInputType? inputType;
  final int? maxLength;
  final ValueChanged<String?>? onChanged;
  final String? initialValue;
  final bool? locked;
  // final Function(InputRowState) callback;

  const InputRow(
      {super.key,
      this.label,
      this.inputType,
      this.maxLength,
      this.onChanged,
      this.initialValue,
      this.locked});

  @override
  State<StatefulWidget> createState() => InputRowState(
        label: label,
        inputType: inputType,
        maxLength: maxLength,
        onChanged: onChanged,
        initialValue: initialValue,
        locked: locked,
      );
}

class InputRowState extends State<StatefulWidget> {
  String? label;
  TextInputType? inputType;
  int? maxLength;
  ValueChanged<String?>? onChanged;
  String? initialValue;
  TextEditingController controller;
  bool? locked;

  InputRowState(
      {this.label,
      this.inputType,
      this.maxLength,
      this.onChanged,
      this.initialValue,
      this.locked})
      : controller = TextEditingController(text: initialValue);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: paddingAroundInputBox,
      child: Row(
        children: [
          if (label != null)
            Text(
              label ?? "",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          Expanded(
            child: Padding(
              padding:
                  (label != null ? paddingInsideInputBox : EdgeInsets.zero),
              child: TextField(
                enabled: !(locked ?? false),
                readOnly: (locked ?? false),
                controller: controller,
                onChanged: onChanged,
                maxLength: maxLength,
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(
                        top: 4, bottom: 4, left: 8, right: 8),
                    border: const OutlineInputBorder(),
                    disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).disabledColor))),
                keyboardType: inputType ?? TextInputType.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClimbingNotesLabel extends StatelessWidget {
  final String text;

  const ClimbingNotesLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Row(
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}

class CheckboxRow extends StatelessWidget {
  final String label1;
  final String label2;
  final bool? initialValue1;
  final bool? initialValue2;
  final ValueChanged<bool?>? onChanged1;
  final ValueChanged<bool?>? onChanged2;
  final bool? locked;

  const CheckboxRow(this.label1, this.label2,
      {super.key,
      this.initialValue1,
      this.initialValue2,
      this.onChanged1,
      this.onChanged2,
      this.locked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 0),
      child: Row(
        children: [
          Text(
            label1,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Checkbox(
            value: initialValue1,
            side: (locked ?? false)
                ? BorderSide(color: Theme.of(context).disabledColor)
                : null,
            onChanged: (locked ?? false) ? null : onChanged1,
          ),
          Text(
            label2,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Checkbox(
              value: initialValue2,
              side: (locked ?? false)
                  ? BorderSide(color: Theme.of(context).disabledColor)
                  : null,
              onChanged: (locked ?? false) ? null : onChanged2),
        ],
      ),
    );
  }
}

class RoutesTableWithExtra extends StatelessWidget {
  final List<DBRouteExtra> data;

  const RoutesTableWithExtra({super.key, required this.data});

  Widget buildInkwell(
      BuildContext context, DBRouteExtra rowData, Widget child) {
    return TableRowInkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AscentsPage(route: DBRoute.fromExtra(rowData))));
      },
      child: child,
    );
  }

  Widget buildRouteFinishedIcon(BuildContext context, bool fin, bool finWithoutRest) {
    Color iconColor = themeTextColor(context);
    if (fin && finWithoutRest) {
      return Stack(
        children: [
          Icon(Icons.check, color: iconColor),
          Positioned(
            left: 5,
            child: Icon(Icons.check, color: iconColor),
          )
        ],
      );
    }
    return Align(
      alignment: Alignment.topLeft,
      child: Icon(fin ? Icons.check : null, color: iconColor),
    );
  }


  @override
  Widget build(BuildContext context) {
    List<TableRow> rows = [
      TableRow(
        // header row
        children: <Widget>[
          const Text("Rope #"),
          const Text("Set date"),
          const Text("Grade"),
          const Text("Color"),
          const Text("Finished"),
          const Text("Last ascent"),
        ].map(padCell).toList(),
        decoration: BoxDecoration(color: contrastingSurface(context)),
      ),
    ];

    rows.addAll(data.map((DBRouteExtra rowData) {
      return TableRow(
        children: <Widget>[
          buildInkwell(context, rowData, Text(rowData.rope.toString())),
          buildInkwell(
              context,
              rowData,
              Text(timeDisplayFromDateTime(
                  AppServices.of(context).settings.smallDateFormat,
                  rowData.date))),
          buildInkwell(context, rowData, Text(rowData.grade.toString())),
          buildInkwell(context, rowData, Text(rowData.color.toString())),
          buildInkwell(context, rowData, buildRouteFinishedIcon(context, rowData.finished ?? false, rowData.finWithoutRest ?? false)),
          buildInkwell(
              context,
              rowData,
              Text(timeDisplayFromDateTime(
                  AppServices.of(context).settings.smallDateFormat,
                  rowData.lastAscentDate))),
        ].map(padCell).toList(),
      );
    }));

    return Table(
        border: TableBorder.all(color: themeTextColor(context)),
        children: rows);
  }
}

class AscentsTable extends StatelessWidget {
  final List<DBAscent> data;
  final DBRoute route;

  const AscentsTable({super.key, required this.route, required this.data});

  Widget buildInkwell(BuildContext context, DBAscent rowData, Widget child) {
    return TableRowInkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AscentPage(providedRoute: route, providedAscent: rowData)));
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<TableRow> rows = [
      TableRow(
        // header row
        children: <Widget>[
          const Text("Date"),
          const Text("Finished"),
          const Text("Rested"),
          const Text("Style"),
          const Text("Notes"),
        ].map(padCell).toList(),
        decoration: BoxDecoration(color: contrastingSurface(context)),
      ),
    ];

    rows.addAll(data.map((DBAscent rowData) {
      return TableRow(
        children: <Widget>[
          buildInkwell(
              context,
              rowData,
              Text(timeDisplayFromTimestampSafe(
                  AppServices.of(context).settings.smallDateFormat,
                  rowData.date))),
          buildInkwell(
              context,
              rowData,
              Icon(
                  (intToBool(rowData.finished) ?? false) ? Icons.check : null)),
          buildInkwell(context, rowData,
              Icon((intToBool(rowData.rested) ?? false) ? Icons.check : null)),
          buildInkwell(context, rowData,
              Text(routeStyleToString(rowData.style))), 
          buildInkwell(context, rowData, Text(rowData.notes ?? "")),
        ].map(padCell).toList(),
      );
    }));

    return Table(
        border: TableBorder.all(color: themeTextColor(context)),
        children: rows);
  }
}

Padding padCell(Widget cellContents) {
  return Padding(
    padding: const EdgeInsets.only(left: 3.0),
    child: cellContents,
  );
}


Future<T?> modalBottomPopup<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet(
    context: context,
    builder: builder,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color: contrastingSurface(context), width: 1)),
    isDismissible: true,
    enableDrag: false,
    showDragHandle: false,
    isScrollControlled: false,
  );
}