import 'package:climbing_notes/database_view.dart';
import 'package:climbing_notes/add_route.dart';
import 'package:climbing_notes/data_structures.dart';
import 'package:flutter/material.dart';

const EdgeInsetsGeometry inputSectionElementPadding =
    EdgeInsets.only(top: 4.0, bottom: 4.0);
const EdgeInsetsGeometry inputBoxPadding = EdgeInsets.only(left: 8.0);

Drawer buildDrawer(BuildContext context) {
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
                    style: TextStyle(fontSize: Theme.of(context).textTheme.titleLarge?.fontSize, color: contrastingThemeTextColor(context))),
              ],
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text("Routes"),
          onTap: () => (Navigator.popUntil(
              context,
              ModalRoute.withName('/'))),
        ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text("Add route"),
          onTap: () => {
            Navigator.pop(context),
            Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AddRoutePage())),
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
            Navigator.push(context,
              MaterialPageRoute(builder: (context) => const DatabaseViewPage())),
          },
        ),
      ],
    ),
  );
}

AppBar buildAppBar(BuildContext context, String pageTitle) {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.primary,
    actionsIconTheme: IconThemeData(color: contrastingThemeTextColor(context)),
    iconTheme: IconThemeData(color: contrastingThemeTextColor(context)),
    title:
        Text(pageTitle, style: TextStyle(color: contrastingThemeTextColor(context))),
  );
}

// Widget buildfloatingActionButtons(BuildContext context, {bool? backButton}) {
//   return Align(
//     alignment: Alignment.bottomRight,
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: <Widget>[
//         Visibility(
//           visible: backButton ?? false,
//           child: FloatingActionButton(
//             heroTag: "backFloatBtn",
//             onPressed: () => {
//               Navigator.pop(context),
//             },
//             tooltip: 'Back',
//             child: const Icon(Icons.arrow_back_rounded),
//           ),
//         ),
//         const SizedBox(height: 8),
//         FloatingActionButton(
//           heroTag: "addFloatBtn",
//           onPressed: () => (Navigator.push(context,
//               MaterialPageRoute(builder: (context) => const AddRoutePage()))),
//           tooltip: 'Add route',
//           child: const Icon(Icons.add),
//         ),
//       ],
//     ),
//   );
// }

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

// inverted for now
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

Widget buildLockedDropdownRow(BuildContext context, RouteColor value) {
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
              enabled: false,
              initialSelection: value,
              inputDecorationTheme: InputDecorationTheme(
                disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).disabledColor)),
              ),
              textStyle: TextStyle(color: Theme.of(context).disabledColor),
              dropdownMenuEntries: RouteColor.values
                  .map<DropdownMenuEntry<RouteColor>>((RouteColor value) {
                return DropdownMenuEntry<RouteColor>(
                    value: value, label: value.string);
              }).toList()),
        ),
      ],
    ),
  );
}

Widget buildDropdownRow(BuildContext context, RouteColor initialValue,
    Function(RouteColor?)? callback) {
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
            initialSelection: initialValue,
            dropdownMenuEntries: RouteColor.values
                .map<DropdownMenuEntry<RouteColor>>((RouteColor value) {
              return DropdownMenuEntry<RouteColor>(
                  value: value, label: value.string);
            }).toList(),
            onSelected: callback,
          ),
        ),
      ],
    ),
  );
}

Widget buildLockedInputRow(BuildContext context, String label, String shownText,
    {int? maxLength}) {
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
              enabled: false,
              
              readOnly: true,
              controller: TextEditingController(text: shownText),
              maxLength: maxLength,
              decoration: InputDecoration(disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).disabledColor))),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildInputRow(BuildContext context, String label,
    {TextInputType? inputType, int? maxLength, ValueChanged<String?>? inputCallback}) {
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
              onChanged: inputCallback,
              maxLength: maxLength,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              keyboardType: inputType ?? TextInputType.text,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildLabel(BuildContext context, String text) {
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

Widget buildLockedNotes(BuildContext context, String notes) {
  return Padding(
    padding: inputSectionElementPadding,
    child: Container(
      decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).disabledColor),
          borderRadius: BorderRadius.circular(4.0)),
      constraints: const BoxConstraints(
        minWidth: double.infinity,
        maxWidth: double.infinity,
      ),
      padding: const EdgeInsets.all(8),
      child: Text(
        notes,
        style: TextStyle(color: Theme.of(context).disabledColor),
      ),
    ),
  );
}

Widget buildNotes(BuildContext context) {
  return const Padding(
    padding: inputSectionElementPadding,
    child: Expanded(
      child: TextField(decoration: InputDecoration(border: OutlineInputBorder())),
    ),
  );
}

Widget buildCheckboxRow(BuildContext context, bool finValue, bool restValue,
    ValueChanged<bool?> finCallback, ValueChanged<bool?> restCallback) {
  return Padding(
    padding: const EdgeInsets.only(top: 0, bottom: 0),
    child: Row(
      children: [
        Text(
          "Finished:",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Checkbox(value: finValue, onChanged: finCallback),
        Text(
          "Rested:",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Checkbox(value: restValue, onChanged: restCallback),
      ],
    ),
  );
}

Padding padCell(Widget cellContents) {
  return Padding(
    padding: const EdgeInsets.only(left: 3.0),
    child: cellContents,
  );
}
