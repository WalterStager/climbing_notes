import 'dart:developer';

import 'package:climbing_notes/database_view.dart';
import 'package:climbing_notes/add_route.dart';
import 'package:climbing_notes/data_structures.dart';
import 'package:climbing_notes/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

const EdgeInsetsGeometry paddingAroundInputBox =
    EdgeInsets.only(top: 4.0, bottom: 4.0);
const EdgeInsetsGeometry paddingInsideInputBox = EdgeInsets.only(left: 8.0);
const Duration pageTransitionDuration = Duration(milliseconds: 500);
const Duration pageTransitionReverseDuration = Duration(milliseconds: 300);

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
          if (kDebugMode)
            InkWell(
              child: ListTile(
                leading: const Icon(Icons.account_tree_sharp),
                title: const Text("DB View"),
                onTap: () => {
                  Navigator.pop(context),
                  Navigator.push(
                    context,
                    cnPageTransition(const DatabaseViewPage()),
                  ),
                },
              ),
            ),
        ],
      ),
    );
  }
}

class ClimbingNotesAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String pageTitle;
  @override
  final Size preferredSize;

  const ClimbingNotesAppBar({super.key, required this.pageTitle})
      : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      actionsIconTheme:
          IconThemeData(color: contrastingThemeTextColor(context)),
      iconTheme: IconThemeData(color: contrastingThemeTextColor(context)),
      title: Text(pageTitle,
          style: TextStyle(color: contrastingThemeTextColor(context))),
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

class DropdownRow extends StatefulWidget {
  final RouteColor initialValue;
  final Function(RouteColor?)? onSelected;
  final bool? locked;

  DropdownRow(
      {super.key, required this.initialValue, this.onSelected, this.locked});

  @override
  State<StatefulWidget> createState() => DropdownRowState(
        initialValue: initialValue,
        onSelected: onSelected,
        locked: locked,
      );
}

class DropdownRowState extends State<StatefulWidget> {
  RouteColor initialValue;
  Function(RouteColor?)? onSelected;
  bool? locked;
  TextEditingController controller;

  DropdownRowState({required this.initialValue, this.onSelected, this.locked})
      : controller = TextEditingController(text: initialValue.string);

  @override
  Widget build(BuildContext context) {
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
            child: DropdownMenu<RouteColor>(
              controller: controller,
              enabled: !(locked ?? false),
              initialSelection: initialValue,
              inputDecorationTheme: InputDecorationTheme(
                contentPadding:
                    paddingInsideInputBox,
                border: const OutlineInputBorder(),
                disabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).disabledColor)),
              ),
              textStyle: (locked ?? false)
                  ? TextStyle(color: Theme.of(context).disabledColor)
                  : null,
              dropdownMenuEntries: RouteColor.values
                  .map<DropdownMenuEntry<RouteColor>>((RouteColor value) {
                return DropdownMenuEntry<RouteColor>(
                    value: value,
                    label: value.string,
                  );
              }).toList(),
              onSelected: onSelected,
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
    log(" $locked");
    
    return Padding(
      padding: paddingAroundInputBox,
      child: Row(
        children: [
          if (label != null) Text(
            label ?? "",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Expanded(
            child: Padding(
              padding: (label != null ? paddingInsideInputBox : EdgeInsets.zero) ,
              child: TextField(
                enabled: !(locked ?? false),
                readOnly: (locked ?? false),
                controller: controller,
                onChanged: onChanged,
                maxLength: maxLength,
                decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
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

  const CheckboxRow(this.label1, this.label2,
      {super.key,
      this.initialValue1,
      this.initialValue2,
      this.onChanged1,
      this.onChanged2});

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
          Checkbox(value: initialValue1, onChanged: onChanged1),
          Text(
            label2,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Checkbox(value: initialValue2, onChanged: onChanged2),
        ],
      ),
    );
  }
}

Padding padCell(Widget cellContents) {
  return Padding(
    padding: const EdgeInsets.only(left: 3.0),
    child: cellContents,
  );
}
