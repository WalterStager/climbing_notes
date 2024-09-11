import 'package:climbing_notes/database_view.dart';
import 'package:climbing_notes/add_route.dart';
import 'package:climbing_notes/data_structures.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

const EdgeInsetsGeometry inputSectionElementPadding =
    EdgeInsets.only(top: 4.0, bottom: 4.0);
const EdgeInsetsGeometry inputBoxPadding = EdgeInsets.only(left: 8.0);

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
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Routes"),
            onTap: () => (Navigator.popUntil(
              context,
              ModalRoute.withName('/'),
            )),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("Add route"),
            onTap: () => {
              Navigator.pop(context),
              Navigator.push(
                context,
                PageTransition(
                  duration: const Duration(milliseconds: 500),
                  type: PageTransitionType.leftToRight,
                  child: const AddRoutePage(),
                ),
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () => {
              Navigator.pop(context),
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_tree_sharp),
            title: const Text("DB View"),
            onTap: () => {
              Navigator.pop(context),
              Navigator.push(
                context,
                PageTransition(
                  duration: const Duration(milliseconds: 500),
                  type: PageTransitionType.leftToRight,
                  child: const DatabaseViewPage(),
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class ClimbingNotesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String pageTitle;
  @override
  final Size preferredSize;

  const ClimbingNotesAppBar({super.key, required this.pageTitle}): preferredSize = const Size.fromHeight(kToolbarHeight);

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

class DropdownRow extends StatelessWidget {
  final RouteColor initialValue;
  final Function(RouteColor?)? onSelected;
  final bool? locked;

  const DropdownRow(
      {super.key, required this.initialValue, this.onSelected, this.locked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: inputSectionElementPadding,
      child: Row(
        children: [
          Text(
            "Color:",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Padding(
            padding: inputBoxPadding,
            child: DropdownMenu<RouteColor>(
              enabled: !(locked ?? false),
              initialSelection: initialValue,
              inputDecorationTheme: InputDecorationTheme(
                border: const OutlineInputBorder(),
                disabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).disabledColor)),
              ),
              textStyle: (locked ?? false) ? TextStyle(color: Theme.of(context).disabledColor) : null,
              dropdownMenuEntries: RouteColor.values
                  .map<DropdownMenuEntry<RouteColor>>((RouteColor value) {
                return DropdownMenuEntry<RouteColor>(
                    value: value, label: value.string);
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
  final String label;
  final TextInputType? inputType;
  final int? maxLength;
  final ValueChanged<String?>? onChanged;
  final String? initialValue;
  final bool? locked;

  const InputRow(this.label,
      {super.key,
      this.inputType,
      this.maxLength,
      this.onChanged,
      this.initialValue,
      this.locked});

  @override
  State<StatefulWidget> createState() => InputRowState(
        label,
        inputType: inputType,
        maxLength: maxLength,
        onChanged: onChanged,
        initialValue: initialValue,
        locked: locked,
      );
}

class InputRowState extends State<StatefulWidget> {
  String label;
  TextInputType? inputType;
  int? maxLength;
  ValueChanged<String?>? onChanged;
  String? initialValue;
  TextEditingController controller;
  bool? locked;

  InputRowState(this.label,
      {this.inputType,
      this.maxLength,
      this.onChanged,
      this.initialValue,
      this.locked})
      : controller = TextEditingController(text: initialValue);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: inputSectionElementPadding,
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Expanded(
            child: Padding(
              padding: inputBoxPadding,
              child: TextField(
                enabled: !(locked ?? false),
                readOnly: (locked ?? false),
                controller: controller,
                onChanged: onChanged,
                maxLength: maxLength,
                decoration: InputDecoration(
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
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}

class Notes extends StatefulWidget {
  final bool? locked;
  final String? initialValue;

  const Notes({super.key, this.locked, this.initialValue});

  @override
  State<StatefulWidget> createState() => NotesState(
    locked: locked,
    initialValue: initialValue,
  );

}

class NotesState extends State<Notes> {
  bool? locked;
  String? initialValue;
  TextEditingController controller;

  NotesState({this.locked, this.initialValue}) :  controller = TextEditingController(text: initialValue);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: inputSectionElementPadding,
      child: TextField(
        enabled: !(locked ?? false),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).disabledColor)),
        ),
        minLines: 1,
        controller: controller,
        style: (locked ?? false) ? TextStyle(color: Theme.of(context).disabledColor) : null,
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

  const CheckboxRow(this.label1, this.label2, {super.key, this.initialValue1, this.initialValue2, this.onChanged1, this.onChanged2});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 0),
      child: Row(
        children: [
          Text(
            label1,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Checkbox(value: initialValue1, onChanged: onChanged1),
          Text(
            label2,
            style: Theme.of(context).textTheme.headlineMedium,
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
